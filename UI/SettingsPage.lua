-- Settings page: one card per list (open world / dungeons and raids) and a general one.
-- Options that depend on another one are dimmed when that one is off.

local _, ns = ...
local UI = ns.UI
local C = UI.C
local L = ns.L

local Page = {}
UI.SettingsPage = Page

-- Controls to refresh; enabledIf (optional) decides whether the control is enabled
local controls = {}
local function track(c, enabledIf)
	c.enabledIf = enabledIf
	controls[#controls + 1] = c
	return c
end

local function changed() ns.fire("SETTINGS_CHANGED") end

---------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------
local ICONS, SOUNDS, COLORS = {}, {}, {}
for i = 1, 8 do ICONS[i] = { value = i, text = ns.icon(i, 14) .. "  " .. ns.ICON_NAMES[i] } end
for i, s in ipairs(ns.SOUNDS) do SOUNDS[i] = { value = s.key, text = s.text } end
for i, c in ipairs(ns.COLORS) do COLORS[i] = { value = c.key, text = "|cff" .. c.hex .. c.text .. "|r" } end
local DURATIONS = {
	{ value = 3, text = L["3 seconds"] }, { value = 5, text = L["5 seconds"] }, { value = 8, text = L["8 seconds"] },
	{ value = 12, text = L["12 seconds"] }, { value = 20, text = L["20 seconds"] },
}
local COOLDOWNS = {
	{ value = 30, text = L["30 seconds"] }, { value = 60, text = L["1 minute"] }, { value = 120, text = L["2 minutes"] },
	{ value = 300, text = L["5 minutes"] }, { value = 600, text = L["10 minutes"] }, { value = 1800, text = L["30 minutes"] },
}
local SCALES = {
	{ value = 0.75, text = L["Small (75%)"] }, { value = 1, text = L["Normal (100%)"] },
	{ value = 1.25, text = L["Large (125%)"] }, { value = 1.5, text = L["Huge (150%)"] },
}
local WINDOW_SCALES = {
	{ value = 0.85, text = L["Small (85%)"] }, { value = 1, text = L["Normal (100%)"] },
	{ value = 1.15, text = L["Large (115%)"] }, { value = 1.3, text = L["Huge (130%)"] },
}

local WHEN = {
	{ "nearby", L["When nearby"], L["When their nameplate shows up, you target them or you mouse over them."] },
	{ "inGroup", L["When in your group"], L["When they join your party or raid, or you join theirs."] },
	{ "invite", L["Invites"], L["When they invite you, or you invite them."] },
}
local HOW = {
	{ "screen", L["On-screen alert"], L["Card in the middle of the screen with their name and reasons."] },
	{ "chat", L["Chat message"], L["Prints the alert in your chat window. Only you see it."] },
	{ "plateIcon", L["Nameplate icon"], L["Draws the chosen icon above their nameplate. Only you see it. Needs nameplates turned on (V key)."] },
	{ "raidMark", L["Raid marker"], L["Puts the chosen raid marker on them. Your group sees it too. Never inside instances, so it doesn't override the leader's markers."] },
}

---------------------------------------------------------------------------
-- List card
---------------------------------------------------------------------------
local CARD_W, PAD = 356, 16
local INNER = CARD_W - PAD * 2

local function listCard(parent, id, x)
	local cfg = function() return ns.cfg(id) end
	local groupAlerts = ns.LISTS[id].groupAlerts
	local anyAlert = function()
		local c = cfg()
		return c.nearby or (groupAlerts and (c.inGroup or c.invite))
	end
	local card = UI.panel(parent, C.panel, C.border)
	card:SetSize(CARD_W, 426)
	card:SetPoint("TOPLEFT", x, -14)

	local stripe = card:CreateTexture(nil, "ARTWORK")
	stripe:SetHeight(2)
	stripe:SetPoint("TOPLEFT", 1, -1)
	stripe:SetPoint("TOPRIGHT", -1, -1)
	stripe:SetColorTexture(ns.hexToRGB(ns.LISTS[id].hex))

	local icon = card:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("TOPLEFT", PAD, -14)
	local test = UI.Button(card, L["Test"], "secondary", nil, 24, function() ns.test(id) end)
	test:SetPoint("TOPRIGHT", -PAD, -12)
	test.tip = L["Shows a sample alert with these settings."]
	local title = UI.text(card, 15, C.text, true)
	title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	title:SetPoint("RIGHT", test, "LEFT", -8, 0)
	title:SetText(ns.LISTS[id].label)
	track({ refresh = function() UI.raidIcon(icon, cfg().icon) end })

	local y = -46
	local function section(text)
		UI.Section(card, text, PAD, y)
		y = y - 16
	end
	local function toggle(opt, enabledIf)
		local key = opt[1]
		local t = track(UI.Toggle(card, opt[2], opt[3],
			function() return cfg()[key] end,
			function(v) cfg()[key] = v; changed() end, INNER), enabledIf)
		t:SetPoint("TOPLEFT", PAD, y)
		y = y - 24
	end
	local function dropdown(text, tip, options, key, enabledIf, after)
		local d = track(UI.Dropdown(card, text, options,
			function() return cfg()[key] end,
			function(v) cfg()[key] = v; if after then after(v) end; changed() end, INNER, 170), enabledIf)
		d.tip = tip
		d:SetPoint("TOPLEFT", PAD, y)
		y = y - 28
	end

	section(L["When to alert"])
	if groupAlerts then
		for _, opt in ipairs(WHEN) do toggle(opt) end
	else
		-- Open world: only "When nearby"; the space of the other two rows explains why
		toggle(WHEN[1])
		local note = UI.text(card, 12, C.faint)
		note:SetPoint("TOPLEFT", PAD, y - 4)
		note:SetPoint("TOPRIGHT", -PAD, y - 4)
		note:SetWordWrap(true)
		note:SetText(L["In the open world they're enemies: no group or invite alerts."])
		y = y - 48
	end
	y = y - 6
	section(L["How to alert"])
	toggle(HOW[1], anyAlert)
	toggle(HOW[2], anyAlert)
	toggle(HOW[3])
	toggle(HOW[4])
	y = y - 6
	section(L["Style"])
	local c = cfg
	dropdown(L["Icon"], L["Icon for the alert, the nameplate and the raid marker."], ICONS, "icon",
		function() return c().screen or c().chat or c().plateIcon or c().raidMark end)
	dropdown(L["Sound"], L["Plays with every alert. You hear it when you pick it."], SOUNDS, "sound", anyAlert, ns.playSound)
	dropdown(L["Color"], L["Color of the on-screen alert and the chat text."], COLORS, "color",
		function() return anyAlert() and (c().screen or c().chat) end)
	dropdown(L["Time on screen"], L["How long the alert stays on screen."], DURATIONS, "duration",
		function() return anyAlert() and c().screen end)
	dropdown(L["Repeat alert every"], L["Minimum time between two alerts for the same person when they're nearby."], COOLDOWNS,
		"cooldown", function() return c().nearby end)
	return card
end

---------------------------------------------------------------------------
-- General card
---------------------------------------------------------------------------
local function generalCard(parent)
	local S = function() return ns.settings end
	local card = UI.panel(parent, C.panel, C.border)
	card:SetSize(CARD_W * 2 + 16, 104)
	card:SetPoint("TOPLEFT", 16, -452)

	local reset = UI.Button(card, L["Reset position"], "ghost", nil, 24, function() UI.Banner.reset() end)
	reset:SetPoint("TOPRIGHT", -PAD, -10)
	reset.tip = L["Puts the alert back in its default spot, top center."]
	local move = UI.Button(card, L["Move alert"], "secondary", 120, 24, function()
		UI.Banner.setUnlocked(not UI.Banner.isUnlocked())
		Page.refresh()
	end)
	move:SetPoint("RIGHT", reset, "LEFT", -8, 0)
	move.tip = L["Shows the alert so you can drag it wherever you like. Click again to lock it."]
	track({ refresh = function() move:SetLabel(UI.Banner.isUnlocked() and L["Lock alert"] or L["Move alert"]) end })

	local title = UI.text(card, 15, C.text, true)
	title:SetPoint("TOPLEFT", PAD, -14)
	title:SetText(L["General"])

	local killer = track(UI.Toggle(card, L["Ask who killed me when I die"],
		L["When you die, offers to add the enemy player who seems to have killed you to the open world list."],
		function() return S().killerPrompt end, function(v) S().killerPrompt = v; changed() end, INNER))
	killer:SetPoint("TOPLEFT", PAD, -42)

	local minimap = track(UI.Toggle(card, L["Minimap icon"],
		L["Blacklist button on the edge of the minimap. Drag it to move it."],
		function() return not S().minimap.hide end, function(v) S().minimap.hide = not v; changed() end, INNER))
	minimap:SetPoint("TOPLEFT", CARD_W + 16 + PAD, -42)

	local scale = track(UI.Dropdown(card, L["Alert size"], SCALES,
		function() return S().alertScale end, function(v) S().alertScale = v; changed() end, INNER, 170))
	scale.tip = L["Size of the on-screen alert."]
	scale:SetPoint("TOPLEFT", PAD, -70)

	local wscale = track(UI.Dropdown(card, L["Window size"], WINDOW_SCALES,
		function() return S().windowScale end, function(v) S().windowScale = v; changed() end, INNER, 170))
	wscale.tip = L["Size of this window and the add window. They shrink on their own if they don't fit your screen."]
	wscale:SetPoint("TOPLEFT", CARD_W + 16 + PAD, -70)
end

---------------------------------------------------------------------------
function Page.build(parent)
	listCard(parent, "pvp", 16)
	listCard(parent, "grupo", 16 + CARD_W + 16)
	generalCard(parent)
end

function Page.refresh()
	for _, c in ipairs(controls) do
		if c.enabledIf then c:SetEnabled(c.enabledIf() and true or false) end
		c.refresh()
	end
end

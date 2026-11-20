-- History page: two separate cards, "Killed me" and "Grouped with", each with its own list.
-- Clicking someone adds them to a list (or edits them if they're already on it).

local _, ns = ...
local UI = ns.UI
local C = UI.C
local L = ns.L

local Page = {}
UI.HistoryPage = Page

local CARD_W, ROW_H, NAME_MAX = 356, 46, 190

-- kind -> how its card looks and which list it adds to
local KINDS = {
	kills = {
		title = L["Killed me"], hint = L["Enemy players who seem to have killed you."], list = "pvp",
		empty = L["When an enemy player kills you, they show up here."],
		icon = function(tex) UI.raidIcon(tex, 8) end,
	},
	party = {
		title = L["Grouped with"], hint = L["Players you were in a party or raid with."], list = "grupo",
		empty = L["Everyone you group with shows up here."],
		icon = function(tex) tex:SetTexture("Interface\\Icons\\INV_Misc_GroupNeedMore"); UI.round(tex) end,
	},
}
local cards = {}

---------------------------------------------------------------------------
-- Row actions
---------------------------------------------------------------------------
-- Adds to a list, or edits the entry if they're already on it
local function addTo(data, id)
	local e = data.e
	local hits = ns.app:lookup(e.name, e.realm, e.guid)
	if hits and hits[id] then
		return ns.openEditor({ mode = "edit", list = id, key = hits[id].key })
	end
	local note = data.kind == "kills" and e.zone and L["Killed me in %s"]:format(e.zone) or nil
	-- Only who they are goes to the list entry, not the history counters
	local info = { class = e.class, race = e.race, level = e.level, faction = e.faction, guid = e.guid }
	ns.openEditor({ mode = "add", list = id, name = e.name, realm = e.realm, info = info, note = note })
end

local function rowMenu(row)
	local data = row.data
	if not (data and MenuUtil and MenuUtil.CreateContextMenu) then return end
	local hits = ns.app:lookup(data.e.name, data.e.realm, data.e.guid) or {}
	MenuUtil.CreateContextMenu(row, function(_, root)
		root:CreateTitle(ns.fullName(data.e))
		for _, id in ipairs(ns.ORDER) do
			local text = (hits[id] and L["Edit in %s"] or L["Add to %s"]):format(ns.LISTS[id].label)
			root:CreateButton(text, function() addTo(data, id) end)
		end
		root:CreateDivider()
		root:CreateButton("|cffe5484d" .. L["Remove from history"] .. "|r", function() ns.app:forget(data.kind, data.k) end)
	end)
end

local function meta(e, withZone)
	local t = {}
	if e.level then t[#t + 1] = L["Lv %d"]:format(e.level) end
	if e.race then t[#t + 1] = e.race end
	if withZone and e.zone then t[#t + 1] = e.zone end
	return table.concat(t, " · ")
end

local function rowTooltip(row)
	local data = row.data
	if not data then return end
	local e, m = data.e, C.muted
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(ns.coloredName(e))
	local info = meta(e)
	if e.faction then info = info ~= "" and (info .. " · " .. ns.factionText(e.faction)) or ns.factionText(e.faction) end
	if info ~= "" then GameTooltip:AddLine(info, 1, 1, 1) end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["Last time"], ns.ago(e.last) .. (e.zone and (" · " .. e.zone) or ""), m[1], m[2], m[3], 1, 1, 1)
	GameTooltip:AddDoubleLine(L["First time"], date(L["%b %d, %Y"], e.first or time()), m[1], m[2], m[3], 1, 1, 1)
	GameTooltip:AddDoubleLine(data.kind == "kills" and L["Killed you"] or L["Groups together"], tostring(e.count or 1),
		m[1], m[2], m[3], 1, 1, 1)
	local hits = ns.app:lookup(e.name, e.realm, e.guid)
	if hits then
		local tags = {}
		for _, id in ipairs(ns.ORDER) do
			if hits[id] then tags[#tags + 1] = ns.listTag(id) end
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["On your lists: %s"]:format(table.concat(tags, ", ")), 1, 1, 1)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Click: add to a list · Right-click: more options"], 0.5, 0.75, 1)
	GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------
local function setHover(row, on) UI.setColors(row, on and C.hover or C.field) end

local function buildRow(row)
	UI.skin(row, C.field, C.border)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(26, 26)
	row.icon:SetPoint("LEFT", 10, 0)
	UI.round(row.icon)

	row.when = UI.text(row, 11, C.faint)
	row.when:SetPoint("TOPRIGHT", -10, -8)
	row.when:SetWidth(90)
	row.when:SetJustifyH("RIGHT")
	row.count = UI.text(row, 12, C.muted)
	row.count:SetPoint("BOTTOMRIGHT", -10, 8)
	row.count:SetWidth(90)
	row.count:SetJustifyH("RIGHT")

	row.name = UI.text(row, 14, nil, true)
	row.name:SetPoint("TOPLEFT", 46, -7)
	row.mark = UI.text(row, 12)
	row.mark:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
	row.meta = UI.text(row, 12, C.muted)
	row.meta:SetPoint("BOTTOMLEFT", 46, 8)
	row.meta:SetPoint("RIGHT", row.count, "LEFT", -8, 0)

	row:SetScript("OnEnter", function(self)
		setHover(self, true)
		rowTooltip(self)
	end)
	row:SetScript("OnLeave", function(self)
		setHover(self, false)
		GameTooltip:Hide()
	end)
	row:SetScript("OnClick", function(self, mouse)
		if not self.data then return end
		if mouse == "RightButton" then
			rowMenu(self)
		else
			UI.click()
			addTo(self.data, KINDS[self.data.kind].list)
		end
	end)
	row.built = true
end

local function initRow(row, data)
	if not row.built then buildRow(row) end
	row.data = data
	local e = data.e
	UI.setClassIcon(row.icon, e.class)
	row.name:SetText(ns.coloredName(e))
	row.name:SetWidth(math.min(math.ceil(UI.textWidth(row.name)) + 2, NAME_MAX))

	-- Already on a list: that list's icon next to the name
	local marks = {}
	local hits = ns.app:lookup(e.name, e.realm, e.guid)
	if hits then
		for _, id in ipairs(ns.ORDER) do
			if hits[id] then marks[#marks + 1] = ns.icon(ns.app:cfg(id).icon or 8, 13) end
		end
	end
	row.mark:SetText(table.concat(marks, " "))

	row.meta:SetText(meta(e, true))
	row.when:SetText(ns.ago(e.last))
	if data.kind == "kills" then
		row.count:SetText(("|cffff6b6b%s %d|r"):format(ns.icon(8, 12), e.count or 1))
	else
		row.count:SetText(("×%d"):format(e.count or 1))
	end
	setHover(row, row:IsMouseOver())
end

---------------------------------------------------------------------------
-- Cards
---------------------------------------------------------------------------
local function card(parent, kind, x)
	local k = KINDS[kind]
	local c = UI.panel(parent, C.panel, C.border)
	c:SetWidth(CARD_W)
	c:SetPoint("TOPLEFT", x, -14)
	c:SetPoint("BOTTOMLEFT", x, 16)

	c.icon = c:CreateTexture(nil, "ARTWORK")
	c.icon:SetSize(20, 20)
	c.icon:SetPoint("TOPLEFT", 16, -14)
	k.icon(c.icon)

	c.clear = UI.Button(c, L["Clear"], "ghost", nil, 24, function()
		UI.confirm(L["Clear history"], L["Clear \"%s\"? This can't be undone."]:format(k.title), L["Clear"],
			function() ns.app:clearHistory(kind) end)
	end)
	c.clear:SetPoint("TOPRIGHT", -16, -12)
	c.clear.tip = L["Empties this history. Your lists aren't touched."]

	c.title = UI.text(c, 15, C.text, true)
	c.title:SetPoint("LEFT", c.icon, "RIGHT", 8, 0)
	c.hint = UI.text(c, 12, C.faint)
	c.hint:SetPoint("TOPLEFT", 16, -42)
	c.hint:SetPoint("TOPRIGHT", -16, -42)
	c.hint:SetText(k.hint)

	local box = CreateFrame("Frame", nil, c, "WowScrollBoxList")
	box:SetPoint("TOPLEFT", 12, -64)
	box:SetPoint("BOTTOMRIGHT", -24, 12)
	local bar = CreateFrame("EventFrame", nil, c, "MinimalScrollBar")
	bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 6, 0)
	bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 6, 0)
	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(ROW_H)
	view:SetPadding(0, 0, 0, 0, 4)
	view:SetElementInitializer("Button", initRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
	if ScrollUtil.AddManagedScrollBarVisibilityBehavior then
		ScrollUtil.AddManagedScrollBarVisibilityBehavior(box, bar)
	end
	c.box = box

	c.empty = CreateFrame("Frame", nil, c)
	c.empty:SetSize(CARD_W - 48, 120)
	c.empty:SetPoint("CENTER", box, "CENTER", 0, 20)
	c.empty.icon = c.empty:CreateTexture(nil, "ARTWORK")
	c.empty.icon:SetSize(44, 44)
	c.empty.icon:SetPoint("TOP")
	c.empty.icon:SetAlpha(0.3)
	k.icon(c.empty.icon)
	c.empty.title = UI.text(c.empty, 15, C.text, true)
	c.empty.title:SetPoint("TOP", c.empty.icon, "BOTTOM", 0, -10)
	c.empty.title:SetText(L["Nobody yet"])
	c.empty.hint = UI.text(c.empty, 13, C.muted)
	c.empty.hint:SetPoint("TOP", c.empty.title, "BOTTOM", 0, -8)
	c.empty.hint:SetWidth(CARD_W - 48)
	c.empty.hint:SetWordWrap(true)
	c.empty.hint:SetJustifyH("CENTER")
	c.empty.hint:SetText(k.empty)

	cards[kind] = c
end

function Page.build(parent)
	card(parent, "kills", 16)
	card(parent, "party", 16 + CARD_W + 16)
end

function Page.refresh()
	for kind, c in pairs(cards) do
		local list = ns.app:historyEntries(kind)
		local dp = CreateDataProvider()
		for _, it in ipairs(list) do
			it.kind = kind
			dp:Insert(it)
		end
		c.box:SetDataProvider(dp, ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition or nil)
		c.title:SetText(("%s  |cff%s%d|r"):format(KINDS[kind].title, UI.HEX.faint, #list))
		c.clear:SetEnabled(#list > 0)
		c.empty:SetShown(#list == 0)
	end
end

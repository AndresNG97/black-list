-- Add / edit window: player, list, reasons (tags) and note.

local _, ns = ...
local UI = ns.UI
local C = UI.C
local L = ns.L

local W = 520
local D -- the window
local state = {} -- mode, list, key, info, fromKill, gameName, gameRealm, initTags, initNote, loadedName

local function copyTags(t)
	local out = {}
	if type(t) == "table" then
		for k, v in pairs(t) do if v then out[k] = true end end
	end
	return out
end

---------------------------------------------------------------------------
-- Window state
---------------------------------------------------------------------------
local function currentName()
	if state.gameName then return state.gameName, state.gameRealm end
	return ns.app:parseName(D.nameInput:GetText())
end

-- "Save" only when there is someone to save
local function updateSave()
	local name = currentName()
	D.save:SetEnabled(name ~= nil and name ~= "")
end

-- Fills in reasons and note: the entry's own if it already exists, otherwise the initial ones
local function loadValues()
	local tags, note = state.initTags or {}, state.initNote or ""
	state.loadedName = D.nameInput:GetText()
	if state.mode == "add" then
		local name, realm = currentName()
		local e = name ~= "" and ns.app:find(state.list, name, realm)
		if e then
			tags = e.tags or {}
			if note == "" then note = e.reason or "" end
		end
	end
	for _, id in ipairs(ns.ORDER) do
		for _, chip in ipairs(D.chips[id]) do
			chip:SetShown(id == state.list)
			chip:SetSelected(id == state.list and tags[chip.key])
		end
	end
	-- Whatever you typed in the note is kept when you switch lists
	local typed = D.noteInput:GetText()
	local userEdited = state.loadedNote ~= nil and typed ~= state.loadedNote
	if not userEdited then
		D.noteInput:SetText(note)
		typed = note
	end
	state.loadedNote = typed
end

local function setList(id)
	state.list = id
	D.listSelect:Select(id, state.mode == "edit")
	loadValues()
end

local function save()
	local tags = {}
	for _, chip in ipairs(D.chips[state.list]) do
		if chip.selected then tags[chip.key] = true end
	end
	local note = strtrim(D.noteInput:GetText() or "")

	local app = ns.app
	if state.mode == "edit" then
		app:edit(state.list, state.key, tags, note)
		D:Hide()
		return
	end

	local name, realm = currentName()
	if name == "" then
		D.nameInput:SetFocus()
		return
	end
	if not state.gameName then name = app:parseName(name, true) end
	local e, k = app:add(state.list, name, realm, { reason = note, tags = tags, info = state.info, exact = true, snooze = true })
	if not e then return end -- e.g. you can't add yourself
	if state.fromKill then app:addKill(state.list, k) end
	D:Hide()
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
local function build()
	D = UI.Window({ name = "ListaNegraEditor", w = W, h = 430, strata = "FULLSCREEN_DIALOG", save = "editor" })

	-- Player: portrait and name (if it comes from the game) or a field to type it
	UI.Section(D, L["Player"], 18, -64)
	D.who = CreateFrame("Frame", nil, D)
	D.who:SetPoint("TOPLEFT", 18, -82)
	D.who:SetSize(W - 36, 34)
	D.whoIcon = D.who:CreateTexture(nil, "ARTWORK")
	D.whoIcon:SetSize(32, 32)
	D.whoIcon:SetPoint("LEFT")
	UI.round(D.whoIcon)
	D.whoName = UI.text(D.who, 15, nil, true)
	D.whoName:SetPoint("TOPLEFT", D.whoIcon, "TOPRIGHT", 10, -1)
	D.whoName:SetPoint("TOPRIGHT", D.who, "TOPRIGHT", 0, -1)
	D.whoMeta = UI.text(D.who, 12, C.muted)
	D.whoMeta:SetPoint("TOPLEFT", D.whoName, "BOTTOMLEFT", 0, -3)
	D.whoMeta:SetPoint("TOPRIGHT", D.whoName, "BOTTOMRIGHT", 0, -3)

	D.nameInput = UI.Input(D, W - 36, 30, L["Name or Name-Realm"])
	D.nameInput:SetPoint("TOPLEFT", 18, -84)
	D.nameInput:SetScript("OnEnterPressed", function() D.noteInput:SetFocus() end)
	D.nameInput:SetScript("OnTabPressed", function() D.noteInput:SetFocus() end)
	D.nameInput:HookScript("OnTextChanged", function() if D.save then updateSave() end end)
	-- If you type the name of someone already listed, load their reasons (otherwise leave the checked ones alone)
	D.nameInput:HookScript("OnEditFocusLost", function()
		if state.mode ~= "add" or state.gameName then return end
		local text = D.nameInput:GetText()
		if text == state.loadedName then return end
		local n, r = ns.app:parseName(text)
		if n ~= "" and ns.app:find(state.list, n, r) then loadValues() else state.loadedName = text end
	end)

	-- List
	UI.Section(D, L["List"], 18, -130)
	local items = {}
	for i, id in ipairs(ns.ORDER) do
		items[i] = { value = id, text = ns.LISTS[id].label, rgb = UI.listRGB(id) }
	end
	D.listSelect = UI.Segmented(D, items, setList, W - 36, 32)
	D.listSelect:SetPoint("TOPLEFT", 18, -148)

	-- Reasons
	UI.Section(D, L["Reasons"], 18, -196)
	D.chips = {}
	local chipsH = 0
	for _, id in ipairs(ns.ORDER) do
		D.chips[id] = {}
		for i, p in ipairs(ns.PRESETS[id]) do
			local chip = UI.Chip(D, p.text, UI.listRGB(id))
			chip.key = p.key
			D.chips[id][i] = chip
		end
		chipsH = math.max(chipsH, UI.flow(D.chips[id], D, 18, -214, W - 36, 6))
	end

	-- Note (below the tags, which can take up several rows)
	local noteY = -214 - chipsH - 18
	UI.Section(D, L["Note"], 18, noteY)
	D.noteInput = UI.Input(D, W - 36, 30, L["Optional: what happened, where, with whom..."])
	D.noteInput:SetPoint("TOPLEFT", 18, noteY - 18)
	D.noteInput:SetMaxLetters(250)
	D.noteInput:SetScript("OnEnterPressed", save)
	D.noteInput:SetScript("OnTabPressed", function()
		if D.nameInput:IsShown() then D.nameInput:SetFocus() end
	end)
	local height = -(noteY - 18) + 30 + 24 + 30 + 18
	D:SetHeight(height)
	D.baseH = height

	-- Buttons
	D.save = UI.Button(D, SAVE or L["Save"], "primary", 120, 30, save)
	D.save:SetPoint("BOTTOMRIGHT", -18, 18)
	D.save.tip = L["Saves the reasons and the note (Enter)."]
	D.cancel = UI.Button(D, CANCEL or L["Cancel"], "secondary", 110, 30, function() D:Hide() end)
	D.cancel:SetPoint("RIGHT", D.save, "LEFT", -8, 0)
	D.cancel.tip = L["Closes without saving (Esc)."]
	D.remove = UI.Button(D, L["Remove from list"], "danger", nil, 30, function()
		local e = ns.app:entry(state.list, state.key)
		if not e then return end
		local list, key = state.list, state.key
		D:Hide()
		UI.confirm(L["Remove from list"], L["Remove %s from %s?"]:format(ns.coloredName(e), ns.listTag(list)), L["Remove"],
			function() ns.app:remove(list, key) end)
	end)
	D.remove:SetPoint("BOTTOMLEFT", 18, 18)
end

local function showWho(name, realm, info)
	info = info or {}
	D.who:Show()
	D.nameInput:Hide()
	UI.setClassIcon(D.whoIcon, info.class)
	D.whoName:SetText(ns.coloredName({ name = name, realm = ns.app:normRealm(realm), class = info.class }))
	local meta = {}
	if info.level then meta[#meta + 1] = L["Level %d"]:format(info.level) end
	if info.race then meta[#meta + 1] = info.race end
	if info.faction then meta[#meta + 1] = ns.factionText(info.faction) end
	D.whoMeta:SetText(table.concat(meta, " · "))
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- opts: mode ("add" | "edit"), list, key (edit), name, realm, info, note, fromKill
function ns.openEditor(opts)
	if not D then build() end
	wipe(state)
	state.mode = opts.mode or "add"
	state.key, state.info, state.fromKill = opts.key, opts.info, opts.fromKill
	state.initNote = opts.note
	D.nameInput:SetText("")

	if state.mode == "edit" then
		local e = ns.app:entry(opts.list, opts.key)
		if not e then return end
		D:SetTitle(L["Edit entry"])
		D:SetSubtitle(L["Added %s · seen %s"]:format(date(L["%b %d, %Y"], e.added or time()), ns.ago(e.lastSeen)))
		showWho(e.name, e.realm, e)
		state.gameName, state.gameRealm = e.name, e.realm
		state.initTags, state.initNote = copyTags(e.tags), e.reason or ""
		D.remove:Show()
	else
		D.remove:Hide()
		if opts.fromKill then
			D:SetTitle(L["Looks like they killed you"])
			D:SetSubtitle(L["Add them to your blacklist?"])
		else
			D:SetTitle(L["Add to blacklist"])
			D:SetSubtitle(L["Pick the list and check the reasons"])
		end
		if opts.name then
			state.gameName, state.gameRealm = opts.name, opts.realm
			showWho(opts.name, opts.realm, opts.info)
		else
			D.who:Hide()
			D.nameInput:Show()
		end
	end
	setList(opts.list or "pvp")
	updateSave()
	D:Show()
	D:Raise()
	if state.mode == "add" and not opts.name then D.nameInput:SetFocus() end
end

-- Used by the right-click menu and /ln
function ns.promptAdd(id, name, realm, note, info, fromKill)
	ns.openEditor({ mode = "add", list = id, name = name, realm = realm, note = note, info = info, fromKill = fromKill })
end

-- ADAPTER · Port prompt: the application asks to open the add window
-- (your target without reasons, or "Looks like they killed you")
ns.Adapters.prompt = {
	add = function(id, name, realm, info, ctx)
		ctx = ctx or {}
		local note = ctx.fromKill and L["Killed me in %s"]:format(ctx.zone or "?") or nil
		ns.promptAdd(id, name, realm, note, info, ctx.fromKill)
	end,
}

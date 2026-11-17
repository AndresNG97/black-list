-- Main window: header, tabs (Open world, Dungeons / Raids, Alerts) and pages.

local _, ns = ...
local UI = ns.UI
local L = ns.L

local W
local current = "pvp"

local function build()
	W = UI.Window({ name = "ListaNegraFrame", w = 760, h = 660, title = L["Blacklist"], save = "main" })

	local items = {}
	for i, id in ipairs(ns.ORDER) do
		items[i] = { value = id, tip = id == "pvp" and L["People you run into in the open world."]
			or L["People you never want to group with again."] }
	end
	items[#items + 1] = { value = "avisos", text = L["Alerts"], tip = L["When and how each list alerts you."] }
	W.tabs = UI.Tabs(W, items, function(v)
		current = v
		ns.refreshWindow()
	end)
	W.tabs:SetPoint("TOPLEFT", 16, -50)
	W.tabs:SetPoint("TOPRIGHT", -16, -50)

	W.listPage = CreateFrame("Frame", nil, W)
	W.listPage:SetPoint("TOPLEFT", 0, -86)
	W.listPage:SetPoint("BOTTOMRIGHT")
	W.settingsPage = CreateFrame("Frame", nil, W)
	W.settingsPage:SetPoint("TOPLEFT", 0, -86)
	W.settingsPage:SetPoint("BOTTOMRIGHT")
	UI.ListPage.build(W.listPage)
	UI.SettingsPage.build(W.settingsPage)

	W:HookScript("OnShow", function() ns.refreshWindow() end)
	W:HookScript("OnHide", function()
		if UI.Banner.isUnlocked() then UI.Banner.setUnlocked(false) end
	end)
end

function ns.refreshWindow()
	if not (W and W:IsShown()) then return end
	local counts = {}
	for _, id in ipairs(ns.ORDER) do
		counts[id] = ns.count(id)
		W.tabs:SetItemText(id, ("%s  %s  |cff%s%d|r"):format(ns.icon(ns.cfg(id).icon or 8, 14), ns.LISTS[id].label,
			UI.HEX.faint, counts[id]))
	end
	W.tabs:Select(current)
	W:SetSubtitle(L["%d in open world · %d in dungeons and raids"]:format(counts.pvp, counts.grupo))

	local settings = current == "avisos"
	W.listPage:SetShown(not settings)
	W.settingsPage:SetShown(settings)
	if settings then UI.SettingsPage.refresh() else UI.ListPage.refresh(current) end
end

function ns.openWindow(tab)
	if not W then build() end
	if tab then current = tab end
	if W:IsShown() then ns.refreshWindow() else W:Show() end
end

function ns.toggleWindow()
	if W and W:IsShown() then W:Hide() else ns.openWindow() end
end

-- Button in the minimap's add-on compartment
function ListaNegra_OnCompartmentClick() ns.toggleWindow() end

-- Seeing someone changes "seen %s": batched refresh, at most once every half second
local pending = false
local function refreshSoon()
	if pending or not (W and W:IsShown()) or current == "avisos" then return end
	pending = true
	C_Timer.After(0.5, function()
		pending = false
		ns.refreshWindow()
	end)
end

ns.onLoad(function()
	ns.listen("LISTS_CHANGED", ns.refreshWindow)
	ns.listen("SETTINGS_CHANGED", ns.refreshWindow)
	ns.listen("SIGHTING", refreshSoon)
end)

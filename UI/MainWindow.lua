-- Ventana principal: cabecera, pestañas (Mundo abierto, Mazmorras / Bandas, Avisos) y páginas.

local _, ns = ...
local UI = ns.UI

local W
local current = "pvp"

local function build()
	W = UI.Window("ListaNegraFrame", 760, 660, "Lista Negra")

	local items = {}
	for i, id in ipairs(ns.ORDER) do items[i] = { value = id } end
	items[#items + 1] = { value = "avisos", text = "Avisos" }
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

	W:SetScript("OnShow", function() ns.refreshWindow() end)
	W:SetScript("OnHide", function()
		if UI.Banner.isUnlocked() then UI.Banner.setUnlocked(false) end
	end)
end

function ns.refreshWindow()
	if not (W and W:IsShown()) then return end
	local counts = {}
	for _, id in ipairs(ns.ORDER) do
		counts[id] = ns.count(id)
		W.tabs:SetItemText(id, ("%s  %s  |cff%s%d|r"):format(ns.icon(ns.cfg(id).icon or 8, 14), ns.LISTS[id].label, UI.HEX.faint, counts[id]))
	end
	W.tabs:Select(current)
	W:SetSubtitle(("%d en mundo abierto · %d en mazmorras y bandas"):format(counts.pvp, counts.grupo))

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

-- Botón en el compartimento de add-ons del minimapa
function ListaNegra_OnCompartmentClick() ns.toggleWindow() end

-- Ver a alguien cambia "visto hace...": refresco agrupado, como mucho uno cada medio segundo
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

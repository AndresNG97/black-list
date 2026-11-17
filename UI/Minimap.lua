-- Botón en el borde del minimapa (clic: listas, clic derecho: avisos, arrastrar: mover).
-- Mismo aspecto y colocación que los botones de LibDBIcon, sin depender de librerías.

local _, ns = ...
local btn
local RADIUS = 5

local function place()
	local angle = math.rad(ns.settings.minimap.angle or 200)
	local x, y = math.cos(angle), math.sin(angle)
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	if shape == "SQUARE" then
		-- En un minimapa cuadrado, lleva el botón hasta el borde
		local d = math.sqrt(2)
		x = math.max(-1, math.min(x * d, 1))
		y = math.max(-1, math.min(y * d, 1))
	end
	local w = Minimap:GetWidth() / 2 + RADIUS
	local h = Minimap:GetHeight() / 2 + RADIUS
	btn:ClearAllPoints()
	btn:SetPoint("CENTER", Minimap, "CENTER", x * w, y * h)
end

local function onUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	px, py = px / scale, py / scale
	ns.settings.minimap.angle = math.deg(math.atan2(py - my, px - mx)) % 360
	place()
end

local function showTooltip(self)
	local L = ns.L
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine(ns.icon(8, 14) .. " " .. L["Blacklist"], 1, 1, 1)
	for _, id in ipairs(ns.ORDER) do
		local r, g, b = ns.hexToRGB(ns.LISTS[id].hex)
		GameTooltip:AddDoubleLine(ns.LISTS[id].label, tostring(ns.count(id)), r, g, b, 1, 1, 1)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Click: open the lists"], 0.64, 0.66, 0.72)
	GameTooltip:AddLine(L["Right-click: alert settings"], 0.64, 0.66, 0.72)
	GameTooltip:AddLine(L["Drag: move the icon"], 0.64, 0.66, 0.72)
	GameTooltip:Show()
end

local function build()
	btn = CreateFrame("Button", "ListaNegraMinimapButton", Minimap)
	btn:SetSize(31, 31)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(8)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:RegisterForDrag("LeftButton")
	btn:SetHighlightTexture(136477) -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight

	local retail = WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(136467) -- Interface\Minimap\UI-Minimap-Background
	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetTexture(136430) -- Interface\Minimap\MiniMap-TrackingBorder
	border:SetPoint("TOPLEFT")
	if retail then
		bg:SetSize(24, 24)
		bg:SetPoint("CENTER")
		icon:SetSize(18, 18)
		icon:SetPoint("CENTER")
		border:SetSize(50, 50)
	else
		bg:SetSize(20, 20)
		bg:SetPoint("TOPLEFT", 7, -5)
		icon:SetSize(17, 17)
		icon:SetPoint("TOPLEFT", 7, -6)
		border:SetSize(53, 53)
	end

	btn:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" then ns.openWindow("avisos") else ns.toggleWindow() end
	end)
	btn:SetScript("OnDragStart", function(self)
		self:LockHighlight()
		GameTooltip:Hide()
		self:SetScript("OnUpdate", onUpdate)
	end)
	btn:SetScript("OnDragStop", function(self)
		self:UnlockHighlight()
		self:SetScript("OnUpdate", nil)
	end)
	btn:SetScript("OnEnter", showTooltip)
	btn:SetScript("OnLeave", GameTooltip_Hide)
end

local function update()
	if not Minimap then return end
	if not btn then build() end
	btn:SetShown(not ns.settings.minimap.hide)
	place()
end
ns.updateMinimap = update

ns.onLoad(function()
	update()
	ns.listen("SETTINGS_CHANGED", update)
end)

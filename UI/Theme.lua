-- Tema visual: colores, tipografías, fondos planos con borde de 1 px, iconos de clase.

local _, ns = ...
local UI = ns.UI

UI.C = {
	bg       = { 0.055, 0.059, 0.071, 0.97 },
	panel    = { 0.090, 0.094, 0.114, 1 },
	hover    = { 0.125, 0.130, 0.157, 1 },
	field    = { 0.039, 0.043, 0.051, 1 },
	border   = { 1, 1, 1, 0.07 },
	borderHi = { 1, 1, 1, 0.15 },
	text     = { 0.93, 0.94, 0.96, 1 },
	muted    = { 0.60, 0.62, 0.68, 1 },
	faint    = { 0.40, 0.42, 0.48, 1 },
	accent   = { 0.898, 0.282, 0.302, 1 },
	accentHi = { 0.957, 0.380, 0.400, 1 },
	off      = { 0.22, 0.23, 0.27, 1 },
	none     = { 0, 0, 0, 0 },
}
UI.HEX = { muted = "9aa0ae", faint = "666b7a", accent = "e5484d" }

---------------------------------------------------------------------------
-- Tipografías: Arial Narrow para el texto, Friz Quadrata para títulos
---------------------------------------------------------------------------
local BODY = "Fonts\\ARIALN.TTF"
local HEAD = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local fonts = {}

function UI.font(size, head)
	local key = (head and "H" or "B") .. size
	local f = fonts[key]
	if not f then
		f = CreateFont("ListaNegraFont" .. key)
		f:SetFont(head and HEAD or BODY, size, "")
		if not f:GetFont() then f:SetFont(HEAD, size, "") end
		f:SetTextColor(unpack(UI.C.text))
		f:SetShadowColor(0, 0, 0, 0.6)
		f:SetShadowOffset(1, -1)
		fonts[key] = f
	end
	return f
end

function UI.text(parent, size, color, head, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	fs:SetFontObject(UI.font(size or 13, head))
	fs:SetJustifyH("LEFT")
	fs:SetWordWrap(false)
	if color then fs:SetTextColor(unpack(color)) end
	return fs
end

---------------------------------------------------------------------------
-- Fondo plano con borde de 1 px (sin plantillas de Blizzard)
---------------------------------------------------------------------------
local EDGES = {
	{ "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
	{ "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false },
}

function UI.setColors(f, bg, border)
	if bg then f._bg:SetColorTexture(unpack(bg)) end
	if border then
		for _, t in ipairs(f._edges) do t:SetColorTexture(unpack(border)) end
	end
end

function UI.skin(f, bg, border)
	if not f._bg then
		f._bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
		f._bg:SetAllPoints()
		f._edges = {}
		for i, e in ipairs(EDGES) do
			local t = f:CreateTexture(nil, "BORDER", nil, -8)
			t:SetPoint(e[1])
			t:SetPoint(e[2])
			if e[3] then t:SetHeight(1) else t:SetWidth(1) end
			f._edges[i] = t
		end
	end
	UI.setColors(f, bg or UI.C.panel, border or UI.C.border)
	return f
end

function UI.panel(parent, bg, border, kind)
	return UI.skin(CreateFrame(kind or "Frame", nil, parent), bg, border)
end

---------------------------------------------------------------------------
-- Formas e iconos
---------------------------------------------------------------------------
local MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

-- Recorta una textura en círculo
function UI.round(tex)
	local m = tex:GetParent():CreateMaskTexture()
	m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(tex)
	tex:AddMaskTexture(m)
	return m
end

function UI.setClassIcon(tex, class)
	tex:SetTexCoord(0, 1, 0, 1)
	if class then
		local atlas = "classicon-" .. class:lower()
		if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
			tex:SetAtlas(atlas)
			return
		end
		if CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] then
			tex:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
			tex:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
			return
		end
	end
	tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
end

function UI.raidIcon(tex, index)
	tex:SetTexCoord(0, 1, 0, 1)
	tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. (index or 8))
end

function UI.listRGB(id)
	return { ns.hexToRGB(ns.LISTS[id].hex) }
end

function UI.tip(owner, title, text)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(title, 1, 1, 1)
	if text then GameTooltip:AddLine(text, 0.8, 0.8, 0.82, true) end
	GameTooltip:Show()
end

function UI.click()
	if SOUNDKIT and SOUNDKIT.U_CHAT_SCROLL_BUTTON then PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end
end

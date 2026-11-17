-- Visual theme: colors, fonts, flat backgrounds with a true 1-pixel border, class icons.

local _, ns = ...
local UI = ns.UI

-- Contrast against the panel background (~#17181d): text ~15:1, muted ~7:1, faint ~4.6:1
UI.C = {
	bg       = { 0.055, 0.059, 0.071, 0.97 },
	panel    = { 0.090, 0.094, 0.114, 1 },
	hover    = { 0.125, 0.130, 0.157, 1 },
	pressed  = { 0.070, 0.074, 0.090, 1 },
	field    = { 0.039, 0.043, 0.051, 1 },
	border   = { 1, 1, 1, 0.08 },
	borderHi = { 1, 1, 1, 0.16 },
	text     = { 0.93, 0.94, 0.96, 1 },
	muted    = { 0.64, 0.66, 0.72, 1 },
	faint    = { 0.50, 0.52, 0.58, 1 },
	accent   = { 0.898, 0.282, 0.302, 1 },
	accentHi = { 0.957, 0.380, 0.400, 1 },
	off      = { 0.26, 0.27, 0.31, 1 },
	none     = { 0, 0, 0, 0 },
}
UI.HEX = { muted = "a3a8b8", faint = "808594", accent = "e5484d" }

---------------------------------------------------------------------------
-- Fonts: the ones for the client's language (so Cyrillic, Korean or Chinese names
-- display correctly). Body text: chat font (Arial Narrow on English/Spanish clients). Titles: standard font.
---------------------------------------------------------------------------
local fonts = {}

local function bodyFont()
	local file = ChatFontNormal and ChatFontNormal:GetFont()
	return file or STANDARD_TEXT_FONT
end

function UI.font(size, head)
	local key = (head and "H" or "B") .. size
	local f = fonts[key]
	if not f then
		f = CreateFont("ListaNegraFont" .. key)
		f:SetFont(head and STANDARD_TEXT_FONT or bodyFont(), size, "")
		if not f:GetFont() then f:SetFont(STANDARD_TEXT_FONT, size, "") end
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

-- Real text width even when the FontString is constrained
function UI.textWidth(fs)
	return fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
end

---------------------------------------------------------------------------
-- 1-physical-pixel lines: recalculated when the UI scale or window size changes
---------------------------------------------------------------------------
local pixelLines = setmetatable({}, { __mode = "k" })

local function onePixel(region)
	local factor = PixelUtil and PixelUtil.GetPixelToUIUnitFactor and PixelUtil.GetPixelToUIUnitFactor()
	if not factor then
		local _, h = GetPhysicalScreenSize()
		factor = 768 / h
	end
	-- A texture's effective scale is that of its frame
	return factor / math.max(region:GetParent():GetEffectiveScale(), 0.01)
end

local function sizeLine(t)
	local px = onePixel(t)
	if t._horizontal then t:SetHeight(px) else t:SetWidth(px) end
end

function UI.pixelLine(t, horizontal)
	t._horizontal = horizontal
	if t.SetSnapToPixelGrid then
		t:SetSnapToPixelGrid(false)
		t:SetTexelSnappingBias(0)
	end
	pixelLines[t] = true
	sizeLine(t)
end

function UI.refreshPixels()
	for t in pairs(pixelLines) do sizeLine(t) end
end

---------------------------------------------------------------------------
-- Flat background with border (no Blizzard templates)
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
			UI.pixelLine(t, e[3])
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
-- Shapes and icons
---------------------------------------------------------------------------
local MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

-- Crops a texture into a circle
function UI.round(tex)
	local m = tex:GetParent():CreateMaskTexture()
	m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	m:SetAllPoints(tex)
	tex:AddMaskTexture(m)
	return m
end

-- Cross drawn with two lines (doesn't depend on the font having the × character)
function UI.cross(parent, size, color)
	local lines = {}
	local h = size / 2
	for i, d in ipairs({ { -h, h, h, -h }, { -h, -h, h, h } }) do
		local l = parent:CreateLine(nil, "OVERLAY")
		l:SetThickness(1.6)
		l:SetColorTexture(unpack(color or UI.C.muted))
		l:SetStartPoint("CENTER", parent, d[1], d[2])
		l:SetEndPoint("CENTER", parent, d[3], d[4])
		lines[i] = l
	end
	function lines.SetColor(_, c)
		for i = 1, 2 do lines[i]:SetColorTexture(unpack(c)) end
	end
	return lines
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

-- Standard tooltip: white title and light gray wrapped description
function UI.tip(owner, title, text, anchor)
	GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
	GameTooltip:AddLine(title, 1, 1, 1)
	if text then GameTooltip:AddLine(text, 0.8, 0.8, 0.82, true) end
	GameTooltip:Show()
end

function UI.click()
	if SOUNDKIT and SOUNDKIT.U_CHAT_SCROLL_BUTTON then PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end
end

ns.onLoad(function()
	ns.on("UI_SCALE_CHANGED", UI.refreshPixels)
	ns.on("DISPLAY_SIZE_CHANGED", UI.refreshPixels)
end)

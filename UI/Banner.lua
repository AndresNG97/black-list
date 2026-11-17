-- On-screen alert: dark card with a color stripe, icon, name and reasons.
-- Can be moved (unlock, drag, lock) and resized.

local _, ns = ...
local UI = ns.UI
local C = UI.C

local Banner = {}
UI.Banner = Banner

local f, unlocked

-- The position is saved in screen units (not the alert's scale), so that
-- resizing doesn't move it
local function savePos()
	local point, _, relPoint, x, y = f:GetPoint(1)
	local s = f:GetScale()
	ns.settings.alertPos = { point = point, relPoint = relPoint, x = x * s, y = y * s, screen = true }
end

local function applyPos()
	local s = ns.settings.alertScale or 1
	f:SetScale(s)
	f:ClearAllPoints()
	local p = ns.settings.alertPos
	if type(p) == "table" and p.point then
		local k = p.screen and s or 1 -- old positions saved without converting
		f:SetPoint(p.point, UIParent, p.relPoint or p.point, (p.x or 0) / k, (p.y or 0) / k)
	else
		f:SetPoint("TOP", UIParent, "TOP", 0, -140 / s)
	end
	UI.refreshPixels()
end

local function setColor(hex)
	local r, g, b = ns.hexToRGB(hex)
	f.stripe:SetColorTexture(r, g, b, 1)
	f.glow:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.28), CreateColor(r, g, b, 0))
end

local function fit()
	f:SetHeight(math.max(66, 30 + f.title:GetStringHeight() + (f.sub:GetText() ~= "" and f.sub:GetStringHeight() + 5 or 0)))
end

local function build()
	f = UI.panel(UIParent, { 0.05, 0.055, 0.065, 0.94 }, { 1, 1, 1, 0.10 })
	_G.ListaNegraAlert = f
	f:SetSize(460, 66)
	f:SetFrameStrata("HIGH")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		savePos()
	end)
	f:EnableMouse(false)
	f:Hide()

	f.glow = f:CreateTexture(nil, "BACKGROUND", nil, -7)
	f.glow:SetTexture("Interface\\Buttons\\WHITE8X8")
	f.glow:SetPoint("TOPLEFT", 1, -1)
	f.glow:SetPoint("BOTTOMLEFT", 1, 1)
	f.glow:SetWidth(180)
	f.stripe = f:CreateTexture(nil, "ARTWORK")
	f.stripe:SetWidth(4)
	f.stripe:SetPoint("TOPLEFT", 1, -1)
	f.stripe:SetPoint("BOTTOMLEFT", 1, 1)

	f.icon = f:CreateTexture(nil, "OVERLAY")
	f.icon:SetSize(38, 38)
	f.icon:SetPoint("LEFT", 18, 0)
	f.title = UI.text(f, 17, C.text, true)
	f.title:SetPoint("TOPLEFT", 68, -14)
	f.title:SetPoint("TOPRIGHT", -16, -14)
	f.sub = UI.text(f, 13, C.muted)
	f.sub:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -5)
	f.sub:SetPoint("TOPRIGHT", f.title, "BOTTOMRIGHT", 0, -5)
	f.sub:SetWordWrap(true)
	f.sub:SetMaxLines(2)

	f.anim = f:CreateAnimationGroup()
	local fadeIn = f.anim:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(0.15)
	fadeIn:SetOrder(1)
	f.fadeOut = f.anim:CreateAnimation("Alpha")
	f.fadeOut:SetFromAlpha(1)
	f.fadeOut:SetToAlpha(0)
	f.fadeOut:SetDuration(1.2)
	f.fadeOut:SetOrder(2)
	f.anim:SetScript("OnFinished", function() f:Hide() end)
	applyPos()
end

local function get()
	if not f then build() end
	return f
end

-- id: list (for the icon, color and duration); e: the person; what: "is nearby"...
function Banner.show(id, e, what, detail)
	local c = ns.cfg(id)
	get()
	if unlocked then return end
	local hex = ns.colorHex(c.color)
	setColor(hex)
	UI.raidIcon(f.icon, c.icon or 8)
	f.title:SetText(("%s |cff%s%s|r"):format(ns.coloredName(e), hex, what))
	f.sub:SetText(detail or "")
	fit()
	f.fadeOut:SetStartDelay(c.duration or 5)
	f.anim:Stop()
	f:SetAlpha(1)
	f:Show()
	f.anim:Play()
end

-- Moving the alert: stays visible and draggable until it's locked again
function Banner.setUnlocked(on)
	get()
	unlocked = on and true or false
	f.anim:Stop()
	f:EnableMouse(unlocked)
	if unlocked then
		setColor(UI.HEX.accent)
		UI.setColors(f, nil, C.accent)
		UI.raidIcon(f.icon, 8)
		f.title:SetText(ns.L["Drag the alert wherever you like"])
		f.sub:SetText(ns.L["Click \"Lock alert\" in the settings when you're done."])
		fit()
		f:SetAlpha(1)
		f:Show()
	else
		UI.setColors(f, nil, { 1, 1, 1, 0.10 })
		f:Hide()
	end
end

function Banner.isUnlocked() return unlocked end

function Banner.reset()
	ns.settings.alertPos = nil
	if f then applyPos() end
end

ns.onLoad(function()
	ns.listen("SETTINGS_CHANGED", function() if f then applyPos() end end)
end)

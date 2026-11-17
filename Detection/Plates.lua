-- Nameplates: our own icon on top (only you see it) and raid marker (your group sees it).

local _, ns = ...
local isSecret, safe, plain = ns.isSecret, ns.safe, ns.plain

local Plates = {}
ns.Plates = Plates

---------------------------------------------------------------------------
-- Raid marker
---------------------------------------------------------------------------
-- If the game blocks the marker in combat, stop trying until combat ends
local blockedThisCombat = false

local function canRaidMark(id)
	if not ns.cfg(id).raidMark then return false end
	if blockedThisCombat and InCombatLockdown() then return false end
	if IsInInstance() then return false end -- don't override the leader's markers in instances
	if IsInRaid() then return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") end
	return true
end

function Plates.raidMark(id, unit)
	if not canRaidMark(id) then return end
	local icon = ns.cfg(id).icon or 8
	if plain(safe(GetRaidTargetIndex, unit)) == icon then return end
	safe(SetRaidTarget, unit, icon)
end

---------------------------------------------------------------------------
-- Icon above the nameplate
---------------------------------------------------------------------------
local overlays = {} -- [nameplate] = frame with the icon

local function plateFor(unit)
	if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
	local plate = plain(safe(C_NamePlate.GetNamePlateForUnit, unit))
	if type(plate) ~= "table" then return end
	if plate.IsForbidden and plate:IsForbidden() then return end
	return plate
end

-- If the game already shows that same raid icon on it, don't duplicate it
local function updateOverlay(o)
	o:SetShown(o.unit ~= nil and plain(safe(GetRaidTargetIndex, o.unit)) ~= o.icon)
end

function Plates.setIcon(unit, icon)
	local plate = plateFor(unit)
	if not plate then return end
	local o = overlays[plate]
	if not o then
		local ok, frame = pcall(CreateFrame, "Frame", nil, plate)
		if not ok or not frame then return end
		o = frame
		o:SetSize(34, 34)
		o:SetPoint("BOTTOM", plate, "TOP", 0, 4)
		-- Above other add-ons' nameplates (ElvUI, Plater...), which hang off the same plate
		o:SetFrameLevel(plate:GetFrameLevel() + 50)
		o.tex = o:CreateTexture(nil, "OVERLAY")
		o.tex:SetAllPoints()
		overlays[plate] = o
	end
	o.unit, o.icon = unit, icon
	o.tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. icon)
	updateOverlay(o)
end

function Plates.clear(unit)
	for _, o in pairs(overlays) do
		if o.unit == unit then
			o.unit = nil
			o:Hide()
		end
	end
end

function Plates.each(fn)
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	local plates = plain(safe(C_NamePlate.GetNamePlates))
	if type(plates) ~= "table" then return end
	for _, plate in ipairs(plates) do
		local u = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if type(u) == "string" and not isSecret(u) then fn(u) end
	end
end

-- Repaint all visible nameplates (no alerts)
function Plates.refresh()
	for _, o in pairs(overlays) do
		o.unit = nil
		o:Hide()
	end
	Plates.each(function(u) ns.checkUnit(u, true) end)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- If the game blocks the raid marker: in combat, pause until combat ends; out of combat,
-- turn it off in the settings (our own nameplate icon keeps working)
local function onForbidden(addon, fn)
	if addon ~= ns.ADDON or type(fn) ~= "string" or not fn:find("SetRaidTarget") then return end
	if InCombatLockdown() then
		if not blockedThisCombat then
			blockedThisCombat = true
			ns.say(ns.L["The game blocks raid markers in combat; trying again when combat ends."])
		end
		return
	end
	local was = false
	for _, id in ipairs(ns.ORDER) do
		was = was or ns.cfg(id).raidMark
		ns.cfg(id).raidMark = false
	end
	if was then
		ns.say(ns.L["The game doesn't let add-ons set raid markers here; using only the nameplate icon."])
		ns.fire("SETTINGS_CHANGED")
	end
end

ns.onLoad(function()
	ns.on("NAME_PLATE_UNIT_REMOVED", Plates.clear)
	ns.on("RAID_TARGET_UPDATE", function()
		for _, o in pairs(overlays) do
			if o.unit then updateOverlay(o) end
		end
	end)
	ns.on("PLAYER_ENTERING_WORLD", function() C_Timer.After(2, Plates.refresh) end)
	ns.on("ADDON_ACTION_FORBIDDEN", onForbidden)
	ns.on("ADDON_ACTION_BLOCKED", onForbidden)
	ns.on("PLAYER_REGEN_ENABLED", function() blockedThisCombat = false end)
	ns.listen("LISTS_CHANGED", Plates.refresh)
	ns.listen("SETTINGS_CHANGED", Plates.refresh)
end)

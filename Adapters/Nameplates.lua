-- ADAPTER · Port plates: our own icon above the nameplate (only you see it) and the
-- nameplate settings that nearby detection needs.
-- No raid markers: since the Midnight engine SetRaidTarget is protected, and an add-on
-- calling it gets the game's "blocked action" popup.

local _, ns = ...
local isSecret, safe, plain = ns.isSecret, ns.safe, ns.plain

local overlays = {} -- [nameplate] = frame with the icon

local function plateFor(unit)
	if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
	local plate = plain(safe(C_NamePlate.GetNamePlateForUnit, unit))
	if type(plate) ~= "table" then return end
	if plate.IsForbidden and plate:IsForbidden() then return end
	return plate
end

-- If the game already shows that same raid icon on it (someone marked them), don't duplicate it
local function updateOverlay(o)
	o:SetShown(o.unit ~= nil and plain(safe(GetRaidTargetIndex, o.unit)) ~= o.icon)
end

local function setIcon(unit, icon)
	-- Only nameplate units: "target" would also find a plate, but it wouldn't be cleared when it goes away
	if type(unit) ~= "string" or not unit:find("^nameplate") then return end
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

local function clear(unit)
	for _, o in pairs(overlays) do
		if o.unit == unit then
			o.unit = nil
			o:Hide()
		end
	end
end

local function clearAll()
	for _, o in pairs(overlays) do
		o.unit = nil
		o:Hide()
	end
end

local function each(fn)
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	local plates = plain(safe(C_NamePlate.GetNamePlates))
	if type(plates) ~= "table" then return end
	for _, plate in ipairs(plates) do
		local u = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if type(u) == "string" and not isSecret(u) then fn(u) end
	end
end

---------------------------------------------------------------------------
-- Nameplate settings: enemy nameplates on, and always shown (not only in combat)
---------------------------------------------------------------------------
local CVARS = { "nameplateShowEnemies", "nameplateShowAll" }

local function getCVar(name)
	local get = (C_CVar and C_CVar.GetCVar) or GetCVar
	return plain(safe(get, name))
end

-- true when both are on; nil if the client doesn't have those settings
local function ready()
	for _, cv in ipairs(CVARS) do
		local v = getCVar(cv)
		if v == nil then return nil end
		if v ~= "1" then return false end
	end
	return true
end

-- Out of combat only (the application checks it)
local function enable()
	local set = (C_CVar and C_CVar.SetCVar) or SetCVar
	for _, cv in ipairs(CVARS) do
		if getCVar(cv) ~= nil then safe(set, cv, "1") end
	end
	return ready() == true
end

ns.Adapters.plates = { setIcon = setIcon, clearAll = clearAll, each = each, ready = ready, enable = enable }

-- The overlays follow the nameplates by themselves
ns.onLoad(function()
	ns.on("NAME_PLATE_UNIT_REMOVED", clear)
	ns.on("RAID_TARGET_UPDATE", function()
		for _, o in pairs(overlays) do
			if o.unit then updateOverlay(o) end
		end
	end)
end)

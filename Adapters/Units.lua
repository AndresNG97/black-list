-- ADAPTER · Ports units and party, on the WoW API.
-- Every read goes through safe/plain: in the Midnight engine the game can hide who a unit is.

local _, ns = ...
local A = ns.Adapters
local isSecret, safe, plain = ns.isSecret, ns.safe, ns.plain
local Names = ns.Domain.Names

local UnitNameFn = UnitNameUnmodified or UnitName

local function yes(fn, ...) return plain(safe(fn, ...)) == true end

-- name, realm, guid of a player unit (nil if it isn't a player or the game hides it)
local function identity(unit)
	if not yes(UnitIsPlayer, unit) then return end
	if C_Secrets and C_Secrets.ShouldUnitIdentityBeSecret
		and plain(safe(C_Secrets.ShouldUnitIdentityBeSecret, unit)) then
		return
	end
	local ok, name, realm = pcall(UnitNameFn, unit)
	if not ok or isSecret(name) or isSecret(realm) then return end
	if type(name) ~= "string" or name == "" or name == UNKNOWNOBJECT then return end
	if type(realm) ~= "string" or realm == "" then realm = nil end
	local guid = plain(safe(UnitGUID, unit))
	if type(guid) ~= "string" then guid = nil end
	return name, realm, guid
end

-- Data saved about the person when they're seen
local function info(unit)
	local t = {}
	local ok, _, class = pcall(UnitClass, unit)
	if ok and type(class) == "string" and not isSecret(class) then t.class = class end
	local ok2, race = pcall(UnitRace, unit)
	if ok2 and type(race) == "string" and not isSecret(race) then t.race = race end
	local lvl = plain(safe(UnitLevel, unit))
	if type(lvl) == "number" and lvl > 0 then t.level = lvl end
	local faction = plain(safe(UnitFactionGroup, unit))
	if type(faction) == "string" then t.faction = faction end
	local _, _, guid = identity(unit)
	t.guid = guid
	return t
end

local function guid(unit)
	local g = plain(safe(UnitGUID, unit))
	if type(g) == "string" then return g end
end

A.units = {
	identity = identity,
	info = info,
	guid = guid,
	isPlayer = function(unit) return yes(UnitIsPlayer, unit) end,
	isMe = function(unit) return yes(UnitIsUnit, unit, "player") end,
	canAttack = function(unit) return yes(UnitCanAttack, "player", unit) end,
	targetsMe = function(unit) return yes(UnitIsUnit, unit .. "target", "player") end,
	-- Invite functions get a name, "Name-Realm" or sometimes a unit token ("target", "party1"...)
	resolve = function(target)
		if type(target) ~= "string" or target == "" or isSecret(target) then return end
		if target == target:lower() and yes(UnitExists, target) then return identity(target) end
		return Names.split(target)
	end,
}

A.party = {
	inGroup = function() return IsInGroup() and true or false end,
	-- party1..4, or raid1..40 without you
	members = function()
		local out = {}
		local raid = IsInRaid()
		local count = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
		for i = 1, count do
			local unit = (raid and "raid" or "party") .. i
			if yes(UnitExists, unit) and not yes(UnitIsUnit, unit, "player") then out[#out + 1] = unit end
		end
		return out
	end,
}

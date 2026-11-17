-- Player names and unit identity.
-- A person's key is "name-realm" in lowercase, with the realm without spaces.

local _, ns = ...
local isSecret, safe, plain = ns.isSecret, ns.safe, ns.plain

local function myRealm()
	local r = GetNormalizedRealmName and GetNormalizedRealmName()
	if type(r) == "string" and r ~= "" then return r end
	return ((GetRealmName() or ""):gsub("[%s%-]", ""))
end

function ns.normRealm(realm)
	if type(realm) ~= "string" or realm == "" then realm = myRealm() end
	return (realm:gsub("[%s%-']", ""))
end

-- "Name-Realm" -> "Name", "Realm"
function ns.splitName(full)
	full = strtrim(full or "")
	local name, realm = full:match("^([^%-]+)%-(.+)$")
	return name or full, realm
end

-- string.lower/upper only change ASCII letters; this also lowercases accented letters
-- (Á É Í Ó Ú Ñ Ü...: in UTF-8 they are \195 + a byte from 128 to 158; the lowercase is that byte + 32)
local function lowerUTF8(s)
	return (s:lower():gsub("\195([\128-\158])", function(c) return "\195" .. string.char(c:byte() + 32) end))
end

-- "álvaro" -> "Álvaro", "PEPE" -> "Pepe"
function ns.prettyName(n)
	n = lowerUTF8(n)
	local b1, b2 = n:byte(1, 2)
	if b1 == 195 and b2 and b2 >= 160 and b2 <= 190 and b2 ~= 183 then
		return "\195" .. string.char(b2 - 32) .. n:sub(3)
	end
	return n:sub(1, 1):upper() .. n:sub(2)
end

function ns.key(name, realm)
	return lowerUTF8(name .. "-" .. ns.normRealm(realm))
end

-- Display name: without the realm if it is yours
function ns.fullName(e)
	if e.realm and e.realm ~= ns.normRealm(nil) then return e.name .. "-" .. e.realm end
	return e.name
end

function ns.isMe(name, realm)
	return name == UnitName("player") and ns.normRealm(realm) == ns.normRealm(nil)
end

-- Identity of a player unit: name, realm, GUID (nil if it isn't a player or the game hides it)
local UnitNameFn = UnitNameUnmodified or UnitName
function ns.unitIdentity(unit)
	if not plain(safe(UnitIsPlayer, unit)) then return end
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

-- Data we save about the person when we see them
function ns.unitInfo(unit)
	local info = {}
	local ok, _, class = pcall(UnitClass, unit)
	if ok and type(class) == "string" and not isSecret(class) then info.class = class end
	local ok2, race = pcall(UnitRace, unit)
	if ok2 and type(race) == "string" and not isSecret(race) then info.race = race end
	local lvl = plain(safe(UnitLevel, unit))
	if type(lvl) == "number" and lvl > 0 then info.level = lvl end
	local faction = plain(safe(UnitFactionGroup, unit))
	if type(faction) == "string" then info.faction = faction end
	local _, _, guid = ns.unitIdentity(unit)
	info.guid = guid
	return info
end

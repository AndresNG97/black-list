-- Nombres de jugador e identidad de unidades.
-- La clave de una persona es "nombre-reino" en minúsculas, con el reino sin espacios.

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

-- "Nombre-Reino" -> "Nombre", "Reino"
function ns.splitName(full)
	full = strtrim(full or "")
	local name, realm = full:match("^([^%-]+)%-(.+)$")
	return name or full, realm
end

function ns.prettyName(n)
	return n:sub(1, 1):upper() .. n:sub(2):lower()
end

function ns.key(name, realm)
	return (name .. "-" .. ns.normRealm(realm)):lower()
end

-- Nombre para mostrar: sin reino si es el tuyo
function ns.fullName(e)
	if e.realm and e.realm ~= ns.normRealm(nil) then return e.name .. "-" .. e.realm end
	return e.name
end

function ns.isMe(name, realm)
	return name == UnitName("player") and ns.normRealm(realm) == ns.normRealm(nil)
end

-- Identidad de una unidad jugador: nombre, reino, GUID (nil si no es jugador o el juego la oculta)
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

-- Datos que guardamos de la persona cuando la vemos
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

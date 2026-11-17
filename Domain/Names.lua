-- DOMAIN · Player names and keys. Pure Lua: no WoW API.
-- A person's key is "name-realm" in lowercase, with the realm without spaces, dashes or quotes.
-- "home" is your own realm: it's used when a name comes without one.

local _, ns = ...
ns.Domain = ns.Domain or {}
local Names = {}
ns.Domain.Names = Names

local function trim(s) return (s:match("^%s*(.-)%s*$")) end

-- string.lower/upper only change ASCII letters; this also lowercases accented letters
-- (Á É Í Ó Ú Ñ Ü...: in UTF-8 they are \195 + a byte from 128 to 158; the lowercase is that byte + 32)
function Names.lower(s)
	return (s:lower():gsub("\195([\128-\158])", function(c) return "\195" .. string.char(c:byte() + 32) end))
end

-- "álvaro" -> "Álvaro", "PEPE" -> "Pepe"
function Names.pretty(n)
	n = Names.lower(n)
	local b1, b2 = n:byte(1, 2)
	if b1 == 195 and b2 and b2 >= 160 and b2 <= 190 and b2 ~= 183 then
		return "\195" .. string.char(b2 - 32) .. n:sub(3)
	end
	return n:sub(1, 1):upper() .. n:sub(2)
end

-- "Name-Realm" -> "Name", "Realm" (realm nil if there isn't one)
function Names.split(full)
	full = trim(full or "")
	local name, realm = full:match("^([^%-]+)%-(.+)$")
	return name or full, realm
end

function Names.normRealm(realm, home)
	if type(realm) ~= "string" or realm == "" then realm = home or "" end
	return (realm:gsub("[%s%-']", ""))
end

function Names.key(name, realm, home)
	return Names.lower(name .. "-" .. Names.normRealm(realm, home))
end

-- Display name: without the realm if it's your own
function Names.full(e, home)
	if e.realm and e.realm ~= Names.normRealm(nil, home) then return e.name .. "-" .. e.realm end
	return e.name
end

function Names.same(name, realm, otherName, otherRealm, home)
	return name == otherName and Names.normRealm(realm, home) == Names.normRealm(otherRealm, home)
end

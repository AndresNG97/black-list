-- ¿Quién me ha matado?
-- WoW Forever no deja a los add-ons leer el registro de combate, así que el asesino se deduce:
-- el jugador enemigo que te tenía en el objetivo en los últimos segundos antes de morir.

local _, ns = ...
local safe, plain = ns.safe, ns.plain

local WINDOW = 20 -- segundos
local suspects = {} -- [clave] = { name, realm, info, t, strong }

-- strong: te tenía en el objetivo. Tu propio objetivo enemigo cuenta como sospechoso débil.
local function note(unit)
	if not plain(safe(UnitCanAttack, "player", unit)) then return end
	local name, realm = ns.unitIdentity(unit)
	if not name then return end
	local strong = plain(safe(UnitIsUnit, unit .. "target", "player")) == true
	if not strong and unit ~= "target" then return end
	local k = ns.key(name, realm)
	local old = suspects[k]
	if old and old.strong and not strong and GetTime() - old.t < WINDOW then return end
	suspects[k] = { name = name, realm = realm, info = ns.unitInfo(unit), t = GetTime(), strong = strong }
end

local function scan()
	ns.Plates.each(note)
	note("target")
end

local function pick()
	scan()
	local best, now = nil, GetTime()
	for k, s in pairs(suspects) do
		if now - s.t > WINDOW then
			suspects[k] = nil
		elseif not best or (s.strong and not best.strong) or (s.strong == best.strong and s.t > best.t) then
			best = s
		end
	end
	return best
end

local ticker
local function startTicker()
	if not ticker then ticker = C_Timer.NewTicker(1, scan) end
end
local function stopTicker()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
end

local function onDeath()
	local s = pick()
	wipe(suspects)
	if not s then return end
	local e = ns.find("pvp", s.name, s.realm, s.info.guid)
	if e then
		ns.addKill(e)
		ns.say("%s te ha vuelto a matar (%d %s).", ns.coloredName(e), e.kills, e.kills == 1 and "vez" or "veces")
	elseif ns.settings.killerPrompt and ns.promptAdd then
		ns.promptAdd("pvp", s.name, s.realm, ("Me mató en %s"):format(GetZoneText() or "?"), s.info, true)
	end
end

ns.onLoad(function()
	ns.on("PLAYER_DEAD", onDeath)
	ns.on("PLAYER_REGEN_DISABLED", startTicker)
	ns.on("PLAYER_REGEN_ENABLED", stopTicker)
	ns.on("NAME_PLATE_UNIT_ADDED", function(unit) if InCombatLockdown() then note(unit) end end)
	ns.on("PLAYER_TARGET_CHANGED", function() note("target") end)
end)

-- Who killed me?
-- WoW Forever doesn't let add-ons read the combat log, so the killer is guessed:
-- the enemy player who had you targeted in the last seconds before you died.
-- Only works in combat (one scan per second) and reuses the suspect tables.

local _, ns = ...
local L = ns.L
local safe, plain = ns.safe, ns.plain

local WINDOW = 20 -- seconds
local suspects = {} -- [key] = { name, realm, info, t, strong }

-- strong: had you targeted. Your own enemy target counts as a weak suspect.
local function note(unit)
	if not plain(safe(UnitCanAttack, "player", unit)) then return end
	local name, realm = ns.unitIdentity(unit)
	if not name then return end
	local strong = plain(safe(UnitIsUnit, unit .. "target", "player")) == true
	if not strong and unit ~= "target" then return end
	local k = ns.key(name, realm)
	local s, now = suspects[k], GetTime()
	if s then
		-- Don't downgrade to "weak" someone who had you targeted recently
		if s.strong and not strong and now - s.t < WINDOW then return end
		s.t, s.strong = now, strong
		return
	end
	suspects[k] = { name = name, realm = realm, info = ns.unitInfo(unit), t = now, strong = strong }
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
		if e.kills == 1 then
			ns.say(L["%s killed you. Noted on their entry."], ns.coloredName(e))
		else
			ns.say(L["%s killed you again (%d times)."], ns.coloredName(e), e.kills)
		end
	elseif ns.settings.killerPrompt and ns.promptAdd then
		ns.promptAdd("pvp", s.name, s.realm, L["Killed me in %s"]:format(GetZoneText() or "?"), s.info, true)
	end
end

ns.onLoad(function()
	ns.on("PLAYER_DEAD", onDeath)
	ns.on("PLAYER_REGEN_DISABLED", startTicker)
	ns.on("PLAYER_REGEN_ENABLED", stopTicker)
	ns.on("NAME_PLATE_UNIT_ADDED", function(unit) if InCombatLockdown() then note(unit) end end)
	ns.on("PLAYER_TARGET_CHANGED", function() note("target") end)
end)

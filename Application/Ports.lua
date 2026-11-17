-- APPLICATION · Ports: what the application needs from the outside world.
-- Each port is a table of functions. Adapters\*.lua implement them for WoW; the tests
-- implement them with fakes. Ports.check() fails at startup if one is missing.
--
-- "unit" values are opaque handles chosen by the adapters ("target", "nameplate3"...).
-- The application only passes them back to the ports; it never looks inside them,
-- except the three tokens it asks about by name: "target", "focus" and "mouseover".

local _, ns = ...
local Ports = {}
ns.Ports = Ports

Ports.CONTRACT = {
	clock = {
		"now",      -- () -> seconds, monotonic (for cooldowns)
		"epoch",    -- () -> seconds since 1970 (stored dates)
		"after",    -- (seconds, fn)
		"every",    -- (seconds, fn) -> handle with :Cancel()
	},
	store = {
		"load",     -- () -> the saved table (created empty if there's none)
	},
	player = {
		"name",     -- () -> your character's name
		"realm",    -- () -> your realm, normalized
		"zone",     -- () -> current zone name
		"inCombat", -- () -> bool
	},
	units = {
		"identity", -- (unit) -> name, realm, guid; nil if not a player or the game hides who it is
		"info",     -- (unit) -> { class, race, level, faction, guid }
		"isMe",     -- (unit) -> bool
		"canAttack",-- (unit) -> bool
		"targetsMe",-- (unit) -> bool: that unit has you targeted
		"guid",     -- (unit) -> guid or nil (to tell whether a handle still points at the same person)
		"isPlayer", -- (unit) -> bool
		"resolve",  -- (target) -> name, realm, guid: a name or "Name-Realm" or a unit, as passed to invite functions
	},
	party = {
		"inGroup",  -- () -> bool
		"members",  -- () -> array of units, without you
	},
	plates = {
		"setIcon",  -- (unit, icon): draw the icon above that nameplate (ignored if the unit isn't a nameplate)
		"clearAll", -- ()
		"each",     -- (fn): fn(unit) for every visible nameplate
		"ready",    -- () -> true if enemy nameplates are on and always shown; nil if unknown
		"enable",   -- () -> true if it could turn them on
	},
	alerts = {
		"alert",    -- (listId, entry, kind, cfg): kind = "nearby" | "inGroup" | "invited" | "youInvited"
	},
	notices = {
		"notify",   -- (kind, ...): chat feedback, see App.lua for every kind and its arguments
	},
	prompt = {
		"add",      -- (listId, name, realm, info, ctx): open the add window; ctx = { fromKill, zone }
	},
	events = {
		"publish",  -- (name): "LISTS_CHANGED" | "SETTINGS_CHANGED" | "SIGHTING"
	},
}

function Ports.check(ports)
	for port, fns in pairs(Ports.CONTRACT) do
		local p = ports[port]
		assert(type(p) == "table", "missing port: " .. port)
		for _, fn in ipairs(fns) do
			assert(type(p[fn]) == "function", ("port %s is missing %s()"):format(port, fn))
		end
	end
	return ports
end

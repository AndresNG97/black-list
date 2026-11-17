-- Saved data (ListaNegraDB): defaults, migrations and access to the settings.
-- Format changes: add fields with a default value (fill) or migrate the old data.

local _, ns = ...

-- Per-list settings: pvp = open world, grupo = dungeons and raids
local ALERT_DEFAULTS = {
	pvp = { -- inGroup/invite are not used in the open world (see groupAlerts in Data.lua)
		nearby = true, inGroup = false, invite = false, screen = true, chat = true,
		plateIcon = true, raidMark = true, icon = 8, sound = "RAID_WARNING", color = "rojo",
		duration = 5, cooldown = 120,
	},
	grupo = {
		nearby = false, inGroup = true, invite = true, screen = true, chat = true,
		plateIcon = true, raidMark = false, icon = 7, sound = "READY_CHECK", color = "naranja",
		duration = 8, cooldown = 120,
	},
}

local GENERAL_DEFAULTS = {
	killerPrompt = true, -- on death, offer to add whoever seems to have killed you
	alertScale = 1,      -- size of the on-screen alert
	windowScale = 1,     -- size of the windows (shrinks automatically if they don't fit on screen)
	sort = "seen",       -- sort order of the lists
}

-- Version 0.1: all settings together -> per-list settings
local function migrateV1(s)
	if s.alerts or s.alertPvp == nil then return end
	s.alerts = { pvp = {}, grupo = {} }
	local p, g = s.alerts.pvp, s.alerts.grupo
	p.nearby, g.nearby = s.alertPvp, s.alertGrupoNearby
	p.inGroup, g.inGroup = s.alertGroup, s.alertGroup
	p.invite, g.invite = s.alertGroup, s.alertGroup
	p.raidMark = s.raidMark
	p.plateIcon, g.plateIcon = s.plateIcon, s.plateIcon
	if s.sound == false then p.sound, g.sound = "none", "none" end
	p.cooldown, g.cooldown = s.cooldown, s.cooldown
	for _, k in ipairs({ "alertPvp", "alertGrupoNearby", "alertGroup", "raidMark", "plateIcon", "sound", "cooldown" }) do
		s[k] = nil
	end
end

local function fill(t, defaults)
	for k, v in pairs(defaults) do
		if t[k] == nil then t[k] = v end
	end
end

local function initDB()
	if type(ListaNegraDB) ~= "table" then ListaNegraDB = {} end
	local db = ListaNegraDB
	db.version = 4
	if type(db.lists) ~= "table" then db.lists = {} end
	for _, id in ipairs(ns.ORDER) do
		if type(db.lists[id]) ~= "table" then db.lists[id] = {} end
	end

	if type(db.settings) ~= "table" then db.settings = {} end
	local s = db.settings
	migrateV1(s)
	fill(s, GENERAL_DEFAULTS)
	if type(s.alerts) ~= "table" then s.alerts = {} end
	for _, id in ipairs(ns.ORDER) do
		if type(s.alerts[id]) ~= "table" then s.alerts[id] = {} end
		fill(s.alerts[id], ALERT_DEFAULTS[id])
	end
	if type(s.minimap) ~= "table" then s.minimap = {} end
	fill(s.minimap, { angle = 200, hide = false })
	if type(s.windows) ~= "table" then s.windows = {} end -- window positions

	ns.db, ns.settings = db, s
end

-- Alert settings of a list
function ns.cfg(id) return ns.settings.alerts[id] end

-- First of all the inits: the other modules can then find ns.db and ns.settings
ns.onLoad(initDB)

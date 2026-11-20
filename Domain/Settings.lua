-- DOMAIN · Saved data: defaults and migrations. Pure Lua.
-- Format changes: add fields with a default value (fill) or migrate the old data.

local _, ns = ...
ns.Domain = ns.Domain or {}
local Catalog = ns.Domain.Catalog
local Settings = {}
ns.Domain.Settings = Settings

Settings.VERSION = 4
Settings.KEY_VERSION = 2

-- Per-list settings: pvp = open world, grupo = dungeons and raids
Settings.ALERT_DEFAULTS = {
	pvp = { -- inGroup/invite are not used in the open world (groupAlerts = false)
		nearby = true, inGroup = false, invite = false, screen = true, chat = true,
		plateIcon = true, icon = 8, sound = "RAID_WARNING", color = "rojo",
		duration = 5, cooldown = 120,
	},
	grupo = {
		nearby = false, inGroup = true, invite = true, screen = true, chat = true,
		plateIcon = true, icon = 7, sound = "READY_CHECK", color = "naranja",
		duration = 8, cooldown = 120,
	},
}

Settings.GENERAL_DEFAULTS = {
	killerPrompt = true, -- on death, offer to add whoever seems to have killed you	alertScale = 1,      -- size of the on-screen alert
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

local function tbl(parent, k)
	if type(parent[k]) ~= "table" then parent[k] = {} end
	return parent[k]
end

-- Brings any saved table up to date. Returns db, needsKeyMigration.
function Settings.prepare(db)
	db.version = Settings.VERSION
	local lists = tbl(db, "lists")
	for _, id in ipairs(Catalog.ORDER) do tbl(lists, id) end

	local s = tbl(db, "settings")
	migrateV1(s)
	fill(s, Settings.GENERAL_DEFAULTS)
	local alerts = tbl(s, "alerts")
	for _, id in ipairs(Catalog.ORDER) do
		fill(tbl(alerts, id), Settings.ALERT_DEFAULTS[id])
		alerts[id].raidMark = nil -- removed in 1.0.3: the game no longer lets add-ons set raid markers
	end
	fill(tbl(s, "minimap"), { angle = 200, hide = false })
	tbl(s, "windows") -- window positions

	-- History (1.1.0): who killed you and who you grouped with
	local history = tbl(db, "history")
	for _, kind in ipairs(ns.Domain.History.KINDS) do tbl(history, kind) end

	local needsKeys = db.keyVersion ~= Settings.KEY_VERSION
	db.keyVersion = Settings.KEY_VERSION
	return db, needsKeys
end

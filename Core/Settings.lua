-- Datos guardados (ListaNegraDB): valores por defecto, migraciones y acceso a los ajustes.

local _, ns = ...

-- Ajustes por lista: pvp = mundo abierto, grupo = mazmorras y bandas
local ALERT_DEFAULTS = {
	pvp = {
		nearby = true, inGroup = true, invite = true, screen = true, chat = true,
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
	killerPrompt = true, -- al morir, ofrecer añadir a quien parece haberte matado
	alertScale = 1,
	sort = "seen",       -- orden de las listas
}

-- Versión 0.1: ajustes todos juntos -> ajustes por lista
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
	db.version = 3
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

	ns.db, ns.settings = db, s
end

-- Ajustes de avisos de una lista
function ns.cfg(id) return ns.settings.alerts[id] end

-- Primero de todos los inicios: el resto de módulos ya encuentra ns.db y ns.settings
ns.onLoad(initDB)

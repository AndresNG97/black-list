-- DOMAIN · Fixed data: the lists, preset reasons and the keys of the alert options.
-- Only keys and rules here; the texts shown on screen are added by Adapters\Text.lua.
-- The keys are stored in the saved data: don't change them without a migration.

local _, ns = ...
ns.Domain = ns.Domain or {}
local Catalog = {}
ns.Domain.Catalog = Catalog

-- groupAlerts: whether the list alerts when someone joins your group or on invites.
-- In the open world they are enemies: you only get alerted when they are nearby.
Catalog.ORDER = { "pvp", "grupo" }
Catalog.LISTS = {
	pvp = { groupAlerts = false },
	grupo = { groupAlerts = true },
}

-- Lists that alert on group and invites, in priority order
Catalog.GROUP_ORDER = {}
for _, id in ipairs(Catalog.ORDER) do
	if Catalog.LISTS[id].groupAlerts then Catalog.GROUP_ORDER[#Catalog.GROUP_ORDER + 1] = id end
end

function Catalog.other(id) return id == "pvp" and "grupo" or "pvp" end

local ALIAS = {
	pvp = "pvp", mundo = "pvp", world = "pvp", open = "pvp", ow = "pvp",
	grupo = "grupo", group = "grupo", raid = "grupo", banda = "grupo", bandas = "grupo",
	mazmorra = "grupo", mazmorras = "grupo", dungeon = "grupo", dungeons = "grupo", raids = "grupo",
}
function Catalog.listId(word) return type(word) == "string" and ALIAS[word:lower()] or nil end

-- Preset reasons: key (stored), word (English keyword for /ln)
Catalog.PRESETS = {
	grupo = {
		{ key = "ninja", word = "ninja" }, { key = "needea", word = "needer" }, { key = "abandona", word = "leaver" },
		{ key = "toxico", word = "toxic" }, { key = "afk", word = "afk" }, { key = "rol", word = "role" },
		{ key = "wipes", word = "wiper" }, { key = "tirones", word = "puller" }, { key = "estafa", word = "scammer" },
		{ key = "bot", word = "bot" },
	},
	pvp = {
		{ key = "campea", word = "camper" }, { key = "ganker", word = "ganker" }, { key = "misiones", word = "questing" },
		{ key = "abusa", word = "zerg" }, { key = "hermandad", word = "guild" }, { key = "revancha", word = "revenge" },
		{ key = "tramposo", word = "cheater" },
	},
}

-- Reason key from a typed word (accepts accents and capital letters)
local UNACCENT = {
	["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
	["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u",
}
function Catalog.presetKey(id, word)
	if type(word) ~= "string" then return end
	local w = word:gsub("[\195][\128-\191]", UNACCENT):lower()
	for _, p in ipairs(Catalog.PRESETS[id] or {}) do
		if p.key == w or p.word == w then return p.key end
	end
end

-- Alert option keys (texts in Adapters\Text.lua)
Catalog.SOUNDS = {
	{ key = "RAID_WARNING", id = 8959 }, { key = "READY_CHECK", id = 8960 },
	{ key = "ALARM_CLOCK_WARNING_3", id = 12889 }, { key = "UI_RAID_BOSS_WHISPER_WARNING", id = 37666 },
	{ key = "MAP_PING", id = 3175 }, { key = "none" },
}
Catalog.COLORS = {
	{ key = "rojo", hex = "e5484d" }, { key = "naranja", hex = "f5a524" }, { key = "amarillo", hex = "ffd100" },
	{ key = "morado", hex = "a78bfa" }, { key = "azul", hex = "4ea8ff" }, { key = "verde", hex = "46c37b" },
	{ key = "blanco", hex = "ffffff" },
}
function Catalog.colorHex(key)
	for _, c in ipairs(Catalog.COLORS) do
		if c.key == key then return c.hex end
	end
	return "ffffff"
end

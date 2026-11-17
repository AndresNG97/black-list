-- Datos fijos: listas, motivos predeterminados, iconos, sonidos y colores.

local _, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- Listas
---------------------------------------------------------------------------
-- groupAlerts: si la lista avisa cuando alguien entra en tu grupo o te invita.
-- En mundo abierto son enemigos: no tiene sentido, solo se avisa al verlos cerca.
ns.LISTS = {
	pvp   = { short = L["PvP"],   label = L["Open world"],      hex = "e5484d", groupAlerts = false },
	grupo = { short = L["Group"], label = L["Dungeons / Raids"], hex = "f5a524", groupAlerts = true },
}
ns.ORDER = { "pvp", "grupo" }

local ALIAS = {
	pvp = "pvp", mundo = "pvp", world = "pvp", open = "pvp", ow = "pvp",
	grupo = "grupo", group = "grupo", raid = "grupo", banda = "grupo", bandas = "grupo",
	mazmorra = "grupo", mazmorras = "grupo", dungeon = "grupo", dungeons = "grupo", raids = "grupo",
}
function ns.listId(word) return type(word) == "string" and ALIAS[word:lower()] or nil end

---------------------------------------------------------------------------
-- Motivos predeterminados (se marcan en la ventana o se escriben en /ln por su clave).
-- La clave se guarda en los datos: no cambiarla sin migrar.
---------------------------------------------------------------------------
ns.PRESETS = {
	grupo = {
		{ key = "ninja",    word = "ninja",     text = L["Ninja"] },
		{ key = "needea",   word = "needer",    text = L["Needs on everything"] },
		{ key = "abandona", word = "leaver",    text = L["Leaves the group"] },
		{ key = "toxico",   word = "toxic",     text = L["Toxic / insults"] },
		{ key = "afk",      word = "afk",       text = L["AFK / leeches"] },
		{ key = "rol",      word = "role",      text = L["Doesn't do their role"] },
		{ key = "wipes",    word = "wiper",     text = L["Causes wipes"] },
		{ key = "tirones",  word = "puller",    text = L["Pulls recklessly"] },
		{ key = "estafa",   word = "scammer",   text = L["Scammer"] },
		{ key = "bot",      word = "bot",       text = L["Bot / cheater"] },
	},
	pvp = {
		{ key = "campea",    word = "camper",    text = L["Camps your corpse"] },
		{ key = "ganker",    word = "ganker",    text = L["Kills low levels"] },
		{ key = "misiones",  word = "questing",  text = L["Attacks you while questing"] },
		{ key = "abusa",     word = "zerg",      text = L["Gangs up on solo players"] },
		{ key = "hermandad", word = "guild",     text = L["Enemy guild"] },
		{ key = "revancha",  word = "revenge",   text = L["Revenge pending"] },
		{ key = "tramposo",  word = "cheater",   text = L["Cheater / bot"] },
	},
}

-- Clave de motivo a partir de una palabra escrita (acepta tildes y mayúsculas)
local UNACCENT = {
	["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
	["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u",
}
function ns.presetKey(id, word)
	if type(word) ~= "string" then return end
	local w = word:gsub("[\195][\128-\191]", UNACCENT):lower()
	for _, p in ipairs(ns.PRESETS[id] or {}) do
		if p.key == w or p.word == w then return p.key end
	end
end

-- Palabra para escribir el motivo en /ln: la inglesa, o la clave española en clientes en español
function ns.presetWord(p) return ns.SPANISH and p.key or p.word end

---------------------------------------------------------------------------
-- Opciones de los avisos (las claves se guardan en los ajustes)
---------------------------------------------------------------------------
ns.ICON_NAMES = {
	L["Star"], L["Circle"], L["Diamond"], L["Triangle"], L["Moon"], L["Square"], L["Cross"], L["Skull"],
}

ns.SOUNDS = {
	{ key = "RAID_WARNING", text = L["Raid warning"], id = 8959 },
	{ key = "READY_CHECK", text = L["Ready check"], id = 8960 },
	{ key = "ALARM_CLOCK_WARNING_3", text = L["Alarm clock"], id = 12889 },
	{ key = "UI_RAID_BOSS_WHISPER_WARNING", text = L["Boss whisper"], id = 37666 },
	{ key = "MAP_PING", text = L["Map ping"], id = 3175 },
	{ key = "none", text = L["No sound"] },
}

ns.COLORS = {
	{ key = "rojo", text = L["Red"], hex = "e5484d" },
	{ key = "naranja", text = L["Orange"], hex = "f5a524" },
	{ key = "amarillo", text = L["Yellow"], hex = "ffd100" },
	{ key = "morado", text = L["Purple"], hex = "a78bfa" },
	{ key = "azul", text = L["Blue"], hex = "4ea8ff" },
	{ key = "verde", text = L["Green"], hex = "46c37b" },
	{ key = "blanco", text = L["White"], hex = "ffffff" },
}

function ns.colorHex(key)
	for _, c in ipairs(ns.COLORS) do
		if c.key == key then return c.hex end
	end
	return "ffffff"
end

function ns.hexToRGB(hex)
	return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

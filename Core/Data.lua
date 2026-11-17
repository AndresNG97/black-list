-- Datos fijos: listas, motivos predeterminados, iconos, sonidos y colores.

local _, ns = ...

---------------------------------------------------------------------------
-- Listas
---------------------------------------------------------------------------
ns.LISTS = {
	pvp   = { short = "PvP",   label = "Mundo abierto",      hex = "e5484d" },
	grupo = { short = "Grupo", label = "Mazmorras / Bandas", hex = "f5a524" },
}
ns.ORDER = { "pvp", "grupo" }

local ALIAS = {
	pvp = "pvp", mundo = "pvp", world = "pvp", open = "pvp", ow = "pvp",
	grupo = "grupo", group = "grupo", raid = "grupo", banda = "grupo", bandas = "grupo",
	mazmorra = "grupo", mazmorras = "grupo", dungeon = "grupo",
}
function ns.listId(word) return type(word) == "string" and ALIAS[word:lower()] or nil end

---------------------------------------------------------------------------
-- Motivos predeterminados (se marcan en la ventana o se escriben en /ln por su clave)
---------------------------------------------------------------------------
ns.PRESETS = {
	grupo = {
		{ key = "ninja",    text = "Ninja" },
		{ key = "needea",   text = "Needea todo" },
		{ key = "abandona", text = "Abandona el grupo" },
		{ key = "toxico",   text = "Tóxico / insulta" },
		{ key = "afk",      text = "AFK / se deja llevar" },
		{ key = "rol",      text = "No hace su rol" },
		{ key = "wipes",    text = "Provoca wipes" },
		{ key = "tirones",  text = "Tira bichos sin control" },
		{ key = "estafa",   text = "Estafador" },
		{ key = "bot",      text = "Bot / tramposo" },
	},
	pvp = {
		{ key = "campea",    text = "Campea tu cadáver" },
		{ key = "ganker",    text = "Mata a niveles bajos" },
		{ key = "misiones",  text = "Ataca mientras haces misiones" },
		{ key = "abusa",     text = "Va en grupo contra uno" },
		{ key = "hermandad", text = "Hermandad enemiga" },
		{ key = "revancha",  text = "Revancha pendiente" },
		{ key = "tramposo",  text = "Tramposo / bot" },
	},
}

ns.PRESET_TEXT = {}
for _, id in ipairs(ns.ORDER) do
	for _, p in ipairs(ns.PRESETS[id]) do ns.PRESET_TEXT[p.key] = p.text end
end

-- Clave de motivo a partir de una palabra escrita (acepta tildes y mayúsculas)
local UNACCENT = {
	["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
	["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u",
}
function ns.presetKey(id, word)
	if type(word) ~= "string" then return end
	local w = word:gsub("[\195][\128-\191]", UNACCENT):lower()
	for _, p in ipairs(ns.PRESETS[id] or {}) do
		if p.key == w then return p.key end
	end
end

---------------------------------------------------------------------------
-- Opciones de los avisos
---------------------------------------------------------------------------
ns.ICON_NAMES = { "Estrella", "Círculo", "Diamante", "Triángulo", "Luna", "Cuadrado", "Cruz", "Calavera" }

ns.SOUNDS = {
	{ key = "RAID_WARNING", text = "Alerta de banda", id = 8959 },
	{ key = "READY_CHECK", text = "Comprobar listos", id = 8960 },
	{ key = "ALARM_CLOCK_WARNING_3", text = "Alarma", id = 12889 },
	{ key = "UI_RAID_BOSS_WHISPER_WARNING", text = "Aviso de jefe", id = 37666 },
	{ key = "MAP_PING", text = "Señal de mapa", id = 3175 },
	{ key = "none", text = "Sin sonido" },
}

ns.COLORS = {
	{ key = "rojo", text = "Rojo", hex = "e5484d" },
	{ key = "naranja", text = "Naranja", hex = "f5a524" },
	{ key = "amarillo", text = "Amarillo", hex = "ffd100" },
	{ key = "morado", text = "Morado", hex = "a78bfa" },
	{ key = "azul", text = "Azul", hex = "4ea8ff" },
	{ key = "verde", text = "Verde", hex = "46c37b" },
	{ key = "blanco", text = "Blanco", hex = "ffffff" },
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

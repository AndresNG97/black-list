-- Datos fijos: listas, motivos predeterminados, iconos, sonidos y colores.

local _, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- Listas
---------------------------------------------------------------------------
-- groupAlerts: si la lista avisa cuando alguien entra en tu grupo o te invita.
-- En mundo abierto son enemigos: no tiene sentido, solo se avisa al verlos cerca.
ns.LISTS = {
	pvp   = { short = L["PvP"],   label = L["Mundo abierto"],      hex = "e5484d", groupAlerts = false },
	grupo = { short = L["Grupo"], label = L["Mazmorras / Bandas"], hex = "f5a524", groupAlerts = true },
}
ns.ORDER = { "pvp", "grupo" }

local ALIAS = {
	pvp = "pvp", mundo = "pvp", world = "pvp", open = "pvp", ow = "pvp",
	grupo = "grupo", group = "grupo", raid = "grupo", banda = "grupo", bandas = "grupo",
	mazmorra = "grupo", mazmorras = "grupo", dungeon = "grupo",
}
function ns.listId(word) return type(word) == "string" and ALIAS[word:lower()] or nil end

---------------------------------------------------------------------------
-- Motivos predeterminados (se marcan en la ventana o se escriben en /ln por su clave).
-- La clave se guarda en los datos: no cambiarla sin migrar.
---------------------------------------------------------------------------
ns.PRESETS = {
	grupo = {
		{ key = "ninja",    text = L["Ninja"] },
		{ key = "needea",   text = L["Needea todo"] },
		{ key = "abandona", text = L["Abandona el grupo"] },
		{ key = "toxico",   text = L["Tóxico / insulta"] },
		{ key = "afk",      text = L["AFK / se deja llevar"] },
		{ key = "rol",      text = L["No hace su rol"] },
		{ key = "wipes",    text = L["Provoca wipes"] },
		{ key = "tirones",  text = L["Tira bichos sin control"] },
		{ key = "estafa",   text = L["Estafador"] },
		{ key = "bot",      text = L["Bot / tramposo"] },
	},
	pvp = {
		{ key = "campea",    text = L["Campea tu cadáver"] },
		{ key = "ganker",    text = L["Mata a niveles bajos"] },
		{ key = "misiones",  text = L["Ataca mientras haces misiones"] },
		{ key = "abusa",     text = L["Va en grupo contra uno"] },
		{ key = "hermandad", text = L["Hermandad enemiga"] },
		{ key = "revancha",  text = L["Revancha pendiente"] },
		{ key = "tramposo",  text = L["Tramposo / bot"] },
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
		if p.key == w then return p.key end
	end
end

---------------------------------------------------------------------------
-- Opciones de los avisos (las claves se guardan en los ajustes)
---------------------------------------------------------------------------
ns.ICON_NAMES = {
	L["Estrella"], L["Círculo"], L["Diamante"], L["Triángulo"], L["Luna"], L["Cuadrado"], L["Cruz"], L["Calavera"],
}

ns.SOUNDS = {
	{ key = "RAID_WARNING", text = L["Alerta de banda"], id = 8959 },
	{ key = "READY_CHECK", text = L["Comprobar listos"], id = 8960 },
	{ key = "ALARM_CLOCK_WARNING_3", text = L["Alarma"], id = 12889 },
	{ key = "UI_RAID_BOSS_WHISPER_WARNING", text = L["Aviso de jefe"], id = 37666 },
	{ key = "MAP_PING", text = L["Señal de mapa"], id = 3175 },
	{ key = "none", text = L["Sin sonido"] },
}

ns.COLORS = {
	{ key = "rojo", text = L["Rojo"], hex = "e5484d" },
	{ key = "naranja", text = L["Naranja"], hex = "f5a524" },
	{ key = "amarillo", text = L["Amarillo"], hex = "ffd100" },
	{ key = "morado", text = L["Morado"], hex = "a78bfa" },
	{ key = "azul", text = L["Azul"], hex = "4ea8ff" },
	{ key = "verde", text = L["Verde"], hex = "46c37b" },
	{ key = "blanco", text = L["Blanco"], hex = "ffffff" },
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

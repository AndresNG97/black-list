-- Comandos /ln y /listanegra.

local _, ns = ...

local function help()
	ns.say("comandos:")
	local lines = {
		{ "/ln", "abre o cierra la ventana" },
		{ "/ln avisos", "ajustes de los avisos" },
		{ "/ln pvp", "añade a tu objetivo a Mundo abierto" },
		{ "/ln grupo", "añade a tu objetivo a Mazmorras / Bandas" },
		{ "/ln grupo Nombre ninja toxico nota", "añade por nombre con motivos y nota" },
		{ "/ln grupo * ninja", "igual, con tu objetivo" },
		{ "/ln motivos", "palabras de los motivos" },
		{ "/ln quitar [pvp o grupo] Nombre", "quita de una lista (o de las dos)" },
		{ "/ln buscar Nombre", "dice si alguien está en tus listas" },
		{ "/ln minimapa", "muestra u oculta el icono del minimapa" },
		{ "/ln prueba [pvp o grupo]", "enseña un aviso de ejemplo" },
	}
	for _, l in ipairs(lines) do print(("  |cffffd100%s|r  %s"):format(l[1], l[2])) end
end

-- Palabras iniciales que son motivos -> etiquetas; el resto es la nota
local function parseTags(id, text)
	local tags, rest = {}, text or ""
	while true do
		local w, r = rest:match("^(%S+)%s*(.-)$")
		local key = w and ns.presetKey(id, w)
		if not key then break end
		tags[key] = true
		rest = r
	end
	return tags, rest
end

local function addCmd(id, rest)
	local who, more = rest:match("^(%S+)%s*(.-)$")
	if not who or who == "*" or who:lower() == "objetivo" then
		local tags, note = parseTags(id, more or "")
		return ns.addTarget(id, note, tags)
	end
	local n, r = ns.splitName(who)
	n = ns.prettyName(n)
	local tags, note = parseTags(id, more)
	if note ~= "" or next(tags) then
		local _, k = ns.add(id, n, r, { reason = note, tags = tags })
		ns.snooze(id, k)
	else
		ns.promptAdd(id, n, r)
	end
end

local function removeCmd(rest)
	local first, second = rest:match("^(%S+)%s*(%S*)")
	if not first then return help() end
	local only = ns.listId(first)
	local who = only and second or first
	if who == "" then return help() end
	local n, r = ns.splitName(who)
	local done = false
	for _, id in ipairs(ns.ORDER) do
		if not only or only == id then
			local _, k = ns.find(id, n, r)
			if k then
				ns.remove(id, k)
				done = true
			end
		end
	end
	if not done then ns.say("%s no está en tus listas.", who) end
end

local function searchCmd(rest)
	if rest == "" then return help() end
	local n, r = ns.splitName(rest)
	local hits = ns.lookup(n, r)
	if not hits then return ns.say("%s no está en tus listas.", rest) end
	for _, id in ipairs(ns.ORDER) do
		local h = hits[id]
		if h then ns.say("%s está en %s. %s", ns.coloredName(h.entry), ns.listTag(id), ns.detail(h.entry)) end
	end
end

local function presetsCmd()
	for _, id in ipairs(ns.ORDER) do
		local words = {}
		for _, p in ipairs(ns.PRESETS[id]) do words[#words + 1] = ("|cffffd100%s|r (%s)"):format(p.key, p.text) end
		ns.say("%s: %s", ns.listTag(id), table.concat(words, ", "))
	end
end

local COMMANDS = {
	avisos = function() ns.openWindow("avisos") end,
	opciones = function() ns.openWindow("avisos") end,
	config = function() ns.openWindow("avisos") end,
	motivos = presetsCmd,
	quitar = removeCmd, borrar = removeCmd, remove = removeCmd,
	buscar = searchCmd, ver = searchCmd,
	minimapa = function()
		ns.settings.minimap.hide = not ns.settings.minimap.hide
		ns.fire("SETTINGS_CHANGED")
		ns.say("icono del minimapa %s.", ns.settings.minimap.hide and "oculto" or "visible")
	end,
	prueba = function(rest) ns.test(ns.listId(rest) or "pvp") end,
	ayuda = help, help = help,
}
COMMANDS.minimap = COMMANDS.minimapa
COMMANDS.test = COMMANDS.prueba

local function slash(msg)
	msg = strtrim(msg or "")
	local cmd, rest = msg:match("^(%S+)%s*(.-)$")
	if not cmd then return ns.toggleWindow() end
	cmd = cmd:lower()
	local id = ns.listId(cmd)
	if id then return addCmd(id, rest) end
	local fn = COMMANDS[cmd]
	if fn then return fn(rest) end
	help()
end

ns.onLoad(function()
	SLASH_LISTANEGRA1 = "/ln"
	SLASH_LISTANEGRA2 = "/listanegra"
	SlashCmdList.LISTANEGRA = slash
end)

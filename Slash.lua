-- Comandos /ln y /listanegra. "/ln ayuda" los lista todos.

local _, ns = ...
local L = ns.L

local function help()
	ns.say(L["comandos:"])
	local lines = {
		{ "/ln", L["abre o cierra la ventana"] },
		{ "/ln avisos", L["ajustes de los avisos"] },
		{ "/ln pvp", L["añade a tu objetivo a Mundo abierto"] },
		{ "/ln grupo", L["añade a tu objetivo a Mazmorras / Bandas"] },
		{ "/ln grupo " .. L["Nombre"] .. " ninja toxico " .. L["nota"], L["añade por nombre con motivos y nota"] },
		{ "/ln grupo * ninja", L["igual, con tu objetivo"] },
		{ "/ln motivos", L["palabras de los motivos"] },
		{ "/ln quitar [pvp|grupo] " .. L["Nombre"], L["quita de una lista (o de las dos)"] },
		{ "/ln buscar " .. L["Nombre"], L["dice si alguien está en tus listas"] },
		{ "/ln minimapa", L["muestra u oculta el icono del minimapa"] },
		{ "/ln prueba [pvp|grupo]", L["enseña un aviso de ejemplo"] },
		{ "/ln reset", L["vuelve a centrar las ventanas y el aviso"] },
	}
	for _, l in ipairs(lines) do
		-- "||" muestra una barra vertical en el chat
		print(("  |cffffd100%s|r  %s"):format((l[1]:gsub("|", "||")), l[2]))
	end
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
	if ns.isMe(n, r) then return ns.say(L["No puedes añadirte a ti mismo."]) end
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
	if not done then ns.say(L["%s no está en tus listas."], who) end
end

local function searchCmd(rest)
	if rest == "" then return help() end
	local n, r = ns.splitName(rest)
	local hits = ns.lookup(n, r)
	if not hits then return ns.say(L["%s no está en tus listas."], rest) end
	for _, id in ipairs(ns.ORDER) do
		local h = hits[id]
		if h then ns.say(L["%s está en %s. %s"], ns.coloredName(h.entry), ns.listTag(id), ns.detail(h.entry)) end
	end
end

local function presetsCmd()
	for _, id in ipairs(ns.ORDER) do
		local words = {}
		for _, p in ipairs(ns.PRESETS[id]) do words[#words + 1] = ("|cffffd100%s|r (%s)"):format(p.key, p.text) end
		ns.say("%s: %s", ns.listTag(id), table.concat(words, ", "))
	end
end

local function resetCmd()
	ns.UI.resetWindows()
	ns.UI.Banner.reset()
	ns.say(L["Ventanas y aviso de vuelta en el centro de la pantalla."])
end

local function minimapCmd()
	ns.settings.minimap.hide = not ns.settings.minimap.hide
	ns.fire("SETTINGS_CHANGED")
	ns.say(ns.settings.minimap.hide and L["Icono del minimapa oculto."] or L["Icono del minimapa visible."])
end

local function alertsCmd() ns.openWindow("avisos") end
local function testCmd(rest) ns.test(ns.listId(rest) or "pvp") end

local COMMANDS = {
	avisos = alertsCmd, opciones = alertsCmd, config = alertsCmd,
	motivos = presetsCmd,
	quitar = removeCmd, borrar = removeCmd, remove = removeCmd,
	buscar = searchCmd, ver = searchCmd,
	minimapa = minimapCmd, minimap = minimapCmd,
	prueba = testCmd, test = testCmd,
	reset = resetCmd,
	ayuda = help, help = help, ["?"] = help,
}

local function slash(msg)
	msg = strtrim(msg or "")
	local cmd, rest = msg:match("^(%S+)%s*(.-)$")
	if not cmd then return ns.toggleWindow() end
	cmd = cmd:lower()
	local id = ns.listId(cmd)
	if id then return addCmd(id, rest) end
	local fn = COMMANDS[cmd]
	if fn then return fn(rest) end
	ns.say(L["No conozco «%s»."], cmd)
	help()
end

ns.onLoad(function()
	SLASH_LISTANEGRA1 = "/ln"
	SLASH_LISTANEGRA2 = "/listanegra"
	SlashCmdList.LISTANEGRA = slash
end)

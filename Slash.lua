-- Comandos /ln, /blacklist y /listanegra. "/ln help" (o "/ln ayuda") los lista todos.

local _, ns = ...
local L = ns.L

-- Palabras de los comandos en el idioma del cliente (las inglesas y las españolas funcionan siempre)
local W = {
	alerts = L["alerts"], reasons = L["reasons"], remove = L["remove"], search = L["search"],
	minimap = L["minimap"], test = L["test"], help = L["help"], group = L["group"],
}

local function help()
	ns.say(L["commands:"])
	local G = W.group
	local lines = {
		{ "/ln", L["opens or closes the window"] },
		{ "/ln " .. W.alerts, L["alert settings"] },
		{ "/ln pvp", L["adds your target to Open world"] },
		{ "/ln " .. G, L["adds your target to Dungeons / Raids"] },
		{ "/ln " .. G .. " " .. L["Name toxic ninja note"], L["adds by name with reasons and a note"] },
		{ "/ln " .. G .. " * ninja", L["same, with your target"] },
		{ "/ln " .. W.reasons, L["reason keywords"] },
		{ "/ln " .. W.remove .. " [pvp|" .. G .. "] " .. L["Name"], L["removes from one list (or both)"] },
		{ "/ln " .. W.search .. " " .. L["Name"], L["tells you if someone is on your lists"] },
		{ "/ln " .. W.minimap, L["shows or hides the minimap icon"] },
		{ "/ln " .. W.test .. " [pvp|" .. G .. "]", L["shows a sample alert"] },
		{ "/ln reset", L["re-centers the windows and the alert"] },
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
	if not who or who == "*" or who:lower() == "target" or who:lower() == "objetivo" then
		local tags, note = parseTags(id, more or "")
		return ns.addTarget(id, note, tags)
	end
	local n, r = ns.splitName(who)
	n = ns.prettyName(n)
	if ns.isMe(n, r) then return ns.say(L["You can't add yourself."]) end
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
	if not done then ns.say(L["%s isn't on your lists."], who) end
end

local function searchCmd(rest)
	if rest == "" then return help() end
	local n, r = ns.splitName(rest)
	local hits = ns.lookup(n, r)
	if not hits then return ns.say(L["%s isn't on your lists."], rest) end
	for _, id in ipairs(ns.ORDER) do
		local h = hits[id]
		if h then ns.say(L["%s is on %s. %s"], ns.coloredName(h.entry), ns.listTag(id), ns.detail(h.entry)) end
	end
end

local function presetsCmd()
	for _, id in ipairs(ns.ORDER) do
		local words = {}
		for _, p in ipairs(ns.PRESETS[id]) do words[#words + 1] = ("|cffffd100%s|r (%s)"):format(ns.presetWord(p), p.text) end
		ns.say("%s: %s", ns.listTag(id), table.concat(words, ", "))
	end
end

local function resetCmd()
	ns.UI.resetWindows()
	ns.UI.Banner.reset()
	ns.say(L["Windows and alert are back in the center of the screen."])
end

local function minimapCmd()
	ns.settings.minimap.hide = not ns.settings.minimap.hide
	ns.fire("SETTINGS_CHANGED")
	ns.say(ns.settings.minimap.hide and L["Minimap icon hidden."] or L["Minimap icon shown."])
end

local function alertsCmd() ns.openWindow("avisos") end
local function testCmd(rest) ns.test(ns.listId(rest) or "pvp") end

local COMMANDS = {
	alerts = alertsCmd, options = alertsCmd, config = alertsCmd, settings = alertsCmd,
	avisos = alertsCmd, opciones = alertsCmd,
	reasons = presetsCmd, motivos = presetsCmd,
	remove = removeCmd, delete = removeCmd, quitar = removeCmd, borrar = removeCmd,
	search = searchCmd, find = searchCmd, buscar = searchCmd, ver = searchCmd,
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
	ns.say(L["Unknown command \"%s\"."], cmd)
	help()
end

ns.onLoad(function()
	SLASH_LISTANEGRA1 = "/ln"
	SLASH_LISTANEGRA2 = "/blacklist"
	SLASH_LISTANEGRA3 = "/listanegra"
	SlashCmdList.LISTANEGRA = slash
end)

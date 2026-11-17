-- Ventana de añadir / editar: jugador, lista, motivos (etiquetas) y nota.

local _, ns = ...
local UI = ns.UI
local C = UI.C
local safe, plain = ns.safe, ns.plain

local W = 520
local D -- la ventana
local state = {} -- mode, list, key, info, fromKill, gameName, gameRealm, initTags, initNote, loadedName

local function copyTags(t)
	local out = {}
	if type(t) == "table" then
		for k, v in pairs(t) do if v then out[k] = true end end
	end
	return out
end

---------------------------------------------------------------------------
-- Estado de la ventana
---------------------------------------------------------------------------
local function currentName()
	if state.gameName then return state.gameName, state.gameRealm end
	return ns.splitName(D.nameInput:GetText())
end

-- Rellena motivos y nota: los de la entrada si ya existe, si no los iniciales
local function loadValues()
	local tags, note = state.initTags or {}, state.initNote or ""
	state.loadedName = D.nameInput:GetText()
	if state.mode == "add" then
		local name, realm = currentName()
		local e = name ~= "" and ns.find(state.list, name, realm)
		if e then
			tags = e.tags or {}
			if note == "" then note = e.reason or "" end
		end
	end
	for _, id in ipairs(ns.ORDER) do
		for _, chip in ipairs(D.chips[id]) do
			chip:SetShown(id == state.list)
			chip:SetSelected(id == state.list and tags[chip.key])
		end
	end
	D.noteInput:SetText(note)
end

local function setList(id)
	state.list = id
	D.listSelect:Select(id, state.mode == "edit")
	loadValues()
end

local function save()
	local tags = {}
	for _, chip in ipairs(D.chips[state.list]) do
		if chip.selected then tags[chip.key] = true end
	end
	local note = strtrim(D.noteInput:GetText() or "")

	if state.mode == "edit" then
		local e = ns.entry(state.list, state.key)
		if e then
			e.tags, e.reason = tags, note
			ns.changed()
			ns.say("%s actualizado en %s.", ns.coloredName(e), ns.listTag(state.list))
		end
		D:Hide()
		return
	end

	local name, realm = currentName()
	if name == "" then
		ns.say("escribe el nombre del jugador.")
		D.nameInput:SetFocus()
		return
	end
	if not state.gameName then name = ns.prettyName(name) end
	if ns.isMe(name, realm) then
		ns.say("no puedes añadirte a ti mismo.")
		return
	end
	local e, k = ns.add(state.list, name, realm, { reason = note, tags = tags, info = state.info, exact = true })
	if e and state.fromKill then ns.addKill(e) end
	ns.snooze(state.list, k)
	D:Hide()
end

---------------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------------
local function build()
	D = UI.Window("ListaNegraEditor", W, 430, "", "FULLSCREEN_DIALOG")
	D:SetPoint("CENTER", 0, 40)

	-- Jugador: retrato y nombre (si viene del juego) o campo para escribirlo
	UI.Section(D, "Jugador", 18, -64)
	D.who = CreateFrame("Frame", nil, D)
	D.who:SetPoint("TOPLEFT", 18, -82)
	D.who:SetSize(W - 36, 34)
	D.whoIcon = D.who:CreateTexture(nil, "ARTWORK")
	D.whoIcon:SetSize(32, 32)
	D.whoIcon:SetPoint("LEFT")
	UI.round(D.whoIcon)
	D.whoName = UI.text(D.who, 15, nil, true)
	D.whoName:SetPoint("TOPLEFT", D.whoIcon, "TOPRIGHT", 10, -1)
	D.whoMeta = UI.text(D.who, 12, C.muted)
	D.whoMeta:SetPoint("TOPLEFT", D.whoName, "BOTTOMLEFT", 0, -3)

	D.nameInput = UI.Input(D, W - 36, 30, "Nombre o Nombre-Reino")
	D.nameInput:SetPoint("TOPLEFT", 18, -84)
	D.nameInput:SetScript("OnEnterPressed", function() D.noteInput:SetFocus() end)
	-- Si escribes el nombre de alguien que ya está, carga sus motivos (si no, no toca lo marcado)
	D.nameInput:HookScript("OnEditFocusLost", function()
		if state.mode ~= "add" or state.gameName then return end
		local text = D.nameInput:GetText()
		if text == state.loadedName then return end
		local n, r = ns.splitName(text)
		if n ~= "" and ns.find(state.list, n, r) then loadValues() else state.loadedName = text end
	end)

	-- Lista
	UI.Section(D, "Lista", 18, -130)
	local items = {}
	for i, id in ipairs(ns.ORDER) do
		items[i] = { value = id, text = ns.LISTS[id].label, rgb = UI.listRGB(id) }
	end
	D.listSelect = UI.Segmented(D, items, setList, W - 36, 32)
	D.listSelect:SetPoint("TOPLEFT", 18, -148)

	-- Motivos
	UI.Section(D, "Motivos", 18, -196)
	D.chips = {}
	local chipsH = 0
	for _, id in ipairs(ns.ORDER) do
		D.chips[id] = {}
		for i, p in ipairs(ns.PRESETS[id]) do
			local chip = UI.Chip(D, p.text, UI.listRGB(id))
			chip.key = p.key
			D.chips[id][i] = chip
		end
		chipsH = math.max(chipsH, UI.flow(D.chips[id], D, 18, -214, W - 36, 6))
	end

	-- Nota (debajo de las etiquetas, que pueden ocupar varias filas)
	local noteY = -214 - chipsH - 18
	UI.Section(D, "Nota", 18, noteY)
	D.noteInput = UI.Input(D, W - 36, 30, "Opcional: qué pasó, dónde, con quién...")
	D.noteInput:SetPoint("TOPLEFT", 18, noteY - 18)
	D:SetHeight(-(noteY - 18) + 30 + 24 + 30 + 18)
	D.noteInput:SetMaxLetters(250)
	D.noteInput:SetScript("OnEnterPressed", save)

	-- Botones
	D.save = UI.Button(D, SAVE or "Guardar", "primary", 120, 30, save)
	D.save:SetPoint("BOTTOMRIGHT", -18, 18)
	D.cancel = UI.Button(D, CANCEL or "Cancelar", "secondary", 110, 30, function() D:Hide() end)
	D.cancel:SetPoint("RIGHT", D.save, "LEFT", -8, 0)
	D.remove = UI.Button(D, "Quitar de la lista", "danger", nil, 30, function()
		local e = ns.entry(state.list, state.key)
		if not e then return end
		local list, key = state.list, state.key
		D:Hide()
		UI.confirm("Quitar de la lista", ("¿Quitar a %s de %s?"):format(ns.coloredName(e), ns.listTag(list)), "Quitar",
			function() ns.remove(list, key) end)
	end)
	D.remove:SetPoint("BOTTOMLEFT", 18, 18)
end

local function showWho(name, realm, info)
	info = info or {}
	D.who:Show()
	D.nameInput:Hide()
	UI.setClassIcon(D.whoIcon, info.class)
	D.whoName:SetText(ns.coloredName({ name = name, realm = ns.normRealm(realm), class = info.class }))
	local meta = {}
	if info.level then meta[#meta + 1] = "Nivel " .. info.level end
	if info.race then meta[#meta + 1] = info.race end
	if info.faction then meta[#meta + 1] = ns.factionText(info.faction) end
	D.whoMeta:SetText(table.concat(meta, " · "))
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- opts: mode ("add" | "edit"), list, key (edit), name, realm, info, note, fromKill
function ns.openEditor(opts)
	if not D then build() end
	wipe(state)
	state.mode = opts.mode or "add"
	state.key, state.info, state.fromKill = opts.key, opts.info, opts.fromKill
	state.initNote = opts.note
	D.nameInput:SetText("")

	if state.mode == "edit" then
		local e = ns.entry(opts.list, opts.key)
		if not e then return end
		D:SetTitle("Editar entrada")
		D:SetSubtitle(("Añadido el %s · visto %s"):format(date("%d/%m/%Y", e.added or time()), ns.ago(e.lastSeen)))
		showWho(e.name, e.realm, e)
		state.initTags, state.initNote = copyTags(e.tags), e.reason or ""
		D.remove:Show()
	else
		D.remove:Hide()
		if opts.fromKill then
			D:SetTitle("Parece que te ha matado")
			D:SetSubtitle("¿Lo añades a tu lista negra?")
		else
			D:SetTitle("Añadir a la lista negra")
			D:SetSubtitle("Elige la lista y marca los motivos")
		end
		if opts.name then
			state.gameName, state.gameRealm = opts.name, opts.realm
			showWho(opts.name, opts.realm, opts.info)
		else
			D.who:Hide()
			D.nameInput:Show()
		end
	end
	setList(opts.list or "pvp")
	D:Show()
	D:Raise()
	if state.mode == "add" and not opts.name then D.nameInput:SetFocus() end
end

-- Usado por el menú de clic derecho, /ln y "te ha matado"
function ns.promptAdd(id, name, realm, note, info, fromKill)
	ns.openEditor({ mode = "add", list = id, name = name, realm = realm, note = note, info = info, fromKill = fromKill })
end

-- Añade a tu objetivo: directamente si ya traes motivos o nota, si no abre la ventana
function ns.addTarget(id, note, tags)
	if plain(safe(UnitIsUnit, "target", "player")) then
		ns.say("no puedes añadirte a ti mismo.")
		return
	end
	local name, realm = ns.unitIdentity("target")
	if not name then
		ns.say("selecciona primero a un jugador, o usa «Añadir por nombre».")
		return
	end
	local info = ns.unitInfo("target")
	if (note and note ~= "") or (tags and next(tags)) then
		local _, k = ns.add(id, name, realm, { reason = note, tags = tags, info = info })
		ns.snooze(id, k)
	else
		ns.promptAdd(id, name, realm, nil, info)
	end
end

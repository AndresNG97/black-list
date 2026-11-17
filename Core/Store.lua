-- Las listas: buscar, añadir, quitar y registrar cuándo se ve a alguien.

local _, ns = ...

-- Índice por GUID (sigue encontrando a la persona aunque escribieras mal el reino)
local guidIndex = {}
local function rebuildIndex()
	for _, id in ipairs(ns.ORDER) do
		local idx = {}
		for k, e in pairs(ns.db.lists[id]) do
			if e.guid then idx[e.guid] = k end
		end
		guidIndex[id] = idx
	end
end

function ns.entry(id, k) return ns.db.lists[id][k] end

function ns.find(id, name, realm, guid)
	local t = ns.db.lists[id]
	local k = ns.key(name, realm)
	if t[k] then return t[k], k end
	if guid then
		local gk = guidIndex[id][guid]
		if gk and t[gk] then return t[gk], gk end
	end
end

-- { pvp = { entry, key }, grupo = { entry, key } } o nil si no está en ninguna lista
function ns.lookup(name, realm, guid)
	local hits
	for _, id in ipairs(ns.ORDER) do
		local e, k = ns.find(id, name, realm, guid)
		if e then
			hits = hits or {}
			hits[id] = { entry = e, key = k }
		end
	end
	return hits
end

function ns.count(id)
	local n = 0
	for _ in pairs(ns.db.lists[id]) do n = n + 1 end
	return n
end

function ns.changed()
	rebuildIndex()
	ns.fire("LISTS_CHANGED")
end

-- opts: reason (nota), tags ({clave = true}), info (datos de la unidad), quiet,
-- exact (la nota y los motivos sustituyen a los anteriores en vez de sumarse)
function ns.add(id, name, realm, opts)
	opts = opts or {}
	if not ns.LISTS[id] or type(name) ~= "string" or name == "" then return end
	local t = ns.db.lists[id]
	local k = ns.key(name, realm)
	local e = t[k]
	local isNew = not e
	if isNew then
		e = { name = name, realm = ns.normRealm(realm), reason = "", tags = {}, added = time(),
			addedBy = UnitName("player"), kills = 0, seen = 0 }
		t[k] = e
	end
	if type(opts.reason) == "string" then
		local r = strtrim(opts.reason)
		if r ~= "" or opts.exact then e.reason = r end
	end
	if type(opts.tags) == "table" then
		if opts.exact then
			e.tags = opts.tags
		else
			e.tags = e.tags or {}
			for tag in pairs(opts.tags) do e.tags[tag] = true end
		end
	end
	if opts.info then
		for f, v in pairs(opts.info) do e[f] = v end
	end
	ns.changed()
	if not opts.quiet then
		ns.say(isNew and ns.L["%s añadido a %s."] or ns.L["%s actualizado en %s."], ns.coloredName(e), ns.listTag(id))
	end
	return e, k
end

function ns.remove(id, k)
	local e = ns.db.lists[id][k]
	if not e then return end
	ns.db.lists[id][k] = nil
	ns.changed()
	ns.say(ns.L["%s quitado de %s."], ns.coloredName(e), ns.listTag(id))
end

-- Pasa a alguien a la otra lista con todos sus datos
function ns.move(from, to, k)
	local e = ns.db.lists[from][k]
	if not e or ns.db.lists[to][k] then return end
	ns.db.lists[to][k] = e
	ns.db.lists[from][k] = nil
	ns.changed()
	ns.say(ns.L["%s movido a %s."], ns.coloredName(e), ns.listTag(to))
end

function ns.addKill(e)
	e.kills = (e.kills or 0) + 1
	e.lastKill = time()
	e.lastZone = GetZoneText()
	ns.changed()
end

-- Se ha visto a la persona: actualiza nombre, clase, nivel, zona...
function ns.recordSighting(id, e, name, unit)
	local cd = ns.cfg(id).cooldown or 120
	if not e.lastSeen or time() - e.lastSeen > cd then e.seen = (e.seen or 0) + 1 end
	e.name = name -- con las mayúsculas reales
	local info = ns.unitInfo(unit)
	local newGuid = info.guid and info.guid ~= e.guid
	for f, v in pairs(info) do e[f] = v end
	e.lastSeen = time()
	e.lastZone = GetZoneText()
	if newGuid then rebuildIndex() end
	ns.fire("SIGHTING")
end

-- Datos de la 0.3 o anteriores: las claves se calculaban sin pasar a minúscula las letras
-- acentuadas. Se recalculan; si dos entradas acaban en la misma clave, se fusionan.
local function merge(into, e)
	into.kills = (into.kills or 0) + (e.kills or 0)
	into.seen = (into.seen or 0) + (e.seen or 0)
	if (into.reason or "") == "" then into.reason = e.reason end
	if type(e.tags) == "table" then
		into.tags = into.tags or {}
		for t in pairs(e.tags) do into.tags[t] = true end
	end
	into.added = math.min(into.added or e.added or time(), e.added or into.added or time())
	into.lastSeen = math.max(into.lastSeen or 0, e.lastSeen or 0)
	if into.lastSeen == 0 then into.lastSeen = nil end
end

local function migrateKeys()
	if ns.db.keyVersion == 2 then return end
	for _, id in ipairs(ns.ORDER) do
		local fresh = {}
		for k, e in pairs(ns.db.lists[id]) do
			if type(e) == "table" and type(e.name) == "string" then
				local nk = ns.key(e.name, e.realm)
				if fresh[nk] then merge(fresh[nk], e) else fresh[nk] = e end
			else
				fresh[k] = e
			end
		end
		ns.db.lists[id] = fresh
	end
	ns.db.keyVersion = 2
end

ns.onLoad(function()
	migrateKeys()
	rebuildIndex()
end)

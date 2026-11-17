-- DOMAIN · The lists: find, add, remove and move people, with a GUID index. Pure Lua.
-- Works on a plain table { pvp = { [key] = entry }, grupo = {...} } (the saved data),
-- and a keyOf(name, realm) function that knows your home realm.

local _, ns = ...
ns.Domain = ns.Domain or {}
local Catalog, Entry = ns.Domain.Catalog, ns.Domain.Entry
local Blacklist = {}
Blacklist.__index = Blacklist
ns.Domain.Blacklist = Blacklist

function Blacklist.new(lists, keyOf)
	local self = setmetatable({ lists = lists, keyOf = keyOf, guidIndex = {} }, Blacklist)
	for _, id in ipairs(Catalog.ORDER) do
		if type(lists[id]) ~= "table" then lists[id] = {} end
	end
	self:reindex()
	return self
end

-- Index by GUID (still finds the person even if you misspelled the realm)
function Blacklist:reindex()
	for _, id in ipairs(Catalog.ORDER) do
		local idx = {}
		for k, e in pairs(self.lists[id]) do
			if type(e) == "table" and e.guid then idx[e.guid] = k end
		end
		self.guidIndex[id] = idx
	end
end

function Blacklist:entry(id, k) return self.lists[id][k] end
function Blacklist:entries(id) return self.lists[id] end

function Blacklist:count(id)
	local n = 0
	for _ in pairs(self.lists[id]) do n = n + 1 end
	return n
end

function Blacklist:find(id, name, realm, guid)
	local t = self.lists[id]
	local k = self.keyOf(name, realm)
	if t[k] then return t[k], k end
	if guid then
		local gk = self.guidIndex[id][guid]
		if gk and t[gk] then return t[gk], gk end
	end
end

-- { pvp = { entry, key }, grupo = { entry, key } } or nil if not on any list
function Blacklist:lookup(name, realm, guid)
	local hits
	for _, id in ipairs(Catalog.ORDER) do
		local e, k = self:find(id, name, realm, guid)
		if e then
			hits = hits or {}
			hits[id] = { entry = e, key = k }
		end
	end
	return hits
end

-- Returns entry, key, isNew. realm: already normalized.
function Blacklist:add(id, name, realm, opts, now, addedBy)
	local t = self.lists[id]
	local k = self.keyOf(name, realm)
	local e = t[k]
	local isNew = not e
	if isNew then
		e = Entry.new(name, realm, now, addedBy)
		t[k] = e
	end
	Entry.apply(e, opts)
	self:reindex()
	return e, k, isNew
end

function Blacklist:remove(id, k)
	local e = self.lists[id][k]
	if not e then return end
	self.lists[id][k] = nil
	self:reindex()
	return e
end

-- Moves someone to the other list with all their data (not if they're already there)
function Blacklist:move(from, to, k)
	local e = self.lists[from][k]
	if not e or self.lists[to][k] then return end
	self.lists[to][k] = e
	self.lists[from][k] = nil
	self:reindex()
	return e
end

-- Data from 0.3 or earlier: keys were computed without lowercasing accented letters.
-- They are recomputed; if two entries end up with the same key, they are merged.
function Blacklist:migrateKeys(now)
	for _, id in ipairs(Catalog.ORDER) do
		local fresh = {}
		for k, e in pairs(self.lists[id]) do
			if type(e) == "table" and type(e.name) == "string" then
				local nk = self.keyOf(e.name, e.realm)
				if fresh[nk] then Entry.merge(fresh[nk], e, now) else fresh[nk] = e end
			else
				fresh[k] = e
			end
		end
		self.lists[id] = fresh
	end
	self:reindex()
end

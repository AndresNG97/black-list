-- DOMAIN · History: who killed you and who you grouped with, whether they're on a list or not. Pure Lua.
-- One log per kind, keyed like the lists ({ [key] = record }). A record:
--   name, realm, class, race, level, faction, guid   who they are (from the last time)
--   count                                            times they killed you / groups together
--   first, last                                      epoch seconds
--   zone                                             where it happened the last time
-- Times are passed in; nothing here reads the clock or the game.

local _, ns = ...
ns.Domain = ns.Domain or {}
local History = {}
ns.Domain.History = History

History.KINDS = { "kills", "party" }
History.MAX = 300 -- per log; the oldest are dropped

local INFO = { "class", "race", "level", "faction", "guid" }

-- Drops the oldest records until the log fits
local function prune(log, max)
	local n = 0
	for _ in pairs(log) do n = n + 1 end
	while n > max do
		local oldK, oldT
		for k, r in pairs(log) do
			if not oldT or (r.last or 0) < oldT then oldK, oldT = k, r.last or 0 end
		end
		log[oldK] = nil
		n = n - 1
	end
end

-- who: { name, realm, info }. counts: false only refreshes the record (same group as before).
-- Returns the record and whether it's new.
function History.note(log, key, who, now, zone, counts)
	local r, isNew = log[key], false
	if not r then
		r, isNew = { count = 0, first = now }, true
		log[key] = r
	end
	r.name, r.realm = who.name, who.realm
	local info = who.info or {}
	for _, f in ipairs(INFO) do
		if info[f] ~= nil then r[f] = info[f] end
	end
	if counts ~= false then r.count = (r.count or 0) + 1 end
	r.last = now
	if zone and zone ~= "" then r.zone = zone end
	if isNew then prune(log, History.MAX) end
	return r, isNew
end

-- { { k = key, e = record }, ... }, most recent first
function History.entries(log)
	local out = {}
	for k, r in pairs(log) do out[#out + 1] = { k = k, e = r } end
	table.sort(out, function(a, b)
		if (a.e.last or 0) ~= (b.e.last or 0) then return (a.e.last or 0) > (b.e.last or 0) end
		return a.k < b.k
	end)
	return out
end

function History.count(log)
	local n = 0
	for _ in pairs(log) do n = n + 1 end
	return n
end

function History.remove(log, key)
	local r = log[key]
	log[key] = nil
	return r
end

function History.clear(log)
	for k in pairs(log) do log[k] = nil end
end

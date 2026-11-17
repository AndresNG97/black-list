-- DOMAIN · One person on a list: create, edit, merge, kills and sightings. Pure Lua.
-- Times are passed in (epoch seconds); nothing here reads the clock or the game.

local _, ns = ...
ns.Domain = ns.Domain or {}
local Entry = {}
ns.Domain.Entry = Entry

local function trim(s) return (s:match("^%s*(.-)%s*$")) end

function Entry.new(name, realm, now, addedBy)
	return { name = name, realm = realm, reason = "", tags = {}, added = now, addedBy = addedBy, kills = 0, seen = 0 }
end

-- opts: reason (note), tags ({key = true}), info (unit data),
-- exact (the note and reasons replace the previous ones instead of being added)
function Entry.apply(e, opts)
	if type(opts.reason) == "string" then
		local r = trim(opts.reason)
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
end

function Entry.edit(e, tags, note)
	e.tags, e.reason = tags or {}, trim(note or "")
end

function Entry.addKill(e, now, zone)
	e.kills = (e.kills or 0) + 1
	e.lastKill = now
	e.lastZone = zone
	return e.kills
end

-- Seen again: counts as a new sighting only after "cooldown" seconds.
-- Returns true if the GUID changed (the GUID index must be rebuilt).
function Entry.sighted(e, name, info, now, zone, cooldown)
	if not e.lastSeen or now - e.lastSeen > cooldown then e.seen = (e.seen or 0) + 1 end
	e.name = name -- with the real capitalization
	local newGuid = info.guid and info.guid ~= e.guid
	for f, v in pairs(info) do e[f] = v end
	e.lastSeen = now
	e.lastZone = zone
	return newGuid and true or false
end

-- Two entries for the same person (old keys): keep everything in "into"
function Entry.merge(into, e, now)
	into.kills = (into.kills or 0) + (e.kills or 0)
	into.seen = (into.seen or 0) + (e.seen or 0)
	if (into.reason or "") == "" then into.reason = e.reason end
	if type(e.tags) == "table" then
		into.tags = into.tags or {}
		for t in pairs(e.tags) do into.tags[t] = true end
	end
	into.added = math.min(into.added or e.added or now, e.added or into.added or now)
	into.lastSeen = math.max(into.lastSeen or 0, e.lastSeen or 0)
	if into.lastSeen == 0 then into.lastSeen = nil end
end

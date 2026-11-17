-- DOMAIN · Which list alerts, and when. Pure Lua.
-- cfgOf(id) returns a list's alert settings; times are passed in (seconds).

local _, ns = ...
ns.Domain = ns.Domain or {}
local Catalog = ns.Domain.Catalog
local AlertPolicy = {}
AlertPolicy.__index = AlertPolicy
ns.Domain.AlertPolicy = AlertPolicy

function AlertPolicy.new(cfgOf)
	return setmetatable({ cfgOf = cfgOf, last = {} }, AlertPolicy)
end

-- One alert per person every "cooldown" seconds (per-list setting)
function AlertPolicy:cooled(id, k, now)
	local tag = id .. ":" .. k
	local t = self.last[tag]
	if t and now - t < (self.cfgOf(id).cooldown or 120) then return false end
	self.last[tag] = now
	return true
end

-- Just added: don't alert right away
function AlertPolicy:snooze(id, k, now)
	if id and k then self.last[id .. ":" .. k] = now end
end

-- Seen nearby: the first list with "nearby" on that isn't cooling down.
-- Only one alert even if they're on both lists: the alert counts as given on both.
-- Returns the list id and its hit, or nil.
function AlertPolicy:nearby(hits, now)
	for _, id in ipairs(Catalog.ORDER) do
		local h = hits[id]
		if h and self.cfgOf(id).nearby and self:cooled(id, h.key, now) then
			for other, oh in pairs(hits) do
				if other ~= id then self:snooze(other, oh.key, now) end
			end
			return id, h
		end
	end
end

-- Group and invites: the first group list (Dungeons / Raids) with that option on.
-- option: "inGroup" or "invite"
function AlertPolicy:group(hits, option)
	for _, id in ipairs(Catalog.GROUP_ORDER) do
		if hits[id] and self.cfgOf(id)[option] then return id, hits[id] end
	end
end

-- Nameplate icon: the open world list wins if they're on both
function AlertPolicy:plateIcon(hits)
	for _, id in ipairs(Catalog.ORDER) do
		if hits[id] and self.cfgOf(id).plateIcon then return self.cfgOf(id).icon or 8 end
	end
end

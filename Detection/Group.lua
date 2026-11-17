-- Group and invites: alert when someone on a list with groupAlerts (Dungeons / Raids)
-- joins your group or invites you. The open world list doesn't alert here: they're enemies.

local _, ns = ...
local isSecret, safe, plain = ns.isSecret, ns.safe, ns.plain

local GROUP_ORDER = {}
for _, id in ipairs(ns.ORDER) do
	if ns.LISTS[id].groupAlerts then GROUP_ORDER[#GROUP_ORDER + 1] = id end
end

local alerted = {} -- [key] = true while they're still in the group
local unreadable = false

local function checkGroup()
	if not IsInGroup() then
		wipe(alerted)
		return
	end
	unreadable = false
	local present = {}
	local raid = IsInRaid()
	local count = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
	for i = 1, count do
		local unit = (raid and "raid" or "party") .. i
		local name, realm, guid = ns.unitIdentity(unit)
		if name then
			local k = ns.key(name, realm)
			local hits = ns.lookup(name, realm, guid)
			if hits then
				present[k] = true
				for id, h in pairs(hits) do ns.recordSighting(id, h.entry, name, unit) end
				if not alerted[k] then
					alerted[k] = true
					for _, id in ipairs(GROUP_ORDER) do
						if hits[id] and ns.cfg(id).inGroup then
							ns.notify(id, hits[id].entry, ns.L["is in your group"])
							break
						end
					end
				end
			end
		elseif plain(safe(UnitExists, unit)) and not plain(safe(UnitIsUnit, unit, "player")) then
			unreadable = true -- name not loaded yet or hidden: retry
		end
	end
	for k in pairs(alerted) do
		if not present[k] then alerted[k] = nil end
	end
end

local pending = false
local function checkSoon()
	if pending then return end
	pending = true
	C_Timer.After(1, function()
		pending = false
		checkGroup()
		if unreadable then C_Timer.After(4, checkGroup) end
	end)
end

local function onInvite(inviter)
	if type(inviter) ~= "string" or isSecret(inviter) then return end
	local n, r = ns.splitName(inviter)
	local hits = ns.lookup(n, r)
	if not hits then return end
	for _, id in ipairs(GROUP_ORDER) do
		if hits[id] and ns.cfg(id).invite then
			ns.notify(id, hits[id].entry, ns.L["is inviting you to a group"])
			return
		end
	end
end

ns.onLoad(function()
	ns.on("GROUP_ROSTER_UPDATE", checkSoon)
	ns.on("PLAYER_ENTERING_WORLD", checkSoon)
	ns.on("PLAYER_REGEN_ENABLED", function() if unreadable then checkSoon() end end)
	ns.on("PARTY_INVITE_REQUEST", onInvite)
end)

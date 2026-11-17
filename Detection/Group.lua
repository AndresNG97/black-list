-- Group and invites: alert when someone on a list with groupAlerts (Dungeons / Raids)
-- joins your group, invites you or you invite them. The open world list doesn't alert here: they're enemies.
-- The game doesn't say who is in a group before you join it: those members alert once you're in.

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

-- Alert for the first group list the person is on, if its "invite" option is on
local function inviteAlert(hits, what)
	for _, id in ipairs(GROUP_ORDER) do
		if hits[id] and ns.cfg(id).invite then
			ns.notify(id, hits[id].entry, what)
			return
		end
	end
end

-- Someone invites you
local function onInvite(inviter)
	if type(inviter) ~= "string" or isSecret(inviter) then return end
	local n, r = ns.splitName(inviter)
	local hits = ns.lookup(n, r)
	if hits then inviteAlert(hits, ns.L["is inviting you to a group"]) end
end

-- You invite someone (unit menu, /invite, friends list...). Name or "Name-Realm",
-- sometimes a unit token. Several invite functions can fire for one invite: alert once.
local lastOut = {}
local function onInviteOut(target)
	if type(target) ~= "string" or target == "" or isSecret(target) then return end
	local n, r, guid
	if target == target:lower() and plain(safe(UnitExists, target)) then
		n, r, guid = ns.unitIdentity(target)
		if not n then return end
	else
		n, r = ns.splitName(target)
	end
	local hits = ns.lookup(n, r, guid)
	if not hits then return end
	local k, now = ns.key(n, r), GetTime()
	if lastOut[k] and now - lastOut[k] < 3 then return end
	lastOut[k] = now
	inviteAlert(hits, ns.L["is on your blacklist: you just invited them"])
end

-- Hooks only watch the call (they never change or block the invite)
local function hookInvites()
	local P = C_PartyInfo
	for _, fn in ipairs({ "InviteUnit", "ConfirmInviteUnit" }) do
		if type(P) == "table" and type(P[fn]) == "function" then
			hooksecurefunc(P, fn, function(target) ns.call(onInviteOut, target) end)
		end
	end
	if type(InviteUnit) == "function" then
		hooksecurefunc("InviteUnit", function(target) ns.call(onInviteOut, target) end)
	end
end

-- /ln check: what the add-on reads from each group member
function ns.groupReport()
	local L = ns.L
	if not IsInGroup() then return ns.say(L["You're not in a group."]) end
	ns.say(L["Group check:"])
	local raid = IsInRaid()
	local count = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
	for i = 1, count do
		local unit = (raid and "raid" or "party") .. i
		if not plain(safe(UnitIsUnit, unit, "player")) then
			local name, realm, guid = ns.unitIdentity(unit)
			if not name then
				print("  " .. L["%s: hidden by the game or not loaded yet"]:format(unit))
			else
				local hits = ns.lookup(name, realm, guid)
				local shown = realm and (name .. "-" .. realm) or name
				if not hits then
					print("  " .. L["%s: not on your lists"]:format(shown))
				else
					for _, id in ipairs(ns.ORDER) do
						if hits[id] then print("  " .. L["%s is on %s. %s"]:format(shown, ns.listTag(id), ns.detail(hits[id].entry))) end
					end
				end
			end
		end
	end
end

ns.onLoad(function()
	ns.on("GROUP_ROSTER_UPDATE", checkSoon)
	ns.on("GROUP_JOINED", checkSoon)
	ns.on("PLAYER_ENTERING_WORLD", checkSoon)
	ns.on("PLAYER_REGEN_ENABLED", function() if unreadable then checkSoon() end end)
	ns.on("PARTY_INVITE_REQUEST", onInvite)
	hookInvites()
end)

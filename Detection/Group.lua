-- Grupo e invitaciones: aviso cuando alguien de una lista con groupAlerts (Mazmorras / Bandas)
-- entra en tu grupo o te invita. La lista de mundo abierto no avisa aquí: son enemigos.

local _, ns = ...
local isSecret, safe, plain = ns.isSecret, ns.safe, ns.plain

local GROUP_ORDER = {}
for _, id in ipairs(ns.ORDER) do
	if ns.LISTS[id].groupAlerts then GROUP_ORDER[#GROUP_ORDER + 1] = id end
end

local alerted = {} -- [clave] = true mientras siga en el grupo
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
							ns.notify(id, hits[id].entry, ns.L["está en tu grupo"])
							break
						end
					end
				end
			end
		elseif plain(safe(UnitExists, unit)) and not plain(safe(UnitIsUnit, unit, "player")) then
			unreadable = true -- nombre aún sin cargar u oculto: se reintenta
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
			ns.notify(id, hits[id].entry, ns.L["te invita a su grupo"])
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

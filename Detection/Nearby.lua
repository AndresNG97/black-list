-- People nearby: checked when their nameplate appears, when targeted or on mouseover.

local _, ns = ...
local Plates = ns.Plates

-- Nameplate icon: the open world list wins if they're on both
local function paintPlate(unit, hits)
	if not unit:find("^nameplate") then return end
	for _, id in ipairs(ns.ORDER) do
		if hits[id] and ns.cfg(id).plateIcon then
			Plates.setIcon(unit, ns.cfg(id).icon or 8)
			return
		end
	end
end

-- quiet: only paint the nameplate icon (when refreshing after list or settings changes);
-- doesn't count as "seen", doesn't mark and doesn't alert
function ns.checkUnit(unit, quiet)
	local name, realm, guid = ns.unitIdentity(unit)
	if not name then return end
	local hits = ns.lookup(name, realm, guid)
	if not hits then return end
	paintPlate(unit, hits)
	if quiet then return hits end

	for id, h in pairs(hits) do ns.recordSighting(id, h.entry, name, unit) end

	-- Raid marker: the first list that has it turned on
	for _, id in ipairs(ns.ORDER) do
		if hits[id] and ns.cfg(id).raidMark then
			Plates.raidMark(id, unit)
			break
		end
	end

	-- Only one alert even if they're on both lists: the alert counts as given on both
	for _, id in ipairs(ns.ORDER) do
		local h = hits[id]
		if h and ns.cfg(id).nearby and ns.cooled(id, h.key) then
			ns.notify(id, h.entry, ns.L["is nearby"])
			for other, oh in pairs(hits) do
				if other ~= id then ns.snooze(other, oh.key) end
			end
			break
		end
	end
	return hits
end

ns.onLoad(function()
	ns.on("NAME_PLATE_UNIT_ADDED", function(unit) ns.checkUnit(unit) end)
	ns.on("PLAYER_TARGET_CHANGED", function() ns.checkUnit("target") end)
	ns.on("UPDATE_MOUSEOVER_UNIT", function() ns.checkUnit("mouseover") end)
end)

-- Gente cerca: se comprueba al aparecer su placa de nombre, al seleccionarla o al pasarle el ratón.

local _, ns = ...
local Plates = ns.Plates

-- quiet: solo pintar iconos, sin aviso (al refrescar las placas)
function ns.checkUnit(unit, quiet)
	local name, realm, guid = ns.unitIdentity(unit)
	if not name then return end
	local hits = ns.lookup(name, realm, guid)
	if not hits then return end
	for id, h in pairs(hits) do ns.recordSighting(id, h.entry, name, unit) end

	-- Icono de la placa: manda la lista de mundo abierto si está en las dos
	if unit:find("^nameplate") then
		for _, id in ipairs(ns.ORDER) do
			if hits[id] and ns.cfg(id).plateIcon then
				Plates.setIcon(unit, ns.cfg(id).icon or 8)
				break
			end
		end
	end

	-- Marca de banda: la primera lista que la tenga activada
	for _, id in ipairs(ns.ORDER) do
		if hits[id] and ns.cfg(id).raidMark then
			Plates.raidMark(id, unit)
			break
		end
	end

	-- Un solo aviso aunque esté en las dos listas
	if not quiet then
		for _, id in ipairs(ns.ORDER) do
			local h = hits[id]
			if h and ns.cfg(id).nearby and ns.cooled(id, h.key) then
				ns.notify(id, h.entry, "está cerca")
				break
			end
		end
	end
	return hits
end

ns.onLoad(function()
	ns.on("NAME_PLATE_UNIT_ADDED", function(unit) ns.checkUnit(unit) end)
	ns.on("PLAYER_TARGET_CHANGED", function() ns.checkUnit("target") end)
	ns.on("UPDATE_MOUSEOVER_UNIT", function() ns.checkUnit("mouseover") end)
end)

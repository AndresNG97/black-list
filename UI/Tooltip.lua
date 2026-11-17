-- Tooltip del jugador: si está en tus listas, añade en qué lista está y por qué.

local _, ns = ...
local isSecret = ns.isSecret

local function onUnitTooltip(tt)
	if tt ~= GameTooltip then return end
	local ok, _, unit = pcall(tt.GetUnit, tt)
	if not ok or type(unit) ~= "string" or isSecret(unit) then return end
	local name, realm, guid = ns.unitIdentity(unit)
	if not name then return end
	local hits = ns.lookup(name, realm, guid)
	if not hits then return end
	for _, id in ipairs(ns.ORDER) do
		local h = hits[id]
		if h then
			local r, g, b = ns.hexToRGB(ns.LISTS[id].hex)
			tt:AddLine(ns.L["%s Lista negra: %s"]:format(ns.icon(ns.cfg(id).icon or 8, 14), ns.LISTS[id].label), r, g, b)
			local d = ns.detail(h.entry)
			if d ~= "" then tt:AddLine(d, 0.85, 0.85, 0.88, true) end
		end
	end
end

ns.onLoad(function()
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onUnitTooltip)
	end
end)

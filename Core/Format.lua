-- Text for the chat, the alerts and the windows.

local _, ns = ...
local L = ns.L

function ns.listTag(id)
	local list = ns.LISTS[id]
	return "|cff" .. list.hex .. list.label .. "|r"
end

function ns.classColor(class)
	if not class then return end
	return (C_ClassColor and C_ClassColor.GetClassColor(class)) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
end

function ns.coloredName(e)
	local n = ns.fullName(e)
	local c = ns.classColor(e.class)
	if c and c.WrapTextInColorCode then return c:WrapTextInColorCode(n) end
	return "|cffffffff" .. n .. "|r"
end

function ns.icon(index, size)
	return ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d|t"):format(index, size or 0)
end

local FACTION = { Alliance = "|cff4ea8ff" .. L["Alliance"] .. "|r", Horde = "|cffe5484d" .. L["Horde"] .. "|r" }
function ns.factionText(f) return f and (FACTION[f] or f) end

-- Names of the checked reasons, in the order of the reason list
function ns.tagNames(e)
	local out = {}
	if type(e.tags) ~= "table" then return out end
	for _, id in ipairs(ns.ORDER) do
		for _, p in ipairs(ns.PRESETS[id]) do
			if e.tags[p.key] then out[#out + 1] = p.text end
		end
	end
	return out
end

-- "Ninja, Toxic / insults · note"
function ns.reasonText(e)
	local parts = {}
	local tags = ns.tagNames(e)
	if #tags > 0 then parts[#parts + 1] = table.concat(tags, ", ") end
	if e.reason and e.reason ~= "" then parts[#parts + 1] = e.reason end
	return table.concat(parts, " · ")
end

function ns.killsText(n)
	return (n == 1 and L["killed you %d time"] or L["killed you %d times"]):format(n)
end

-- reasons + "killed you N times"
function ns.detail(e)
	local parts = {}
	local r = ns.reasonText(e)
	if r ~= "" then parts[#parts + 1] = r end
	if (e.kills or 0) > 0 then parts[#parts + 1] = ns.killsText(e.kills) end
	return table.concat(parts, " · ")
end

function ns.ago(t)
	if not t then return L["never"] end
	local d = time() - t
	if d < 60 then return L["just now"] end
	if d < 3600 then return L["%d min ago"]:format(math.floor(d / 60)) end
	if d < 86400 then return L["%d h ago"]:format(math.floor(d / 3600)) end
	return L["%d d ago"]:format(math.floor(d / 86400))
end

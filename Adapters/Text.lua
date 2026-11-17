-- ADAPTER · What the player reads: list names, reason texts, option texts, colors and
-- the formatting used by the chat, the alerts and the windows. Adds the translated texts
-- to the domain catalog (Domain\Catalog.lua).

local _, ns = ...
local L = ns.L
local Catalog = ns.Domain.Catalog

---------------------------------------------------------------------------
-- Catalog with texts
---------------------------------------------------------------------------
ns.ORDER = Catalog.ORDER
ns.listId = Catalog.listId
ns.presetKey = Catalog.presetKey
ns.colorHex = Catalog.colorHex

local LIST_TEXT = {
	pvp = { short = L["PvP"], label = L["Open world"], hex = "e5484d" },
	grupo = { short = L["Group"], label = L["Dungeons / Raids"], hex = "f5a524" },
}
ns.LISTS = {}
for _, id in ipairs(Catalog.ORDER) do
	local t = LIST_TEXT[id]
	ns.LISTS[id] = { short = t.short, label = t.label, hex = t.hex, groupAlerts = Catalog.LISTS[id].groupAlerts }
end

local PRESET_TEXT = {
	ninja = L["Ninja"], needea = L["Needs on everything"], abandona = L["Leaves the group"],
	toxico = L["Toxic / insults"], afk = L["AFK / leeches"], rol = L["Doesn't do their role"],
	wipes = L["Causes wipes"], tirones = L["Pulls recklessly"], estafa = L["Scammer"], bot = L["Bot / cheater"],
	campea = L["Camps your corpse"], ganker = L["Kills low levels"], misiones = L["Attacks you while questing"],
	abusa = L["Gangs up on solo players"], hermandad = L["Enemy guild"], revancha = L["Revenge pending"],
	tramposo = L["Cheater / bot"],
}
ns.PRESETS = {}
for id, list in pairs(Catalog.PRESETS) do
	ns.PRESETS[id] = {}
	for i, p in ipairs(list) do ns.PRESETS[id][i] = { key = p.key, word = p.word, text = PRESET_TEXT[p.key] or p.key } end
end

-- Word to type the reason in /ln: the English one, or the Spanish key on Spanish clients
function ns.presetWord(p) return ns.SPANISH and p.key or p.word end

ns.ICON_NAMES = {
	L["Star"], L["Circle"], L["Diamond"], L["Triangle"], L["Moon"], L["Square"], L["Cross"], L["Skull"],
}

local SOUND_TEXT = {
	RAID_WARNING = L["Raid warning"], READY_CHECK = L["Ready check"], ALARM_CLOCK_WARNING_3 = L["Alarm clock"],
	UI_RAID_BOSS_WHISPER_WARNING = L["Boss whisper"], MAP_PING = L["Map ping"], none = L["No sound"],
}
ns.SOUNDS = {}
for i, s in ipairs(Catalog.SOUNDS) do ns.SOUNDS[i] = { key = s.key, id = s.id, text = SOUND_TEXT[s.key] } end

local COLOR_TEXT = {
	rojo = L["Red"], naranja = L["Orange"], amarillo = L["Yellow"], morado = L["Purple"],
	azul = L["Blue"], verde = L["Green"], blanco = L["White"],
}
ns.COLORS = {}
for i, c in ipairs(Catalog.COLORS) do ns.COLORS[i] = { key = c.key, hex = c.hex, text = COLOR_TEXT[c.key] } end

function ns.hexToRGB(hex)
	return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------
function ns.listTag(id)
	local list = ns.LISTS[id]
	return "|cff" .. list.hex .. list.label .. "|r"
end

function ns.classColor(class)
	if not class then return end
	return (C_ClassColor and C_ClassColor.GetClassColor(class)) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
end

function ns.fullName(e) return ns.app:fullName(e) end

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

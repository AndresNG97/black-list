-- Alerts: sound, on-screen alert and chat according to each list's settings,
-- and the wait between alerts for the same person.

local _, ns = ...

function ns.playSound(key)
	if not key or key == "none" then return end
	local id = SOUNDKIT and SOUNDKIT[key]
	if not id then
		for _, s in ipairs(ns.SOUNDS) do
			if s.key == key then id = s.id end
		end
	end
	if id then pcall(PlaySound, id, "Master") end
end

-- One alert per person every "cooldown" seconds (per-list setting)
local lastAlert = {}

function ns.cooled(id, k)
	local tag = id .. ":" .. k
	local now, t = GetTime(), lastAlert[tag]
	if t and now - t < (ns.cfg(id).cooldown or 120) then return false end
	lastAlert[tag] = now
	return true
end

-- Just added: don't alert right away
function ns.snooze(id, k)
	if id and k then lastAlert[id .. ":" .. k] = GetTime() end
end

-- what: already translated text ("is nearby", "is in your group"...)
function ns.notify(id, e, what)
	local c = ns.cfg(id)
	local detail = ns.detail(e)
	if c.screen and ns.UI.Banner then
		ns.UI.Banner.show(id, e, what, detail)
	end
	ns.playSound(c.sound)
	if c.chat then
		ns.say("%s %s |cff%s%s|r.%s", ns.icon(c.icon or 8, 12), ns.coloredName(e), ns.colorHex(c.color), what,
			detail ~= "" and (" " .. detail) or "")
	end
end

-- Sample alert using a list's settings
function ns.test(id)
	id = id or "pvp"
	local sample = {
		name = "Fulano", class = "ROGUE", reason = "",
		kills = id == "pvp" and 3 or 0,
		tags = id == "pvp" and { campea = true } or { ninja = true },
	}
	ns.notify(id, sample, id == "pvp" and ns.L["is nearby"] or ns.L["is in your group"])
end

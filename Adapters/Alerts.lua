-- ADAPTER · Port alerts: sound, on-screen alert and chat, according to the list's settings.

local _, ns = ...
local L = ns.L

local WHAT = {
	nearby = L["is nearby"],
	inGroup = L["is in your group"],
	invited = L["is inviting you to a group"],
	youInvited = L["is on your blacklist: you just invited them"],
}

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

local function alert(id, e, kind, c)
	local what = WHAT[kind] or kind
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

ns.Adapters.alerts = { alert = alert }

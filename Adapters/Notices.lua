-- ADAPTER · Port notices: the application's feedback, as chat messages in the player's language.

local _, ns = ...
local L = ns.L

local function line(text) print("  " .. text) end

local MESSAGES = {
	added = function(id, e) ns.say(L["%s added to %s."], ns.coloredName(e), ns.listTag(id)) end,
	updated = function(id, e) ns.say(L["%s updated in %s."], ns.coloredName(e), ns.listTag(id)) end,
	removed = function(id, e) ns.say(L["%s removed from %s."], ns.coloredName(e), ns.listTag(id)) end,
	moved = function(to, e) ns.say(L["%s moved to %s."], ns.coloredName(e), ns.listTag(to)) end,
	cantAddSelf = function() ns.say(L["You can't add yourself."]) end,
	noTarget = function() ns.say(L["Target a player first, or use \"Add by name\"."]) end,
	notListed = function(text) ns.say(L["%s isn't on your lists."], text) end,
	found = function(id, e) ns.say(L["%s is on %s. %s"], ns.coloredName(e), ns.listTag(id), ns.detail(e)) end,
	killedYou = function(e) ns.say(L["%s killed you. Noted on their entry."], ns.coloredName(e)) end,
	killedAgain = function(e, kills) ns.say(L["%s killed you again (%d times)."], ns.coloredName(e), kills) end,

	notInGroup = function() ns.say(L["You're not in a group."]) end,
	groupHeader = function() ns.say(L["Group check:"]) end,
	groupHidden = function(unit) line(L["%s: hidden by the game or not loaded yet"]:format(unit)) end,
	groupMember = function(shown, hits)
		if not hits then return line(L["%s: not on your lists"]:format(shown)) end
		for _, id in ipairs(ns.ORDER) do
			if hits[id] then line(L["%s is on %s. %s"]:format(shown, ns.listTag(id), ns.detail(hits[id].entry))) end
		end
	end,

	platesCombat = function()
		ns.say(L["The game doesn't let you change nameplates in combat. Try again when combat ends."])
	end,
	platesOn = function()
		ns.say(L["Enemy nameplates are on and always shown: listed players within about 40 yards will alert."])
	end,
	platesFailed = function()
		ns.say(L["Couldn't turn nameplates on. In Options > Nameplates, turn on enemy nameplates and Always show nameplates."])
	end,
	platesHint = function()
		ns.say(L["To see open world blacklist players around you, enemy nameplates must be on and always shown. Type /ln %s."],
			L["nameplates"])
	end,
}

ns.Adapters.notices = {
	notify = function(kind, ...)
		local fn = MESSAGES[kind]
		if fn then fn(...) end
	end,
}

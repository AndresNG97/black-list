-- ADAPTER (driving) · Game events and invite hooks -> application use cases.
-- WoW Forever doesn't let add-ons read the combat log: people nearby are seen through
-- nameplates (about 40 yards), your target, focus and mouseover.

local _, ns = ...
local isSecret = ns.isSecret
local Names = ns.Domain.Names

local function app() return ns.app end

-- Someone invites you
local function onInviteRequest(inviter)
	if type(inviter) ~= "string" or isSecret(inviter) then return end
	app():inviteReceived(Names.split(inviter))
end

-- You invite someone (unit menu, /invite, friends list...)
local function onInviteOut(target)
	local name, realm, guid = ns.Adapters.units.resolve(target)
	if name and name ~= "" then app():inviteSent(name, realm, guid) end
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

ns.onLoad(function()
	-- People nearby
	ns.on("NAME_PLATE_UNIT_ADDED", function(unit) app():plateAdded(unit) end)
	ns.on("PLAYER_TARGET_CHANGED", function() app():targetChanged() end)
	ns.on("PLAYER_FOCUS_CHANGED", function() app():focusChanged() end)
	ns.on("UPDATE_MOUSEOVER_UNIT", function() app():mouseover() end)

	-- Group and invites
	ns.on("GROUP_ROSTER_UPDATE", function() app():groupChanged() end)
	ns.on("GROUP_JOINED", function() app():groupChanged() end)
	ns.on("PARTY_INVITE_REQUEST", onInviteRequest)
	hookInvites()

	-- Combat and death (who killed me)
	ns.on("PLAYER_REGEN_DISABLED", function() app():combatStarted() end)
	ns.on("PLAYER_REGEN_ENABLED", function() app():combatEnded() end)
	ns.on("PLAYER_DEAD", function() app():died() end)

	-- Login, reload, zone change
	ns.on("PLAYER_ENTERING_WORLD", function()
		app():groupChanged()
		C_Timer.After(2, function() app():repaintPlates() end)
		C_Timer.After(8, function() app():hintPlates() end)
	end)
end)

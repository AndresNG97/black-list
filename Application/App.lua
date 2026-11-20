-- APPLICATION · Use cases. Uses the domain rules and reaches the game only through the ports
-- (Application\Ports.lua). Driving adapters (game events, /ln, the windows) call these methods.
--
-- Notices sent to ports.notices.notify(kind, ...):
--   added(listId, entry)   updated(listId, entry)   removed(listId, entry)   moved(toListId, entry)
--   cantAddSelf()   noTarget()   notListed(text)   found(listId, entry)
--   killedYou(entry)   killedAgain(entry, kills)
--   notInGroup()   groupHeader()   groupHidden(unit)   groupMember(shownName, hits)
--   platesCombat()   platesOn()   platesFailed()   platesHint()
--
-- Events sent to ports.events.publish(name): LISTS_CHANGED, SETTINGS_CHANGED, SIGHTING, HISTORY_CHANGED

local _, ns = ...
local D = ns.Domain
local Names, Catalog, Entry, Blacklist = D.Names, D.Catalog, D.Entry, D.Blacklist
local AlertPolicy, KillerGuess, Settings, History = D.AlertPolicy, D.KillerGuess, D.Settings, D.History

local App = {}
App.__index = App
ns.App = App

local INVITE_DEDUPE = 3       -- seconds: several invite functions can fire for one invite
local GROUP_DELAY, GROUP_RETRY = 1, 4
local PLATE_RETRIES = { 0.5, 2 } -- a nameplate can show up before the player's name has loaded
local REGROUP_GAP = 300       -- seconds: grouped with someone again after a /reload within this time = same group

function App.new(ports)
	ns.Ports.check(ports)
	local self = setmetatable({ p = ports }, App)
	self.alerted, self.lastOut, self.grouped = {}, {}, {}
	self.guess = KillerGuess.new()
	return self
end

-- Loads and migrates the saved data. Call once, when the saved variables are available.
function App:start()
	local p = self.p
	local db, needsKeys = Settings.prepare(p.store.load())
	self.db, self.s = db, db.settings
	self.list = Blacklist.new(db.lists, function(name, realm) return self:key(name, realm) end)
	if needsKeys then self.list:migrateKeys(p.clock.epoch()) end
	db.lists = self.list.lists
	self.history = db.history
	self.policy = AlertPolicy.new(function(id) return self.s.alerts[id] end)
	return self
end

---------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------
function App:home() return self.p.player.realm() end
function App:key(name, realm) return Names.key(name, realm, self:home()) end
function App:normRealm(realm) return Names.normRealm(realm, self:home()) end
function App:fullName(e) return Names.full(e, self:home()) end
function App:isMe(name, realm) return Names.same(name, realm, self.p.player.name(), nil, self:home()) end

-- "name-realm" typed by the user -> name, realm (pretty: fix the capitalization)
function App:parseName(text, pretty)
	local n, r = Names.split(text)
	if pretty and n ~= "" then n = Names.pretty(n) end
	return n, r
end

function App:cfg(id) return self.s.alerts[id] end
function App:settings() return self.s end

---------------------------------------------------------------------------
-- Lists
---------------------------------------------------------------------------
function App:entry(id, k) return self.list:entry(id, k) end
function App:entries(id) return self.list:entries(id) end
function App:count(id) return self.list:count(id) end
function App:find(id, name, realm, guid) return self.list:find(id, name, realm, guid) end
function App:lookup(name, realm, guid) return self.list:lookup(name, realm, guid) end

function App:changed()
	self.p.events.publish("LISTS_CHANGED")
	self:repaintPlates()
end

-- opts: reason, tags, info, exact (replace instead of add), quiet (no chat message),
-- snooze (just added by hand: don't alert right away)
function App:add(id, name, realm, opts)
	opts = opts or {}
	if not Catalog.LISTS[id] or type(name) ~= "string" or name == "" then return end
	if self:isMe(name, realm) then return self.p.notices.notify("cantAddSelf") end
	local e, k, isNew = self.list:add(id, name, self:normRealm(realm), opts, self.p.clock.epoch(), self.p.player.name())
	if opts.snooze then self.policy:snooze(id, k, self.p.clock.now()) end
	self:changed()
	if not opts.quiet then self.p.notices.notify(isNew and "added" or "updated", id, e) end
	return e, k
end

function App:edit(id, k, tags, note)
	local e = self.list:entry(id, k)
	if not e then return end
	Entry.edit(e, tags, note)
	self:changed()
	self.p.notices.notify("updated", id, e)
	return e
end

function App:remove(id, k)
	local e = self.list:remove(id, k)
	if not e then return end
	self:changed()
	self.p.notices.notify("removed", id, e)
end

function App:move(from, to, k)
	local e = self.list:move(from, to, k)
	if not e then return end
	self:changed()
	self.p.notices.notify("moved", to, e)
end

function App:addKill(id, k)
	local e = self.list:entry(id, k)
	if not e then return end
	local kills = Entry.addKill(e, self.p.clock.epoch(), self.p.player.zone())
	self:changed()
	return kills
end

-- /ln remove [list] Name
function App:removeByName(onlyList, who)
	local n, r = Names.split(who)
	local done = false
	for _, id in ipairs(Catalog.ORDER) do
		if not onlyList or onlyList == id then
			local _, k = self.list:find(id, n, r)
			if k then
				self:remove(id, k)
				done = true
			end
		end
	end
	if not done then self.p.notices.notify("notListed", who) end
end

-- /ln search Name
function App:search(text)
	local n, r = Names.split(text)
	local hits = self.list:lookup(n, r)
	if not hits then return self.p.notices.notify("notListed", text) end
	for _, id in ipairs(Catalog.ORDER) do
		if hits[id] then self.p.notices.notify("found", id, hits[id].entry) end
	end
end

---------------------------------------------------------------------------
-- Your target and other units (for the windows and menus)
---------------------------------------------------------------------------
-- name, realm, info of a unit; nil if it isn't a player or the game hides who it is
function App:identify(unit)
	local name, realm = self.p.units.identity(unit)
	if not name then return end
	return name, realm, self.p.units.info(unit)
end

function App:hitsForUnit(unit)
	local name, realm, guid = self.p.units.identity(unit)
	if not name then return end
	return self.list:lookup(name, realm, guid)
end

function App:targetIsAddable()
	if self.p.units.isMe("target") then return false end
	return self.p.units.identity("target") ~= nil
end

-- Adds your target: directly if reasons or a note are passed in, otherwise opens the add window
function App:addTarget(id, note, tags)
	if self.p.units.isMe("target") then return self.p.notices.notify("cantAddSelf") end
	local name, realm, info = self:identify("target")
	if not name then return self.p.notices.notify("noTarget") end
	if (note and note ~= "") or (tags and next(tags)) then
		return self:add(id, name, realm, { reason = note, tags = tags, info = info, snooze = true })
	end
	self.p.prompt.add(id, name, realm, info, {})
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function App:settingsChanged()
	self.p.events.publish("SETTINGS_CHANGED")
	self:repaintPlates()
end

-- Sample alert using a list's settings
function App:test(id)
	id = Catalog.LISTS[id] and id or "pvp"
	local sample = {
		name = "Fulano", class = "ROGUE", reason = "",
		kills = id == "pvp" and 3 or 0,
		tags = id == "pvp" and { campea = true } or { ninja = true },
	}
	self.p.alerts.alert(id, sample, id == "pvp" and "nearby" or "inGroup", self:cfg(id))
end

---------------------------------------------------------------------------
-- Sightings: nameplates, target, focus, mouseover
---------------------------------------------------------------------------
function App:recordSighting(id, e, name, unit)
	local cd = self:cfg(id).cooldown or 120
	local newGuid = Entry.sighted(e, name, self.p.units.info(unit), self.p.clock.epoch(), self.p.player.zone(), cd)
	if newGuid then self.list:reindex() end
	self.p.events.publish("SIGHTING")
end

-- quiet: only paint the nameplate icon (repaint after list or settings changes);
-- doesn't count as "seen" and doesn't alert
function App:unitSeen(unit, quiet)
	local p = self.p
	local name, realm, guid = p.units.identity(unit)
	if not name then return end
	local hits = self.list:lookup(name, realm, guid)
	if not hits then return end
	local icon = self.policy:plateIcon(hits)
	if icon then p.plates.setIcon(unit, icon) end
	if quiet then return hits end

	for id, h in pairs(hits) do self:recordSighting(id, h.entry, name, unit) end
	local id, h = self.policy:nearby(hits, p.clock.now())
	if id then p.alerts.alert(id, h.entry, "nearby", self:cfg(id)) end
	return hits
end

function App:repaintPlates()
	if not self.list then return end
	self.p.plates.clearAll()
	self.p.plates.each(function(u) self:unitSeen(u, true) end)
end

function App:plateAdded(unit)
	local p = self.p
	if p.player.inCombat() then self:noteSuspect(unit) end
	self:unitSeen(unit)
	if p.units.identity(unit) or not p.units.isPlayer(unit) then return end
	local guid = p.units.guid(unit)
	if not guid then return end
	for _, delay in ipairs(PLATE_RETRIES) do
		p.clock.after(delay, function()
			-- Same person still on that nameplate
			if p.units.guid(unit) == guid then self:unitSeen(unit) end
		end)
	end
end

function App:targetChanged()
	self:unitSeen("target")
	self:noteSuspect("target")
end
function App:focusChanged() self:unitSeen("focus") end
function App:mouseover() self:unitSeen("mouseover") end

---------------------------------------------------------------------------
-- Nameplate settings
---------------------------------------------------------------------------
function App:enablePlates()
	local p = self.p
	if p.player.inCombat() then return p.notices.notify("platesCombat") end
	p.notices.notify(p.plates.enable() and "platesOn" or "platesFailed")
end

-- Once per session: if the open world list alerts nearby but nameplates are off, say how to fix it
function App:hintPlates()
	if self.hinted then return end
	self.hinted = true
	if not self:cfg("pvp").nearby or self:count("pvp") == 0 then return end
	if self.p.plates.ready() == false then self.p.notices.notify("platesHint") end
end

---------------------------------------------------------------------------
-- Group and invites (Dungeons / Raids). The game doesn't say who is in a group
-- before you join it: those members alert once you're in.
---------------------------------------------------------------------------
function App:checkGroup()
	local p = self.p
	if not p.party.inGroup() then
		for k in pairs(self.alerted) do self.alerted[k] = nil end
		for k in pairs(self.grouped) do self.grouped[k] = nil end
		return
	end
	self.unreadable = false
	local present, members = {}, {}
	for _, unit in ipairs(p.party.members()) do
		local name, realm, guid = p.units.identity(unit)
		if name then
			local k = self:key(name, realm)
			members[k] = true
			self:recordMember(k, name, realm, unit)
			local hits = self.list:lookup(name, realm, guid)
			if hits then
				present[k] = true
				for id, h in pairs(hits) do self:recordSighting(id, h.entry, name, unit) end
				if not self.alerted[k] then
					self.alerted[k] = true
					local id, h = self.policy:group(hits, "inGroup")
					if id then p.alerts.alert(id, h.entry, "inGroup", self:cfg(id)) end
				end
			end
		else
			self.unreadable = true -- name not loaded yet or hidden: retry
		end
	end
	for k in pairs(self.alerted) do
		if not present[k] then self.alerted[k] = nil end
	end
	-- Who is still in the group (someone unreadable right now isn't counted as gone)
	if not self.unreadable then
		for k in pairs(self.grouped) do
			if not members[k] then self.grouped[k] = nil end
		end
	end
	self:historyChanged()
end

-- Roster changes come in bursts: check once, a second later
function App:groupChanged()
	if self.pending then return end
	self.pending = true
	self.p.clock.after(GROUP_DELAY, function()
		self.pending = false
		self:checkGroup()
		if self.unreadable then self.p.clock.after(GROUP_RETRY, function() self:checkGroup() end) end
	end)
end

-- Someone invites you
function App:inviteReceived(name, realm)
	local hits = self.list:lookup(name, realm)
	if not hits then return end
	local id, h = self.policy:group(hits, "invite")
	if id then self.p.alerts.alert(id, h.entry, "invited", self:cfg(id)) end
end

-- You invite someone
function App:inviteSent(name, realm, guid)
	local hits = self.list:lookup(name, realm, guid)
	if not hits then return end
	local k, now = self:key(name, realm), self.p.clock.now()
	if self.lastOut[k] and now - self.lastOut[k] < INVITE_DEDUPE then return end
	self.lastOut[k] = now
	local id, h = self.policy:group(hits, "invite")
	if id then self.p.alerts.alert(id, h.entry, "youInvited", self:cfg(id)) end
end

-- /ln check: what the add-on reads from each group member
function App:groupReport()
	local p = self.p
	if not p.party.inGroup() then return p.notices.notify("notInGroup") end
	p.notices.notify("groupHeader")
	for _, unit in ipairs(p.party.members()) do
		local name, realm, guid = p.units.identity(unit)
		if not name then
			p.notices.notify("groupHidden", unit)
		else
			p.notices.notify("groupMember", realm and (name .. "-" .. realm) or name, self.list:lookup(name, realm, guid))
		end
	end
end

---------------------------------------------------------------------------
-- Who killed me (only works in combat: one scan per second)
---------------------------------------------------------------------------
function App:noteSuspect(unit)
	local u = self.p.units
	if not u.canAttack(unit) then return end
	local name, realm = u.identity(unit)
	if not name then return end
	local strong = u.targetsMe(unit) == true
	if not strong and unit ~= "target" then return end
	self.guess:note(self:key(name, realm), { name = name, realm = realm, info = u.info(unit) }, strong, self.p.clock.now())
end

function App:scanSuspects()
	self.p.plates.each(function(u) self:noteSuspect(u) end)
	self:noteSuspect("target")
end

function App:combatStarted()
	if not self.ticker then self.ticker = self.p.clock.every(1, function() self:scanSuspects() end) end
end

function App:combatEnded()
	if self.ticker then
		self.ticker:Cancel()
		self.ticker = nil
	end
	if self.unreadable then self:groupChanged() end
end

function App:died()
	local p = self.p
	self:scanSuspects()
	local s = self.guess:pick(p.clock.now())
	self.guess:clear()
	if not s then return end
	self:recordKiller(s)
	local e, k = self.list:find("pvp", s.name, s.realm, s.info.guid)
	if e then
		local kills = self:addKill("pvp", k)
		if kills == 1 then p.notices.notify("killedYou", e) else p.notices.notify("killedAgain", e, kills) end
	elseif self.s.killerPrompt then
		p.prompt.add("pvp", s.name, s.realm, s.info, { fromKill = true, zone = p.player.zone() })
	end
end

---------------------------------------------------------------------------
-- History: who killed you and who you grouped with (on a list or not)
---------------------------------------------------------------------------
function App:historyChanged() self.p.events.publish("HISTORY_CHANGED") end

-- kind: "kills" | "party" -> { { k, e }, ... }, most recent first
function App:historyEntries(kind) return History.entries(self.history[kind]) end
function App:historyCount(kind) return History.count(self.history[kind]) end
function App:historyEntry(kind, k) return self.history[kind][k] end

function App:forget(kind, k)
	if History.remove(self.history[kind], k) then self:historyChanged() end
end

function App:clearHistory(kind)
	History.clear(self.history[kind])
	self:historyChanged()
end

-- s: { name, realm, info } from the killer guess
function App:recordKiller(s)
	local p = self.p
	History.note(self.history.kills, self:key(s.name, s.realm), { name = s.name, realm = self:normRealm(s.realm), info = s.info },
		p.clock.epoch(), p.player.zone())
	self:historyChanged()
end

-- A group member: counts as a new group only when they weren't already in it
function App:recordMember(k, name, realm, unit)
	local p = self.p
	local now, r = p.clock.epoch(), self.history.party[k]
	local counts = not self.grouped[k] and not (r and r.last and now - r.last < REGROUP_GAP)
	self.grouped[k] = true
	History.note(self.history.party, k, { name = name, realm = self:normRealm(realm), info = p.units.info(unit) },
		now, p.player.zone(), counts)
end

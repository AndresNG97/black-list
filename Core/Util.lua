-- Shared utilities: messages, safe reads, game events, internal notices and startup.
-- WoW Forever uses the Midnight engine: some reads can return "secret" values
-- (identity hidden in instances, BGs or arenas). Everything that reads a unit goes through safe/plain.

local ADDON, ns = ...
ns.ADDON = ADDON
ns.UI = {}

---------------------------------------------------------------------------
-- Chat messages: always with the add-on prefix, and the same message is not
-- repeated several times in a row
---------------------------------------------------------------------------
local REPEAT_GAP = 3 -- seconds
local lastText, lastTime = nil, 0

function ns.say(fmt, ...)
	local text = select("#", ...) > 0 and string.format(fmt, ...) or fmt
	local now = GetTime()
	if text == lastText and now - lastTime < REPEAT_GAP then return end
	lastText, lastTime = text, now
	print("|cffe5484d" .. ns.L["Blacklist"] .. "|r: " .. text)
end

---------------------------------------------------------------------------
-- Safe reads
---------------------------------------------------------------------------
function ns.isSecret(v) return issecretvalue ~= nil and issecretvalue(v) or false end

function ns.safe(fn, ...)
	if type(fn) ~= "function" then return false end
	return pcall(fn, ...)
end

-- plain(safe(fn, ...)): the value if the read worked and it isn't secret; otherwise nil
function ns.plain(ok, v)
	if ok and not ns.isSecret(v) then return v end
end

-- Calls fn so that an error doesn't stop the others (the error is still shown)
local call = securecallfunction or function(fn, ...) return fn(...) end
ns.call = call

---------------------------------------------------------------------------
-- Game events: a single frame, several modules per event
---------------------------------------------------------------------------
local bus = CreateFrame("Frame")
local gameHandlers = {}

function ns.on(event, fn)
	local list = gameHandlers[event]
	if not list then
		if not pcall(bus.RegisterEvent, bus, event) then
			ns.say(ns.L["The event %s doesn't exist in this client; that feature is turned off."], event)
			return
		end
		list = {}
		gameHandlers[event] = list
	end
	list[#list + 1] = fn
end

bus:SetScript("OnEvent", function(_, event, ...)
	local list = gameHandlers[event]
	if not list then return end
	for i = 1, #list do call(list[i], ...) end
end)

---------------------------------------------------------------------------
-- Internal notices between modules
--   LISTS_CHANGED      someone was added, edited or removed
--   SETTINGS_CHANGED   a setting changed
--   SIGHTING           someone on the lists was seen ("seen", level... change)
---------------------------------------------------------------------------
local listeners = {}

function ns.listen(name, fn)
	listeners[name] = listeners[name] or {}
	table.insert(listeners[name], fn)
end

function ns.fire(name, ...)
	local list = listeners[name]
	if not list then return end
	for i = 1, #list do call(list[i], ...) end
end

---------------------------------------------------------------------------
-- Startup: each module registers its init with ns.onLoad (in .toc order)
---------------------------------------------------------------------------
local inits = {}
function ns.onLoad(fn) inits[#inits + 1] = fn end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON then return end
	self:UnregisterEvent("ADDON_LOADED")
	for i = 1, #inits do call(inits[i]) end
end)

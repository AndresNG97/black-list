-- ADAPTER · Ports clock, store and player, on the WoW API.

local _, ns = ...
local A = ns.Adapters

A.clock = {
	now = function() return GetTime() end,
	epoch = function() return time() end,
	after = function(seconds, fn) C_Timer.After(seconds, fn) end,
	every = function(seconds, fn) return C_Timer.NewTicker(seconds, fn) end,
}

-- SavedVariables: ListaNegraDB (the name is kept from the add-on's first version)
A.store = {
	load = function()
		if type(ListaNegraDB) ~= "table" then ListaNegraDB = {} end
		return ListaNegraDB
	end,
}

A.player = {
	name = function() return UnitName("player") end,
	realm = function()
		local r = GetNormalizedRealmName and GetNormalizedRealmName()
		if type(r) == "string" and r ~= "" then return r end
		return ((GetRealmName() or ""):gsub("[%s%-]", ""))
	end,
	zone = function() return GetZoneText() end,
	inCombat = function() return InCombatLockdown() and true or false end,
}

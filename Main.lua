-- COMPOSITION ROOT · Plugs the WoW adapters into the application's ports and creates ns.app.
-- Runs first when the saved variables load (ns.onBoot), before every module's ns.onLoad.
--
-- Layers (see README.md, "Code layout"):
--   Domain\       rules, pure Lua (no WoW API)
--   Application\  use cases (App) and the ports they need
--   Adapters\     the ports on the WoW API, plus game events and /ln calling the use cases
--   UI\           the windows, the alert and the menus, which also call the use cases

local _, ns = ...
local A = ns.Adapters

ns.onBoot(function()
	ns.app = ns.App.new({
		clock = A.clock,
		store = A.store,
		player = A.player,
		units = A.units,
		party = A.party,
		plates = A.plates,
		alerts = A.alerts,
		notices = A.notices,
		prompt = A.prompt,
		events = A.events,
	}):start()
end)

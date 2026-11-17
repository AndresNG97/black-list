-- Entry in the game's Options → AddOns: summary and shortcuts to the add-on window.

local _, ns = ...
local UI = ns.UI
local C = UI.C
local L = ns.L

local function build()
	local panel = CreateFrame("Frame")
	panel.name = L["Blacklist"]

	local icon = panel:CreateTexture(nil, "ARTWORK")
	icon:SetSize(32, 32)
	icon:SetPoint("TOPLEFT", 16, -16)
	UI.raidIcon(icon, 8)
	local title = UI.text(panel, 20, C.text, true)
	title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
	title:SetText(L["Blacklist"])

	local desc = UI.text(panel, 14, C.muted)
	desc:SetPoint("TOPLEFT", 16, -64)
	desc:SetPoint("TOPRIGHT", -16, -64)
	desc:SetWordWrap(true)
	desc:SetText(L["Keeps blacklists of players and alerts you when you run into them in the open world, or when someone on your dungeons and raids list joins your group or invites you."])

	local lists = UI.Button(panel, L["Open the lists"], "primary", nil, 30, function() ns.openWindow("pvp") end)
	lists:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
	local alerts = UI.Button(panel, L["Alert settings"], "secondary", nil, 30, function() ns.openWindow("avisos") end)
	alerts:SetPoint("LEFT", lists, "RIGHT", 8, 0)

	local help = UI.text(panel, 13, C.muted)
	-- Below the buttons (which are 30 tall and sit 16 below the description)
	help:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -66)
	help:SetPoint("TOPRIGHT", desc, "BOTTOMRIGHT", 0, -66)
	help:SetWordWrap(true)
	help:SetText(L["Also with /ln (type /ln help to see every command) or with the minimap icon."])

	local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
	Settings.RegisterAddOnCategory(category)
	ns.optionsCategory = category
end

ns.onLoad(function()
	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local ok, err = pcall(build)
		if not ok then geterrorhandler()(err) end
	end
end)

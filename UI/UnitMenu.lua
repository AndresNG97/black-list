-- Clic derecho en retratos y en nombres del chat: añadir, editar o quitar de las listas.

local _, ns = ...
local isSecret, safe, plain = ns.isSecret, ns.safe, ns.plain

local MENU_TAGS = {
	"MENU_UNIT_PLAYER", "MENU_UNIT_ENEMY_PLAYER", "MENU_UNIT_TARGET", "MENU_UNIT_FOCUS",
	"MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_RAID", "MENU_UNIT_FRIEND",
	"MENU_UNIT_COMMUNITIES_GUILD_MEMBER", "MENU_UNIT_GUILD",
}

-- Nombre, reino y datos de la persona del menú (nil si es un PNJ o el juego oculta quién es)
local function identity(ctx)
	if type(ctx) ~= "table" then return end
	local unit = ctx.unit
	if type(unit) == "string" and not isSecret(unit) and plain(safe(UnitExists, unit)) then
		local name, realm = ns.unitIdentity(unit)
		if not name then return end
		return name, realm, ns.unitInfo(unit)
	end
	local name = ctx.name
	if type(name) ~= "string" or isSecret(name) or name == "" then return end
	local n, r = ns.splitName(name)
	local server = ctx.server
	if type(server) == "string" and not isSecret(server) and server ~= "" then r = server end
	return n, r
end

local function later(fn) C_Timer.After(0, fn) end

local function addToMenu(_, root, ctx)
	local name, realm, info = identity(ctx)
	if not name or ns.isMe(name, realm) then return end
	root:CreateDivider()
	root:CreateTitle("Lista Negra")
	for _, id in ipairs(ns.ORDER) do
		local e, k = ns.find(id, name, realm)
		local label = ns.LISTS[id].label
		if e then
			root:CreateButton(("Editar en %s"):format(label), function()
				later(function() ns.openEditor({ mode = "edit", list = id, key = k }) end)
			end)
			root:CreateButton(("Quitar de %s"):format(label), function() ns.remove(id, k) end)
		else
			root:CreateButton(("Añadir a %s"):format(label), function()
				later(function() ns.promptAdd(id, name, realm, nil, info) end)
			end)
		end
	end
end

ns.onLoad(function()
	if not (Menu and type(Menu.ModifyMenu) == "function") then return end
	for _, tag in ipairs(MENU_TAGS) do pcall(Menu.ModifyMenu, tag, addToMenu) end
end)

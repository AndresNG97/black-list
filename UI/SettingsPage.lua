-- Página de ajustes: una tarjeta por lista (mundo abierto / mazmorras y bandas) y otra general.

local _, ns = ...
local UI = ns.UI
local C = UI.C

local Page = {}
UI.SettingsPage = Page

local controls = {}
local function track(c)
	controls[#controls + 1] = c
	return c
end

local function changed() ns.fire("SETTINGS_CHANGED") end

---------------------------------------------------------------------------
-- Opciones
---------------------------------------------------------------------------
local ICONS, SOUNDS, COLORS = {}, {}, {}
for i = 1, 8 do ICONS[i] = { value = i, text = ns.icon(i, 14) .. "  " .. ns.ICON_NAMES[i] } end
for i, s in ipairs(ns.SOUNDS) do SOUNDS[i] = { value = s.key, text = s.text } end
for i, c in ipairs(ns.COLORS) do COLORS[i] = { value = c.key, text = "|cff" .. c.hex .. c.text .. "|r" } end
local DURATIONS = {
	{ value = 3, text = "3 segundos" }, { value = 5, text = "5 segundos" }, { value = 8, text = "8 segundos" },
	{ value = 12, text = "12 segundos" }, { value = 20, text = "20 segundos" },
}
local COOLDOWNS = {
	{ value = 30, text = "30 segundos" }, { value = 60, text = "1 minuto" }, { value = 120, text = "2 minutos" },
	{ value = 300, text = "5 minutos" }, { value = 600, text = "10 minutos" }, { value = 1800, text = "30 minutos" },
}
local SCALES = {
	{ value = 0.75, text = "Pequeño (75 %)" }, { value = 1, text = "Normal (100 %)" },
	{ value = 1.25, text = "Grande (125 %)" }, { value = 1.5, text = "Muy grande (150 %)" },
}

local WHEN = {
	{ "nearby", "Al verlo cerca", "Cuando aparece su placa de nombre, lo seleccionas o le pasas el ratón por encima." },
	{ "inGroup", "Si está en tu grupo", "Cuando entra en tu grupo o banda, o entras tú en el suyo." },
	{ "invite", "Si te invita a un grupo", "Cuando te llega una invitación suya." },
}
local HOW = {
	{ "screen", "Aviso en pantalla", "Tarjeta en el centro de la pantalla con su nombre y los motivos." },
	{ "chat", "Mensaje en el chat", "Escribe el aviso en tu ventana de chat. Solo lo ves tú." },
	{ "plateIcon", "Icono sobre su placa", "Dibuja el icono elegido encima de su placa de nombre. Solo lo ves tú. Necesita las placas de nombre activadas (tecla V)." },
	{ "raidMark", "Marca de banda", "Le pone la marca de banda con el icono elegido. La ve también tu grupo. Nunca dentro de instancias, para no pisar las marcas del líder." },
}

---------------------------------------------------------------------------
-- Tarjeta de una lista
---------------------------------------------------------------------------
local CARD_W, PAD = 356, 16
local INNER = CARD_W - PAD * 2

local function listCard(parent, id, x)
	local cfg = function() return ns.cfg(id) end
	local card = UI.panel(parent, C.panel, C.border)
	card:SetSize(CARD_W, 426)
	card:SetPoint("TOPLEFT", x, -14)

	local stripe = card:CreateTexture(nil, "ARTWORK")
	stripe:SetHeight(2)
	stripe:SetPoint("TOPLEFT", 1, -1)
	stripe:SetPoint("TOPRIGHT", -1, -1)
	stripe:SetColorTexture(ns.hexToRGB(ns.LISTS[id].hex))

	local icon = card:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("TOPLEFT", PAD, -14)
	local title = UI.text(card, 15, C.text, true)
	title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	title:SetText(ns.LISTS[id].label)
	track({ refresh = function() UI.raidIcon(icon, cfg().icon) end })

	local test = UI.Button(card, "Probar", "secondary", nil, 24, function() ns.test(id) end)
	test:SetPoint("TOPRIGHT", -PAD, -12)
	test.tip = "Enseña un aviso de ejemplo con estos ajustes."

	local y = -46
	local function section(text)
		UI.Section(card, text, PAD, y)
		y = y - 16
	end
	local function toggle(opt)
		local key = opt[1]
		local t = track(UI.Toggle(card, opt[2], opt[3],
			function() return cfg()[key] end,
			function(v) cfg()[key] = v; changed() end, INNER))
		t:SetPoint("TOPLEFT", PAD, y)
		y = y - 24
	end
	local function dropdown(text, options, key, after)
		local d = track(UI.Dropdown(card, text, options,
			function() return cfg()[key] end,
			function(v) cfg()[key] = v; if after then after(v) end; changed() end, INNER, 170))
		d:SetPoint("TOPLEFT", PAD, y)
		y = y - 28
	end

	section("Cuándo avisar")
	for _, opt in ipairs(WHEN) do toggle(opt) end
	y = y - 6
	section("Cómo avisar")
	for _, opt in ipairs(HOW) do toggle(opt) end
	y = y - 6
	section("Estilo")
	dropdown("Icono", ICONS, "icon")
	dropdown("Sonido", SOUNDS, "sound", ns.playSound)
	dropdown("Color", COLORS, "color")
	dropdown("Duración en pantalla", DURATIONS, "duration")
	dropdown("Repetir aviso cada", COOLDOWNS, "cooldown")
	return card
end

---------------------------------------------------------------------------
-- Tarjeta general
---------------------------------------------------------------------------
local function generalCard(parent)
	local S = function() return ns.settings end
	local card = UI.panel(parent, C.panel, C.border)
	card:SetSize(CARD_W * 2 + 16, 104)
	card:SetPoint("TOPLEFT", 16, -452)

	local title = UI.text(card, 15, C.text, true)
	title:SetPoint("TOPLEFT", PAD, -14)
	title:SetText("General")

	local killer = track(UI.Toggle(card, "Preguntar al morir quién me mató",
		"Al morir, te propone añadir a la lista de mundo abierto al jugador enemigo que parece haberte matado.",
		function() return S().killerPrompt end, function(v) S().killerPrompt = v; changed() end, INNER))
	killer:SetPoint("TOPLEFT", PAD, -42)

	local minimap = track(UI.Toggle(card, "Icono en el minimapa",
		"Botón de Lista Negra en el borde del minimapa. Arrástralo para moverlo.",
		function() return not S().minimap.hide end, function(v) S().minimap.hide = not v; changed() end, INNER))
	minimap:SetPoint("TOPLEFT", CARD_W + 16 + PAD, -42)

	local scale = track(UI.Dropdown(card, "Tamaño del aviso", SCALES,
		function() return S().alertScale end, function(v) S().alertScale = v; changed() end, INNER, 170))
	scale:SetPoint("TOPLEFT", PAD, -70)

	local reset = UI.Button(card, "Posición inicial", "ghost", nil, 26, function() UI.Banner.reset() end)
	reset:SetPoint("TOPRIGHT", -PAD, -70)
	local move = UI.Button(card, "Mover aviso", "secondary", 130, 26, function()
		UI.Banner.setUnlocked(not UI.Banner.isUnlocked())
		Page.refresh()
	end)
	move:SetPoint("RIGHT", reset, "LEFT", -8, 0)
	move.tip = "Muestra el aviso para que lo arrastres donde quieras. Vuelve a pulsar para fijarlo."
	track({ refresh = function() move:SetLabel(UI.Banner.isUnlocked() and "Fijar aviso" or "Mover aviso") end })
end

---------------------------------------------------------------------------
function Page.build(parent)
	listCard(parent, "pvp", 16)
	listCard(parent, "grupo", 16 + CARD_W + 16)
	generalCard(parent)
end

function Page.refresh()
	for _, c in ipairs(controls) do c.refresh() end
end

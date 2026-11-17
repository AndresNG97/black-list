-- Página de ajustes: una tarjeta por lista (mundo abierto / mazmorras y bandas) y otra general.
-- Las opciones que dependen de otra se atenúan cuando esa está apagada.

local _, ns = ...
local UI = ns.UI
local C = UI.C
local L = ns.L

local Page = {}
UI.SettingsPage = Page

-- Controles a refrescar; enabledIf (opcional) decide si el control está activo
local controls = {}
local function track(c, enabledIf)
	c.enabledIf = enabledIf
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
	{ value = 3, text = L["3 segundos"] }, { value = 5, text = L["5 segundos"] }, { value = 8, text = L["8 segundos"] },
	{ value = 12, text = L["12 segundos"] }, { value = 20, text = L["20 segundos"] },
}
local COOLDOWNS = {
	{ value = 30, text = L["30 segundos"] }, { value = 60, text = L["1 minuto"] }, { value = 120, text = L["2 minutos"] },
	{ value = 300, text = L["5 minutos"] }, { value = 600, text = L["10 minutos"] }, { value = 1800, text = L["30 minutos"] },
}
local SCALES = {
	{ value = 0.75, text = L["Pequeño (75 %)"] }, { value = 1, text = L["Normal (100 %)"] },
	{ value = 1.25, text = L["Grande (125 %)"] }, { value = 1.5, text = L["Muy grande (150 %)"] },
}
local WINDOW_SCALES = {
	{ value = 0.85, text = L["Pequeño (85 %)"] }, { value = 1, text = L["Normal (100 %)"] },
	{ value = 1.15, text = L["Grande (115 %)"] }, { value = 1.3, text = L["Muy grande (130 %)"] },
}

local WHEN = {
	{ "nearby", L["Al verlo cerca"], L["Cuando aparece su placa de nombre, lo seleccionas o le pasas el ratón por encima."] },
	{ "inGroup", L["Si está en tu grupo"], L["Cuando entra en tu grupo o banda, o entras tú en el suyo."] },
	{ "invite", L["Si te invita a un grupo"], L["Cuando te llega una invitación suya."] },
}
local HOW = {
	{ "screen", L["Aviso en pantalla"], L["Tarjeta en el centro de la pantalla con su nombre y los motivos."] },
	{ "chat", L["Mensaje en el chat"], L["Escribe el aviso en tu ventana de chat. Solo lo ves tú."] },
	{ "plateIcon", L["Icono sobre su placa"], L["Dibuja el icono elegido encima de su placa de nombre. Solo lo ves tú. Necesita las placas de nombre activadas (tecla V)."] },
	{ "raidMark", L["Marca de banda"], L["Le pone la marca de banda con el icono elegido. La ve también tu grupo. Nunca dentro de instancias, para no pisar las marcas del líder."] },
}

---------------------------------------------------------------------------
-- Tarjeta de una lista
---------------------------------------------------------------------------
local CARD_W, PAD = 356, 16
local INNER = CARD_W - PAD * 2

local function listCard(parent, id, x)
	local cfg = function() return ns.cfg(id) end
	local groupAlerts = ns.LISTS[id].groupAlerts
	local anyAlert = function()
		local c = cfg()
		return c.nearby or (groupAlerts and (c.inGroup or c.invite))
	end
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
	local test = UI.Button(card, L["Probar"], "secondary", nil, 24, function() ns.test(id) end)
	test:SetPoint("TOPRIGHT", -PAD, -12)
	test.tip = L["Enseña un aviso de ejemplo con estos ajustes."]
	local title = UI.text(card, 15, C.text, true)
	title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	title:SetPoint("RIGHT", test, "LEFT", -8, 0)
	title:SetText(ns.LISTS[id].label)
	track({ refresh = function() UI.raidIcon(icon, cfg().icon) end })

	local y = -46
	local function section(text)
		UI.Section(card, text, PAD, y)
		y = y - 16
	end
	local function toggle(opt, enabledIf)
		local key = opt[1]
		local t = track(UI.Toggle(card, opt[2], opt[3],
			function() return cfg()[key] end,
			function(v) cfg()[key] = v; changed() end, INNER), enabledIf)
		t:SetPoint("TOPLEFT", PAD, y)
		y = y - 24
	end
	local function dropdown(text, tip, options, key, enabledIf, after)
		local d = track(UI.Dropdown(card, text, options,
			function() return cfg()[key] end,
			function(v) cfg()[key] = v; if after then after(v) end; changed() end, INNER, 170), enabledIf)
		d.tip = tip
		d:SetPoint("TOPLEFT", PAD, y)
		y = y - 28
	end

	section(L["Cuándo avisar"])
	if groupAlerts then
		for _, opt in ipairs(WHEN) do toggle(opt) end
	else
		-- Mundo abierto: solo "al verlo cerca"; el hueco de las otras dos filas explica por qué
		toggle(WHEN[1])
		local note = UI.text(card, 12, C.faint)
		note:SetPoint("TOPLEFT", PAD, y - 4)
		note:SetPoint("TOPRIGHT", -PAD, y - 4)
		note:SetWordWrap(true)
		note:SetText(L["En mundo abierto son enemigos: no se avisa por grupo ni por invitaciones."])
		y = y - 48
	end
	y = y - 6
	section(L["Cómo avisar"])
	toggle(HOW[1], anyAlert)
	toggle(HOW[2], anyAlert)
	toggle(HOW[3])
	toggle(HOW[4])
	y = y - 6
	section(L["Estilo"])
	local c = cfg
	dropdown(L["Icono"], L["Icono del aviso, de la placa de nombre y de la marca de banda."], ICONS, "icon",
		function() return c().screen or c().chat or c().plateIcon or c().raidMark end)
	dropdown(L["Sonido"], L["Suena con cada aviso. Al elegirlo lo oyes."], SOUNDS, "sound", anyAlert, ns.playSound)
	dropdown(L["Color"], L["Color del aviso en pantalla y del texto en el chat."], COLORS, "color",
		function() return anyAlert() and (c().screen or c().chat) end)
	dropdown(L["Duración en pantalla"], L["Cuánto tiempo se queda el aviso en pantalla."], DURATIONS, "duration",
		function() return anyAlert() and c().screen end)
	dropdown(L["Repetir aviso cada"], L["Tiempo mínimo entre dos avisos de la misma persona cuando la ves cerca."], COOLDOWNS,
		"cooldown", function() return c().nearby end)
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

	local reset = UI.Button(card, L["Posición inicial"], "ghost", nil, 24, function() UI.Banner.reset() end)
	reset:SetPoint("TOPRIGHT", -PAD, -10)
	reset.tip = L["Devuelve el aviso a su sitio, arriba en el centro."]
	local move = UI.Button(card, L["Mover aviso"], "secondary", 120, 24, function()
		UI.Banner.setUnlocked(not UI.Banner.isUnlocked())
		Page.refresh()
	end)
	move:SetPoint("RIGHT", reset, "LEFT", -8, 0)
	move.tip = L["Muestra el aviso para que lo arrastres donde quieras. Vuelve a pulsar para fijarlo."]
	track({ refresh = function() move:SetLabel(UI.Banner.isUnlocked() and L["Fijar aviso"] or L["Mover aviso"]) end })

	local title = UI.text(card, 15, C.text, true)
	title:SetPoint("TOPLEFT", PAD, -14)
	title:SetText(L["General"])

	local killer = track(UI.Toggle(card, L["Preguntar al morir quién me mató"],
		L["Al morir, te propone añadir a la lista de mundo abierto al jugador enemigo que parece haberte matado."],
		function() return S().killerPrompt end, function(v) S().killerPrompt = v; changed() end, INNER))
	killer:SetPoint("TOPLEFT", PAD, -42)

	local minimap = track(UI.Toggle(card, L["Icono en el minimapa"],
		L["Botón de Lista Negra en el borde del minimapa. Arrástralo para moverlo."],
		function() return not S().minimap.hide end, function(v) S().minimap.hide = not v; changed() end, INNER))
	minimap:SetPoint("TOPLEFT", CARD_W + 16 + PAD, -42)

	local scale = track(UI.Dropdown(card, L["Tamaño del aviso"], SCALES,
		function() return S().alertScale end, function(v) S().alertScale = v; changed() end, INNER, 170))
	scale.tip = L["Tamaño del aviso en pantalla."]
	scale:SetPoint("TOPLEFT", PAD, -70)

	local wscale = track(UI.Dropdown(card, L["Tamaño de las ventanas"], WINDOW_SCALES,
		function() return S().windowScale end, function(v) S().windowScale = v; changed() end, INNER, 170))
	wscale.tip = L["Tamaño de esta ventana y de la de añadir. Si no caben en tu pantalla se reducen solas."]
	wscale:SetPoint("TOPLEFT", CARD_W + 16 + PAD, -70)
end

---------------------------------------------------------------------------
function Page.build(parent)
	listCard(parent, "pvp", 16)
	listCard(parent, "grupo", 16 + CARD_W + 16)
	generalCard(parent)
end

function Page.refresh()
	for _, c in ipairs(controls) do
		if c.enabledIf then c:SetEnabled(c.enabledIf() and true or false) end
		c.refresh()
	end
end

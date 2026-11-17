-- Componentes reutilizables: ventana, botones, interruptores, desplegables, campos de texto,
-- pestañas, selector segmentado, etiquetas de motivo y diálogo de confirmación.
-- Todos tienen estado normal, encima, pulsado y desactivado, y aceptan un tooltip (.tip).

local _, ns = ...
local UI = ns.UI
local C = UI.C
local L = ns.L

-- Tooltip del control si tiene .tip (y .tipTitle opcional). Sin título, el texto hace de título.
local function showTip(self, fallbackTitle)
	if not self.tip then return end
	local title = self.tipTitle or fallbackTitle
	if title and title ~= "" then UI.tip(self, title, self.tip) else UI.tip(self, self.tip) end
end

---------------------------------------------------------------------------
-- Botón
---------------------------------------------------------------------------
local KINDS = {
	primary   = { bg = C.accent, hi = C.accentHi, down = { 0.78, 0.22, 0.24, 1 }, border = C.none, text = { 1, 1, 1, 1 } },
	secondary = { bg = C.panel, hi = C.hover, down = C.pressed, border = C.borderHi, text = C.text },
	ghost     = { bg = C.none, hi = C.hover, down = C.pressed, border = C.none, text = C.muted },
	danger    = { bg = { 0.898, 0.282, 0.302, 0.12 }, hi = { 0.898, 0.282, 0.302, 0.26 },
		down = { 0.898, 0.282, 0.302, 0.36 }, border = { 0.898, 0.282, 0.302, 0.55 }, text = C.accentHi },
}

-- w: ancho fijo o nil (se ajusta al texto)
function UI.Button(parent, text, kind, w, h, onClick)
	local k = KINDS[kind or "secondary"]
	local b = UI.panel(parent, k.bg, k.border, "Button")
	b:SetMotionScriptsWhileDisabled(true)
	b.label = UI.text(b, 13, k.text)
	b.label:SetPoint("CENTER")
	b.onClick = onClick
	function b:SetLabel(t)
		self.label:SetText(t)
		if not w then self:SetWidth(math.max(72, math.ceil(UI.textWidth(self.label)) + 28)) end
	end
	b:SetHeight(h or 28)
	if w then b:SetWidth(w) end
	b:SetLabel(text)
	b:SetScript("OnEnter", function(self)
		if self:IsEnabled() then UI.setColors(self, k.hi) end
		showTip(self, self.label:GetText())
	end)
	b:SetScript("OnLeave", function(self)
		UI.setColors(self, k.bg)
		GameTooltip:Hide()
	end)
	b:SetScript("OnMouseDown", function(self)
		if not self:IsEnabled() then return end
		UI.setColors(self, k.down)
		self.label:SetPoint("CENTER", 0, -1)
	end)
	b:SetScript("OnMouseUp", function(self)
		UI.setColors(self, self:IsMouseOver() and self:IsEnabled() and k.hi or k.bg)
		self.label:SetPoint("CENTER", 0, 0)
	end)
	b:SetScript("OnEnable", function(self)
		self:SetAlpha(1)
		self.label:SetTextColor(unpack(k.text))
	end)
	b:SetScript("OnDisable", function(self)
		self:SetAlpha(0.55)
		self.label:SetTextColor(unpack(C.faint))
		UI.setColors(self, k.bg)
	end)
	b:SetScript("OnClick", function(self, mouse)
		UI.click()
		if self.onClick then self.onClick(self, mouse) end
	end)
	return b
end

-- Botón pequeño con un aspa (cerrar, quitar, borrar texto)
function UI.CloseButton(parent, size, tip, onClick, hoverColor)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(size, size)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	b.bg:SetColorTexture(1, 1, 1, 0.08)
	b.bg:Hide()
	b.cross = UI.cross(b, math.floor(size * 0.36), C.muted)
	b.tip = tip
	b.onClick = onClick
	b:SetScript("OnEnter", function(self)
		self.bg:Show()
		self.cross:SetColor(hoverColor or C.text)
		showTip(self)
	end)
	b:SetScript("OnLeave", function(self)
		self.bg:Hide()
		self.cross:SetColor(C.muted)
		GameTooltip:Hide()
		local p = self:GetParent()
		if p and p.onChildLeave then p.onChildLeave(p) end
	end)
	b:SetScript("OnMouseDown", function(self) self.bg:SetColorTexture(1, 1, 1, 0.14) end)
	b:SetScript("OnMouseUp", function(self) self.bg:SetColorTexture(1, 1, 1, 0.08) end)
	b:SetScript("OnClick", function(self, mouse)
		UI.click()
		if self.onClick then self.onClick(self, mouse) end
	end)
	return b
end

---------------------------------------------------------------------------
-- Interruptor (fila con texto a la izquierda y el interruptor a la derecha)
---------------------------------------------------------------------------
function UI.Toggle(parent, text, tip, get, set, width)
	local row = CreateFrame("Button", nil, parent)
	row:SetSize(width or 320, 24)
	row:SetMotionScriptsWhileDisabled(true)
	row.label = UI.text(row, 13)
	row.label:SetPoint("LEFT")
	row.label:SetPoint("RIGHT", -46, 0)
	row.label:SetText(text)
	row.tip, row.tipTitle = tip, text

	local track = CreateFrame("Frame", nil, row)
	track:SetSize(34, 18)
	track:SetPoint("RIGHT")
	local parts = {}
	local function part()
		local t = track:CreateTexture(nil, "ARTWORK")
		t:SetColorTexture(1, 1, 1, 1)
		parts[#parts + 1] = t
		return t
	end
	local l, r, m = part(), part(), part()
	l:SetSize(18, 18); l:SetPoint("LEFT"); UI.round(l)
	r:SetSize(18, 18); r:SetPoint("RIGHT"); UI.round(r)
	m:SetPoint("TOPLEFT", 9, 0); m:SetPoint("BOTTOMRIGHT", -9, 0)
	local knob = track:CreateTexture(nil, "OVERLAY")
	knob:SetColorTexture(1, 1, 1, 1)
	knob:SetSize(14, 14)
	UI.round(knob)

	function row.refresh()
		local on = get() and true or false
		local c = on and C.accent or C.off
		for _, t in ipairs(parts) do t:SetVertexColor(c[1], c[2], c[3], 1) end
		knob:ClearAllPoints()
		knob:SetPoint(on and "RIGHT" or "LEFT", on and -2 or 2, 0)
		row.label:SetTextColor(unpack(on and C.text or C.muted))
		row:SetAlpha(row:IsEnabled() and 1 or 0.45)
	end
	row:SetScript("OnClick", function()
		UI.click()
		set(not get())
		row.refresh()
	end)
	row:SetScript("OnEnter", function(self)
		if self:IsEnabled() then self.label:SetTextColor(1, 1, 1, 1) end
		showTip(self)
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
		row.refresh()
	end)
	row:SetScript("OnEnable", row.refresh)
	row:SetScript("OnDisable", row.refresh)
	row.refresh()
	return row
end

---------------------------------------------------------------------------
-- Desplegable: el menú del juego anclado bajo el botón, con nuestro estilo.
-- options: { { value = ..., text = ... }, ... }
---------------------------------------------------------------------------
function UI.Dropdown(parent, text, options, get, set, width, buttonWidth)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(width or 320, 26)

	-- "DropdownButton" se encarga de abrir y cerrar el menú; si no existiera, botón normal
	local okDD, dd = pcall(CreateFrame, "DropdownButton", nil, row)
	local b = okDD and dd or CreateFrame("Button", nil, row)
	UI.skin(b, C.field, C.borderHi)
	b:SetSize(buttonWidth or 170, 26)
	b:SetPoint("RIGHT")
	b:SetMotionScriptsWhileDisabled(true)
	b.value = UI.text(b, 13)
	b.value:SetPoint("LEFT", 10, 0)
	b.value:SetPoint("RIGHT", -24, 0)
	local chevron = {}
	for i, d in ipairs({ { -16, 2, -12, -2 }, { -12, -2, -8, 2 } }) do
		local l = b:CreateLine(nil, "OVERLAY")
		l:SetThickness(1.5)
		l:SetColorTexture(unpack(C.muted))
		l:SetStartPoint("RIGHT", b, d[1], d[2])
		l:SetEndPoint("RIGHT", b, d[3], d[4])
		chevron[i] = l
	end

	if text and text ~= "" then
		row.label = UI.text(row, 13)
		row.label:SetPoint("LEFT")
		row.label:SetPoint("RIGHT", b, "LEFT", -10, 0)
		row.label:SetText(text)
	end

	function row.refresh()
		local cur, label = get(), nil
		for _, o in ipairs(options) do
			if o.value == cur then label = o.text end
		end
		b.value:SetText(label or tostring(cur))
		local on = b:IsEnabled()
		row:SetAlpha(on and 1 or 0.45)
	end
	local function choose(v)
		set(v)
		row.refresh()
	end
	local function generate(_, root)
		for _, o in ipairs(options) do
			root:CreateRadio(o.text, function() return get() == o.value end, function() choose(o.value) end)
		end
	end

	if okDD and b.SetupMenu then
		b:SetupMenu(generate)
		if b.SetMenuAnchor and AnchorUtil and AnchorUtil.CreateAnchor then
			b:SetMenuAnchor(AnchorUtil.CreateAnchor("TOPLEFT", b, "BOTTOMLEFT", 0, -2))
		end
	else
		b:SetScript("OnClick", function(self)
			UI.click()
			if MenuUtil and MenuUtil.CreateContextMenu then
				MenuUtil.CreateContextMenu(self, generate)
			else
				local idx = 0
				for i, o in ipairs(options) do if o.value == get() then idx = i end end
				choose(options[idx % #options + 1].value)
			end
		end)
	end

	b:SetScript("OnEnter", function(self)
		if self:IsEnabled() then UI.setColors(self, nil, C.accent) end
		if row.tip then UI.tip(self, row.tipTitle or text or "", row.tip) end
	end)
	b:SetScript("OnLeave", function(self)
		UI.setColors(self, nil, C.borderHi)
		GameTooltip:Hide()
	end)

	function row.SetEnabled(_, on)
		b:SetEnabled(on)
		row.refresh()
	end
	row.button = b
	row.refresh()
	return row
end

---------------------------------------------------------------------------
-- Campo de texto con texto de ayuda y, opcionalmente, botón para borrarlo
---------------------------------------------------------------------------
function UI.Input(parent, w, h, placeholder, withClear)
	local e = UI.panel(parent, C.field, C.borderHi, "EditBox")
	e:SetSize(w, h or 28)
	e:SetFontObject(UI.font(13))
	e:SetTextColor(unpack(C.text))
	e:SetTextInsets(10, withClear and 28 or 10, 0, 0)
	e:SetAutoFocus(false)
	e.ph = UI.text(e, 13, C.faint)
	e.ph:SetPoint("LEFT", 10, 0)
	e.ph:SetPoint("RIGHT", -10, 0)
	e.ph:SetText(placeholder or "")
	if withClear then
		e.clear = UI.CloseButton(e, 20, L["Borrar"], function()
			e:SetText("")
			e:ClearFocus()
		end)
		e.clear:SetPoint("RIGHT", -4, 0)
		e.clear:Hide()
	end
	local function update()
		local empty = e:GetText() == ""
		e.ph:SetShown(empty and not e:HasFocus())
		if e.clear then e.clear:SetShown(not empty) end
	end
	e:SetScript("OnEditFocusGained", function(self) UI.setColors(self, nil, C.accent); update() end)
	e:SetScript("OnEditFocusLost", function(self) UI.setColors(self, nil, C.borderHi); update() end)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	e:SetScript("OnTextChanged", update)
	e:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
	e:SetScript("OnDisable", function(self) self:SetAlpha(0.5) end)
	return e
end

---------------------------------------------------------------------------
-- Pestañas con subrayado
-- items: { { value = ..., text = ..., tip = ... }, ... }
---------------------------------------------------------------------------
function UI.Tabs(parent, items, onSelect)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetHeight(34)
	local div = bar:CreateTexture(nil, "BACKGROUND")
	div:SetColorTexture(unpack(C.border))
	div:SetPoint("BOTTOMLEFT")
	div:SetPoint("BOTTOMRIGHT")
	UI.pixelLine(div, true)
	bar.buttons = {}
	for i, it in ipairs(items) do
		local b = CreateFrame("Button", nil, bar)
		b.value = it.value
		b.tip = it.tip
		b.label = UI.text(b, 13, C.muted, true)
		b.label:SetPoint("CENTER", 0, 1)
		b.label:SetText(it.text or "")
		b.line = b:CreateTexture(nil, "OVERLAY")
		b.line:SetColorTexture(unpack(C.accent))
		b.line:SetHeight(2)
		b.line:SetPoint("BOTTOMLEFT")
		b.line:SetPoint("BOTTOMRIGHT")
		b.line:Hide()
		b.hl = b:CreateTexture(nil, "BACKGROUND")
		b.hl:SetAllPoints()
		b.hl:SetColorTexture(1, 1, 1, 0.04)
		b.hl:Hide()
		b:SetScript("OnClick", function() UI.click(); onSelect(it.value) end)
		b:SetScript("OnEnter", function(self)
			self.hl:Show()
			if not self.selected then self.label:SetTextColor(unpack(C.text)) end
			if self.tip then UI.tip(self, self.label:GetText(), self.tip, "ANCHOR_BOTTOM") end
		end)
		b:SetScript("OnLeave", function(self)
			self.hl:Hide()
			if not self.selected then self.label:SetTextColor(unpack(C.muted)) end
			GameTooltip:Hide()
		end)
		bar.buttons[i] = b
	end
	function bar:Layout()
		local x = 0
		for _, b in ipairs(self.buttons) do
			local w = math.ceil(UI.textWidth(b.label)) + 28
			b:SetSize(w, 34)
			b:ClearAllPoints()
			b:SetPoint("BOTTOMLEFT", x, 0)
			x = x + w + 2
		end
	end
	function bar:SetItemText(value, text)
		for _, b in ipairs(self.buttons) do
			if b.value == value then b.label:SetText(text) end
		end
		self:Layout()
	end
	function bar:Select(value)
		for _, b in ipairs(self.buttons) do
			local on = b.value == value
			b.selected = on
			b.line:SetShown(on)
			b.label:SetTextColor(unpack(on and C.text or C.muted))
		end
	end
	bar:Layout()
	return bar
end

---------------------------------------------------------------------------
-- Selector segmentado (varias opciones en una barra; una activa)
-- items: { { value, text, rgb }, ... }
---------------------------------------------------------------------------
function UI.Segmented(parent, items, onSelect, w, h)
	h = h or 30
	local box = UI.panel(parent, C.field, C.borderHi)
	box:SetSize(w, h)
	local bw = (w - 6) / #items
	box.buttons = {}
	for i, it in ipairs(items) do
		local b = UI.panel(box, C.none, C.none, "Button")
		b:SetSize(bw, h - 6)
		b:SetPoint("LEFT", 3 + (i - 1) * bw, 0)
		b.label = UI.text(b, 13, C.muted)
		b.label:SetPoint("LEFT", 8, 0)
		b.label:SetPoint("RIGHT", -8, 0)
		b.label:SetJustifyH("CENTER")
		b.label:SetText(it.text)
		b.item = it
		b:SetScript("OnClick", function(self)
			if self.locked then return end
			UI.click()
			onSelect(it.value)
		end)
		b:SetScript("OnEnter", function(self)
			if self.locked then
				UI.tip(self, it.text, L["Para cambiar de lista, usa «Mover a…» con clic derecho en la fila."])
			elseif not self.on then
				self.label:SetTextColor(unpack(C.text))
			end
		end)
		b:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
			if not self.on then self.label:SetTextColor(unpack(self.locked and C.faint or C.muted)) end
		end)
		box.buttons[i] = b
	end
	-- locked: solo se ve la opción activa (al editar)
	function box:Select(value, locked)
		for _, b in ipairs(self.buttons) do
			local on = b.item.value == value
			local c = b.item.rgb or C.accent
			b.on, b.locked = on, locked
			if on then
				UI.setColors(b, { c[1], c[2], c[3], 0.22 }, { c[1], c[2], c[3], 0.75 })
				b.label:SetTextColor(1, 1, 1, 1)
			else
				UI.setColors(b, C.none, C.none)
				b.label:SetTextColor(unpack(locked and C.faint or C.muted))
			end
		end
	end
	return box
end

---------------------------------------------------------------------------
-- Etiqueta de motivo que se marca y desmarca
---------------------------------------------------------------------------
function UI.Chip(parent, text, rgb)
	local c = UI.panel(parent, C.panel, C.borderHi, "Button")
	c.label = UI.text(c, 13, C.muted)
	c.label:SetPoint("CENTER")
	c.label:SetText(text)
	c:SetSize(math.ceil(UI.textWidth(c.label)) + 24, 26)
	c.rgb = rgb or C.accent
	function c:SetSelected(on)
		self.selected = on and true or false
		local k = self.rgb
		if self.selected then
			UI.setColors(self, { k[1], k[2], k[3], 0.20 }, { k[1], k[2], k[3], 0.85 })
			self.label:SetTextColor(1, 1, 1, 1)
		else
			UI.setColors(self, C.panel, C.borderHi)
			self.label:SetTextColor(unpack(C.muted))
		end
	end
	c:SetScript("OnClick", function(self)
		UI.click()
		self:SetSelected(not self.selected)
	end)
	c:SetScript("OnEnter", function(self)
		if not self.selected then
			UI.setColors(self, C.hover)
			self.label:SetTextColor(unpack(C.text))
		end
	end)
	c:SetScript("OnLeave", function(self) self:SetSelected(self.selected) end)
	c:SetSelected(false)
	return c
end

-- Coloca elementos en filas que se parten al llegar al ancho máximo. Devuelve el alto usado.
function UI.flow(items, parent, x, y, maxW, gap)
	local cx, cy, rowH = x, y, 0
	for _, it in ipairs(items) do
		local w, h = it:GetWidth(), it:GetHeight()
		if cx + w > x + maxW and cx > x then
			cx, cy, rowH = x, cy - rowH - gap, 0
		end
		it:ClearAllPoints()
		it:SetPoint("TOPLEFT", parent, "TOPLEFT", cx, cy)
		cx = cx + w + gap
		rowH = math.max(rowH, h)
	end
	return (y - cy) + rowH
end

---------------------------------------------------------------------------
-- Ventanas
--   · Escape cierra solo la de arriba (las otras salen de UISpecialFrames mientras tanto)
--   · Guardan su posición (opts.save) y se encogen solas si no caben en pantalla
---------------------------------------------------------------------------
local escStack, ours = {}, {}

local function syncEscape()
	for i = #UISpecialFrames, 1, -1 do
		if ours[UISpecialFrames[i]] then table.remove(UISpecialFrames, i) end
	end
	local top = escStack[#escStack]
	if top then table.insert(UISpecialFrames, top:GetName()) end
end

local function unstack(f)
	for i = #escStack, 1, -1 do
		if escStack[i] == f then table.remove(escStack, i) end
	end
end

local windows = {}

-- Coloca la ventana en su posición guardada (en unidades de pantalla) o en el centro
local function place(f)
	f:ClearAllPoints()
	local saved = f.saveKey and ns.settings.windows[f.saveKey]
	if saved and saved.point then
		local s = f:GetScale()
		f:SetPoint(saved.point, UIParent, saved.relPoint or saved.point, (saved.x or 0) / s, (saved.y or 0) / s)
	else
		f:SetPoint("CENTER")
	end
end

local function fit(f)
	local want = ns.settings.windowScale or 1
	local maxW = (UIParent:GetWidth() - 40) / f.baseW
	local maxH = (UIParent:GetHeight() - 40) / f.baseH
	local s = math.max(0.5, math.min(want, maxW, maxH))
	if math.abs(s - f:GetScale()) > 0.001 then
		f:SetScale(s)
		place(f)
	end
	UI.refreshPixels()
end

function UI.fitWindows()
	for _, f in ipairs(windows) do fit(f) end
end

-- opts: name, w, h, title, strata, save (clave para guardar la posición)
function UI.Window(opts)
	local f = UI.skin(CreateFrame("Frame", opts.name, UIParent), C.bg, C.borderHi)
	f.baseW, f.baseH = opts.w, opts.h
	f:SetSize(opts.w, opts.h)
	f:SetFrameStrata(opts.strata or "DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:Hide()

	f.saveKey = opts.save
	place(f)

	ours[opts.name] = true
	windows[#windows + 1] = f
	f:HookScript("OnShow", function(self)
		fit(self)
		unstack(self)
		escStack[#escStack + 1] = self
		syncEscape()
	end)
	f:HookScript("OnHide", function(self)
		unstack(self)
		-- Al pulsar Escape el juego está recorriendo UISpecialFrames: no tocarla hasta el siguiente fotograma
		C_Timer.After(0, syncEscape)
	end)

	local top = f:CreateTexture(nil, "ARTWORK")
	top:SetColorTexture(unpack(C.accent))
	top:SetHeight(2)
	top:SetPoint("TOPLEFT", 1, -1)
	top:SetPoint("TOPRIGHT", -1, -1)

	local head = CreateFrame("Frame", nil, f)
	head:SetPoint("TOPLEFT")
	head:SetPoint("TOPRIGHT")
	head:SetHeight(50)
	head:EnableMouse(true)
	head:RegisterForDrag("LeftButton")
	head:SetScript("OnDragStart", function() f:StartMoving() end)
	head:SetScript("OnDragStop", function()
		f:StopMovingOrSizing()
		if opts.save then
			-- En unidades de pantalla: cambiar el tamaño de la ventana no la mueve de sitio
			local point, _, relPoint, x, y = f:GetPoint(1)
			local s = f:GetScale()
			ns.settings.windows[opts.save] = { point = point, relPoint = relPoint, x = x * s, y = y * s }
		end
	end)

	f.icon = head:CreateTexture(nil, "ARTWORK")
	f.icon:SetSize(24, 24)
	f.icon:SetPoint("LEFT", 16, -1)
	UI.raidIcon(f.icon, 8)
	f.close = UI.CloseButton(head, 26, L["Cerrar (Esc)"], function() f:Hide() end)
	f.close:SetPoint("RIGHT", -12, 0)
	-- Título y subtítulo: anclados por la izquierda y la derecha a la misma altura
	f.title = UI.text(head, 16, C.text, true)
	f.title:SetText(opts.title or "")
	f.subtitle = UI.text(head, 12, C.muted)
	f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
	f.subtitle:SetPoint("TOPRIGHT", f.title, "BOTTOMRIGHT", 0, -3)
	local function placeTitle(withSub)
		local dy = withSub and 7 or 0
		f.title:ClearAllPoints()
		f.title:SetPoint("LEFT", f.icon, "RIGHT", 10, dy)
		f.title:SetPoint("RIGHT", f.close, "LEFT", -12, dy)
	end
	placeTitle(false)

	function f:SetTitle(t) self.title:SetText(t or "") end
	function f:SetSubtitle(t)
		self.subtitle:SetText(t or "")
		placeTitle(t and t ~= "")
	end
	return f
end

-- Vuelve a poner las ventanas en el centro (por si alguna quedó fuera de la pantalla)
function UI.resetWindows()
	wipe(ns.settings.windows)
	for _, f in ipairs(windows) do
		f:ClearAllPoints()
		f:SetPoint("CENTER")
	end
end

-- Título pequeño de sección
function UI.Section(parent, text, x, y)
	local fs = UI.text(parent, 12, C.faint, true)
	fs:SetPoint("TOPLEFT", x, y)
	fs:SetText(text)
	return fs
end

---------------------------------------------------------------------------
-- Confirmación
---------------------------------------------------------------------------
local confirm
function UI.confirm(title, text, yesText, onYes)
	if not confirm then
		confirm = UI.Window({ name = "ListaNegraConfirm", w = 400, h = 160, strata = "FULLSCREEN_DIALOG" })
		confirm.msg = UI.text(confirm, 13)
		confirm.msg:SetPoint("TOPLEFT", 18, -60)
		confirm.msg:SetPoint("TOPRIGHT", -18, -60)
		confirm.msg:SetWordWrap(true)
		confirm.yes = UI.Button(confirm, "", "danger", 120, 28)
		confirm.yes:SetPoint("BOTTOMRIGHT", -16, 16)
		confirm.no = UI.Button(confirm, CANCEL or L["Cancelar"], "secondary", 110, 28, function() confirm:Hide() end)
		confirm.no:SetPoint("RIGHT", confirm.yes, "LEFT", -8, 0)
	end
	confirm:SetTitle(title)
	confirm.msg:SetText(text)
	confirm.yes:SetLabel(yesText or ACCEPT or L["Aceptar"])
	confirm.yes.onClick = function()
		confirm:Hide()
		onYes()
	end
	confirm:Show()
	confirm:Raise()
end

ns.onLoad(function()
	ns.on("UI_SCALE_CHANGED", UI.fitWindows)
	ns.on("DISPLAY_SIZE_CHANGED", UI.fitWindows)
	ns.listen("SETTINGS_CHANGED", UI.fitWindows)
end)

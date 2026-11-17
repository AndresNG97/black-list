-- Componentes reutilizables: ventana, botones, interruptores, desplegables, campos de texto,
-- pestañas, selector segmentado, etiquetas de motivo y diálogo de confirmación.

local _, ns = ...
local UI = ns.UI
local C = UI.C

---------------------------------------------------------------------------
-- Botón
---------------------------------------------------------------------------
local KINDS = {
	primary   = { bg = C.accent, hi = C.accentHi, border = C.none, text = { 1, 1, 1, 1 } },
	secondary = { bg = C.panel, hi = C.hover, border = C.borderHi, text = C.text },
	ghost     = { bg = C.none, hi = C.hover, border = C.none, text = C.muted },
	danger    = { bg = { 0.898, 0.282, 0.302, 0.12 }, hi = { 0.898, 0.282, 0.302, 0.26 },
		border = { 0.898, 0.282, 0.302, 0.55 }, text = C.accentHi },
}

-- w: ancho fijo o nil (se ajusta al texto)
function UI.Button(parent, text, kind, w, h, onClick)
	local k = KINDS[kind or "secondary"]
	local b = UI.panel(parent, k.bg, k.border, "Button")
	b.label = UI.text(b, 13, k.text)
	b.label:SetPoint("CENTER")
	b.onClick = onClick
	function b:SetLabel(t)
		self.label:SetText(t)
		if not w then self:SetWidth(math.max(70, self.label:GetStringWidth() + 28)) end
	end
	b:SetHeight(h or 28)
	if w then b:SetWidth(w) end
	b:SetLabel(text)
	b:SetScript("OnEnter", function(self)
		if self:IsEnabled() then UI.setColors(self, k.hi) end
		if self.tip then UI.tip(self, self.tipTitle or self.label:GetText(), self.tip) end
	end)
	b:SetScript("OnLeave", function(self)
		UI.setColors(self, k.bg)
		GameTooltip:Hide()
	end)
	b:SetScript("OnMouseDown", function(self) if self:IsEnabled() then self.label:SetPoint("CENTER", 0, -1) end end)
	b:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER", 0, 0) end)
	b:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
	b:SetScript("OnDisable", function(self) self:SetAlpha(0.4) end)
	b:SetScript("OnClick", function(self, mouse)
		UI.click()
		if self.onClick then self.onClick(self, mouse) end
	end)
	return b
end

-- Botón pequeño con un símbolo (cerrar, quitar...)
function UI.IconButton(parent, glyph, size, tip, onClick, hoverColor)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(size, size)
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	b.bg:SetColorTexture(1, 1, 1, 0.08)
	b.bg:Hide()
	b.label = UI.text(b, size - 4, C.muted, true)
	b.label:SetPoint("CENTER", 0, 1)
	b.label:SetText(glyph)
	b.onClick = onClick
	b:SetScript("OnEnter", function(self)
		self.bg:Show()
		self.label:SetTextColor(unpack(hoverColor or C.text))
		if tip then UI.tip(self, tip) end
	end)
	b:SetScript("OnLeave", function(self)
		self.bg:Hide()
		self.label:SetTextColor(unpack(C.muted))
		GameTooltip:Hide()
		local p = self:GetParent()
		if p and p.onChildLeave then p.onChildLeave(p) end
	end)
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
	row.label = UI.text(row, 13)
	row.label:SetPoint("LEFT")
	row.label:SetPoint("RIGHT", -46, 0)
	row.label:SetText(text)

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
	end
	row:SetScript("OnClick", function()
		UI.click()
		set(not get())
		row.refresh()
	end)
	row:SetScript("OnEnter", function(self)
		self.label:SetTextColor(1, 1, 1, 1)
		if tip then UI.tip(self, text, tip) end
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
		row.refresh()
	end)
	row.refresh()
	return row
end

---------------------------------------------------------------------------
-- Desplegable (menú moderno del juego; si no existe, recorre las opciones al hacer clic)
-- options: { { value = ..., text = ... }, ... }
---------------------------------------------------------------------------
function UI.Dropdown(parent, text, options, get, set, width, buttonWidth)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(width or 320, 26)
	if text and text ~= "" then
		row.label = UI.text(row, 13)
		row.label:SetPoint("LEFT")
		row.label:SetText(text)
	end

	local b = UI.panel(row, C.field, C.borderHi, "Button")
	b:SetSize(buttonWidth or 170, 26)
	b:SetPoint("RIGHT")
	b.value = UI.text(b, 13)
	b.value:SetPoint("LEFT", 10, 0)
	b.value:SetPoint("RIGHT", -24, 0)
	local c1 = b:CreateLine(nil, "OVERLAY")
	c1:SetThickness(1.5)
	c1:SetColorTexture(unpack(C.muted))
	c1:SetStartPoint("RIGHT", b, -16, 2)
	c1:SetEndPoint("RIGHT", b, -12, -2)
	local c2 = b:CreateLine(nil, "OVERLAY")
	c2:SetThickness(1.5)
	c2:SetColorTexture(unpack(C.muted))
	c2:SetStartPoint("RIGHT", b, -12, -2)
	c2:SetEndPoint("RIGHT", b, -8, 2)

	function row.refresh()
		local cur, label = get(), nil
		for _, o in ipairs(options) do
			if o.value == cur then label = o.text end
		end
		b.value:SetText(label or tostring(cur))
	end
	local function choose(v)
		set(v)
		row.refresh()
	end

	b:SetScript("OnEnter", function(self) UI.setColors(self, nil, C.accent) end)
	b:SetScript("OnLeave", function(self) UI.setColors(self, nil, C.borderHi) end)
	b:SetScript("OnClick", function(self)
		UI.click()
		if MenuUtil and MenuUtil.CreateContextMenu then
			MenuUtil.CreateContextMenu(self, function(_, root)
				for _, o in ipairs(options) do
					root:CreateRadio(o.text, function() return get() == o.value end, function() choose(o.value) end)
				end
			end)
		else
			local idx = 0
			for i, o in ipairs(options) do if o.value == get() then idx = i end end
			choose(options[idx % #options + 1].value)
		end
	end)
	row.button = b
	row.refresh()
	return row
end

---------------------------------------------------------------------------
-- Campo de texto con texto de ayuda
---------------------------------------------------------------------------
function UI.Input(parent, w, h, placeholder)
	local e = UI.panel(parent, C.field, C.borderHi, "EditBox")
	e:SetSize(w, h or 28)
	e:SetFontObject(UI.font(13))
	e:SetTextColor(unpack(C.text))
	e:SetTextInsets(10, 10, 0, 0)
	e:SetAutoFocus(false)
	e.ph = UI.text(e, 13, C.faint)
	e.ph:SetPoint("LEFT", 10, 0)
	e.ph:SetText(placeholder or "")
	local function update() e.ph:SetShown(e:GetText() == "" and not e:HasFocus()) end
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
-- items: { { value = ..., text = ... }, ... }
---------------------------------------------------------------------------
function UI.Tabs(parent, items, onSelect)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetHeight(34)
	local div = bar:CreateTexture(nil, "BACKGROUND")
	div:SetColorTexture(unpack(C.border))
	div:SetHeight(1)
	div:SetPoint("BOTTOMLEFT")
	div:SetPoint("BOTTOMRIGHT")
	bar.buttons = {}
	for i, it in ipairs(items) do
		local b = CreateFrame("Button", nil, bar)
		b.value = it.value
		b.label = UI.text(b, 13, C.muted, true)
		b.label:SetPoint("CENTER", 0, 1)
		b.label:SetText(it.text or "")
		b.line = b:CreateTexture(nil, "OVERLAY")
		b.line:SetColorTexture(unpack(C.accent))
		b.line:SetHeight(2)
		b.line:SetPoint("BOTTOMLEFT")
		b.line:SetPoint("BOTTOMRIGHT")
		b.line:Hide()
		b:SetScript("OnClick", function() UI.click(); onSelect(it.value) end)
		b:SetScript("OnEnter", function(self) if not self.selected then self.label:SetTextColor(unpack(C.text)) end end)
		b:SetScript("OnLeave", function(self) if not self.selected then self.label:SetTextColor(unpack(C.muted)) end end)
		bar.buttons[i] = b
	end
	function bar:Layout()
		local x = 0
		for _, b in ipairs(self.buttons) do
			local w = b.label:GetStringWidth() + 28
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
		b.label:SetPoint("CENTER")
		b.label:SetText(it.text)
		b.item = it
		b:SetScript("OnClick", function(self)
			if self.locked then return end
			UI.click()
			onSelect(it.value)
		end)
		box.buttons[i] = b
	end
	-- locked: solo se puede ver la opción activa (al editar)
	function box:Select(value, locked)
		for _, b in ipairs(self.buttons) do
			local on = b.item.value == value
			local c = b.item.rgb or C.accent
			b.locked = locked
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
	c:SetSize(c.label:GetStringWidth() + 24, 26)
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
	c:SetScript("OnEnter", function(self) if not self.selected then self.label:SetTextColor(unpack(C.text)) end end)
	c:SetScript("OnLeave", function(self) if not self.selected then self.label:SetTextColor(unpack(C.muted)) end end)
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
-- Ventana: cabecera arrastrable con icono, título, subtítulo y botón de cerrar
---------------------------------------------------------------------------
function UI.Window(name, w, h, title, strata)
	local f = UI.panel(UIParent, C.bg, C.borderHi)
	if name then _G[name] = f end
	f:SetSize(w, h)
	f:SetPoint("CENTER")
	f:SetFrameStrata(strata or "DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:Hide()
	if name then tinsert(UISpecialFrames, name) end

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
	head:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

	f.icon = head:CreateTexture(nil, "ARTWORK")
	f.icon:SetSize(24, 24)
	f.icon:SetPoint("LEFT", 16, -1)
	UI.raidIcon(f.icon, 8)
	f.title = UI.text(head, 16, C.text, true)
	f.title:SetPoint("LEFT", f.icon, "RIGHT", 10, 0)
	f.title:SetText(title or "")
	f.subtitle = UI.text(head, 12, C.muted)
	f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
	f.close = UI.IconButton(head, "×", 26, nil, function() f:Hide() end)
	f.close:SetPoint("RIGHT", -12, 0)

	function f:SetTitle(t) self.title:SetText(t or "") end
	function f:SetSubtitle(t)
		self.subtitle:SetText(t or "")
		self.title:SetPoint("LEFT", self.icon, "RIGHT", 10, (t and t ~= "") and 7 or 0)
	end
	return f
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
		confirm = UI.Window("ListaNegraConfirm", 400, 160, "", "FULLSCREEN_DIALOG")
		confirm.msg = UI.text(confirm, 13)
		confirm.msg:SetPoint("TOPLEFT", 18, -60)
		confirm.msg:SetPoint("TOPRIGHT", -18, -60)
		confirm.msg:SetWordWrap(true)
		confirm.yes = UI.Button(confirm, "", "danger", 120, 28)
		confirm.yes:SetPoint("BOTTOMRIGHT", -16, 16)
		confirm.no = UI.Button(confirm, CANCEL or "Cancelar", "secondary", 110, 28, function() confirm:Hide() end)
		confirm.no:SetPoint("RIGHT", confirm.yes, "LEFT", -8, 0)
	end
	confirm:SetTitle(title)
	confirm.msg:SetText(text)
	confirm.yes:SetLabel(yesText or ACCEPT or "Aceptar")
	confirm.yes.onClick = function()
		confirm:Hide()
		onYes()
	end
	confirm:Show()
	confirm:Raise()
end

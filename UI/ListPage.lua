-- Página de una lista: buscador, orden, botones de añadir y filas con desplazamiento suave.

local _, ns = ...
local UI = ns.UI
local C = UI.C

local Page = {}
UI.ListPage = Page

local listId, filter = "pvp", ""
local ROW_H = 58

local SORTS = {
	{ value = "seen", text = "Visto hace menos" },
	{ value = "added", text = "Añadido hace menos" },
	{ value = "kills", text = "Más muertes" },
	{ value = "name", text = "Nombre (A-Z)" },
}
local SORTERS = {
	seen = function(a, b) return (a.e.lastSeen or a.e.added or 0) > (b.e.lastSeen or b.e.added or 0) end,
	added = function(a, b) return (a.e.added or 0) > (b.e.added or 0) end,
	kills = function(a, b)
		if (a.e.kills or 0) ~= (b.e.kills or 0) then return (a.e.kills or 0) > (b.e.kills or 0) end
		return a.k < b.k
	end,
	name = function(a, b) return a.k < b.k end,
}

local function entries()
	local out, f = {}, filter:lower()
	for k, e in pairs(ns.db.lists[listId]) do
		if f == "" or k:find(f, 1, true) or ns.reasonText(e):lower():find(f, 1, true) then
			out[#out + 1] = { k = k, e = e, list = listId }
		end
	end
	table.sort(out, SORTERS[ns.settings.sort] or SORTERS.seen)
	return out
end

---------------------------------------------------------------------------
-- Acciones de una fila
---------------------------------------------------------------------------
local function other(id) return id == "pvp" and "grupo" or "pvp" end

local function confirmRemove(data)
	UI.confirm("Quitar de la lista", ("¿Quitar a %s de %s?"):format(ns.coloredName(data.e), ns.listTag(data.list)), "Quitar",
		function() ns.remove(data.list, data.k) end)
end

local function moveTo(data, to)
	local e = data.e
	local copy = {}
	for f, v in pairs(e) do copy[f] = v end
	ns.db.lists[to][data.k] = copy
	ns.db.lists[data.list][data.k] = nil
	ns.changed()
	ns.say("%s movido a %s.", ns.coloredName(e), ns.listTag(to))
end

local function rowMenu(row)
	local data = row.data
	if not (data and MenuUtil and MenuUtil.CreateContextMenu) then return end
	MenuUtil.CreateContextMenu(row, function(_, root)
		root:CreateTitle(ns.fullName(data.e))
		root:CreateButton("Editar motivos y nota", function() ns.openEditor({ mode = "edit", list = data.list, key = data.k }) end)
		local to = other(data.list)
		if not ns.entry(to, data.k) then
			root:CreateButton(("Mover a %s"):format(ns.LISTS[to].label), function() moveTo(data, to) end)
		end
		root:CreateDivider()
		root:CreateButton("|cffe5484dQuitar de la lista|r", function() confirmRemove(data) end)
	end)
end

local function rowTooltip(row)
	local e = row.data and row.data.e
	if not e then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(ns.coloredName(e))
	local reason = ns.reasonText(e)
	if reason ~= "" then GameTooltip:AddLine(reason, 1, 1, 1, true) end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Añadido", date("%d/%m/%Y", e.added or time()), 0.6, 0.62, 0.68, 1, 1, 1)
	GameTooltip:AddDoubleLine("Visto", ns.ago(e.lastSeen) .. (e.lastZone and (" en " .. e.lastZone) or ""), 0.6, 0.62, 0.68, 1, 1, 1)
	GameTooltip:AddDoubleLine("Veces visto", tostring(e.seen or 0), 0.6, 0.62, 0.68, 1, 1, 1)
	if (e.kills or 0) > 0 then
		GameTooltip:AddDoubleLine("Te ha matado", ("%d (la última %s)"):format(e.kills, ns.ago(e.lastKill)), 0.6, 0.62, 0.68, 1, 0.35, 0.35)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Clic: editar · Clic derecho: más opciones", 0.5, 0.75, 1)
	GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Filas
---------------------------------------------------------------------------
local function buildRow(row)
	UI.skin(row, C.panel, C.border)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	row.stripe = row:CreateTexture(nil, "ARTWORK")
	row.stripe:SetWidth(3)
	row.stripe:SetPoint("TOPLEFT", 1, -1)
	row.stripe:SetPoint("BOTTOMLEFT", 1, 1)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(32, 32)
	row.icon:SetPoint("LEFT", 16, 0)
	UI.round(row.icon)

	row.name = UI.text(row, 15, nil, true)
	row.name:SetPoint("TOPLEFT", 60, -11)
	row.meta = UI.text(row, 12, C.muted)
	row.meta:SetPoint("LEFT", row.name, "RIGHT", 10, -1)
	row.reason = UI.text(row, 13, C.muted)
	row.reason:SetPoint("BOTTOMLEFT", 60, 11)
	row.reason:SetPoint("RIGHT", -150, 0)

	row.seen = UI.text(row, 12, C.faint)
	row.seen:SetPoint("TOPRIGHT", -44, -12)
	row.seen:SetJustifyH("RIGHT")
	row.kills = UI.text(row, 13, { 1, 0.4, 0.4, 1 })
	row.kills:SetPoint("BOTTOMRIGHT", -44, 11)
	row.kills:SetJustifyH("RIGHT")

	row.del = UI.IconButton(row, "×", 24, "Quitar de la lista", function() confirmRemove(row.data) end, C.accentHi)
	row.del:SetPoint("RIGHT", -10, 0)
	row.del:SetAlpha(0)
	row.onChildLeave = function(self)
		if not self:IsMouseOver() then
			UI.setColors(self, C.panel)
			self.del:SetAlpha(0)
		end
	end

	row:SetScript("OnEnter", function(self)
		UI.setColors(self, C.hover)
		self.del:SetAlpha(1)
		rowTooltip(self)
	end)
	row:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		self:onChildLeave()
	end)
	row:SetScript("OnClick", function(self, mouse)
		if not self.data then return end
		if mouse == "RightButton" then
			rowMenu(self)
		else
			UI.click()
			ns.openEditor({ mode = "edit", list = self.data.list, key = self.data.k })
		end
	end)
	row.built = true
end

local function initRow(row, data)
	if not row.built then buildRow(row) end
	row.data = data
	local e = data.e
	local hex = ns.LISTS[data.list].hex
	row.stripe:SetColorTexture(ns.hexToRGB(hex))
	UI.setClassIcon(row.icon, e.class)
	row.name:SetText(ns.coloredName(e))

	local meta = {}
	if e.level then meta[#meta + 1] = "Nv " .. e.level end
	if e.race then meta[#meta + 1] = e.race end
	if e.faction then meta[#meta + 1] = ns.factionText(e.faction) end
	row.meta:SetText(table.concat(meta, " · "))

	local parts = {}
	local tags = ns.tagNames(e)
	if #tags > 0 then parts[#parts + 1] = ("|cff%s%s|r"):format(hex, table.concat(tags, " · ")) end
	if e.reason and e.reason ~= "" then parts[#parts + 1] = e.reason end
	row.reason:SetText(#parts > 0 and table.concat(parts, "   ") or ("|cff%sSin motivo: haz clic para añadirlo|r"):format(UI.HEX.faint))

	row.seen:SetText(e.lastSeen and ("visto " .. ns.ago(e.lastSeen)) or "sin ver todavía")
	row.kills:SetText((e.kills or 0) > 0 and (ns.icon(8, 13) .. " " .. e.kills) or "")
	UI.setColors(row, C.panel)
	row.del:SetAlpha(0)
end

---------------------------------------------------------------------------
-- Página
---------------------------------------------------------------------------
function Page.build(parent)
	Page.search = UI.Input(parent, 250, 30, "Buscar por nombre o motivo...")
	Page.search:SetPoint("TOPLEFT", 16, -14)
	Page.search:HookScript("OnTextChanged", function(self)
		filter = self:GetText() or ""
		Page.refresh()
	end)

	Page.sort = UI.Dropdown(parent, nil, SORTS, function() return ns.settings.sort end,
		function(v) ns.settings.sort = v; Page.refresh() end, 170, 170)
	Page.sort:SetPoint("LEFT", Page.search, "RIGHT", 8, 0)

	Page.addTarget = UI.Button(parent, "+ Añadir objetivo", "primary", nil, 30, function() ns.addTarget(listId) end)
	Page.addTarget:SetPoint("TOPRIGHT", -16, -14)
	Page.addTarget.tip = "Añade al jugador que tienes seleccionado."
	Page.addName = UI.Button(parent, "Añadir por nombre", "secondary", nil, 30,
		function() ns.openEditor({ mode = "add", list = listId }) end)
	Page.addName:SetPoint("RIGHT", Page.addTarget, "LEFT", -8, 0)

	local box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
	box:SetPoint("TOPLEFT", 16, -58)
	box:SetPoint("BOTTOMRIGHT", -28, 16)
	local bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
	bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 8, 0)
	bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 8, 0)
	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(ROW_H)
	view:SetPadding(0, 0, 0, 0, 6)
	view:SetElementInitializer("Button", initRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
	if ScrollUtil.AddManagedScrollBarVisibilityBehavior then
		ScrollUtil.AddManagedScrollBarVisibilityBehavior(box, bar)
	end
	Page.box = box

	-- Lista vacía
	local empty = CreateFrame("Frame", nil, parent)
	empty:SetSize(420, 140)
	empty:SetPoint("CENTER", box, "CENTER", 0, 20)
	empty.icon = empty:CreateTexture(nil, "ARTWORK")
	empty.icon:SetSize(56, 56)
	empty.icon:SetPoint("TOP")
	empty.icon:SetAlpha(0.25)
	empty.title = UI.text(empty, 16, C.text, true)
	empty.title:SetPoint("TOP", empty.icon, "BOTTOM", 0, -12)
	empty.hint = UI.text(empty, 13, C.muted)
	empty.hint:SetPoint("TOP", empty.title, "BOTTOM", 0, -8)
	empty.hint:SetWidth(420)
	empty.hint:SetWordWrap(true)
	empty.hint:SetJustifyH("CENTER")
	Page.empty = empty
end

function Page.refresh(id)
	if id then listId = id end
	if not Page.box then return end
	local list = entries()
	local dp = CreateDataProvider()
	for _, it in ipairs(list) do dp:Insert(it) end
	Page.box:SetDataProvider(dp, ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
	Page.sort.refresh()

	local empty = Page.empty
	empty:SetShown(#list == 0)
	if #list == 0 then
		UI.raidIcon(empty.icon, ns.cfg(listId).icon or 8)
		if filter ~= "" then
			empty.title:SetText("Sin resultados")
			empty.hint:SetText(("Nadie en %s coincide con «%s»."):format(ns.LISTS[listId].label, filter))
		else
			empty.title:SetText("Todavía no hay nadie aquí")
			empty.hint:SetText("Selecciona a un jugador y pulsa «Añadir objetivo», haz clic derecho en su retrato o en su nombre del chat, o usa «Añadir por nombre».")
		end
	end
end

function Page.list() return listId end

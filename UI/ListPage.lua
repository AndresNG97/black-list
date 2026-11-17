-- Página de una lista: buscador, orden, botones de añadir y filas con desplazamiento suave.

local _, ns = ...
local UI = ns.UI
local C = UI.C
local L = ns.L

local Page = {}
UI.ListPage = Page

local listId, filter = "pvp", ""
local ROW_H = 58
local NAME_MAX = 280 -- ancho máximo del nombre; lo que sobre se recorta con "..."

local SORTS = {
	{ value = "seen", text = L["Recently seen"] },
	{ value = "added", text = L["Recently added"] },
	{ value = "kills", text = L["Most kills"] },
	{ value = "name", text = L["Name (A-Z)"] },
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
	UI.confirm(L["Remove from list"], L["Remove %s from %s?"]:format(ns.coloredName(data.e), ns.listTag(data.list)), L["Remove"],
		function() ns.remove(data.list, data.k) end)
end

local function rowMenu(row)
	local data = row.data
	if not (data and MenuUtil and MenuUtil.CreateContextMenu) then return end
	MenuUtil.CreateContextMenu(row, function(_, root)
		root:CreateTitle(ns.fullName(data.e))
		root:CreateButton(L["Edit reasons and note"], function() ns.openEditor({ mode = "edit", list = data.list, key = data.k }) end)
		local to = other(data.list)
		if not ns.entry(to, data.k) then
			root:CreateButton(L["Move to %s"]:format(ns.LISTS[to].label), function() ns.move(data.list, to, data.k) end)
		end
		root:CreateDivider()
		root:CreateButton("|cffe5484d" .. L["Remove from list"] .. "|r", function() confirmRemove(data) end)
	end)
end

local function rowTooltip(row)
	local e = row.data and row.data.e
	if not e then return end
	local m = C.muted
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(ns.coloredName(e))
	local reason = ns.reasonText(e)
	if reason ~= "" then GameTooltip:AddLine(reason, 1, 1, 1, true) end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["Added"], date(L["%b %d, %Y"], e.added or time()), m[1], m[2], m[3], 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Seen"], ns.ago(e.lastSeen) .. (e.lastZone and (" · " .. e.lastZone) or ""), m[1], m[2], m[3], 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Times seen"], tostring(e.seen or 0), m[1], m[2], m[3], 1, 1, 1)
	if (e.kills or 0) > 0 then
		GameTooltip:AddDoubleLine(L["Killed you"], L["%d (last %s)"]:format(e.kills, ns.ago(e.lastKill)), m[1], m[2], m[3], 1, 0.35, 0.35)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Click: edit · Right-click: more options"], 0.5, 0.75, 1)
	GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Filas
---------------------------------------------------------------------------
local function setHover(row, on)
	UI.setColors(row, on and C.hover or C.panel)
	row.del:SetShown(on)
end

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

	-- Derecha: cuándo se le vio y muertes (anchos fijos para que no bailen)
	row.seen = UI.text(row, 12, C.faint)
	row.seen:SetPoint("TOPRIGHT", -44, -12)
	row.seen:SetWidth(120)
	row.seen:SetJustifyH("RIGHT")
	row.kills = UI.text(row, 13, { 1, 0.42, 0.42, 1 })
	row.kills:SetPoint("BOTTOMRIGHT", -44, 11)
	row.kills:SetWidth(120)
	row.kills:SetJustifyH("RIGHT")

	-- Izquierda: nombre, datos y motivos; nunca se meten bajo la columna derecha
	row.name = UI.text(row, 15, nil, true)
	row.name:SetPoint("TOPLEFT", 60, -11)
	row.meta = UI.text(row, 12, C.muted)
	row.meta:SetPoint("LEFT", row.name, "RIGHT", 10, -1)
	row.meta:SetPoint("RIGHT", row.seen, "LEFT", -10, 0)
	row.reason = UI.text(row, 13, C.muted)
	row.reason:SetPoint("BOTTOMLEFT", 60, 11)
	row.reason:SetPoint("RIGHT", row.kills, "LEFT", -10, 0)

	row.del = UI.CloseButton(row, 24, L["Remove from list"], function() confirmRemove(row.data) end, C.accentHi)
	row.del:SetPoint("RIGHT", -10, 0)
	row.del:Hide()
	row.onChildLeave = function(self)
		if not self:IsMouseOver() then setHover(self, false) end
	end

	row:SetScript("OnEnter", function(self)
		setHover(self, true)
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
	row.name:SetWidth(math.min(math.ceil(UI.textWidth(row.name)) + 2, NAME_MAX))

	local meta = {}
	if e.level then meta[#meta + 1] = L["Lv %d"]:format(e.level) end
	if e.race then meta[#meta + 1] = e.race end
	if e.faction then meta[#meta + 1] = ns.factionText(e.faction) end
	row.meta:SetText(table.concat(meta, " · "))

	local parts = {}
	local tags = ns.tagNames(e)
	if #tags > 0 then parts[#parts + 1] = ("|cff%s%s|r"):format(hex, table.concat(tags, " · ")) end
	if e.reason and e.reason ~= "" then parts[#parts + 1] = e.reason end
	row.reason:SetText(#parts > 0 and table.concat(parts, "   ")
		or ("|cff%s%s|r"):format(UI.HEX.faint, L["No reason: click to add one"]))

	row.seen:SetText(e.lastSeen and L["seen %s"]:format(ns.ago(e.lastSeen)) or L["not seen yet"])
	row.kills:SetText((e.kills or 0) > 0 and (ns.icon(8, 13) .. " " .. e.kills) or "")
	setHover(row, row:IsMouseOver())
end

---------------------------------------------------------------------------
-- Página
---------------------------------------------------------------------------
local function updateAddTarget()
	if not Page.addTarget then return end
	local ok = ns.targetIsAddable()
	Page.addTarget:SetEnabled(ok)
	Page.addTarget.tip = ok and L["Adds the player you have targeted."]
		or L["Target a player (other than yourself) to add them."]
end

function Page.build(parent)
	Page.search = UI.Input(parent, 240, 30, L["Search by name or reason..."], true)
	Page.search:SetPoint("TOPLEFT", 16, -14)
	Page.search:HookScript("OnTextChanged", function(self)
		filter = self:GetText() or ""
		Page.refresh()
	end)

	Page.sort = UI.Dropdown(parent, nil, SORTS, function() return ns.settings.sort end,
		function(v) ns.settings.sort = v; Page.refresh() end, 170, 170)
	Page.sort:SetPoint("LEFT", Page.search, "RIGHT", 8, 0)
	Page.sort.tipTitle = L["Sort"]
	Page.sort.tip = L["Changes the list order."]

	Page.addTarget = UI.Button(parent, L["+ Add target"], "primary", nil, 30, function() ns.addTarget(listId) end)
	Page.addTarget:SetPoint("TOPRIGHT", -16, -14)
	Page.addName = UI.Button(parent, L["Add by name"], "secondary", nil, 30,
		function() ns.openEditor({ mode = "add", list = listId }) end)
	Page.addName:SetPoint("RIGHT", Page.addTarget, "LEFT", -8, 0)
	Page.addName.tip = L["Type the name of someone who isn't in front of you."]

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
	empty:SetSize(420, 150)
	empty:SetPoint("CENTER", box, "CENTER", 0, 20)
	empty.icon = empty:CreateTexture(nil, "ARTWORK")
	empty.icon:SetSize(56, 56)
	empty.icon:SetPoint("TOP")
	empty.icon:SetAlpha(0.3)
	empty.title = UI.text(empty, 16, C.text, true)
	empty.title:SetPoint("TOP", empty.icon, "BOTTOM", 0, -12)
	empty.hint = UI.text(empty, 13, C.muted)
	empty.hint:SetPoint("TOP", empty.title, "BOTTOM", 0, -8)
	empty.hint:SetWidth(420)
	empty.hint:SetWordWrap(true)
	empty.hint:SetJustifyH("CENTER")
	Page.empty = empty

	parent:HookScript("OnShow", updateAddTarget)
	updateAddTarget()
end

function Page.refresh(id)
	if not Page.box then return end
	local switched = id and id ~= listId
	if id then listId = id end
	local list = entries()
	local dp = CreateDataProvider()
	for _, it in ipairs(list) do dp:Insert(it) end
	-- Al cambiar de lista se empieza arriba; si no, se conserva el desplazamiento
	local retain = not switched and ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition or nil
	Page.box:SetDataProvider(dp, retain)
	Page.sort.refresh()
	updateAddTarget()

	local empty = Page.empty
	empty:SetShown(#list == 0)
	if #list == 0 then
		UI.raidIcon(empty.icon, ns.cfg(listId).icon or 8)
		if filter ~= "" then
			empty.title:SetText(L["No results"])
			empty.hint:SetText(L["Nobody in %s matches \"%s\"."]:format(ns.LISTS[listId].label, filter))
		else
			empty.title:SetText(L["Nobody here yet"])
			empty.hint:SetText(L["Target a player and click \"Add target\", right-click their portrait or their name in chat, or use \"Add by name\"."])
		end
	end
end

ns.onLoad(function()
	ns.on("PLAYER_TARGET_CHANGED", updateAddTarget)
end)

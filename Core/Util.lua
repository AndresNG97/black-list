-- Utilidades compartidas: mensajes, lecturas seguras, eventos del juego, avisos internos y arranque.
-- WoW Forever usa el motor de Midnight: algunas lecturas pueden devolver valores "secretos"
-- (identidad oculta en instancias, BG o arenas). Todo lo que lee una unidad pasa por safe/plain.

local ADDON, ns = ...
ns.ADDON = ADDON
ns.UI = {}

---------------------------------------------------------------------------
-- Mensajes en el chat: siempre con el prefijo del add-on y sin repetir el mismo
-- mensaje varias veces seguidas
---------------------------------------------------------------------------
local REPEAT_GAP = 3 -- segundos
local lastText, lastTime = nil, 0

function ns.say(fmt, ...)
	local text = select("#", ...) > 0 and string.format(fmt, ...) or fmt
	local now = GetTime()
	if text == lastText and now - lastTime < REPEAT_GAP then return end
	lastText, lastTime = text, now
	print("|cffe5484d" .. ns.L["Blacklist"] .. "|r: " .. text)
end

---------------------------------------------------------------------------
-- Lecturas seguras
---------------------------------------------------------------------------
function ns.isSecret(v) return issecretvalue ~= nil and issecretvalue(v) or false end

function ns.safe(fn, ...)
	if type(fn) ~= "function" then return false end
	return pcall(fn, ...)
end

-- plain(safe(fn, ...)): el valor si la lectura funcionó y no es secreto; si no, nil
function ns.plain(ok, v)
	if ok and not ns.isSecret(v) then return v end
end

-- Llama a fn sin que un error corte a los demás (el error se muestra igualmente)
local call = securecallfunction or function(fn, ...) return fn(...) end
ns.call = call

---------------------------------------------------------------------------
-- Eventos del juego: un único marco, varios módulos por evento
---------------------------------------------------------------------------
local bus = CreateFrame("Frame")
local gameHandlers = {}

function ns.on(event, fn)
	local list = gameHandlers[event]
	if not list then
		if not pcall(bus.RegisterEvent, bus, event) then
			ns.say(ns.L["The event %s doesn't exist in this client; that feature is turned off."], event)
			return
		end
		list = {}
		gameHandlers[event] = list
	end
	list[#list + 1] = fn
end

bus:SetScript("OnEvent", function(_, event, ...)
	local list = gameHandlers[event]
	if not list then return end
	for i = 1, #list do call(list[i], ...) end
end)

---------------------------------------------------------------------------
-- Avisos internos entre módulos
--   LISTS_CHANGED      se añadió, editó o quitó a alguien
--   SETTINGS_CHANGED   cambió un ajuste
--   SIGHTING           se ha visto a alguien de las listas (cambian "visto", nivel...)
---------------------------------------------------------------------------
local listeners = {}

function ns.listen(name, fn)
	listeners[name] = listeners[name] or {}
	table.insert(listeners[name], fn)
end

function ns.fire(name, ...)
	local list = listeners[name]
	if not list then return end
	for i = 1, #list do call(list[i], ...) end
end

---------------------------------------------------------------------------
-- Arranque: cada módulo registra su inicio con ns.onLoad (en el orden del .toc)
---------------------------------------------------------------------------
local inits = {}
function ns.onLoad(fn) inits[#inits + 1] = fn end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON then return end
	self:UnregisterEvent("ADDON_LOADED")
	for i = 1, #inits do call(inits[i]) end
end)

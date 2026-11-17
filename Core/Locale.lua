-- Textos: todo lo que se muestra pasa por L["..."].
-- La clave es el propio texto en español; si falta una traducción se muestra la clave.
-- Para traducir, añade un bloque por idioma con las claves que quieras cambiar, por ejemplo:
--
--   if GetLocale() == "enUS" then
--       L["Mundo abierto"] = "Open world"
--       L["%s está cerca"] = "%s is nearby"
--   end

local _, ns = ...

local L = setmetatable({}, {
	__index = function(t, k)
		t[k] = k
		return k
	end,
})
ns.L = L

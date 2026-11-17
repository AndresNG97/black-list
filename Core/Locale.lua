-- Texts: everything shown on screen goes through L["..."].
-- The key is the English text itself; a missing translation shows the English key.
-- Translations live in Locales\<locale>.lua and only fill the keys they change.

local _, ns = ...

local L = setmetatable({}, {
	__index = function(t, k)
		t[k] = k
		return k
	end,
})
ns.L = L

local locale = GetLocale and GetLocale() or "enUS"
ns.SPANISH = locale == "esES" or locale == "esMX"

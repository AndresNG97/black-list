-- DOMAIN · Who killed me? Pure Lua.
-- WoW Forever doesn't let add-ons read the combat log, so the killer is guessed:
-- the enemy player who had you targeted in the last seconds before you died.
-- strong = had you targeted; your own enemy target counts as a weak suspect.

local _, ns = ...
ns.Domain = ns.Domain or {}
local KillerGuess = {}
KillerGuess.__index = KillerGuess
ns.Domain.KillerGuess = KillerGuess

KillerGuess.WINDOW = 20 -- seconds

function KillerGuess.new() return setmetatable({ suspects = {} }, KillerGuess) end

-- key: the person's key; who: { name, realm, info } (kept from the first time they're noted)
function KillerGuess:note(key, who, strong, now)
	local s = self.suspects[key]
	if s then
		-- Don't downgrade to "weak" someone who had you targeted recently
		if s.strong and not strong and now - s.t < KillerGuess.WINDOW then return end
		s.t, s.strong = now, strong
		return
	end
	self.suspects[key] = { name = who.name, realm = who.realm, info = who.info, t = now, strong = strong }
end

-- The best suspect: strong beats weak, then the most recent. Drops anyone older than the window.
function KillerGuess:pick(now)
	local best
	for k, s in pairs(self.suspects) do
		if now - s.t > KillerGuess.WINDOW then
			self.suspects[k] = nil
		elseif not best or (s.strong and not best.strong) or (s.strong == best.strong and s.t > best.t) then
			best = s
		end
	end
	return best
end

function KillerGuess:clear()
	for k in pairs(self.suspects) do self.suspects[k] = nil end
end

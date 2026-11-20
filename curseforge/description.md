# Player Blacklist

**Never get ganked by the same player twice. Never group with that ninja again.**

Player Blacklist keeps two blacklists of players and warns you the moment you run into them.

### Open world (PvP)

The people who camp your corpse, gank lowbies or jump you while you quest. When one of them shows up nearby:

- a **skull** appears over their head (on their nameplate),
- an **alert** pops up in the middle of your screen with your reasons and how many times they've killed you,
- a sound plays and a line goes to your chat.

When you die, Player Blacklist offers to add the enemy player who seems to have killed you, and keeps count of every kill.

### Dungeons / Raids

Ninjas, toxic players, leavers, people who don't do their role... You get warned when **you invite** one of them, when one of them **invites you**, and when you **join a group** they're in, before you waste an hour with them.

## Features

- **Preset reasons** for each list (Ninja, Needs on everything, Leaves the group, Camps your corpse, Kills low levels...) plus a free-text note.
- **Alerts set up per list:** when (nearby, in your group, invites either way), how (on-screen alert, chat, nameplate icon), icon, sound, color, duration and cooldown.
- **History** with two separate lists: who killed you and who you grouped with, even if they aren't on a list. Click anyone there to blacklist them.
- **On-screen alert** you can move and resize.
- **Right-click** on unit portraits and chat names to add, edit or remove someone.
- **Tooltip** shows the list and reasons when you mouse over a listed player.
- **Minimap icon** and an entry in **Options → AddOns**.
- Search, sort and move entries between lists.
- **English and Spanish** — follows your game client's language.

## Commands

| Command | What it does |
|---|---|
| `/ln` | Open or close the window |
| `/ln alerts` | Alert settings |
| `/ln history` | Who killed you and who you grouped with |
| `/ln pvp` · `/ln group` | Add your target to that list |
| `/ln group Name toxic ninja note` | Add by name with reasons and a note |
| `/ln remove Name` | Remove from your lists |
| `/ln search Name` | Check if someone is on your lists |
| `/ln check` | See who in your group is on your lists |
| `/ln nameplates` | Turn on enemy nameplates so nearby players are detected |
| `/ln test` | Show a sample alert |
| `/ln help` | Every command |

`/blacklist` and `/listanegra` work too.

## Good to know (WoW: Forever)

WoW: Forever runs on the Midnight engine, which limits what add-ons can do:

- **There's no combat log for add-ons.** "Who killed you" is worked out from the enemy player who had you targeted in the last few seconds, so Player Blacklist always asks before adding them.
- **Inside instances, battlegrounds and arenas** the game can hide player identities, so listed players aren't recognized there.
- **Nearby detection uses nameplates (about 40 yards).** WoW Forever doesn't let add-ons read the combat log, so turn on enemy nameplates and **Always show nameplates**, or type `/ln nameplates`. Without them, players are only detected when you target, focus or mouse over them.
- **No raid markers:** WoW Forever doesn't let add-ons set them, so Player Blacklist draws its own icon on the nameplate instead.

Everything stays on your computer: your lists are saved per account in your SavedVariables and are never shared.

## Feedback

Bugs and ideas: [GitHub issues](https://github.com/AndresNG97/black-list/issues).

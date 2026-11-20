# Player Blacklist

An add-on for **World of Warcraft: Forever** that keeps blacklists of players and warns you when you run into them.

*[Leer en español](README.es.md)*

- **Open world (PvP):** the people who camp you, gank you or jump you while you quest. When one of them is nearby, it puts a skull over their head and shows an alert with your reasons and how many times they've killed you.
- **Dungeons / Raids:** ninjas, toxic players, leavers... It warns you when you invite one of them, when one of them invites you, and when you join a group they're in.

## Features

- Two lists with **preset reasons** (Ninja, Needs on everything, Leaves the group, Camps your corpse, Kills low levels...) plus a free-text note.
- **Alerts you set up per list:** when to alert (when nearby; for Dungeons / Raids also when they're in your group and on invites, yours or theirs), how (on-screen alert, chat, nameplate icon), icon, sound, color, duration and how often it repeats.
- **On-screen alert** you can move and resize.
- **When you die**, it offers to add the enemy player who seems to have killed you, and counts the kills.
- **History** with two separate lists: who killed you and who you grouped with, whether they're on a list or not. Click someone to add them to a list.
- **Right-click** on portraits and chat names to add, edit or remove.
- **Tooltip** shows the list and the reasons when you mouse over someone listed.
- **Minimap icon** (click: lists · right-click: alerts · drag: move).
- **English and Spanish.** The language follows your game client.

## Installation

**From CurseForge:** install it with the CurseForge app, or download the file and follow step 3.

**From GitHub:**

1. Download the repository (**Code → Download ZIP**) and unzip it.
2. **Rename the folder to `ListaNegra`** (the add-on keeps this folder name). The game only loads the add-on if the folder has the same name as `ListaNegra.toc`. A GitHub download is called `black-list` or `black-list-main`.
3. Move it to `World of Warcraft\_forever_\Interface\AddOns\`.
4. Restart the game and enable **Player Blacklist** in the AddOns list on the character screen.

## Commands

`/ln`, `/blacklist` and `/listanegra` all work.

| Command | What it does |
|---|---|
| `/ln` | Opens or closes the window |
| `/ln alerts` | Alert settings |
| `/ln history` | Who killed you and who you grouped with |
| `/ln pvp` · `/ln group` | Adds your target to that list |
| `/ln group Name toxic ninja free note` | Adds by name with reasons and a note |
| `/ln group * ninja` | Same, with your target |
| `/ln reasons` | Keywords for the reasons |
| `/ln remove [pvp or group] Name` | Removes from one list (or both) |
| `/ln search Name` | Tells you if someone is on your lists |
| `/ln check` | Shows who in your group is on your lists |
| `/ln nameplates` | Turns on enemy nameplates (always shown) so nearby players are detected |
| `/ln minimap` | Shows or hides the minimap icon |
| `/ln test [pvp or group]` | Shows a sample alert |
| `/ln reset` | Re-centers the windows and the alert |
| `/ln help` | Lists every command |

The Spanish commands (`avisos`, `motivos`, `quitar`, `buscar`, `minimapa`, `prueba`, `ayuda`) also work in any language.

It also shows up in **Options → AddOns → Blacklist**, with shortcuts to the lists and the settings.

## WoW: Forever limitations

WoW: Forever runs on the Midnight engine, which restricts add-ons:

- **The combat log isn't available.** "Who killed you" is worked out from the enemy player who had you targeted in the last few seconds, so it asks before adding them.
- **In instances, battlegrounds and arenas** the game can hide players' identities. They aren't recognized there.
- **Nearby detection uses nameplates (about 40 yards):** WoW Forever doesn't let add-ons read the combat log, so turn on enemy nameplates and **Always show nameplates**, or just type `/ln nameplates`. Without them, people are only detected when you target, focus or mouse over them.
- **No raid markers:** the game no longer lets add-ons set them (it shows a "blocked action" popup), so Player Blacklist only draws its own icon on the nameplate.

## Translating

Every on-screen text goes through `L["..."]`, and the key is the English text. To add a language, copy `Locales/esES.lua`, change the locale check at the top and translate the right-hand side. Add the file to `ListaNegra.toc` right after `Locales\esES.lua`.

## Code layout

Hexagonal architecture (ports and adapters). The rules don't know about WoW; the game is plugged in from the outside.

```
                 driving adapters                         driven adapters
  game events, invite hooks ─┐                      ┌─ clock, store, player   (Adapters/Game)
  /ln commands               ├─► Application (App) ─┤  units, party           (Adapters/Units)
  windows, menus, tooltip    ┘     uses Domain      ├─ plates                 (Adapters/Nameplates)
                                                    ├─ alerts                 (Adapters/Alerts → UI/Banner)
                                                    ├─ notices                (Adapters/Notices)
                                                    ├─ prompt                 (UI/Editor)
                                                    └─ events                 (Adapters/Runtime → UI)
```

```
Domain/        the rules, pure Lua: no WoW API (checked automatically)
  Names          keys, realms, "Name-Realm"
  Catalog        lists, preset reasons, option keys
  Entry          create, edit, merge, kills, sightings
  Blacklist      the two lists: find, add, remove, move, GUID index, key migration
  AlertPolicy    which list alerts, cooldowns, nameplate icon
  KillerGuess    who killed you (suspects in the last 20 seconds)
  History        who killed you and who you grouped with: counts, dates, oldest dropped
  Settings       defaults and migrations of the saved data
Application/   use cases
  Ports          what the application needs from outside (clock, store, units, alerts...)
  App            every use case: add, remove, seen nearby, group, invites, death, history, /ln check...
Adapters/      the ports on the WoW API, and what calls the use cases
  Runtime        chat, safe reads, game events, internal events, startup
  Text           texts and formatting for chat and windows
  Game           clock, saved variables, your character
  Units          unit identity (with the game's secret values), group members
  Nameplates     icon above the nameplate, nameplate settings
  Alerts         sound, on-screen alert and chat
  Notices        chat feedback
  GameEvents     game events and invite hooks → use cases
  Slash          /ln commands → use cases
Locales/       L[] table and translations (esES: Spanish for Spain and Latin America)
UI/            windows, alert, menus and tooltip (they call ns.app)
Main.lua       composition root: plugs the adapters into the ports and creates ns.app
```

To change a rule, edit `Domain/` or `Application/` and test it without the game, with fake ports. To support another client or API change, edit only the adapter involved.

## License

[MIT](LICENSE)

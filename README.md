# Player Blacklist

An add-on for **World of Warcraft: Forever** that keeps blacklists of players and warns you when you run into them.

*[Leer en español](README.es.md)*

- **Open world (PvP):** the people who camp you, gank you or jump you while you quest. When one of them is nearby, it puts a skull over their head and shows an alert with your reasons and how many times they've killed you.
- **Dungeons / Raids:** ninjas, toxic players, leavers... It warns you when you invite one of them, when one of them invites you, and when you join a group they're in.

## Features

- Two lists with **preset reasons** (Ninja, Needs on everything, Leaves the group, Camps your corpse, Kills low levels...) plus a free-text note.
- **Alerts you set up per list:** when to alert (when nearby; for Dungeons / Raids also when they're in your group and on invites, yours or theirs), how (on-screen alert, chat, nameplate icon, raid marker), icon, sound, color, duration and how often it repeats.
- **On-screen alert** you can move and resize.
- **When you die**, it offers to add the enemy player who seems to have killed you, and counts the kills.
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
| `/ln pvp` · `/ln group` | Adds your target to that list |
| `/ln group Name toxic ninja free note` | Adds by name with reasons and a note |
| `/ln group * ninja` | Same, with your target |
| `/ln reasons` | Keywords for the reasons |
| `/ln remove [pvp or group] Name` | Removes from one list (or both) |
| `/ln search Name` | Tells you if someone is on your lists |
| `/ln check` | Shows who in your group is on your lists |
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
- **Nearby detection uses nameplates:** turn on enemy nameplates (V key). Without them, people are only detected when you target them or mouse over them.
- If the game doesn't allow **raid markers**, the add-on turns them off by itself and keeps using its own nameplate icon.

## Translating

Every on-screen text goes through `L["..."]`, and the key is the English text. To add a language, copy `Locales/esES.lua`, change the locale check at the top and translate the right-hand side. Add the file to `ListaNegra.toc` right after `Locales\esES.lua`.

## Code layout

```
Core/        data and logic, no UI
  Util         chat messages, safe reads, events, internal signals and startup
  Locale       L[] table with every text
  Data         lists, reasons, icons, sounds and colors
  Settings     saved data, defaults and migrations
  Names        names, realms and unit identity
  Store        add, remove, find and record when someone is seen
  Format       text for chat and windows
Locales/     translations (esES: Spanish for Spain and Latin America)
Detection/   what happens in the game
  Notify       sound, on-screen alert, chat and alert cooldown
  Plates       nameplate icon and raid marker
  Nearby       people nearby (nameplates, target, mouseover)
  Group        group and invites
  Killer       who killed you
UI/          interface
  Theme        colors, fonts and flat backgrounds
  Widgets      window, buttons, toggles, dropdowns, inputs, tabs, chips
  Banner       on-screen alert
  Editor       add / edit window
  ListPage     page for each list
  SettingsPage settings page
  MainWindow   main window and tabs
  Options      entry in Options → AddOns
  UnitMenu     right-click on portraits and chat
  Tooltip      lines in the player tooltip
  Minimap      minimap button
Slash.lua    /ln commands
```

Modules talk to each other through internal signals (`LISTS_CHANGED`, `SETTINGS_CHANGED`, `SIGHTING`) instead of calling each other directly.

## License

[MIT](LICENSE)

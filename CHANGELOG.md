# Changelog

## 1.0.3

- **Fixed the "blocked action" popup on every alert.** WoW Forever (Midnight engine) no longer lets add-ons set raid markers, so the raid marker option is gone. The icon above the nameplate still works.
- **Open world: better nearby detection.** Players on the list are also detected when you focus them, and a nameplate that shows up before the player's name has loaded is checked again a moment later.
- New `/ln nameplates`: turns on enemy nameplates and Always show nameplates, which nearby detection needs (about 40 yards). If they're off, the add-on tells you once when you log in.
- Internal: the code is reorganized as a hexagonal architecture (Domain, Application, Adapters). Nothing changes in game, and your lists and settings are kept.

## 1.0.2

- **Dungeons / Raids: alert when you invite someone on the list.** Before, only invites you received alerted.
- When you join a group, everyone in it who is on the list alerts as soon as you're in (the game doesn't show a group's members before you accept).
- The "When they invite you" option is now **Invites** and covers both directions.
- New `/ln check`: shows what the add-on reads from each group member and whether they're on your lists.

## 1.0.1

- The add-on is now called **Player Blacklist** (it was ListaNegra). Your lists and settings are kept.
- Code comments in English.

## 1.0.0

First public release.

- **English by default.** Spanish clients (esES, esMX) get the Spanish translation automatically.
- English commands: `/ln alerts`, `/ln reasons`, `/ln remove`, `/ln search`, `/ln minimap`, `/ln test`, `/ln help`. The Spanish ones keep working.
- New `/blacklist` command (same as `/ln`).
- Reasons can be typed with English keywords too (`toxic`, `leaver`, `camper`...). `/ln reasons` lists them.
- The Open world list no longer alerts on group or invites: in the open world they're enemies. Only Dungeons / Raids alerts for those.

## 0.4.0

- Full UI/UX review: modern windows (scroll lists, menus, dropdowns), clearer settings, a movable and resizable alert, a minimap icon and an Options → AddOns entry.
- Alerts set up per list: when, how, icon, sound, color, duration and cooldown.
- Preset reasons for both lists.
- Fixes for raid markers in combat, accented names and duplicate alerts.

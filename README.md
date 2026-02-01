# ActionTracker

Comprehensive statistics tracker for World of Warcraft TBC Classic. Passively tracks your gameplay statistics including abilities used, damage dealt, kills, deaths, and more.

## Features

- **Combat Statistics**: Track ability usage, damage done, healing done, damage taken, kills, and deaths
- **Economy Statistics**: Track gold earned/spent, items looted, quests completed (basic in v1.0)
- **Lifestyle Statistics**: Planned for future updates
- **Per-Character & Account-Wide**: Statistics tracked both per-character and aggregated across your account
- **Tabbed UI**: Clean, organized interface with tabs for each category
- **Minimap Button**: Quick access to statistics window
- **Export**: Copy statistics to clipboard for sharing
- **Selective Reset**: Reset individual categories or all statistics

## Usage

### Slash Commands

- `/at` or `/actiontracker` - Toggle statistics window
- `/at config` - Open options panel
- `/at summary` - Print summary to chat
- `/at export` - Export statistics to clipboard
- `/at reset combat` - Reset combat statistics
- `/at reset economy` - Reset economy statistics
- `/at reset lifestyle` - Reset lifestyle statistics
- `/at reset all` - Reset all statistics

### Keybinding

Set a keybind in Options → Key Bindings → AddOns → ActionTracker

### Macro

```
/run ActionTracker:Toggle()
```

## Installation

1. Download the addon
2. Extract to `Interface/AddOns/ActionTracker`
3. Ensure Ace3 addon is installed (or libraries are included)
4. Restart WoW or `/reload`

## Requirements

- World of Warcraft TBC Classic (Interface 20504)
- Ace3 libraries (included via CurseForge packaging or OptionalDeps)

## License

MIT License

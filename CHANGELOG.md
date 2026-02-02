# Changelog

## [1.1.2] - 2026-02-02

### Fixed
- Fixed embeds.xml to properly load bundled libraries (matching other addons)
- Local dev: symlink libs/ folder or download libs manually (gitignored)

## [1.1.1] - 2026-02-02

### Fixed
- Fixed embeds.xml errors when libs folder doesn't exist locally
- Now relies on Ace3 addon being installed (OptionalDeps)
- Minimap button is optional (works if LibDataBroker/LibDBIcon available)

## [1.1.0] - 2026-02-02

### Added
- XP tracking from kills (displayed in Combat tab)
- XP tracking from quests (displayed in Economy tab)
- Detailed gold source tracking:
  - Gold from vendors (selling items)
  - Gold from mail
  - Gold from loot
  - Gold from quests
- Improved Economy tab with organized sections

### Fixed
- Fixed `InterfaceOptionsFrame_OpenToCategory` error (API compatibility)
- Fixed Bindings.xml category attribute warning
- Main window content is now scrollable (fixes overflow with Kills by Mob section)
- Limited Top Abilities and Kills by Mob to top 15 entries for cleaner display

## [1.0.1] - 2026-02-02

### Fixed
- Main window content is now scrollable (fixes overflow with Kills by Mob section)
- Limited Top Abilities and Kills by Mob to top 15 entries for cleaner display

## [1.0.0] - 2026-02-02

### Added
- Initial release
- Combat statistics tracking (abilities, damage, healing, kills, deaths)
- Basic economy tracking (gold, items looted, quests)
- Tabbed UI interface
- Minimap button with tooltip summary
- Export statistics to clipboard
- Selective reset per category
- Per-character and account-wide statistics
- Keybinding support

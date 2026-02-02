-- Luacheck configuration for WoW TBC Classic addon
std = "lua51"
codes = true
quiet = 1
max_line_length = false

exclude_files = {
    ".release/",
    "libs/",
    "Libs/",
}

-- Ignore common WoW addon patterns
ignore = {
    "211/_.*",      -- Unused variables starting with _
    "211/addonName", -- Common unused addon name
    "212/self",     -- Unused self in methods
    "212/event",    -- Unused event argument
    "212/msg",      -- Unused msg argument
    "212/questId",  -- Unused questId
    "212/mobGUID",  -- Unused mobGUID
    "213",          -- Unused loop variables
    "311",          -- Value assigned to variable is unused
    "631",          -- Line too long (disabled via max_line_length)
}

-- Globals we define
globals = {
    "_G",
    "ActionTracker",
    "BINDING_HEADER_ACTIONTRACKER",
    "BINDING_NAME_ACTIONTRACKER_TOGGLE",
}

-- WoW API globals (read-only)
read_globals = {
    -- Lua
    "date",
    "format",
    "pairs",
    "ipairs",
    "next",
    "select",
    "string",
    "table",
    "math",
    "tonumber",
    "tostring",
    "type",
    "unpack",

    -- Libraries
    "LibStub",

    -- WoW API
    "CreateFrame",
    "GetMoney",
    "GetCoinTextureString",
    "GetRealmName",
    "GetTime",
    "UnitGUID",
    "UnitName",
    "UnitXP",
    "UnitXPMax",
    "UnitLevel",
    "CombatLogGetCurrentEventInfo",
    "GetAddOnMetadata",
    "InterfaceOptionsFrame_OpenToCategory",
    "C_Timer",

    -- Frames
    "UIParent",
    "GameTooltip",
    "Settings",

    -- Constants
    "RAID_CLASS_COLORS",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
}

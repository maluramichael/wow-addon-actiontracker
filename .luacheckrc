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

-- Globals we define
globals = {
    "ActionTracker",
    "BINDING_HEADER_ACTIONTRACKER",
    "BINDING_NAME_ACTIONTRACKER_TOGGLE",
}

-- WoW API globals (read-only)
read_globals = {
    -- Lua
    "_G",
    "date",
    "format",
    "pairs",
    "ipairs",
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

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
    "21.",          -- All unused variable warnings (W211, W212, W213)
    "231",          -- Variable never accessed
    "311",          -- Value assigned to variable is unused
    "631",          -- Line too long
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

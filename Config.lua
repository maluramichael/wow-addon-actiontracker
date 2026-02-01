local addonName, addon = ...
local ActionTracker = addon

function ActionTracker:GetOptionsTable()
    return {
        type = "group",
        name = "ActionTracker",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                inline = true,
                args = {
                    desc = {
                        type = "description",
                        name = "ActionTracker passively tracks your gameplay statistics including abilities used, damage dealt, kills, and more.\n",
                        order = 1,
                    },
                    showMinimap = {
                        type = "toggle",
                        name = "Show Minimap Button",
                        desc = "Show or hide the minimap button",
                        order = 2,
                        get = function()
                            return not self.db.profile.minimap.hide
                        end,
                        set = function(_, value)
                            self.db.profile.minimap.hide = not value
                            if value then
                                LibStub("LibDBIcon-1.0"):Show("ActionTracker")
                            else
                                LibStub("LibDBIcon-1.0"):Hide("ActionTracker")
                            end
                        end,
                    },
                },
            },
            commands = {
                type = "group",
                name = "Commands",
                order = 2,
                inline = true,
                args = {
                    cmdDesc = {
                        type = "description",
                        name = [[
|cffffd700/at|r - Toggle statistics window
|cffffd700/at config|r - Open this options panel
|cffffd700/at summary|r - Print summary to chat
|cffffd700/at export|r - Export stats to clipboard
|cffffd700/at reset combat|r - Reset combat stats
|cffffd700/at reset economy|r - Reset economy stats
|cffffd700/at reset lifestyle|r - Reset lifestyle stats
|cffffd700/at reset all|r - Reset all statistics
]],
                        order = 1,
                    },
                },
            },
            reset = {
                type = "group",
                name = "Reset Statistics",
                order = 3,
                inline = true,
                args = {
                    resetWarning = {
                        type = "description",
                        name = "|cffff0000Warning:|r Resetting statistics cannot be undone!\n",
                        order = 1,
                    },
                    resetCombat = {
                        type = "execute",
                        name = "Reset Combat",
                        desc = "Reset all combat statistics for this character",
                        order = 2,
                        confirm = true,
                        confirmText = "Are you sure you want to reset combat statistics?",
                        func = function()
                            self:ResetCategory("combat")
                        end,
                    },
                    resetEconomy = {
                        type = "execute",
                        name = "Reset Economy",
                        desc = "Reset all economy statistics for this character",
                        order = 3,
                        confirm = true,
                        confirmText = "Are you sure you want to reset economy statistics?",
                        func = function()
                            self:ResetCategory("economy")
                        end,
                    },
                    resetLifestyle = {
                        type = "execute",
                        name = "Reset Lifestyle",
                        desc = "Reset all lifestyle statistics for this character",
                        order = 4,
                        confirm = true,
                        confirmText = "Are you sure you want to reset lifestyle statistics?",
                        func = function()
                            self:ResetCategory("lifestyle")
                        end,
                    },
                    resetAll = {
                        type = "execute",
                        name = "Reset All",
                        desc = "Reset ALL statistics for this character",
                        order = 5,
                        confirm = true,
                        confirmText = "Are you sure you want to reset ALL statistics? This cannot be undone!",
                        func = function()
                            self:ResetCategory("all")
                        end,
                    },
                },
            },
        },
    }
end

-- Keybinding support
BINDING_HEADER_ACTIONTRACKER = "ActionTracker"
BINDING_NAME_ACTIONTRACKER_TOGGLE = "Toggle Statistics Window"

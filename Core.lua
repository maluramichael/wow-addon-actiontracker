local addonName, addon = ...

local ActionTracker = LibStub("AceAddon-3.0"):NewAddon(addon, addonName,
    "AceEvent-3.0", "AceConsole-3.0")

-- Expose globally for macros
_G["ActionTracker"] = ActionTracker

-- Player info cache
local playerGUID = nil
local playerName = nil
local goldSource = nil -- Track pending gold source
local timePlayedReceived = false -- Suppress default chat output on first request

-- Helper to open options (compatible with different WoW versions)
local function OpenOptions()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("ActionTracker")
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("ActionTracker")
        InterfaceOptionsFrame_OpenToCategory("ActionTracker")
    end
end

function ActionTracker:OnInitialize()
    -- Initialize database with defaults
    self.db = LibStub("AceDB-3.0"):New("ActionTrackerDB", self:GetDefaults(), true)

    -- Register slash commands
    self:RegisterChatCommand("at", "SlashCommand")
    self:RegisterChatCommand("actiontracker", "SlashCommand")

    -- Register options
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self:GetOptionsTable())
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "ActionTracker")

    -- Setup minimap button
    self:SetupMinimapButton()

    -- Cache player info
    playerGUID = UnitGUID("player")
    playerName = UnitName("player")
end

function ActionTracker:OnEnable()
    -- Register combat log event
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    -- XP tracking
    self:RegisterEvent("PLAYER_XP_UPDATE")
    self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")

    -- Gold tracking
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("MAIL_SHOW")
    self:RegisterEvent("MAIL_CLOSED")
    self:RegisterEvent("QUEST_COMPLETE")
    self:RegisterEvent("CHAT_MSG_MONEY")

    -- Other events
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("QUEST_TURNED_IN")
    self:RegisterEvent("PLAYER_DEAD")

    -- Playtime tracking
    self:RegisterEvent("TIME_PLAYED_MSG")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    timePlayedReceived = false
    RequestTimePlayed()

    -- Store character metadata
    self:UpdateCharacterMeta()

    self:Print("ActionTracker enabled. Use /at to open statistics.")
end

function ActionTracker:OnDisable()
    self:UnregisterAllEvents()
end

function ActionTracker:SlashCommand(input)
    local cmd = input and input:trim():lower() or ""

    if cmd == "" or cmd == "show" then
        self:ToggleUI()
    elseif cmd == "config" or cmd == "options" then
        OpenOptions()
    elseif cmd == "reset" then
        self:Print("Use /at reset combat|economy|lifestyle|all")
    elseif cmd:match("^reset%s+(%w+)$") then
        local category = cmd:match("^reset%s+(%w+)$")
        self:ResetCategory(category)
    elseif cmd == "export" then
        self:ExportToClipboard()
    elseif cmd == "summary" then
        self:PrintSummary()
    else
        self:Print("ActionTracker commands:")
        self:Print("  /at - Toggle statistics window")
        self:Print("  /at config - Open options")
        self:Print("  /at summary - Print summary to chat")
        self:Print("  /at export - Copy stats to clipboard")
        self:Print("  /at reset <category> - Reset statistics")
    end
end

function ActionTracker:Toggle()
    self:ToggleUI()
end

-- Combat Log Event Handler
function ActionTracker:COMBAT_LOG_EVENT_UNFILTERED()
    local _, subevent, _, sourceGUID, _, _, _,
          destGUID, destName = CombatLogGetCurrentEventInfo()

    -- Only track player's actions
    if sourceGUID == playerGUID then
        if subevent == "SPELL_CAST_SUCCESS" then
            local spellId, spellName = select(12, CombatLogGetCurrentEventInfo())
            self:TrackAbilityUse(spellId, spellName)

        elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
            local spellId, spellName, _, amount = select(12, CombatLogGetCurrentEventInfo())
            self:TrackDamage(spellId, spellName, amount or 0)

        elseif subevent == "SWING_DAMAGE" then
            local amount = select(12, CombatLogGetCurrentEventInfo())
            self:TrackDamage(0, "Melee", amount or 0)
            self:TrackAbilityUse(0, "Melee")

        elseif subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
            local spellId, spellName, _, amount = select(12, CombatLogGetCurrentEventInfo())
            self:TrackHealing(spellId, spellName, amount or 0)

        elseif subevent == "PARTY_KILL" then
            self:TrackKill(destName, destGUID)
        end
    end

    -- Track damage taken by player
    if destGUID == playerGUID then
        if subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
            local amount = select(15, CombatLogGetCurrentEventInfo())
            self:TrackDamageTaken(amount or 0)
        elseif subevent == "SWING_DAMAGE" then
            local amount = select(12, CombatLogGetCurrentEventInfo())
            self:TrackDamageTaken(amount or 0)
        end
    end
end

function ActionTracker:PLAYER_DEAD()
    self:TrackDeath()
end

-- XP Tracking
function ActionTracker:CHAT_MSG_COMBAT_XP_GAIN(event, msg)
    -- Parse XP from kill message: "Mob Name dies, you gain X experience."
    local xp = msg:match("you gain (%d+) experience")
    if xp then
        self:TrackXPFromKill(tonumber(xp))
    end
end

function ActionTracker:PLAYER_XP_UPDATE()
    -- This fires for all XP gains, we use CHAT_MSG_COMBAT_XP_GAIN for kill XP
    -- Quest XP is tracked in QUEST_TURNED_IN
end

-- Gold source tracking
function ActionTracker:MERCHANT_SHOW()
    goldSource = "vendor"
end

function ActionTracker:MERCHANT_CLOSED()
    goldSource = nil
end

function ActionTracker:MAIL_SHOW()
    goldSource = "mail"
end

function ActionTracker:MAIL_CLOSED()
    goldSource = nil
end

function ActionTracker:QUEST_COMPLETE()
    goldSource = "quest"
end

function ActionTracker:CHAT_MSG_MONEY(event, msg)
    -- Parse gold from loot: "You loot X Gold Y Silver Z Copper"
    local gold = msg:match("(%d+) Gold") or 0
    local silver = msg:match("(%d+) Silver") or 0
    local copper = msg:match("(%d+) Copper") or 0

    local total = (tonumber(gold) or 0) * 10000 + (tonumber(silver) or 0) * 100 + (tonumber(copper) or 0)

    if total > 0 then
        self:TrackGoldFromSource(total, "loot")
    end
end

function ActionTracker:PLAYER_MONEY()
    local currentGold = GetMoney()
    local data = self:GetCharacterData()

    if data.economy.lastKnownGold then
        local diff = currentGold - data.economy.lastKnownGold

        if diff > 0 then
            -- Gold gained
            if goldSource == "vendor" then
                self:TrackGoldFromSource(diff, "vendor")
            elseif goldSource == "mail" then
                self:TrackGoldFromSource(diff, "mail")
            elseif goldSource == "quest" then
                self:TrackGoldFromSource(diff, "quest")
                goldSource = nil -- Reset after quest reward
            else
                -- Unknown source (could be trade, AH, etc.)
                data.economy.goldEarned = (data.economy.goldEarned or 0) + diff
            end
        elseif diff < 0 then
            -- Gold spent
            data.economy.goldSpent = (data.economy.goldSpent or 0) + math.abs(diff)
        end
    end

    data.economy.lastKnownGold = currentGold
end

function ActionTracker:CHAT_MSG_LOOT(event, msg)
    local data = self:GetCharacterData()
    data.economy.itemsLooted = (data.economy.itemsLooted or 0) + 1
end

function ActionTracker:QUEST_TURNED_IN(event, questId, xpReward, moneyReward)
    local data = self:GetCharacterData()
    data.economy.questsCompleted = (data.economy.questsCompleted or 0) + 1

    -- Track XP from quest
    if xpReward and xpReward > 0 then
        self:TrackXPFromQuest(xpReward)
    end

    -- Track gold from quest (moneyReward is in copper)
    if moneyReward and moneyReward > 0 then
        self:TrackGoldFromSource(moneyReward, "quest")
    end
end

-- Playtime tracking
function ActionTracker:TIME_PLAYED_MSG(event, totalTime, levelTime)
    if not totalTime or totalTime <= 0 then return end
    local data = self:GetCharacterData()
    data.lifestyle.timePlayed = totalTime
    if not timePlayedReceived then
        timePlayedReceived = true
    end
end

function ActionTracker:PLAYER_LEVEL_UP()
    self:UpdateCharacterMeta()
end

-- Minimap Button Setup
function ActionTracker:SetupMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)

    if not LDB or not LDBIcon then return end

    local dataObj = LDB:NewDataObject("ActionTracker", {
        type = "launcher",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:ToggleUI()
            elseif button == "RightButton" then
                OpenOptions()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("ActionTracker")
            tooltip:AddLine("|cff00ff00Left-click|r to toggle statistics", 1, 1, 1)
            tooltip:AddLine("|cff00ff00Right-click|r for options", 1, 1, 1)

            local data = self:GetCharacterData()
            if data.combat.totalAbilitiesUsed > 0 then
                tooltip:AddLine(" ")
                tooltip:AddDoubleLine("Abilities Used:", tostring(data.combat.totalAbilitiesUsed), 1, 0.82, 0, 1, 1, 1)
                tooltip:AddDoubleLine("Total Damage:", self:FormatNumber(data.combat.totalDamage), 1, 0.82, 0, 1, 1, 1)
                tooltip:AddDoubleLine("Total Kills:", tostring(data.combat.totalKills), 1, 0.82, 0, 1, 1, 1)
            end
        end,
    })

    if not self.db.profile.minimap then
        self.db.profile.minimap = { hide = false }
    end

    LDBIcon:Register("ActionTracker", dataObj, self.db.profile.minimap)
end

function ActionTracker:PrintSummary()
    local data = self:GetCharacterData()

    self:Print("=== ActionTracker Summary ===")
    self:Print(string.format("Abilities Used: %s", self:FormatNumber(data.combat.totalAbilitiesUsed)))
    self:Print(string.format("Total Damage: %s", self:FormatNumber(data.combat.totalDamage)))
    self:Print(string.format("Total Healing: %s", self:FormatNumber(data.combat.totalHealing)))
    self:Print(string.format("Damage Taken: %s", self:FormatNumber(data.combat.totalDamageTaken)))
    self:Print(string.format("Kills: %d | Deaths: %d", data.combat.totalKills, data.combat.deaths))
    self:Print(string.format("XP from Kills: %s | XP from Quests: %s",
        self:FormatNumber(data.combat.xpFromKills or 0),
        self:FormatNumber(data.economy.xpFromQuests or 0)))

    local sorted = self:GetSortedAbilities(data.combat.abilities, "count")
    if #sorted > 0 then
        self:Print("--- Top Abilities ---")
        for i = 1, math.min(3, #sorted) do
            local ability = sorted[i]
            self:Print(string.format("  %d. %s: %d uses", i, ability.name, ability.count))
        end
    end
end

function ActionTracker:ExportToClipboard()
    local data = self:GetCharacterData()
    local text = self:GenerateExportText(data)

    if not self.exportFrame then
        self.exportFrame = CreateFrame("Frame", "ActionTrackerExportFrame", UIParent, "BasicFrameTemplateWithInset")
        self.exportFrame:SetSize(500, 400)
        self.exportFrame:SetPoint("CENTER")
        self.exportFrame:SetMovable(true)
        self.exportFrame:EnableMouse(true)
        self.exportFrame:RegisterForDrag("LeftButton")
        self.exportFrame:SetScript("OnDragStart", self.exportFrame.StartMoving)
        self.exportFrame:SetScript("OnDragStop", self.exportFrame.StopMovingOrSizing)
        self.exportFrame.title = self.exportFrame:CreateFontString(nil, "OVERLAY")
        self.exportFrame.title:SetFontObject("GameFontHighlight")
        self.exportFrame.title:SetPoint("LEFT", self.exportFrame.TitleBg, "LEFT", 5, 0)
        self.exportFrame.title:SetText("ActionTracker Export - Press Ctrl+C to copy")

        local scrollFrame = CreateFrame("ScrollFrame", nil, self.exportFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetWidth(440)
        editBox:SetAutoFocus(true)
        editBox:SetScript("OnEscapePressed", function() self.exportFrame:Hide() end)
        scrollFrame:SetScrollChild(editBox)

        self.exportFrame.editBox = editBox
    end

    self.exportFrame.editBox:SetText(text)
    self.exportFrame.editBox:HighlightText()
    self.exportFrame:Show()
end

function ActionTracker:GenerateExportText(data)
    local lines = {
        "=== ActionTracker Statistics ===",
        string.format("Character: %s", playerName or "Unknown"),
        string.format("Generated: %s", date("%Y-%m-%d %H:%M:%S")),
        "",
        "--- Combat Summary ---",
        string.format("Total Abilities Used: %s", self:FormatNumber(data.combat.totalAbilitiesUsed)),
        string.format("Total Damage Done: %s", self:FormatNumber(data.combat.totalDamage)),
        string.format("Total Healing Done: %s", self:FormatNumber(data.combat.totalHealing)),
        string.format("Total Damage Taken: %s", self:FormatNumber(data.combat.totalDamageTaken)),
        string.format("Total Kills: %d", data.combat.totalKills),
        string.format("Total Deaths: %d", data.combat.deaths),
        string.format("XP from Kills: %s", self:FormatNumber(data.combat.xpFromKills or 0)),
        "",
        "--- Economy Summary ---",
        string.format("Gold Earned: %s", GetCoinTextureString(data.economy.goldEarned or 0)),
        string.format("  From Vendors: %s", GetCoinTextureString(data.economy.goldFromVendor or 0)),
        string.format("  From Mail: %s", GetCoinTextureString(data.economy.goldFromMail or 0)),
        string.format("  From Loot: %s", GetCoinTextureString(data.economy.goldFromLoot or 0)),
        string.format("  From Quests: %s", GetCoinTextureString(data.economy.goldFromQuest or 0)),
        string.format("Gold Spent: %s", GetCoinTextureString(data.economy.goldSpent or 0)),
        string.format("Quests Completed: %d", data.economy.questsCompleted or 0),
        string.format("XP from Quests: %s", self:FormatNumber(data.economy.xpFromQuests or 0)),
        "",
        "--- Abilities (by usage count) ---",
    }

    local sorted = self:GetSortedAbilities(data.combat.abilities, "count")
    for i, ability in ipairs(sorted) do
        table.insert(lines, string.format("%d. %s: %d uses, %s damage",
            i, ability.name, ability.count, self:FormatNumber(ability.damage)))
    end

    if data.combat.kills and next(data.combat.kills) then
        table.insert(lines, "")
        table.insert(lines, "--- Kills (by mob) ---")
        local killsSorted = {}
        for name, count in pairs(data.combat.kills) do
            table.insert(killsSorted, {name = name, count = count})
        end
        table.sort(killsSorted, function(a, b) return a.count > b.count end)
        for i, kill in ipairs(killsSorted) do
            table.insert(lines, string.format("%d. %s: %d kills", i, kill.name, kill.count))
        end
    end

    return table.concat(lines, "\n")
end

function ActionTracker:FormatNumber(num)
    if not num then return "0" end
    if num >= 1000000000 then
        return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

function ActionTracker:GetSortedAbilities(abilities, sortBy)
    local sorted = {}
    for name, data in pairs(abilities or {}) do
        table.insert(sorted, {
            name = name,
            count = data.count or 0,
            damage = data.damage or 0,
            healing = data.healing or 0,
        })
    end

    if sortBy == "count" then
        table.sort(sorted, function(a, b) return a.count > b.count end)
    elseif sortBy == "damage" then
        table.sort(sorted, function(a, b) return a.damage > b.damage end)
    elseif sortBy == "healing" then
        table.sort(sorted, function(a, b) return a.healing > b.healing end)
    end

    return sorted
end

function ActionTracker:ResetCategory(category)
    local data = self:GetCharacterData()

    if category == "combat" then
        data.combat = self:GetDefaults().profile.characters[""].combat
        self:Print("Combat statistics reset.")
    elseif category == "economy" then
        data.economy = self:GetDefaults().profile.characters[""].economy
        self:Print("Economy statistics reset.")
    elseif category == "lifestyle" then
        data.lifestyle = self:GetDefaults().profile.characters[""].lifestyle
        self:Print("Lifestyle statistics reset.")
    elseif category == "all" then
        local charKey = self:GetCharacterKey()
        self.db.profile.characters[charKey] = nil
        self:Print("All statistics reset.")
    else
        self:Print("Unknown category. Use: combat, economy, lifestyle, or all")
    end
end

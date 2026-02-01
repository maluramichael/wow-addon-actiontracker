local addonName, addon = ...
local ActionTracker = addon

local AceGUI = LibStub("AceGUI-3.0")

local mainFrame = nil
local currentTab = "combat"

function ActionTracker:ToggleUI()
    if mainFrame and mainFrame:IsShown() then
        mainFrame:Hide()
    else
        self:ShowUI()
    end
end

function ActionTracker:ShowUI()
    if mainFrame then
        self:RefreshUI()
        mainFrame:Show()
        return
    end

    -- Create main frame
    mainFrame = AceGUI:Create("Frame")
    mainFrame:SetTitle("ActionTracker Statistics")
    mainFrame:SetStatusText("Tracking your gameplay statistics")
    mainFrame:SetLayout("Fill")
    mainFrame:SetWidth(600)
    mainFrame:SetHeight(500)
    mainFrame:SetCallback("OnClose", function(widget)
        widget:Hide()
    end)

    -- Create tab group
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetTabs({
        {text = "Combat", value = "combat"},
        {text = "Economy", value = "economy"},
        {text = "Lifestyle", value = "lifestyle"},
        {text = "Account", value = "account"},
    })
    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        currentTab = group
        self:RefreshTabContent(container, group)
    end)

    mainFrame:AddChild(tabGroup)

    -- Select combat tab by default
    tabGroup:SelectTab("combat")

    self.tabGroup = tabGroup
end

function ActionTracker:RefreshUI()
    if self.tabGroup then
        self:RefreshTabContent(self.tabGroup, currentTab)
    end
end

function ActionTracker:RefreshTabContent(container, tab)
    container:ReleaseChildren()

    if tab == "combat" then
        self:DrawCombatTab(container)
    elseif tab == "economy" then
        self:DrawEconomyTab(container)
    elseif tab == "lifestyle" then
        self:DrawLifestyleTab(container)
    elseif tab == "account" then
        self:DrawAccountTab(container)
    end
end

function ActionTracker:DrawCombatTab(container)
    local data = self:GetCharacterData()
    local combat = data.combat

    -- Summary section
    local summaryGroup = AceGUI:Create("InlineGroup")
    summaryGroup:SetTitle("Combat Summary")
    summaryGroup:SetFullWidth(true)
    summaryGroup:SetLayout("Flow")
    container:AddChild(summaryGroup)

    local stats = {
        {label = "Abilities Used", value = self:FormatNumber(combat.totalAbilitiesUsed)},
        {label = "Total Damage", value = self:FormatNumber(combat.totalDamage)},
        {label = "Total Healing", value = self:FormatNumber(combat.totalHealing)},
        {label = "Damage Taken", value = self:FormatNumber(combat.totalDamageTaken)},
        {label = "Total Kills", value = tostring(combat.totalKills)},
        {label = "Deaths", value = tostring(combat.deaths)},
    }

    for _, stat in ipairs(stats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("|cffffd700%s:|r %s", stat.label, stat.value))
        label:SetWidth(180)
        summaryGroup:AddChild(label)
    end

    -- Abilities section
    local abilitiesGroup = AceGUI:Create("InlineGroup")
    abilitiesGroup:SetTitle("Top Abilities")
    abilitiesGroup:SetFullWidth(true)
    abilitiesGroup:SetLayout("List")
    container:AddChild(abilitiesGroup)

    local sorted = self:GetSortedAbilities(combat.abilities, "count")

    if #sorted == 0 then
        local noData = AceGUI:Create("Label")
        noData:SetText("No abilities tracked yet. Start fighting!")
        noData:SetFullWidth(true)
        abilitiesGroup:AddChild(noData)
    else
        -- Create scrolling frame for abilities
        local scroll = AceGUI:Create("ScrollFrame")
        scroll:SetLayout("List")
        scroll:SetFullWidth(true)
        scroll:SetHeight(200)
        abilitiesGroup:AddChild(scroll)

        for i, ability in ipairs(sorted) do
            local row = AceGUI:Create("Label")
            local damageStr = ability.damage > 0 and string.format(" | %s dmg", self:FormatNumber(ability.damage)) or ""
            local healStr = ability.healing > 0 and string.format(" | %s heal", self:FormatNumber(ability.healing)) or ""
            row:SetText(string.format("|cff00ff00%d.|r %s: |cffffffff%d uses|r%s%s",
                i, ability.name, ability.count, damageStr, healStr))
            row:SetFullWidth(true)
            scroll:AddChild(row)
        end
    end

    -- Kills section
    if combat.kills and next(combat.kills) then
        local killsGroup = AceGUI:Create("InlineGroup")
        killsGroup:SetTitle("Kills by Mob")
        killsGroup:SetFullWidth(true)
        killsGroup:SetLayout("List")
        container:AddChild(killsGroup)

        local killsSorted = {}
        for name, count in pairs(combat.kills) do
            table.insert(killsSorted, {name = name, count = count})
        end
        table.sort(killsSorted, function(a, b) return a.count > b.count end)

        local scroll = AceGUI:Create("ScrollFrame")
        scroll:SetLayout("List")
        scroll:SetFullWidth(true)
        scroll:SetHeight(100)
        killsGroup:AddChild(scroll)

        for i, kill in ipairs(killsSorted) do
            if i > 20 then break end
            local row = AceGUI:Create("Label")
            row:SetText(string.format("|cff00ff00%d.|r %s: |cffffffff%d kills|r", i, kill.name, kill.count))
            row:SetFullWidth(true)
            scroll:AddChild(row)
        end
    end
end

function ActionTracker:DrawEconomyTab(container)
    local data = self:GetCharacterData()
    local economy = data.economy

    local group = AceGUI:Create("InlineGroup")
    group:SetTitle("Economy Statistics")
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    container:AddChild(group)

    local goldEarned = economy.goldEarned or 0
    local goldSpent = economy.goldSpent or 0

    local stats = {
        {label = "Gold Earned", value = GetCoinTextureString(goldEarned)},
        {label = "Gold Spent", value = GetCoinTextureString(goldSpent)},
        {label = "Net Gold", value = GetCoinTextureString(goldEarned - goldSpent)},
        {label = "Items Looted", value = tostring(economy.itemsLooted or 0)},
        {label = "Quests Completed", value = tostring(economy.questsCompleted or 0)},
    }

    for _, stat in ipairs(stats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("|cffffd700%s:|r %s", stat.label, stat.value))
        label:SetFullWidth(true)
        group:AddChild(label)
    end

    local note = AceGUI:Create("Label")
    note:SetText("\n|cff888888Economy tracking is basic in v1.0. More detailed tracking coming in future updates.|r")
    note:SetFullWidth(true)
    container:AddChild(note)
end

function ActionTracker:DrawLifestyleTab(container)
    local data = self:GetCharacterData()
    local lifestyle = data.lifestyle

    local group = AceGUI:Create("InlineGroup")
    group:SetTitle("Lifestyle Statistics")
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    container:AddChild(group)

    local stats = {
        {label = "Time Played", value = tostring(lifestyle.timePlayed or 0) .. " seconds"},
        {label = "Distance Traveled", value = tostring(lifestyle.distanceTraveled or 0) .. " yards"},
        {label = "Emotes Used", value = tostring(lifestyle.emotesUsed or 0)},
        {label = "Whispers Sent", value = tostring(lifestyle.whispersSent or 0)},
    }

    for _, stat in ipairs(stats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("|cffffd700%s:|r %s", stat.label, stat.value))
        label:SetFullWidth(true)
        group:AddChild(label)
    end

    local note = AceGUI:Create("Label")
    note:SetText("\n|cff888888Lifestyle tracking is planned for future updates.|r")
    note:SetFullWidth(true)
    container:AddChild(note)
end

function ActionTracker:DrawAccountTab(container)
    local account = self:GetAccountData()

    local combatGroup = AceGUI:Create("InlineGroup")
    combatGroup:SetTitle("Account-Wide Combat Stats")
    combatGroup:SetFullWidth(true)
    combatGroup:SetLayout("Flow")
    container:AddChild(combatGroup)

    local stats = {
        {label = "Total Abilities Used", value = self:FormatNumber(account.combat.totalAbilitiesUsed)},
        {label = "Total Damage Done", value = self:FormatNumber(account.combat.totalDamage)},
        {label = "Total Healing Done", value = self:FormatNumber(account.combat.totalHealing)},
        {label = "Total Damage Taken", value = self:FormatNumber(account.combat.totalDamageTaken)},
        {label = "Total Kills", value = tostring(account.combat.totalKills)},
        {label = "Total Deaths", value = tostring(account.combat.deaths)},
    }

    for _, stat in ipairs(stats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("|cffffd700%s:|r %s", stat.label, stat.value))
        label:SetWidth(280)
        combatGroup:AddChild(label)
    end

    -- List characters
    local charsGroup = AceGUI:Create("InlineGroup")
    charsGroup:SetTitle("Characters Tracked")
    charsGroup:SetFullWidth(true)
    charsGroup:SetLayout("List")
    container:AddChild(charsGroup)

    local charCount = 0
    for charKey, charData in pairs(self.db.profile.characters) do
        if charKey ~= "" and charData.combat then
            charCount = charCount + 1
            local label = AceGUI:Create("Label")
            label:SetText(string.format("|cff00ff00%s|r - %s abilities, %s damage, %d kills",
                charKey,
                self:FormatNumber(charData.combat.totalAbilitiesUsed),
                self:FormatNumber(charData.combat.totalDamage),
                charData.combat.totalKills))
            label:SetFullWidth(true)
            charsGroup:AddChild(label)
        end
    end

    if charCount == 0 then
        local noData = AceGUI:Create("Label")
        noData:SetText("No character data yet.")
        noData:SetFullWidth(true)
        charsGroup:AddChild(noData)
    end
end

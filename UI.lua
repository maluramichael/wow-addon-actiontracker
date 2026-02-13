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
    tabGroup:SetLayout("Fill")
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

    -- Create scrollable container for all tab content
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)

    if tab == "combat" then
        self:DrawCombatTab(scroll)
    elseif tab == "economy" then
        self:DrawEconomyTab(scroll)
    elseif tab == "lifestyle" then
        self:DrawLifestyleTab(scroll)
    elseif tab == "account" then
        self:DrawAccountTab(scroll)
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
        {label = "XP from Kills", value = self:FormatNumber(combat.xpFromKills or 0)},
    }

    for _, stat in ipairs(stats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("|cffffd700%s:|r %s", stat.label, stat.value))
        label:SetWidth(180)
        summaryGroup:AddChild(label)
    end

    -- Abilities section
    local abilitiesGroup = AceGUI:Create("InlineGroup")
    abilitiesGroup:SetTitle("Top Abilities (Top 15)")
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
        for i, ability in ipairs(sorted) do
            if i > 15 then break end
            local row = AceGUI:Create("Label")
            local damageStr = ability.damage > 0 and string.format(" | %s dmg", self:FormatNumber(ability.damage)) or ""
            local healStr = ability.healing > 0 and string.format(" | %s heal", self:FormatNumber(ability.healing)) or ""
            row:SetText(string.format("|cff00ff00%d.|r %s: |cffffffff%d uses|r%s%s",
                i, ability.name, ability.count, damageStr, healStr))
            row:SetFullWidth(true)
            abilitiesGroup:AddChild(row)
        end
    end

    -- Kills section
    if combat.kills and next(combat.kills) then
        local killsGroup = AceGUI:Create("InlineGroup")
        killsGroup:SetTitle("Kills by Mob (Top 15)")
        killsGroup:SetFullWidth(true)
        killsGroup:SetLayout("List")
        container:AddChild(killsGroup)

        local killsSorted = {}
        for name, count in pairs(combat.kills) do
            table.insert(killsSorted, {name = name, count = count})
        end
        table.sort(killsSorted, function(a, b) return a.count > b.count end)

        for i, kill in ipairs(killsSorted) do
            if i > 15 then break end
            local row = AceGUI:Create("Label")
            row:SetText(string.format("|cff00ff00%d.|r %s: |cffffffff%d kills|r", i, kill.name, kill.count))
            row:SetFullWidth(true)
            killsGroup:AddChild(row)
        end
    end
end

function ActionTracker:DrawEconomyTab(container)
    local data = self:GetCharacterData()
    local economy = data.economy

    -- Gold Summary
    local goldGroup = AceGUI:Create("InlineGroup")
    goldGroup:SetTitle("Gold Summary")
    goldGroup:SetFullWidth(true)
    goldGroup:SetLayout("List")
    container:AddChild(goldGroup)

    local goldEarned = economy.goldEarned or 0
    local goldSpent = economy.goldSpent or 0

    local goldStats = {
        {label = "Total Gold Earned", value = GetCoinTextureString(goldEarned)},
        {label = "Total Gold Spent", value = GetCoinTextureString(goldSpent)},
        {label = "Net Gold", value = GetCoinTextureString(goldEarned - goldSpent)},
    }

    for _, stat in ipairs(goldStats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("|cffffd700%s:|r %s", stat.label, stat.value))
        label:SetFullWidth(true)
        goldGroup:AddChild(label)
    end

    -- Gold Sources
    local sourcesGroup = AceGUI:Create("InlineGroup")
    sourcesGroup:SetTitle("Gold by Source")
    sourcesGroup:SetFullWidth(true)
    sourcesGroup:SetLayout("List")
    container:AddChild(sourcesGroup)

    local sourceStats = {
        {label = "From Vendors (selling)", value = GetCoinTextureString(economy.goldFromVendor or 0)},
        {label = "From Mail", value = GetCoinTextureString(economy.goldFromMail or 0)},
        {label = "From Loot", value = GetCoinTextureString(economy.goldFromLoot or 0)},
        {label = "From Quests", value = GetCoinTextureString(economy.goldFromQuest or 0)},
    }

    for _, stat in ipairs(sourceStats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("  |cff888888%s:|r %s", stat.label, stat.value))
        label:SetFullWidth(true)
        sourcesGroup:AddChild(label)
    end

    -- XP & Quests
    local xpGroup = AceGUI:Create("InlineGroup")
    xpGroup:SetTitle("Experience & Quests")
    xpGroup:SetFullWidth(true)
    xpGroup:SetLayout("List")
    container:AddChild(xpGroup)

    local xpStats = {
        {label = "Quests Completed", value = tostring(economy.questsCompleted or 0)},
        {label = "XP from Quests", value = self:FormatNumber(economy.xpFromQuests or 0)},
        {label = "Items Looted", value = tostring(economy.itemsLooted or 0)},
    }

    for _, stat in ipairs(xpStats) do
        local label = AceGUI:Create("Label")
        label:SetText(string.format("|cffffd700%s:|r %s", stat.label, stat.value))
        label:SetFullWidth(true)
        xpGroup:AddChild(label)
    end
end

local function FormatPlaytime(seconds)
    if not seconds or seconds <= 0 then return "0m" end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

local function GetClassColor(classEnglish)
    if classEnglish and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classEnglish] then
        local c = RAID_CLASS_COLORS[classEnglish]
        return string.format("%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    return "ffffff"
end

function ActionTracker:DrawLifestyleTab(container)
    -- Collect all characters with playtime data
    local characters = {}
    local totalTime = 0

    for charKey, charData in pairs(self.db.profile.characters) do
        if charKey ~= "" and charData.lifestyle then
            local time = charData.lifestyle.timePlayed or 0
            local meta = charData.meta or {}
            table.insert(characters, {
                key = charKey,
                faction = meta.faction or "Unknown",
                class = meta.class or "Unknown",
                classEnglish = meta.classEnglish or "WARRIOR",
                race = meta.race or "",
                level = meta.level or 0,
                timePlayed = time,
            })
            totalTime = totalTime + time
        end
    end

    -- Sort by faction, then class, then time descending
    table.sort(characters, function(a, b)
        if a.faction ~= b.faction then return a.faction < b.faction end
        if a.class ~= b.class then return a.class < b.class end
        return a.timePlayed > b.timePlayed
    end)

    -- Total playtime header
    local totalGroup = AceGUI:Create("InlineGroup")
    totalGroup:SetTitle("Playtime Overview")
    totalGroup:SetFullWidth(true)
    totalGroup:SetLayout("List")
    container:AddChild(totalGroup)

    local totalLabel = AceGUI:Create("Label")
    totalLabel:SetText(string.format("|cffffd700Total Playtime:|r  |cffffffff%s|r  |cff888888(%d characters)|r",
        FormatPlaytime(totalTime), #characters))
    totalLabel:SetFullWidth(true)
    totalGroup:AddChild(totalLabel)

    if #characters == 0 then
        local note = AceGUI:Create("Label")
        note:SetText("\n|cff888888No playtime data yet. Log in to each character to record playtime.|r")
        note:SetFullWidth(true)
        container:AddChild(note)
        return
    end

    -- Group by faction
    local factions = {}
    local factionOrder = {}
    for _, char in ipairs(characters) do
        if not factions[char.faction] then
            factions[char.faction] = { time = 0, classes = {}, classOrder = {} }
            table.insert(factionOrder, char.faction)
        end
        local f = factions[char.faction]
        f.time = f.time + char.timePlayed

        if not f.classes[char.class] then
            f.classes[char.class] = { time = 0, classEnglish = char.classEnglish, chars = {} }
            table.insert(f.classOrder, char.class)
        end
        local cl = f.classes[char.class]
        cl.time = cl.time + char.timePlayed
        table.insert(cl.chars, char)
    end

    -- Draw faction groups
    for _, factionName in ipairs(factionOrder) do
        local fData = factions[factionName]

        local factionGroup = AceGUI:Create("InlineGroup")
        factionGroup:SetTitle(string.format("%s  -  %s", factionName, FormatPlaytime(fData.time)))
        factionGroup:SetFullWidth(true)
        factionGroup:SetLayout("List")
        container:AddChild(factionGroup)

        -- Faction header color
        if factionGroup.content then
            local bg = factionGroup.content:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            if factionName == "Horde" then
                bg:SetColorTexture(0.6, 0.1, 0.1, 0.06)
            elseif factionName == "Alliance" then
                bg:SetColorTexture(0.1, 0.2, 0.6, 0.06)
            end
        end

        for _, className in ipairs(fData.classOrder) do
            local clData = fData.classes[className]
            local cColor = GetClassColor(clData.classEnglish)

            -- Class header
            local classHeader = AceGUI:Create("Label")
            classHeader:SetText(string.format("  |cff%s%s|r  |cff888888-  %s|r",
                cColor, className, FormatPlaytime(clData.time)))
            classHeader:SetFullWidth(true)
            classHeader:SetFontObject(GameFontNormal)
            factionGroup:AddChild(classHeader)

            -- Character rows
            for _, char in ipairs(clData.chars) do
                local name = char.key:match("^(.+)-") or char.key
                local realm = char.key:match("-(.+)$") or ""
                local row = AceGUI:Create("Label")
                row:SetText(string.format(
                    "      |cff%s%s|r  |cff666666%s|r  |cffaaaaaa%s|r  |cffffd700Lv %d|r  |cffffffff%s|r",
                    cColor, name, realm, char.race, char.level, FormatPlaytime(char.timePlayed)))
                row:SetFullWidth(true)
                factionGroup:AddChild(row)
            end
        end
    end
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

local addonName, addon = ...
local ActionTracker = addon

-- Default database structure
function ActionTracker:GetDefaults()
    return {
        profile = {
            enabled = true,
            minimap = { hide = false },
            characters = {
                [""] = {
                    combat = {
                        totalAbilitiesUsed = 0,
                        totalDamage = 0,
                        totalHealing = 0,
                        totalDamageTaken = 0,
                        totalKills = 0,
                        deaths = 0,
                        abilities = {},
                        kills = {},
                        xpFromKills = 0,
                    },
                    economy = {
                        goldEarned = 0,
                        goldSpent = 0,
                        goldFromVendor = 0,
                        goldFromMail = 0,
                        goldFromLoot = 0,
                        goldFromQuest = 0,
                        itemsLooted = 0,
                        questsCompleted = 0,
                        xpFromQuests = 0,
                        lastKnownGold = nil,
                    },
                    lifestyle = {
                        timePlayed = 0,
                        distanceTraveled = 0,
                        emotesUsed = 0,
                        whispersSent = 0,
                    },
                },
            },
            accountWide = {
                combat = {
                    totalAbilitiesUsed = 0,
                    totalDamage = 0,
                    totalHealing = 0,
                    totalDamageTaken = 0,
                    totalKills = 0,
                    deaths = 0,
                    xpFromKills = 0,
                },
                economy = {
                    goldEarned = 0,
                    goldSpent = 0,
                    goldFromVendor = 0,
                    goldFromMail = 0,
                    goldFromLoot = 0,
                    goldFromQuest = 0,
                    itemsLooted = 0,
                    questsCompleted = 0,
                    xpFromQuests = 0,
                },
                lifestyle = {
                    timePlayed = 0,
                    distanceTraveled = 0,
                    emotesUsed = 0,
                    whispersSent = 0,
                },
            },
        },
    }
end

function ActionTracker:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

function ActionTracker:GetCharacterData()
    local charKey = self:GetCharacterKey()

    if not self.db.profile.characters[charKey] then
        self.db.profile.characters[charKey] = {
            combat = {
                totalAbilitiesUsed = 0,
                totalDamage = 0,
                totalHealing = 0,
                totalDamageTaken = 0,
                totalKills = 0,
                deaths = 0,
                abilities = {},
                kills = {},
                xpFromKills = 0,
            },
            economy = {
                goldEarned = 0,
                goldSpent = 0,
                goldFromVendor = 0,
                goldFromMail = 0,
                goldFromLoot = 0,
                goldFromQuest = 0,
                itemsLooted = 0,
                questsCompleted = 0,
                xpFromQuests = 0,
                lastKnownGold = nil,
            },
            lifestyle = {
                timePlayed = 0,
                distanceTraveled = 0,
                emotesUsed = 0,
                whispersSent = 0,
            },
        }
    end

    -- Ensure new fields exist for older saved data
    local data = self.db.profile.characters[charKey]
    if not data.combat.xpFromKills then data.combat.xpFromKills = 0 end
    if not data.economy.goldFromVendor then data.economy.goldFromVendor = 0 end
    if not data.economy.goldFromMail then data.economy.goldFromMail = 0 end
    if not data.economy.goldFromLoot then data.economy.goldFromLoot = 0 end
    if not data.economy.goldFromQuest then data.economy.goldFromQuest = 0 end
    if not data.economy.xpFromQuests then data.economy.xpFromQuests = 0 end

    return data
end

function ActionTracker:GetAccountData()
    local data = self.db.profile.accountWide

    -- Ensure new fields exist
    if not data.combat.xpFromKills then data.combat.xpFromKills = 0 end
    if not data.economy.goldFromVendor then data.economy.goldFromVendor = 0 end
    if not data.economy.goldFromMail then data.economy.goldFromMail = 0 end
    if not data.economy.goldFromLoot then data.economy.goldFromLoot = 0 end
    if not data.economy.goldFromQuest then data.economy.goldFromQuest = 0 end
    if not data.economy.xpFromQuests then data.economy.xpFromQuests = 0 end

    return data
end

-- Tracking Functions
function ActionTracker:TrackAbilityUse(spellId, spellName)
    if not spellName or spellName == "" then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    -- Initialize ability if not exists
    if not charData.combat.abilities[spellName] then
        charData.combat.abilities[spellName] = {
            count = 0,
            damage = 0,
            healing = 0,
            spellId = spellId,
        }
    end

    -- Increment counts
    charData.combat.abilities[spellName].count = charData.combat.abilities[spellName].count + 1
    charData.combat.totalAbilitiesUsed = charData.combat.totalAbilitiesUsed + 1
    accountData.combat.totalAbilitiesUsed = accountData.combat.totalAbilitiesUsed + 1
end

function ActionTracker:TrackDamage(spellId, spellName, amount)
    if not spellName or spellName == "" then return end
    if not amount or amount <= 0 then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    -- Initialize ability if not exists
    if not charData.combat.abilities[spellName] then
        charData.combat.abilities[spellName] = {
            count = 0,
            damage = 0,
            healing = 0,
            spellId = spellId,
        }
    end

    -- Add damage
    charData.combat.abilities[spellName].damage = charData.combat.abilities[spellName].damage + amount
    charData.combat.totalDamage = charData.combat.totalDamage + amount
    accountData.combat.totalDamage = accountData.combat.totalDamage + amount
end

function ActionTracker:TrackHealing(spellId, spellName, amount)
    if not spellName or spellName == "" then return end
    if not amount or amount <= 0 then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    -- Initialize ability if not exists
    if not charData.combat.abilities[spellName] then
        charData.combat.abilities[spellName] = {
            count = 0,
            damage = 0,
            healing = 0,
            spellId = spellId,
        }
    end

    -- Add healing
    charData.combat.abilities[spellName].healing = charData.combat.abilities[spellName].healing + amount
    charData.combat.totalHealing = charData.combat.totalHealing + amount
    accountData.combat.totalHealing = accountData.combat.totalHealing + amount
end

function ActionTracker:TrackDamageTaken(amount)
    if not amount or amount <= 0 then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    charData.combat.totalDamageTaken = charData.combat.totalDamageTaken + amount
    accountData.combat.totalDamageTaken = accountData.combat.totalDamageTaken + amount
end

function ActionTracker:TrackKill(mobName, mobGUID)
    if not mobName or mobName == "" then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    -- Track per-mob kills
    if not charData.combat.kills[mobName] then
        charData.combat.kills[mobName] = 0
    end
    charData.combat.kills[mobName] = charData.combat.kills[mobName] + 1

    -- Total kills
    charData.combat.totalKills = charData.combat.totalKills + 1
    accountData.combat.totalKills = accountData.combat.totalKills + 1
end

function ActionTracker:TrackDeath()
    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    charData.combat.deaths = charData.combat.deaths + 1
    accountData.combat.deaths = accountData.combat.deaths + 1
end

function ActionTracker:TrackXPFromKill(xp)
    if not xp or xp <= 0 then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    charData.combat.xpFromKills = charData.combat.xpFromKills + xp
    accountData.combat.xpFromKills = accountData.combat.xpFromKills + xp
end

function ActionTracker:TrackXPFromQuest(xp)
    if not xp or xp <= 0 then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    charData.economy.xpFromQuests = charData.economy.xpFromQuests + xp
    accountData.economy.xpFromQuests = accountData.economy.xpFromQuests + xp
end

function ActionTracker:TrackGoldFromSource(amount, source)
    if not amount or amount <= 0 then return end

    local charData = self:GetCharacterData()
    local accountData = self:GetAccountData()

    if source == "vendor" then
        charData.economy.goldFromVendor = charData.economy.goldFromVendor + amount
        accountData.economy.goldFromVendor = accountData.economy.goldFromVendor + amount
    elseif source == "mail" then
        charData.economy.goldFromMail = charData.economy.goldFromMail + amount
        accountData.economy.goldFromMail = accountData.economy.goldFromMail + amount
    elseif source == "loot" then
        charData.economy.goldFromLoot = charData.economy.goldFromLoot + amount
        accountData.economy.goldFromLoot = accountData.economy.goldFromLoot + amount
    elseif source == "quest" then
        charData.economy.goldFromQuest = charData.economy.goldFromQuest + amount
        accountData.economy.goldFromQuest = accountData.economy.goldFromQuest + amount
    end

    charData.economy.goldEarned = charData.economy.goldEarned + amount
    accountData.economy.goldEarned = accountData.economy.goldEarned + amount
end

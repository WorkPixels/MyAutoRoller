local addonName, addonTable = ...

-- API Compatibility Layer for WoW Forever (16001 / 12.x) and Classic Era / TBC / Wrath
local CI = _G.C_Item
if CI then
    pcall(function()
        if not _G.GetItemInfo and CI.GetItemInfo then _G.GetItemInfo = CI.GetItemInfo end
        if not _G.GetItemInfoInstant and CI.GetItemInfoInstant then _G.GetItemInfoInstant = CI.GetItemInfoInstant end
        if not _G.GetItemStats and CI.GetItemStats then _G.GetItemStats = CI.GetItemStats end
        if not _G.GetItemQualityColor and CI.GetItemQualityColor then _G.GetItemQualityColor = CI.GetItemQualityColor end
    end)
end
local GetItemInfo = (CI and CI.GetItemInfo) or _G.GetItemInfo
local GetItemInfoInstant = (CI and CI.GetItemInfoInstant) or _G.GetItemInfoInstant
local GetItemStats = (CI and CI.GetItemStats) or _G.GetItemStats

-- Default Account-wide DB Configuration
local defaultDB = {
    enabled = true,
    bopSafety = false,
    boeSafety = true,
    passIfNotUpgrade = false,
    chatAnnounce = true,
    needProfessions = true,
    showLootTracker = true,
    qualities = {
        [0] = "pass",    -- Poor
        [1] = "pass",    -- Common
        [2] = "greed",   -- Uncommon
        [3] = "upgrade", -- Rare
        [4] = "upgrade", -- Epic
        [5] = "manual",  -- Legendary
    }
}

-- Default Character-specific DB Configuration
local defaultCharDB = {
    statWeightEnabled = false,
    currentProfile = "Default",
    minWeaponSpeed1H = 0.00,
    minWeaponSpeed2H = 0.00,
    minWeaponSpeedRanged = 0.00,
    profiles = {},
    statWeights = {
        ["ITEM_MOD_STRENGTH_SHORT"] = 0,
        ["ITEM_MOD_AGILITY_SHORT"] = 0,
        ["ITEM_MOD_STAMINA_SHORT"] = 0,
        ["ITEM_MOD_INTELLECT_SHORT"] = 0,
        ["ITEM_MOD_SPIRIT_SHORT"] = 0,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = 0,
        ["ITEM_MOD_HEALING_DONE_SHORT"] = 0,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 0,
        ["ITEM_MOD_CRIT_RATING_SHORT"] = 0,
        ["ITEM_MOD_CRIT_SPELL_RATING_SHORT"] = 0,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 0,
        ["ITEM_MOD_HASTE_RATING_SHORT"] = 0,
        ["ITEM_MOD_HASTE_SPELL_RATING_SHORT"] = 0,
        ["ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT"] = 0,
        ["ITEM_MOD_SPELL_PENETRATION_SHORT"] = 0,
        ["ITEM_MOD_POWER_REGEN0_SHORT"] = 0,
        ["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"] = 0,
        ["ITEM_MOD_DODGE_RATING_SHORT"] = 0,
        ["ITEM_MOD_PARRY_RATING_SHORT"] = 0,
        ["ITEM_MOD_BLOCK_RATING_SHORT"] = 0,
        ["ITEM_MOD_BLOCK_VALUE_SHORT"] = 0,
        ["ITEM_MOD_ARMOR_SHORT"] = 0,
        ["ITEM_MOD_WEAPON_DPS_SHORT"] = 0,
        ["ITEM_MOD_WEAPON_RANGED_DPS_SHORT"] = 0,
        ["ITEM_MOD_EXPERTISE_RATING_SHORT"] = 0,
        ["ITEM_MOD_RESILIENCE_RATING_SHORT"] = 0,
    },
    statEnabled = {
        ["ITEM_MOD_STRENGTH_SHORT"] = true,
        ["ITEM_MOD_AGILITY_SHORT"] = true,
        ["ITEM_MOD_STAMINA_SHORT"] = true,
        ["ITEM_MOD_INTELLECT_SHORT"] = true,
        ["ITEM_MOD_SPIRIT_SHORT"] = true,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = true,
        ["ITEM_MOD_HEALING_DONE_SHORT"] = true,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = true,
        ["ITEM_MOD_CRIT_RATING_SHORT"] = true,
        ["ITEM_MOD_CRIT_SPELL_RATING_SHORT"] = true,
        ["ITEM_MOD_HIT_RATING_SHORT"] = true,
        ["ITEM_MOD_HASTE_RATING_SHORT"] = true,
        ["ITEM_MOD_HASTE_SPELL_RATING_SHORT"] = true,
        ["ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT"] = true,
        ["ITEM_MOD_SPELL_PENETRATION_SHORT"] = true,
        ["ITEM_MOD_POWER_REGEN0_SHORT"] = true,
        ["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"] = true,
        ["ITEM_MOD_DODGE_RATING_SHORT"] = true,
        ["ITEM_MOD_PARRY_RATING_SHORT"] = true,
        ["ITEM_MOD_BLOCK_RATING_SHORT"] = true,
        ["ITEM_MOD_BLOCK_VALUE_SHORT"] = true,
        ["ITEM_MOD_ARMOR_SHORT"] = true,
        ["ITEM_MOD_WEAPON_DPS_SHORT"] = true,
        ["ITEM_MOD_WEAPON_RANGED_DPS_SHORT"] = true,
        ["ITEM_MOD_EXPERTISE_RATING_SHORT"] = true,
        ["ITEM_MOD_RESILIENCE_RATING_SHORT"] = true,
    }
}

-- Quality configuration for labels and styling
local QUALITIES = {
    [0] = { name = "Poor (Gray)", color = "9d9d9d" },
    [1] = { name = "Common (White)", color = "ffffff" },
    [2] = { name = "Uncommon (Green)", color = "1eff00" },
    [3] = { name = "Rare (Blue)", color = "0070dd" },
    [4] = { name = "Epic (Purple)", color = "a335ee" },
    [5] = { name = "Legendary (Orange)", color = "ff8000" },
}

-- Roll type configuration
local ROLL_TYPES = {
    { key = "manual", label = "Manual" },
    { key = "pass", label = "Pass" },
    { key = "greed", label = "Greed" },
    { key = "need", label = "Need" },
    { key = "disenchant", label = "Disenchant" },
}

-- Create Options Panel Frame
local panel = CreateFrame("Frame", "MyAutoRollerOptionsPanel", UIParent)
panel.name = "MyAutoRoller"
panel:Hide()

-- Title
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MyAutoRoller Settings")

-- Description
local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetText("Automatically rolls Need, Greed, Disenchant, or Pass on items based on quality. Use settings below to configure thresholds.")

-- Checkbox creator helper (supports account-wide or character-specific DB)
local function CreateCheckbox(name, parent, label, x, y, dbKey, useCharDB)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    _G[name .. "Text"]:SetText(label)
    cb:SetScript("OnClick", function(self)
        local db = useCharDB and MyAutoRollerCharDB or MyAutoRollerDB
        if db then
            db[dbKey] = self:GetChecked() and true or false
        end
    end)
    return cb
end

-- Create Main Config checkboxes
local cbEnable = CreateCheckbox("MyAutoRoller_CB_Enable", panel, "Enable Auto Roller", 20, -65, "enabled")
local cbBoP = CreateCheckbox("MyAutoRoller_CB_BoP", panel, "Skip Bind-on-Pickup (Roll Manually)", 20, -90, "bopSafety")
local cbBoE = CreateCheckbox("MyAutoRoller_CB_BoE", panel, "Skip BoE Items (Never Need on Bind-on-Equip)", 20, -115, "boeSafety")
local cbPassNotUpgrade = CreateCheckbox("MyAutoRoller_CB_PassNotUpgrade", panel, "Pass if Not an Upgrade (Instead of Greed)", 20, -140, "passIfNotUpgrade")

local cbAnnounce = CreateCheckbox("MyAutoRoller_CB_Announce", panel, "Announce Rolls in Chat Log", 340, -65, "chatAnnounce")
local cbProfessions = CreateCheckbox("MyAutoRoller_CB_Professions", panel, "Need on My Professions", 340, -90, "needProfessions")
local cbTracker = CreateCheckbox("MyAutoRoller_CB_Tracker", panel, "Show Live Loot Roll Tracker Window", 340, -115, "showLootTracker")

-- Subtitle for loot matrix
local matrixTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
matrixTitle:SetPoint("TOPLEFT", 20, -175)
matrixTitle:SetText("Auto-Roll Configuration Matrix:")

-- Column layout settings
local columns = {
    { label = "Manual", x = 165 },
    { label = "Upgrade", x = 235 },
    { label = "Pass", x = 305 },
    { label = "Greed", x = 370 },
    { label = "Need", x = 430 },
    { label = "Disenchant", x = 500 },
}

-- Render Column Headers
for _, col in ipairs(columns) do
    if col.label == "Upgrade" then
        local btn = CreateFrame("Button", "MyAutoRoller_Header_Upgrade", panel)
        btn:SetSize(75, 20)
        btn:SetPoint("CENTER", panel, "TOPLEFT", col.x, -205)
        
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetText("Upgrade |cffffd100(?)|r")
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Upgrade Mode", 1, 1, 1)
            GameTooltip:AddLine("• Rolls |cff00ff00NEED|r if the gear drop is a Stat Weight Upgrade for your class/spec.", 0.2, 1, 0.2, true)
            GameTooltip:AddLine("• Rolls |cffffd100GREED|r (or |cff888888PASS|r if 'Pass if Not an Upgrade' is checked) if not an upgrade.", 1, 0.82, 0, true)
            GameTooltip:AddLine("• Rolls |cffffd100GREED|r (or |cff888888PASS|r) on BoE items if BoE Protection is enabled.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    else
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("CENTER", panel, "TOPLEFT", col.x, -205)
        fs:SetText(col.label)
    end
end

-- Radio button storage
local radioButtons = {}

-- Render Rows for each Item Quality
for q = 0, 5 do
    radioButtons[q] = {}
    local yOffset = -235 - (q * 30)

    -- Quality label text
    local qInfo = QUALITIES[q]
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", panel, "TOPLEFT", 20, yOffset)
    label:SetText(string.format("|cff%s%s|r", qInfo.color, qInfo.name))

    -- Render radio buttons for each column
    for _, col in ipairs(columns) do
        local key = string.lower(col.label)
        local btnName = "MyAutoRollerRadio_" .. q .. "_" .. key
        
        local cb = CreateFrame("CheckButton", btnName, panel, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("CENTER", panel, "TOPLEFT", col.x, yOffset)
        radioButtons[q][key] = cb

        cb:SetScript("OnClick", function(self)
            -- Uncheck all other radio buttons in this quality's row
            for otherKey, otherBtn in pairs(radioButtons[q]) do
                if otherKey ~= key then
                    otherBtn:SetChecked(false)
                end
            end
            -- Force check current button
            self:SetChecked(true)
            -- Save setting to database
            if MyAutoRollerDB and MyAutoRollerDB.qualities then
                MyAutoRollerDB.qualities[q] = key
            end
        end)
    end
end

-- UI State Updater
local function UpdateUI()
    if not MyAutoRollerDB then return end

    -- Check main controls
    cbEnable:SetChecked(MyAutoRollerDB.enabled)
    cbBoP:SetChecked(MyAutoRollerDB.bopSafety)
    cbBoE:SetChecked(MyAutoRollerDB.boeSafety)
    if cbPassNotUpgrade then cbPassNotUpgrade:SetChecked(MyAutoRollerDB.passIfNotUpgrade) end
    cbAnnounce:SetChecked(MyAutoRollerDB.chatAnnounce)
    cbProfessions:SetChecked(MyAutoRollerDB.needProfessions)
    if cbTracker then cbTracker:SetChecked(MyAutoRollerDB.showLootTracker) end

    -- Check matrix controls
    for q = 0, 5 do
        local savedAction = MyAutoRollerDB.qualities[q] or "manual"
        for key, btn in pairs(radioButtons[q]) do
            btn:SetChecked(key == savedAction)
        end
    end
end

panel:SetScript("OnShow", UpdateUI)

-- Stats configuration separated by 3 distinct categories & columns (.00 scale)
local PHYSICAL_DPS_STATS = {
    { key = "ITEM_MOD_STRENGTH_SHORT", label = "Strength", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_AGILITY_SHORT", label = "Agility", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_ATTACK_POWER_SHORT", label = "Attack Power", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_CRIT_RATING_SHORT", label = "Melee Crit", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_HIT_RATING_SHORT", label = "Hit Rating", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_HASTE_RATING_SHORT", label = "Melee Haste", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT", label = "Armor Pen (ArP)", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_EXPERTISE_RATING_SHORT", label = "Expertise", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_WEAPON_DPS_SHORT", label = "Melee Wpn DPS", min = 0, max = 20, step = 0.05 },
    { key = "ITEM_MOD_WEAPON_RANGED_DPS_SHORT", label = "Ranged DPS", min = 0, max = 25, step = 0.05 },
}

local TANK_STATS = {
    { key = "ITEM_MOD_STAMINA_SHORT", label = "Stamina", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", label = "Defense Rating", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_DODGE_RATING_SHORT", label = "Dodge Rating", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_PARRY_RATING_SHORT", label = "Parry Rating", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_BLOCK_RATING_SHORT", label = "Block Rating", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_BLOCK_VALUE_SHORT", label = "Block Value", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_ARMOR_SHORT", label = "Bonus Armor", min = 0, max = 2, step = 0.01 },
    { key = "ITEM_MOD_RESILIENCE_RATING_SHORT", label = "Resilience", min = 0, max = 10, step = 0.01 },
}

local CASTER_HEALER_STATS = {
    { key = "ITEM_MOD_INTELLECT_SHORT", label = "Intellect", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_SPIRIT_SHORT", label = "Spirit", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_SPELL_POWER_SHORT", label = "Spell Power", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_HEALING_DONE_SHORT", label = "Healing Power", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_CRIT_SPELL_RATING_SHORT", label = "Spell Crit", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_HASTE_SPELL_RATING_SHORT", label = "Spell Haste", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_POWER_REGEN0_SHORT", label = "MP5 (Mana/5s)", min = 0, max = 10, step = 0.01 },
    { key = "ITEM_MOD_SPELL_PENETRATION_SHORT", label = "Spell Pen", min = 0, max = 10, step = 0.01 },
}

-- Combined master list for database loops
local STATS_CONFIG = {}
for _, s in ipairs(PHYSICAL_DPS_STATS) do table.insert(STATS_CONFIG, s) end
for _, s in ipairs(TANK_STATS) do table.insert(STATS_CONFIG, s) end
for _, s in ipairs(CASTER_HEALER_STATS) do table.insert(STATS_CONFIG, s) end

-- Create Sub-Panel Frame
local subPanel = CreateFrame("Frame", "MyAutoRollerStatWeightsPanel", UIParent)
subPanel.name = "Stat Weights"
subPanel:Hide()

-- Sub-Panel Title
local subTitle = subPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
subTitle:SetPoint("TOPLEFT", 16, -16)
subTitle:SetText("MyAutoRoller - Stat Weights")

-- Sub-Panel Description
local subDesc = subPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subDesc:SetPoint("TOPLEFT", subTitle, "BOTTOMLEFT", 0, -8)
subDesc:SetText("Configure Pawn-style weights for all gear stats. Gear scoring uses the exact sum(stat * weight) formula as Pawn.")

-- Forward declarations
local UpdateSubPanelUI
local profileDropdown
local isProgrammaticChange = false
local isProgrammaticSpeed = false

-- Deep copy table helper
local function DeepCopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = DeepCopyTable(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

-- Profile Management Functions
local function SetActiveProfile(profileName, quiet)
    if not MyAutoRollerCharDB or not MyAutoRollerCharDB.profiles then return false end
    local prof = MyAutoRollerCharDB.profiles[profileName]
    if not prof then return false end

    MyAutoRollerCharDB.currentProfile = profileName
    MyAutoRollerCharDB.statWeights = prof.statWeights
    MyAutoRollerCharDB.statEnabled = prof.statEnabled
    MyAutoRollerCharDB.minWeaponSpeed1H = prof.minWeaponSpeed1H or 0.00
    MyAutoRollerCharDB.minWeaponSpeed2H = prof.minWeaponSpeed2H or 0.00
    MyAutoRollerCharDB.minWeaponSpeedRanged = prof.minWeaponSpeedRanged or 0.00

    if profileDropdown and UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(profileDropdown, profileName)
        if UIDropDownMenu_SetSelectedValue then
            UIDropDownMenu_SetSelectedValue(profileDropdown, profileName)
        end
    end
    if UpdateSubPanelUI then
        UpdateSubPanelUI()
    end
    if UpdateLootTrackerUI then
        UpdateLootTrackerUI()
    end
    if not quiet then
        print(string.format("|cff00ff00MyAutoRoller|r: Switched to stat weight profile '|cffffd000%s|r'.", profileName))
    end
    return true
end

local function CreateNewProfile(profileName, copyFromCurrent)
    if not MyAutoRollerCharDB then return false end
    if not MyAutoRollerCharDB.profiles then MyAutoRollerCharDB.profiles = {} end

    profileName = strtrim(profileName)
    if profileName == "" then return false end

    if MyAutoRollerCharDB.profiles[profileName] then
        print(string.format("|cffff0000MyAutoRoller Error:|r A profile named '|cffffd000%s|r' already exists!", profileName))
        return false
    end

    local newProf = {
        statWeights = {},
        statEnabled = {},
        minWeaponSpeed1H = 0.00,
        minWeaponSpeed2H = 0.00,
        minWeaponSpeedRanged = 0.00,
    }

    local curProf = copyFromCurrent and MyAutoRollerCharDB.profiles[MyAutoRollerCharDB.currentProfile]
    if curProf then
        newProf.statWeights = DeepCopyTable(curProf.statWeights or {})
        newProf.statEnabled = DeepCopyTable(curProf.statEnabled or {})
        newProf.minWeaponSpeed1H = curProf.minWeaponSpeed1H or 0.00
        newProf.minWeaponSpeed2H = curProf.minWeaponSpeed2H or 0.00
        newProf.minWeaponSpeedRanged = curProf.minWeaponSpeedRanged or 0.00
    else
        for _, conf in ipairs(STATS_CONFIG) do
            newProf.statWeights[conf.key] = 0
            newProf.statEnabled[conf.key] = true
        end
    end

    MyAutoRollerCharDB.profiles[profileName] = newProf
    SetActiveProfile(profileName)
    print(string.format("|cff00ff00MyAutoRoller|r: Created and activated new profile '|cffffd000%s|r'.", profileName))
    return true
end

local function DeleteProfile(profileName)
    if not MyAutoRollerCharDB or not MyAutoRollerCharDB.profiles then return false end
    if not MyAutoRollerCharDB.profiles[profileName] then return false end

    local count = 0
    local nextProfile = nil
    for name in pairs(MyAutoRollerCharDB.profiles) do
        count = count + 1
        if name ~= profileName and not nextProfile then
            nextProfile = name
        end
    end

    if count <= 1 then
        print("|cffff0000MyAutoRoller Error:|r Cannot delete the only remaining profile! You must have at least one profile.")
        return false
    end

    MyAutoRollerCharDB.profiles[profileName] = nil
    print(string.format("|cff00ff00MyAutoRoller|r: Deleted profile '|cffffd000%s|r'.", profileName))

    if MyAutoRollerCharDB.currentProfile == profileName then
        local fallback = MyAutoRollerCharDB.profiles["Default"] and "Default" or nextProfile
        SetActiveProfile(fallback)
    else
        if UpdateSubPanelUI then UpdateSubPanelUI() end
    end
    return true
end

local function ResetCurrentProfile()
    if not MyAutoRollerCharDB or not MyAutoRollerCharDB.profiles then return end
    local cur = MyAutoRollerCharDB.currentProfile
    local prof = MyAutoRollerCharDB.profiles[cur]
    if not prof then return end

    prof.minWeaponSpeed1H = 0.00
    prof.minWeaponSpeed2H = 0.00
    prof.minWeaponSpeedRanged = 0.00
    for _, conf in ipairs(STATS_CONFIG) do
        prof.statWeights[conf.key] = 0
        prof.statEnabled[conf.key] = true
    end

    MyAutoRollerCharDB.minWeaponSpeed1H = 0.00
    MyAutoRollerCharDB.minWeaponSpeed2H = 0.00
    MyAutoRollerCharDB.minWeaponSpeedRanged = 0.00

    if UpdateSubPanelUI then UpdateSubPanelUI() end
    if UpdateLootTrackerUI then UpdateLootTrackerUI() end
    print(string.format("|cff00ff00MyAutoRoller|r: Reset profile '|cffffd000%s|r' to defaults (all weights set to 0.00).", cur))
end

-- Static Popup Dialogs for Profile Management
StaticPopupDialogs["MYAUTOROLLER_NEW_PROFILE"] = {
    text = "Enter a name for the new stat weight profile:",
    button1 = "Create",
    button2 = CANCEL,
    hasEditBox = true,
    editBoxWidth = 240,
    OnShow = function(self)
        local eb = self.editBox or self.EditBox
        if eb then
            eb:SetText("")
            eb:SetFocus()
        end
    end,
    OnAccept = function(self)
        local eb = self.editBox or self.EditBox
        local text = eb and eb:GetText()
        text = text and strtrim(text)
        if text and text ~= "" then
            CreateNewProfile(text, false)
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local text = self:GetText()
        text = text and strtrim(text)
        if text and text ~= "" then
            CreateNewProfile(text, false)
        end
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MYAUTOROLLER_COPY_PROFILE"] = {
    text = "Enter a name for the copied profile (copies '|cffffd000%s|r'):",
    button1 = "Copy",
    button2 = CANCEL,
    hasEditBox = true,
    editBoxWidth = 240,
    OnShow = function(self)
        local eb = self.editBox or self.EditBox
        if eb then
            local cur = MyAutoRollerCharDB and MyAutoRollerCharDB.currentProfile or "Profile"
            eb:SetText(cur .. " Copy")
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    OnAccept = function(self)
        local eb = self.editBox or self.EditBox
        local text = eb and eb:GetText()
        text = text and strtrim(text)
        if text and text ~= "" then
            CreateNewProfile(text, true)
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local text = self:GetText()
        text = text and strtrim(text)
        if text and text ~= "" then
            CreateNewProfile(text, true)
        end
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MYAUTOROLLER_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete profile '|cffffd000%s|r'?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        local target = data or (MyAutoRollerCharDB and MyAutoRollerCharDB.currentProfile)
        if target then
            DeleteProfile(target)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MYAUTOROLLER_RESET_PROFILE"] = {
    text = "Are you sure you want to reset all stat weights in profile '|cffffd000%s|r' to 0?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        ResetCurrentProfile()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Sub-Panel Enable Checkbox (Pass true to store per-character)
local cbWeightEnable = CreateCheckbox("MyAutoRoller_CB_WeightEnable", subPanel, "Enable Stat Weights Auto-Rolling", 20, -55, "statWeightEnabled", true)
local cbSubPassNotUpgrade = CreateCheckbox("MyAutoRoller_CB_SubPassNotUpgrade", subPanel, "Pass if Not an Upgrade (Instead of Greed)", 310, -55, "passIfNotUpgrade", false)

-- Profile Selection Bar
local profileLabel = subPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profileLabel:SetPoint("TOPLEFT", 20, -88)
profileLabel:SetText("Profile:")

profileDropdown = CreateFrame("Frame", "MyAutoRollerProfileDropdown", subPanel, "UIDropDownMenuTemplate")
profileDropdown:SetPoint("LEFT", profileLabel, "RIGHT", -12, -2)
UIDropDownMenu_SetWidth(profileDropdown, 120)
UIDropDownMenu_JustifyText(profileDropdown, "LEFT")

local function ProfileDropdown_Initialize(self, level)
    if not MyAutoRollerCharDB or not MyAutoRollerCharDB.profiles then return end

    local profileNames = {}
    for name in pairs(MyAutoRollerCharDB.profiles) do
        table.insert(profileNames, name)
    end
    table.sort(profileNames, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return string.lower(a) < string.lower(b)
    end)

    local cur = MyAutoRollerCharDB.currentProfile or "Default"
    for _, name in ipairs(profileNames) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = name
        info.value = name
        info.checked = (name == cur)
        info.func = function()
            SetActiveProfile(name)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end
UIDropDownMenu_Initialize(profileDropdown, ProfileDropdown_Initialize)

local function AddButtonTooltip(btn, titleText, descText)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(titleText, 1, 1, 1)
        if descText then
            GameTooltip:AddLine(descText, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local btnNew = CreateFrame("Button", "MyAutoRoller_Btn_NewProfile", subPanel, "UIPanelButtonTemplate")
btnNew:SetSize(52, 22)
btnNew:SetPoint("LEFT", profileDropdown, "RIGHT", -5, 2)
btnNew:SetText("+ New")
AddButtonTooltip(btnNew, "New Profile", "Create a new blank stat weight profile for another spec.")
btnNew:SetScript("OnClick", function()
    StaticPopup_Show("MYAUTOROLLER_NEW_PROFILE")
end)

local btnCopy = CreateFrame("Button", "MyAutoRoller_Btn_CopyProfile", subPanel, "UIPanelButtonTemplate")
btnCopy:SetSize(50, 22)
btnCopy:SetPoint("LEFT", btnNew, "RIGHT", 4, 0)
btnCopy:SetText("Copy")
AddButtonTooltip(btnCopy, "Copy Profile", "Duplicate the current profile's weights into a new profile.")
btnCopy:SetScript("OnClick", function()
    local cur = MyAutoRollerCharDB and MyAutoRollerCharDB.currentProfile or "Default"
    StaticPopup_Show("MYAUTOROLLER_COPY_PROFILE", cur)
end)

local btnDelete = CreateFrame("Button", "MyAutoRoller_Btn_DeleteProfile", subPanel, "UIPanelButtonTemplate")
btnDelete:SetSize(54, 22)
btnDelete:SetPoint("LEFT", btnCopy, "RIGHT", 4, 0)
btnDelete:SetText("Delete")
AddButtonTooltip(btnDelete, "Delete Profile", "Permanently remove the currently active profile.")
btnDelete:SetScript("OnClick", function()
    local cur = MyAutoRollerCharDB and MyAutoRollerCharDB.currentProfile or "Default"
    StaticPopup_Show("MYAUTOROLLER_DELETE_PROFILE", cur, nil, cur)
end)

local btnReset = CreateFrame("Button", "MyAutoRoller_Btn_ResetProfile", subPanel, "UIPanelButtonTemplate")
btnReset:SetSize(52, 22)
btnReset:SetPoint("LEFT", btnDelete, "RIGHT", 4, 0)
btnReset:SetText("Reset")
AddButtonTooltip(btnReset, "Reset Profile", "Reset all stat weights in the current profile back to 0.00.")
btnReset:SetScript("OnClick", function()
    local cur = MyAutoRollerCharDB and MyAutoRollerCharDB.currentProfile or "Default"
    StaticPopup_Show("MYAUTOROLLER_RESET_PROFILE", cur)
end)

-- ScrollFrame Container for Stat Controls
local scrollFrame = CreateFrame("ScrollFrame", "MyAutoRollerStatScrollFrame", subPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -118)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local scrollContent = CreateFrame("Frame", "MyAutoRollerStatScrollContent", scrollFrame)
scrollContent:SetSize(620, 640)
scrollFrame:SetScrollChild(scrollContent)

-- Column Headers inside ScrollContent (3 distinct columns)
local headerCol1 = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerCol1:SetPoint("TOPLEFT", 5, -5)
headerCol1:SetText("Physical DPS Stats")

local headerCol2 = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerCol2:SetPoint("TOPLEFT", 215, -5)
headerCol2:SetText("Tanking & Defense")

local headerCol3 = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerCol3:SetPoint("TOPLEFT", 425, -5)
headerCol3:SetText("Caster & Healer")

-- Sub-Panel Sliders and Stat Checkboxes inside ScrollContent
local sliders = {}
local editBoxes = {}
local statCheckboxes = {}

local function CreateStatControls(statList, startX)
    for i, conf in ipairs(statList) do
        local yPos = -30 - (i - 1) * 47

        -- Individual Stat Enable/Disable Checkbox
        local cbName = "MyAutoRoller_CB_StatEnable_" .. conf.key
        local cb = CreateFrame("CheckButton", cbName, scrollContent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", startX, yPos)
        cb:SetSize(20, 20)
        cb.statKey = conf.key
        statCheckboxes[conf.key] = cb

        cb:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            if MyAutoRollerCharDB and MyAutoRollerCharDB.statEnabled then
                MyAutoRollerCharDB.statEnabled[self.statKey] = isChecked
            end
        end)

        -- Stat Label
        local fs = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        fs:SetText(conf.label)

        local sliderName = "MyAutoRoller_Slider_" .. conf.key
        local slider = CreateFrame("Slider", sliderName, scrollContent, "OptionsSliderTemplate")
        slider:SetWidth(75)
        slider:SetHeight(14)
        slider:SetPoint("TOPLEFT", startX + 115, yPos - 10)
        slider:SetMinMaxValues(conf.min, conf.max)
        slider:SetValueStep(conf.step)
        if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
        slider.statKey = conf.key
        sliders[conf.key] = slider

        -- Hide standard slider title text to replace it with an interactive EditBox
        local standardText = _G[sliderName .. "Text"] or slider.Text
        if standardText then standardText:Hide() end

        local lowText = _G[sliderName .. "Low"] or slider.Low
        if lowText then lowText:SetText(string.format("%.2f", conf.min)) end
        local highText = _G[sliderName .. "High"] or slider.High
        if highText then highText:SetText(string.format("%.2f", conf.max)) end

        -- Create interactive EditBox above slider for typing exact custom values
        local ebName = "MyAutoRoller_EB_" .. conf.key
        local eb = CreateFrame("EditBox", ebName, scrollContent, "InputBoxTemplate")
        eb:SetSize(42, 18)
        eb:SetPoint("BOTTOM", slider, "TOP", 0, 3)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontHighlightSmall")
        eb:SetJustifyH("CENTER")
        eb.statKey = conf.key
        eb.minVal = conf.min
        eb.maxVal = conf.max
        editBoxes[conf.key] = eb

        slider:SetScript("OnValueChanged", function(self, value)
            value = tonumber(string.format("%.2f", value))
            if not isProgrammaticChange and editBoxes[self.statKey] then
                editBoxes[self.statKey]:SetText(string.format("%.2f", value))
            end
            if MyAutoRollerCharDB and MyAutoRollerCharDB.statWeights then
                MyAutoRollerCharDB.statWeights[self.statKey] = value
            end
        end)

        local function ApplyEditBoxValue(self)
            local txt = self:GetText()
            local num = tonumber(txt)
            if num then
                if num < self.minVal then num = self.minVal end
                if num > self.maxVal then num = self.maxVal end
                num = tonumber(string.format("%.2f", num))
                self:SetText(string.format("%.2f", num))
                
                isProgrammaticChange = true
                if sliders[self.statKey] then
                    sliders[self.statKey]:SetValue(num)
                end
                isProgrammaticChange = false

                if MyAutoRollerCharDB and MyAutoRollerCharDB.statWeights then
                    MyAutoRollerCharDB.statWeights[self.statKey] = num
                end
            else
                local currentVal = MyAutoRollerCharDB and MyAutoRollerCharDB.statWeights and MyAutoRollerCharDB.statWeights[self.statKey] or 0
                self:SetText(string.format("%.2f", currentVal))
            end
            self:ClearFocus()
        end

        eb:SetScript("OnEnterPressed", ApplyEditBoxValue)
        eb:SetScript("OnEditFocusLost", ApplyEditBoxValue)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    end
end

-- Generate stat controls for all 3 columns
CreateStatControls(PHYSICAL_DPS_STATS, 5)
CreateStatControls(TANK_STATS, 215)
CreateStatControls(CASTER_HEALER_STATS, 425)

-- Weapon Speed Filter Sub-panel Section
local speedHeader = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
speedHeader:SetPoint("TOPLEFT", 10, -512)
speedHeader:SetText("Weapon Speed Filters (Minimum Required Weapon Speed):")

local speedNote = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
speedNote:SetPoint("TOPLEFT", 10, -528)
speedNote:SetText("Weapons faster than these minimum speeds are automatically disqualified (0.00 = Any Speed)")

local function CreateSpeedControl(label, colCenterX, y, dbKey)
    local sliderName = "MyAutoRoller_SpeedSlider_" .. dbKey
    local slider = CreateFrame("Slider", sliderName, scrollContent, "OptionsSliderTemplate")
    slider:SetWidth(120)
    slider:SetHeight(14)
    slider:SetPoint("TOP", scrollContent, "TOPLEFT", colCenterX, y - 44)
    slider:SetMinMaxValues(0.0, 4.0)
    slider:SetValueStep(0.05)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

    local spdText = _G[sliderName .. "Text"] or slider.Text
    if spdText then spdText:Hide() end
    local spdLow = _G[sliderName .. "Low"] or slider.Low
    if spdLow then spdLow:SetText("0.00") end
    local spdHigh = _G[sliderName .. "High"] or slider.High
    if spdHigh then spdHigh:SetText("4.00") end

    local ebName = "MyAutoRoller_SpeedEB_" .. dbKey
    local eb = CreateFrame("EditBox", ebName, scrollContent, "InputBoxTemplate")
    eb:SetSize(44, 18)
    eb:SetPoint("BOTTOM", slider, "TOP", 0, 4)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontHighlightSmall")
    eb:SetJustifyH("CENTER")

    local fs = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("BOTTOM", eb, "TOP", 0, 4)
    fs:SetText(label)

    local isProgrammatic = false
    slider:SetScript("OnValueChanged", function(self, val)
        val = tonumber(string.format("%.2f", val))
        if not isProgrammatic and not isProgrammaticSpeed then
            eb:SetText(string.format("%.2f", val))
        end
        if MyAutoRollerCharDB then
            MyAutoRollerCharDB[dbKey] = val
            local curProf = MyAutoRollerCharDB.profiles and MyAutoRollerCharDB.profiles[MyAutoRollerCharDB.currentProfile]
            if curProf then
                curProf[dbKey] = val
            end
        end
    end)

    local function ApplySpeedEB(self)
        local num = tonumber(self:GetText())
        if num then
            num = math.max(0.0, math.min(4.0, num))
            num = tonumber(string.format("%.2f", num))
            self:SetText(string.format("%.2f", num))
            isProgrammatic = true
            slider:SetValue(num)
            isProgrammatic = false
            if MyAutoRollerCharDB then
                MyAutoRollerCharDB[dbKey] = num
                local curProf = MyAutoRollerCharDB.profiles and MyAutoRollerCharDB.profiles[MyAutoRollerCharDB.currentProfile]
                if curProf then
                    curProf[dbKey] = num
                end
            end
        else
            local cur = MyAutoRollerCharDB and MyAutoRollerCharDB[dbKey] or 0.00
            self:SetText(string.format("%.2f", cur))
        end
        self:ClearFocus()
    end

    eb:SetScript("OnEnterPressed", ApplySpeedEB)
    eb:SetScript("OnEditFocusLost", ApplySpeedEB)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    return slider, eb
end

local sliderSpeed1H, ebSpeed1H
local sliderSpeed2H, ebSpeed2H
local sliderSpeedRanged, ebSpeedRanged

sliderSpeed1H, ebSpeed1H = CreateSpeedControl("Min 1H/MH Speed:", 100, -550, "minWeaponSpeed1H")
sliderSpeed2H, ebSpeed2H = CreateSpeedControl("Min 2H Speed:", 300, -550, "minWeaponSpeed2H")
sliderSpeedRanged, ebSpeedRanged = CreateSpeedControl("Min Ranged Speed:", 500, -550, "minWeaponSpeedRanged")

UpdateSubPanelUI = function()
    if not MyAutoRollerCharDB then return end
    cbWeightEnable:SetChecked(MyAutoRollerCharDB.statWeightEnabled)
    if cbSubPassNotUpgrade and MyAutoRollerDB then
        cbSubPassNotUpgrade:SetChecked(MyAutoRollerDB.passIfNotUpgrade)
    end

    local curProfile = MyAutoRollerCharDB.currentProfile or "Default"
    if profileDropdown and UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(profileDropdown, curProfile)
        if UIDropDownMenu_SetSelectedValue then
            UIDropDownMenu_SetSelectedValue(profileDropdown, curProfile)
        end
    end

    isProgrammaticChange = true
    for key, slider in pairs(sliders) do
        local val = MyAutoRollerCharDB.statWeights and MyAutoRollerCharDB.statWeights[key] or 0
        slider:SetValue(val)
        if editBoxes[key] then
            editBoxes[key]:SetText(string.format("%.2f", val))
        end
    end
    isProgrammaticChange = false

    for key, cb in pairs(statCheckboxes) do
        local isEnabled = MyAutoRollerCharDB.statEnabled and MyAutoRollerCharDB.statEnabled[key]
        if isEnabled == nil then isEnabled = true end
        cb:SetChecked(isEnabled)
    end

    isProgrammaticSpeed = true
    if sliderSpeed1H and ebSpeed1H then
        local v1 = MyAutoRollerCharDB.minWeaponSpeed1H or 0.00
        sliderSpeed1H:SetValue(v1)
        ebSpeed1H:SetText(string.format("%.2f", v1))
    end
    if sliderSpeed2H and ebSpeed2H then
        local v2 = MyAutoRollerCharDB.minWeaponSpeed2H or 0.00
        sliderSpeed2H:SetValue(v2)
        ebSpeed2H:SetText(string.format("%.2f", v2))
    end
    if sliderSpeedRanged and ebSpeedRanged then
        local v3 = MyAutoRollerCharDB.minWeaponSpeedRanged or 0.00
        sliderSpeedRanged:SetValue(v3)
        ebSpeedRanged:SetText(string.format("%.2f", v3))
    end
    isProgrammaticSpeed = false
end
subPanel:SetScript("OnShow", UpdateSubPanelUI)

-- Category and Sub-category Registration
local category
local categoryID
local subcategoryID
if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    categoryID = category:GetID()

    local subcategory = Settings.RegisterCanvasLayoutSubcategory(category, subPanel, subPanel.name)
    Settings.RegisterAddOnCategory(subcategory)
    subcategoryID = subcategory:GetID()
else
    InterfaceOptions_AddCategory(panel)

    subPanel.parent = panel.name
    InterfaceOptions_AddCategory(subPanel)
end

-- Standalone Movable Options Window (avoids protected OpenSettingsPanel() taint/combat block)
local standaloneFrame = CreateFrame("Frame", "MyAutoRollerStandaloneFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
standaloneFrame:SetSize(680, 560)
standaloneFrame:SetPoint("CENTER")
standaloneFrame:SetFrameStrata("DIALOG")
standaloneFrame:SetToplevel(true)
standaloneFrame:SetClampedToScreen(true)
standaloneFrame:EnableMouse(true)
standaloneFrame:SetMovable(true)
standaloneFrame:RegisterForDrag("LeftButton")
standaloneFrame:SetScript("OnDragStart", standaloneFrame.StartMoving)
standaloneFrame:SetScript("OnDragStop", standaloneFrame.StopMovingOrSizing)
standaloneFrame:Hide()

if standaloneFrame.SetBackdrop then
    standaloneFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    standaloneFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
    standaloneFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
end

if UISpecialFrames then
    table.insert(UISpecialFrames, "MyAutoRollerStandaloneFrame")
end

local standaloneHeader = standaloneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
standaloneHeader:SetPoint("TOPLEFT", 16, -12)
standaloneHeader:SetText("|cff00ff00MyAutoRoller|r Configuration")

local standaloneCloseBtn = CreateFrame("Button", nil, standaloneFrame, "UIPanelCloseButton")
standaloneCloseBtn:SetPoint("TOPRIGHT", -4, -4)

local standaloneDivider = standaloneFrame:CreateTexture(nil, "ARTWORK")
standaloneDivider:SetHeight(1)
standaloneDivider:SetPoint("TOPLEFT", 8, -36)
standaloneDivider:SetPoint("TOPRIGHT", -8, -36)
standaloneDivider:SetColorTexture(0.3, 0.3, 0.35, 0.8)

local standaloneContent = CreateFrame("Frame", nil, standaloneFrame)
standaloneContent:SetPoint("TOPLEFT", 4, -38)
standaloneContent:SetPoint("BOTTOMRIGHT", -4, 6)

local tabGeneralBtn = CreateFrame("Button", "MyAutoRoller_Tab_General", standaloneFrame, "UIPanelButtonTemplate")
tabGeneralBtn:SetSize(130, 22)
tabGeneralBtn:SetPoint("TOPLEFT", 220, -9)
tabGeneralBtn:SetText("General Settings")

local tabWeightsBtn = CreateFrame("Button", "MyAutoRoller_Tab_Weights", standaloneFrame, "UIPanelButtonTemplate")
tabWeightsBtn:SetSize(130, 22)
tabWeightsBtn:SetPoint("LEFT", tabGeneralBtn, "RIGHT", 8, 0)
tabWeightsBtn:SetText("Stat Weights")

local savedPanelParent = nil
local savedSubPanelParent = nil
local activeStandaloneTab = "general"

local function SelectStandaloneTab(tabKey)
    activeStandaloneTab = (tabKey == "weights") and "weights" or "general"

    local pParent = panel:GetParent()
    if pParent and pParent ~= standaloneContent then
        savedPanelParent = pParent
    end
    local subParent = subPanel:GetParent()
    if subParent and subParent ~= standaloneContent then
        savedSubPanelParent = subParent
    end

    panel:SetParent(standaloneContent)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", standaloneContent, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMRIGHT", standaloneContent, "BOTTOMRIGHT", 0, 0)

    subPanel:SetParent(standaloneContent)
    subPanel:ClearAllPoints()
    subPanel:SetPoint("TOPLEFT", standaloneContent, "TOPLEFT", 0, 0)
    subPanel:SetPoint("BOTTOMRIGHT", standaloneContent, "BOTTOMRIGHT", 0, 0)

    if activeStandaloneTab == "weights" then
        panel:Hide()
        subPanel:Show()
        if UpdateSubPanelUI then UpdateSubPanelUI() end
        tabGeneralBtn:Enable()
        tabWeightsBtn:Disable()
    else
        subPanel:Hide()
        panel:Show()
        UpdateUI()
        tabGeneralBtn:Disable()
        tabWeightsBtn:Enable()
    end
end

tabGeneralBtn:SetScript("OnClick", function()
    SelectStandaloneTab("general")
end)

tabWeightsBtn:SetScript("OnClick", function()
    SelectStandaloneTab("weights")
end)

standaloneFrame:SetScript("OnHide", function()
    panel:Hide()
    subPanel:Hide()
    if savedPanelParent and savedPanelParent ~= standaloneContent then
        panel:SetParent(savedPanelParent)
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", 0, 0)
        panel:SetPoint("BOTTOMRIGHT", 0, 0)
    end
    if savedSubPanelParent and savedSubPanelParent ~= standaloneContent then
        subPanel:SetParent(savedSubPanelParent)
        subPanel:ClearAllPoints()
        subPanel:SetPoint("TOPLEFT", 0, 0)
        subPanel:SetPoint("BOTTOMRIGHT", 0, 0)
    end
end)

if SettingsPanel and SettingsPanel.HookScript then
    SettingsPanel:HookScript("OnShow", function()
        if standaloneFrame:IsShown() then
            standaloneFrame:Hide()
        end
    end)
end

local function OpenMyAutoRollerOptions(tabKey)
    if standaloneFrame:IsShown() and not tabKey then
        standaloneFrame:Hide()
        return
    end
    standaloneFrame:Show()
    SelectStandaloneTab(tabKey or activeStandaloneTab or "general")
end

SLASH_MYAUTOROLLER1 = "/mar"
SLASH_MYAUTOROLLER2 = "/myautoroller"
SlashCmdList["MYAUTOROLLER"] = function(msg)
    local rawMsg = msg and strtrim(msg) or ""
    local cmd, arg = string.match(rawMsg, "^(%S+)%s*(.-)$")
    cmd = cmd and string.lower(cmd) or ""
    arg = arg and strtrim(arg) or ""

    if cmd == "tracker" or cmd == "rolls" or cmd == "roll" then
        if MyAutoRollerLootTrackerFrame then
            local isShown = not MyAutoRollerLootTrackerFrame:IsShown()
            MyAutoRollerLootTrackerFrame:SetShown(isShown)
            if MyAutoRollerDB then MyAutoRollerDB.showLootTracker = isShown end
            if cbTracker then cbTracker:SetChecked(isShown) end
            if isShown and UpdateLootTrackerUI then UpdateLootTrackerUI() end
            print(string.format("|cff00ff00MyAutoRoller|r: Loot Tracker window is now %s.", isShown and "|cff00ff00Shown|r" or "|cffff0000Hidden|r"))
        end
        return
    end

    if cmd == "profile" or cmd == "spec" or cmd == "profiles" then
        if arg == "" or arg == "list" then
            print("|cff00ff00MyAutoRoller Stat Weight Profiles:|r")
            if MyAutoRollerCharDB and MyAutoRollerCharDB.profiles then
                local cur = MyAutoRollerCharDB.currentProfile or "Default"
                local profileNames = {}
                for name in pairs(MyAutoRollerCharDB.profiles) do
                    table.insert(profileNames, name)
                end
                table.sort(profileNames, function(a, b)
                    if a == "Default" then return true end
                    if b == "Default" then return false end
                    return string.lower(a) < string.lower(b)
                end)
                for _, name in ipairs(profileNames) do
                    if name == cur then
                        print(string.format("  |cff00ff00* %s (Active)|r", name))
                    else
                        print(string.format("    |cffffd000%s|r", name))
                    end
                end
            end
            print("Type |cff0070dd/mar profile <name>|r to switch profiles.")
            print("Type |cff0070dd/mar profile new <name>|r to create a new profile.")
            print("Type |cff0070dd/mar profile copy <name>|r to copy current profile.")
            print("Type |cff0070dd/mar profile delete <name>|r to delete a profile.")
            return
        end

        local subCmd, subArg = string.match(arg, "^(%S+)%s*(.-)$")
        subCmd = subCmd and string.lower(subCmd) or ""
        subArg = subArg and strtrim(subArg) or ""

        if subCmd == "new" and subArg ~= "" then
            CreateNewProfile(subArg, false)
            return
        elseif subCmd == "copy" and subArg ~= "" then
            CreateNewProfile(subArg, true)
            return
        elseif (subCmd == "delete" or subCmd == "del" or subCmd == "remove") and subArg ~= "" then
            DeleteProfile(subArg)
            return
        elseif subCmd == "reset" then
            ResetCurrentProfile()
            return
        end

        -- Direct switch by profile name
        local targetName = arg
        if SetActiveProfile(targetName) then
            return
        end

        -- Try case-insensitive lookup
        local lowerTarget = string.lower(targetName)
        local matchedName = nil
        for name in pairs(MyAutoRollerCharDB.profiles or {}) do
            if string.lower(name) == lowerTarget then
                matchedName = name
                break
            end
        end

        -- If still not found, try partial substring match
        if not matchedName then
            for name in pairs(MyAutoRollerCharDB.profiles or {}) do
                if string.find(string.lower(name), lowerTarget, 1, true) then
                    matchedName = name
                    break
                end
            end
        end

        if matchedName and SetActiveProfile(matchedName) then
            return
        end

        print(string.format("|cffff0000MyAutoRoller Error:|r Profile '|cffffd000%s|r' not found! Type |cff0070dd/mar profile|r to list all profiles.", targetName))
        return
    end

    if cmd == "help" then
        print("|cff00ff00MyAutoRoller Slash Commands:|r")
        print("  |cff0070dd/mar|r - Open configuration panel")
        print("  |cff0070dd/mar weights|r - Open Stat Weights panel")
        print("  |cff0070dd/mar tracker|r - Toggle Live Loot Tracker window")
        print("  |cff0070dd/mar profile|r - List all stat weight profiles")
        print("  |cff0070dd/mar profile <name>|r - Switch active profile (supports partial names)")
        print("  |cff0070dd/mar profile new <name>|r - Create new profile")
        print("  |cff0070dd/mar profile copy <name>|r - Copy current profile")
        print("  |cff0070dd/mar profile delete <name>|r - Delete a profile")
        print("  |cff0070dd/mar status|r or |cff0070dd/mar debug|r - Display live status and weights")
        return
    end

    if cmd == "weights" or cmd == "weight" or cmd == "stats" or cmd == "stat" then
        OpenMyAutoRollerOptions("weights")
        return
    end

    if cmd == "debug" or cmd == "status" then
        print("|cff00ff00MyAutoRoller Status Debug:|r")
        print(string.format("  - Addon Enabled: %s", tostring(MyAutoRollerDB and MyAutoRollerDB.enabled)))
        print(string.format("  - Stat Weights Enabled (this char): %s", tostring(MyAutoRollerCharDB and MyAutoRollerCharDB.statWeightEnabled)))
        print(string.format("  - Active Stat Weight Profile: |cffffd000%s|r", tostring(MyAutoRollerCharDB and MyAutoRollerCharDB.currentProfile or "Default")))
        print(string.format("  - BoE Safety (Skip BoE Need): %s", tostring(MyAutoRollerDB and MyAutoRollerDB.boeSafety)))
        print(string.format("  - BoP Safety (Skip BoP Manual): %s", tostring(MyAutoRollerDB and MyAutoRollerDB.bopSafety)))
        print(string.format("  - Pass if Not an Upgrade: %s", tostring(MyAutoRollerDB and MyAutoRollerDB.passIfNotUpgrade)))
        print(string.format("  - Loot Tracker Window: %s", tostring(MyAutoRollerDB and MyAutoRollerDB.showLootTracker)))
        
        local activeWeights = {}
        if MyAutoRollerCharDB and MyAutoRollerCharDB.statWeights then
            for k, v in pairs(MyAutoRollerCharDB.statWeights) do
                if v and v > 0 then
                    local label = string.gsub(k, "ITEM_MOD_", "")
                    label = string.gsub(label, "_SHORT", "")
                    table.insert(activeWeights, label .. "=" .. v)
                end
            end
        end
        print(string.format("  - Active Stat Weights (>0): %s", #activeWeights > 0 and table.concat(activeWeights, ", ") or "|cffff0000None set! (Set weights in /mar > Stat Weights)|r"))

        local disabledStats = {}
        if MyAutoRollerCharDB and MyAutoRollerCharDB.statEnabled then
            for k, isEnabled in pairs(MyAutoRollerCharDB.statEnabled) do
                if isEnabled == false then
                    local label = string.gsub(k, "ITEM_MOD_", "")
                    label = string.gsub(label, "_SHORT", "")
                    table.insert(disabledStats, label)
                end
            end
        end
        local profsList = {}
        local playerProfs = GetPlayerProfessions and GetPlayerProfessions() or {}
        for pName, pRank in pairs(playerProfs) do
            table.insert(profsList, pName .. " (" .. tostring(pRank) .. ")")
        end
        print(string.format("  - Need on Professions: %s", tostring(MyAutoRollerDB and MyAutoRollerDB.needProfessions)))
        print(string.format("  - Detected Professions: %s", #profsList > 0 and table.concat(profsList, ", ") or "|cffff0000None detected!|r"))
        return
    end

    OpenMyAutoRollerOptions()
end

-- Get player's active professions and their ranks
local function GetPlayerProfessions()
    local professions = {}
    if GetProfessions then
        local profs = { GetProfessions() }
        for _, index in ipairs(profs) do
            if index then
                local name, icon, skillLevel = GetProfessionInfo(index)
                if name then
                    professions[name] = skillLevel
                end
            end
        end
    end

    if GetNumSkillLines and GetSkillLineInfo then
        for i = 1, GetNumSkillLines() do
            local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
            if skillName and not isHeader then
                professions[skillName] = skillRank
            end
        end
    end
    return professions
end

local ALL_PROFESSIONS = {
    ["Leatherworking"] = true,
    ["Tailoring"] = true,
    ["Engineering"] = true,
    ["Blacksmithing"] = true,
    ["Cooking"] = true,
    ["Alchemy"] = true,
    ["First Aid"] = true,
    ["Enchanting"] = true,
    ["Fishing"] = true,
    ["Jewelcrafting"] = true,
    ["Inscription"] = true,
    ["Mining"] = true,
    ["Herbalism"] = true,
    ["Skinning"] = true
}

-- Helper to check if an RGB color tuple is red (unusable requirement in tooltip)
local function IsTooltipColorRed(r, g, b)
    return type(r) == "number" and type(g) == "number" and type(b) == "number" and r > 0.85 and g < 0.25 and b < 0.25
end

local function ExtractTooltipColorRGB(colorObj)
    if type(colorObj) ~= "table" then return nil, nil, nil end
    if type(colorObj.GetRGB) == "function" then
        local ok, r, g, b = pcall(colorObj.GetRGB, colorObj)
        if ok then return r, g, b end
    end
    return colorObj.r, colorObj.g, colorObj.b
end

-- Unified Tooltip Line Scanner (Supports both Classic/WoWF GameTooltip and Modern C_TooltipInfo)
local tooltipScanner
local function GetItemTooltipLines(itemLink)
    if not itemLink then return {} end
    local cleanLink = string.match(itemLink, "(item:[%d:-]+)") or itemLink
    local results = {}

    if CreateFrame then
        if not tooltipScanner then
            tooltipScanner = CreateFrame("GameTooltip", "MyAutoRollerScanTooltip", UIParent or WorldFrame, "GameTooltipTemplate")
        end
        tooltipScanner:Hide()
        tooltipScanner:SetOwner(UIParent or WorldFrame, "ANCHOR_NONE")
        tooltipScanner:ClearLines()
        pcall(tooltipScanner.SetHyperlink, tooltipScanner, cleanLink)

        local numLines = tooltipScanner:NumLines() or 0
        for i = 1, numLines do
            local leftObj = _G["MyAutoRollerScanTooltipTextLeft" .. i]
            local rightObj = _G["MyAutoRollerScanTooltipTextRight" .. i]
            local lText = leftObj and leftObj:GetText() or nil
            local rText = rightObj and rightObj:GetText() or nil
            local lr, lg, lb = nil, nil, nil
            local rr, rg, rb = nil, nil, nil
            if leftObj and leftObj.GetTextColor then lr, lg, lb = leftObj:GetTextColor() end
            if rightObj and rightObj.GetTextColor then rr, rg, rb = rightObj:GetTextColor() end
            if (lText and lText ~= "") or (rText and rText ~= "") then
                table.insert(results, {
                    left = lText,
                    right = rText,
                    leftRed = IsTooltipColorRed(lr, lg, lb),
                    rightRed = IsTooltipColorRed(rr, rg, rb),
                })
            end
        end
        tooltipScanner:Hide()
        if #results >= 2 then
            return results
        end
    end

    if _G.C_TooltipInfo and _G.C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(_G.C_TooltipInfo.GetHyperlink, cleanLink)
        if (not ok or not data or not data.lines or #data.lines == 0) and cleanLink ~= itemLink then
            ok, data = pcall(_G.C_TooltipInfo.GetHyperlink, itemLink)
        end
        if ok and data and data.lines and #data.lines > 0 then
            results = {}
            for _, line in ipairs(data.lines) do
                if _G.TooltipUtil and _G.TooltipUtil.SurfaceArgs then
                    pcall(_G.TooltipUtil.SurfaceArgs, line)
                end
                local lr, lg, lb = ExtractTooltipColorRGB(line.leftColor or line.color)
                local rr, rg, rb = ExtractTooltipColorRGB(line.rightColor)
                local lText = line.leftText or line.text
                local rText = line.rightText
                if (lText and lText ~= "") or (rText and rText ~= "") then
                    table.insert(results, {
                        left = lText,
                        right = rText,
                        leftRed = IsTooltipColorRed(lr, lg, lb),
                        rightRed = IsTooltipColorRed(rr, rg, rb),
                    })
                end
            end
            if #results > 0 then
                return results
            end
        end
    end

    return results
end

-- Helper to check if item requires a profession player possesses
local function ItemRequiresPlayerProfession(itemLink)
    if not itemLink then return false, nil, false, false end
    
    local playerProfs = GetPlayerProfessions()
    local knownString = ITEM_SPELL_KNOWN or "Already known"
    
    local isRecipe = false
    local requiredProf = nil
    local alreadyKnown = false
    
    local itemName, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemLink)
    if not itemName then itemName = GetItemInfo(itemLink) end

    if classID == 9 then
        isRecipe = true
    end
    
    -- Layer 1: Tooltip line scanning for requirement text or "Already Known"
    local scanLines = GetItemTooltipLines(itemLink)
    for i = 1, #scanLines do
        local leftText = scanLines[i].left
        if leftText then
            if string.find(leftText, knownString) or string.find(leftText, "Already Known") or string.find(leftText, "Already known") then
                alreadyKnown = true
            end
            
            -- Check for any profession requirement line
            for profName, _ in pairs(ALL_PROFESSIONS) do
                if string.find(leftText, profName) then
                    if string.find(leftText, "Requires") or string.find(leftText, "requires") or isRecipe then
                        isRecipe = true
                        requiredProf = profName
                        break
                    end
                end
            end
        end
    end

    -- Layer 2: WoW Subclass ID Mapping (ClassID 9 = Recipe)
    if isRecipe and not requiredProf then
        local recipeProfMap = {
            [1] = "Leatherworking",
            [2] = "Tailoring",
            [3] = "Engineering",
            [4] = "Blacksmithing",
            [5] = "Cooking",
            [6] = "Alchemy",
            [7] = "First Aid",
            [8] = "Enchanting",
            [9] = "Fishing",
            [10] = "Jewelcrafting",
            [11] = "Inscription"
        }
        requiredProf = recipeProfMap[subclassID]
    end

    -- Layer 3: Item Name Prefix Fallback Matching
    if not requiredProf and itemName then
        local prefixProfMap = {
            ["Schematic:"] = "Engineering",
            ["Formula:"] = "Enchanting",
            ["Plans:"] = "Blacksmithing",
            ["Design:"] = "Jewelcrafting",
            ["Technique:"] = "Inscription",
            ["Manual:"] = "First Aid",
            ["Guide:"] = "Fishing"
        }
        for prefix, profName in pairs(prefixProfMap) do
            if string.find(itemName, prefix) then
                isRecipe = true
                requiredProf = profName
                break
            end
        end

        if not requiredProf then
            if string.find(itemName, "Pattern:") then
                isRecipe = true
                if playerProfs["Tailoring"] then
                    requiredProf = "Tailoring"
                elseif playerProfs["Leatherworking"] then
                    requiredProf = "Leatherworking"
                else
                    requiredProf = "Tailoring / Leatherworking"
                end
            elseif string.find(itemName, "Recipe:") then
                isRecipe = true
                if playerProfs["Alchemy"] then
                    requiredProf = "Alchemy"
                elseif playerProfs["Cooking"] then
                    requiredProf = "Cooking"
                else
                    requiredProf = "Alchemy / Cooking"
                end
            end
        end
    end

    local playerHasProf = false
    if requiredProf then
        if playerProfs[requiredProf] then
            playerHasProf = true
        elseif string.find(requiredProf, "/") then
            for pName, _ in pairs(playerProfs) do
                if string.find(requiredProf, pName) then
                    playerHasProf = true
                    requiredProf = pName
                    break
                end
            end
        end
    end
    
    return isRecipe, requiredProf, alreadyKnown, playerHasProf
end

-- Slot mapping to character slots
local slotMapping = {
    ["INVTYPE_HEAD"] = { 1 },
    ["INVTYPE_NECK"] = { 2 },
    ["INVTYPE_SHOULDER"] = { 3 },
    ["INVTYPE_CHEST"] = { 5 },
    ["INVTYPE_ROBE"] = { 5 },
    ["INVTYPE_WAIST"] = { 6 },
    ["INVTYPE_LEGS"] = { 7 },
    ["INVTYPE_FEET"] = { 8 },
    ["INVTYPE_WRIST"] = { 9 },
    ["INVTYPE_HAND"] = { 10 },
    ["INVTYPE_FINGER"] = { 11, 12 },
    ["INVTYPE_TRINKET"] = { 13, 14 },
    ["INVTYPE_CLOAK"] = { 15 },
    ["INVTYPE_WEAPON"] = { 16, 17 },
    ["INVTYPE_2HWEAPON"] = { 16 },
    ["INVTYPE_WEAPONMAINHAND"] = { 16 },
    ["INVTYPE_WEAPONOFFHAND"] = { 17 },
    ["INVTYPE_SHIELD"] = { 17 },
    ["INVTYPE_HOLDABLE"] = { 17 },
    ["INVTYPE_RANGED"] = { 18 },
    ["INVTYPE_RANGEDRIGHT"] = { 18 },
    ["INVTYPE_THROWN"] = { 18 },
    ["INVTYPE_RELIC"] = { 18 },
}

-- Built-in Class Default Stat Weights (used ONLY when the player has not set any custom stat weights > 0 yet)
local CLASS_DEFAULT_WEIGHTS = {
    ["WARRIOR"] = {
        ["ITEM_MOD_STRENGTH_SHORT"] = 2.0,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 1.0,
        ["ITEM_MOD_AGILITY_SHORT"] = 1.2,
        ["ITEM_MOD_CRIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.8,
        ["ITEM_MOD_WEAPON_DPS_SHORT"] = 4.0,
        ["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"] = 0.5,
        ["ITEM_MOD_DODGE_RATING_SHORT"] = 0.5,
        ["ITEM_MOD_PARRY_RATING_SHORT"] = 0.5,
        ["ITEM_MOD_BLOCK_VALUE_SHORT"] = 0.5,
    },
    ["PALADIN"] = {
        ["ITEM_MOD_STRENGTH_SHORT"] = 2.0,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 1.0,
        ["ITEM_MOD_CRIT_RATING_SHORT"] = 1.4,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 1.4,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.8,
        ["ITEM_MOD_INTELLECT_SHORT"] = 0.6,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = 0.8,
        ["ITEM_MOD_HEALING_DONE_SHORT"] = 0.8,
        ["ITEM_MOD_WEAPON_DPS_SHORT"] = 3.5,
    },
    ["HUNTER"] = {
        ["ITEM_MOD_AGILITY_SHORT"] = 2.2,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 1.0,
        ["ITEM_MOD_CRIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.6,
        ["ITEM_MOD_INTELLECT_SHORT"] = 0.4,
        ["ITEM_MOD_WEAPON_RANGED_DPS_SHORT"] = 4.5,
    },
    ["ROGUE"] = {
        ["ITEM_MOD_AGILITY_SHORT"] = 2.2,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 1.0,
        ["ITEM_MOD_STRENGTH_SHORT"] = 1.1,
        ["ITEM_MOD_CRIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 1.6,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.6,
        ["ITEM_MOD_WEAPON_DPS_SHORT"] = 4.5,
    },
    ["PRIEST"] = {
        ["ITEM_MOD_INTELLECT_SHORT"] = 1.5,
        ["ITEM_MOD_SPIRIT_SHORT"] = 1.2,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = 1.5,
        ["ITEM_MOD_HEALING_DONE_SHORT"] = 1.5,
        ["ITEM_MOD_CRIT_SPELL_RATING_SHORT"] = 1.2,
        ["ITEM_MOD_POWER_REGEN0_SHORT"] = 2.0,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.5,
    },
    ["DEATHKNIGHT"] = {
        ["ITEM_MOD_STRENGTH_SHORT"] = 2.2,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 1.0,
        ["ITEM_MOD_CRIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 1.6,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.8,
        ["ITEM_MOD_WEAPON_DPS_SHORT"] = 4.5,
    },
    ["SHAMAN"] = {
        ["ITEM_MOD_STRENGTH_SHORT"] = 1.5,
        ["ITEM_MOD_AGILITY_SHORT"] = 1.5,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 1.0,
        ["ITEM_MOD_INTELLECT_SHORT"] = 1.2,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = 1.2,
        ["ITEM_MOD_HEALING_DONE_SHORT"] = 1.2,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.7,
        ["ITEM_MOD_WEAPON_DPS_SHORT"] = 3.5,
    },
    ["MAGE"] = {
        ["ITEM_MOD_INTELLECT_SHORT"] = 1.5,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = 1.8,
        ["ITEM_MOD_CRIT_SPELL_RATING_SHORT"] = 1.4,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_SPIRIT_SHORT"] = 0.8,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.5,
    },
    ["WARLOCK"] = {
        ["ITEM_MOD_INTELLECT_SHORT"] = 1.4,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = 1.8,
        ["ITEM_MOD_CRIT_SPELL_RATING_SHORT"] = 1.4,
        ["ITEM_MOD_HIT_RATING_SHORT"] = 1.5,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.8,
        ["ITEM_MOD_SPIRIT_SHORT"] = 0.6,
    },
    ["DRUID"] = {
        ["ITEM_MOD_AGILITY_SHORT"] = 1.8,
        ["ITEM_MOD_STRENGTH_SHORT"] = 1.5,
        ["ITEM_MOD_ATTACK_POWER_SHORT"] = 1.0,
        ["ITEM_MOD_INTELLECT_SHORT"] = 1.2,
        ["ITEM_MOD_SPIRIT_SHORT"] = 1.0,
        ["ITEM_MOD_SPELL_POWER_SHORT"] = 1.2,
        ["ITEM_MOD_HEALING_DONE_SHORT"] = 1.2,
        ["ITEM_MOD_STAMINA_SHORT"] = 0.8,
    },
}

-- Check if the player has configured at least one custom stat weight > 0 in their active profile
local function HasAnyCustomStatWeight()
    local dbWeights = MyAutoRollerCharDB and MyAutoRollerCharDB.statWeights
    if not dbWeights then return false end
    for _, v in pairs(dbWeights) do
        if type(v) == "number" and v > 0 then
            return true
        end
    end
    return false
end

-- Fetch the weight for a stat, including fallback mappings for TBC/Classic Era/WoWF
local function GetStatWeight(statKey)
    local dbWeights = MyAutoRollerCharDB and MyAutoRollerCharDB.statWeights
    if not HasAnyCustomStatWeight() then
        local _, pClass = UnitClass("player")
        dbWeights = (pClass and CLASS_DEFAULT_WEIGHTS[pClass]) or dbWeights
    end
    if not dbWeights then return 0 end

    if dbWeights[statKey] then
        return dbWeights[statKey]
    end

    -- Base stats fallbacks
    if statKey == "ITEM_MOD_STRENGTH" then return dbWeights["ITEM_MOD_STRENGTH_SHORT"] or 0 end
    if statKey == "ITEM_MOD_AGILITY" then return dbWeights["ITEM_MOD_AGILITY_SHORT"] or 0 end
    if statKey == "ITEM_MOD_STAMINA" then return dbWeights["ITEM_MOD_STAMINA_SHORT"] or 0 end
    if statKey == "ITEM_MOD_INTELLECT" then return dbWeights["ITEM_MOD_INTELLECT_SHORT"] or 0 end
    if statKey == "ITEM_MOD_SPIRIT" then return dbWeights["ITEM_MOD_SPIRIT_SHORT"] or 0 end

    -- Dedicated Healing Power mappings
    if statKey == "ITEM_MOD_HEALING_DONE" or statKey == "ITEM_MOD_HEALING_DONE_SHORT" or
       statKey == "ITEM_MOD_HEALING_STAT" or statKey == "ITEM_MOD_SPELL_HEALING_DONE" then
        local healWeight = dbWeights["ITEM_MOD_HEALING_DONE_SHORT"] or 0
        if healWeight > 0 then return healWeight end
        return dbWeights["ITEM_MOD_SPELL_POWER_SHORT"] or 0
    end

    -- Spell Power mappings
    if statKey == "ITEM_MOD_SPELL_POWER" or statKey == "ITEM_MOD_SPELL_POWER_SHORT" or
       statKey == "ITEM_MOD_SPELL_DAMAGE_DONE" or statKey == "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" then
        return dbWeights["ITEM_MOD_SPELL_POWER_SHORT"] or 0
    end

    -- Attack Power
    if statKey == "ITEM_MOD_ATTACK_POWER" or statKey == "ITEM_MOD_ATTACK_POWER_SHORT" or string.find(statKey, "ATTACK_POWER") then
        return dbWeights["ITEM_MOD_ATTACK_POWER_SHORT"] or 0
    end

    -- Spell Crit Rating
    if statKey == "ITEM_MOD_CRIT_SPELL_RATING" or statKey == "ITEM_MOD_CRIT_SPELL_RATING_SHORT" or string.find(statKey, "CRIT_SPELL") or string.find(statKey, "SPELL_CRIT") then
        local spCritWeight = dbWeights["ITEM_MOD_CRIT_SPELL_RATING_SHORT"] or 0
        if spCritWeight > 0 then return spCritWeight end
        return dbWeights["ITEM_MOD_CRIT_RATING_SHORT"] or 0
    end

    -- Critical Strike / Melee Crit
    if string.find(statKey, "CRIT") then
        return dbWeights["ITEM_MOD_CRIT_RATING_SHORT"] or 0
    end

    -- Hit Rating
    if string.find(statKey, "HIT") then
        return dbWeights["ITEM_MOD_HIT_RATING_SHORT"] or 0
    end

    -- Spell Haste Rating
    if statKey == "ITEM_MOD_HASTE_SPELL_RATING" or statKey == "ITEM_MOD_HASTE_SPELL_RATING_SHORT" or string.find(statKey, "HASTE_SPELL") then
        local spHasteWeight = dbWeights["ITEM_MOD_HASTE_SPELL_RATING_SHORT"] or 0
        if spHasteWeight > 0 then return spHasteWeight end
        return dbWeights["ITEM_MOD_HASTE_RATING_SHORT"] or 0
    end

    -- Haste Rating / Melee Haste
    if string.find(statKey, "HASTE") then
        return dbWeights["ITEM_MOD_HASTE_RATING_SHORT"] or 0
    end

    -- Armor Penetration
    if string.find(statKey, "ARMOR_PENETRATION") then
        return dbWeights["ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT"] or 0
    end

    -- Expertise Rating
    if statKey == "ITEM_MOD_EXPERTISE_RATING" or statKey == "ITEM_MOD_EXPERTISE_RATING_SHORT" or string.find(statKey, "EXPERTISE") then
        return dbWeights["ITEM_MOD_EXPERTISE_RATING_SHORT"] or 0
    end

    -- Spell Penetration
    if string.find(statKey, "SPELL_PENETRATION") then
        return dbWeights["ITEM_MOD_SPELL_PENETRATION_SHORT"] or 0
    end

    -- Defense Rating
    if string.find(statKey, "DEFENSE") then
        return dbWeights["ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"] or 0
    end

    -- Dodge Rating
    if string.find(statKey, "DODGE") then
        return dbWeights["ITEM_MOD_DODGE_RATING_SHORT"] or 0
    end

    -- Parry Rating
    if string.find(statKey, "PARRY") then
        return dbWeights["ITEM_MOD_PARRY_RATING_SHORT"] or 0
    end

    -- Block Rating
    if string.find(statKey, "BLOCK_RATING") then
        return dbWeights["ITEM_MOD_BLOCK_RATING_SHORT"] or 0
    end

    -- Block Value
    if string.find(statKey, "BLOCK_VALUE") then
        return dbWeights["ITEM_MOD_BLOCK_VALUE_SHORT"] or 0
    end

    -- Bonus Armor
    if statKey == "ITEM_MOD_ARMOR_SHORT" or statKey == "ITEM_MOD_ARMOR" then
        return dbWeights["ITEM_MOD_ARMOR_SHORT"] or 0
    end

    -- Ranged Weapon DPS
    if statKey == "ITEM_MOD_WEAPON_RANGED_DPS" or statKey == "ITEM_MOD_WEAPON_RANGED_DPS_SHORT" or string.find(statKey, "RANGED_DPS") then
        local rDpsWeight = dbWeights["ITEM_MOD_WEAPON_RANGED_DPS_SHORT"] or 0
        if rDpsWeight > 0 then return rDpsWeight end
        return dbWeights["ITEM_MOD_WEAPON_DPS_SHORT"] or 0
    end

    -- Weapon DPS (Melee)
    if statKey == "ITEM_MOD_WEAPON_DPS_SHORT" or string.find(statKey, "WEAPON_DPS") then
        return dbWeights["ITEM_MOD_WEAPON_DPS_SHORT"] or 0
    end

    -- Resilience
    if string.find(statKey, "RESILIENCE") then
        return dbWeights["ITEM_MOD_RESILIENCE_RATING_SHORT"] or 0
    end

    -- MP5 / Mana Regeneration
    if string.find(statKey, "POWER_REGEN") or string.find(statKey, "MANA_REGEN") then
        return dbWeights["ITEM_MOD_POWER_REGEN0_SHORT"] or 0
    end

    return 0
end

-- Hidden GameTooltip / C_TooltipInfo scanner for parsing random suffix stats ("of the Bear", "of the Eagle", etc.)
local function GetItemScoreFromTooltip(itemLink)
    if not itemLink then return 0 end

    local scanLines = GetItemTooltipLines(itemLink)
    if #scanLines == 0 then return 0 end

    local score = 0

    for i = 2, #scanLines do
        local text = scanLines[i].left
        if text and text ~= "" then
            -- Stop at item set bonus headers ("Defias Leather (0/5)") so set bonuses are not counted as single-item stats
            if string.find(text, "%(%d+/%d+%)%s*$") then
                break
            end
            if not string.find(text, "^%(%d+%)%s*Set:") then
                -- Check for split "+X Healing Spells and +Y Damage Spells" or "+X Healing and +Y Damage" lines
                local healAmount, dmgAmount = string.match(text, "%+(%d+)%s+Healing.-%+(%d+)%s+Damage")
                if not healAmount then
                    healAmount, dmgAmount = string.match(text, "%+(%d+)%s+Healing Spells and %+(%d+)%s+Damage Spells")
                end

                if healAmount and dmgAmount then
                    local hVal = tonumber(healAmount) or 0
                    local dVal = tonumber(dmgAmount) or 0
                    local healWeight = GetStatWeight("ITEM_MOD_HEALING_DONE_SHORT")
                    local dmgWeight = GetStatWeight("ITEM_MOD_SPELL_POWER_SHORT")
                    -- Take max of healing vs damage benefit instead of double-counting both on the same line!
                    score = score + math.max(hVal * healWeight, dVal * dmgWeight)
                else
                    -- Check +X Stat patterns (e.g. +15 Strength, +12 Agility, +10 Stamina, +8 Intellect, +6 Spirit)
                    local val, stat = string.match(text, "%+(%d+)%s+([%a%s]+)")
                    if val and stat then
                        val = tonumber(val) or 0
                        if string.find(stat, "Strength") then
                            score = score + val * GetStatWeight("ITEM_MOD_STRENGTH_SHORT")
                        elseif string.find(stat, "Agility") then
                            score = score + val * GetStatWeight("ITEM_MOD_AGILITY_SHORT")
                        elseif string.find(stat, "Stamina") then
                            score = score + val * GetStatWeight("ITEM_MOD_STAMINA_SHORT")
                        elseif string.find(stat, "Intellect") then
                            score = score + val * GetStatWeight("ITEM_MOD_INTELLECT_SHORT")
                        elseif string.find(stat, "Spirit") then
                            score = score + val * GetStatWeight("ITEM_MOD_SPIRIT_SHORT")
                        elseif string.find(stat, "Attack Power") then
                            score = score + val * GetStatWeight("ITEM_MOD_ATTACK_POWER_SHORT")
                        elseif string.find(stat, "Spell Power") or string.find(stat, "Spell Damage") then
                            score = score + val * GetStatWeight("ITEM_MOD_SPELL_POWER_SHORT")
                        elseif string.find(stat, "Healing") then
                            score = score + val * GetStatWeight("ITEM_MOD_HEALING_DONE_SHORT")
                        elseif string.find(stat, "Defense") then
                            score = score + val * GetStatWeight("ITEM_MOD_DEFENSE_SKILL_RATING_SHORT")
                        end
                    else
                        -- Check Equip / Green effect lines
                        local hitVal = string.match(text, "hit rating by (%d+)") or string.match(text, "hit by (%d+)") or string.match(text, "hit with spells by (%d+)")
                        if hitVal then
                            score = score + (tonumber(hitVal) or 0) * GetStatWeight("ITEM_MOD_HIT_RATING_SHORT")
                        end

                        local spHasteVal = string.match(text, "spell haste rating by (%d+)") or string.match(text, "spell haste by (%d+)")
                        if spHasteVal then
                            score = score + (tonumber(spHasteVal) or 0) * GetStatWeight("ITEM_MOD_HASTE_SPELL_RATING_SHORT")
                        else
                            local hasteVal = string.match(text, "haste rating by (%d+)") or string.match(text, "haste by (%d+)")
                            if hasteVal then
                                score = score + (tonumber(hasteVal) or 0) * GetStatWeight("ITEM_MOD_HASTE_RATING_SHORT")
                            end
                        end

                        local arpVal = string.match(text, "armor penetration rating by (%d+)") or string.match(text, "armor penetration by (%d+)")
                        if arpVal then
                            score = score + (tonumber(arpVal) or 0) * GetStatWeight("ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT")
                        end

                        local expVal = string.match(text, "expertise rating by (%d+)") or string.match(text, "expertise by (%d+)")
                        if expVal then
                            score = score + (tonumber(expVal) or 0) * GetStatWeight("ITEM_MOD_EXPERTISE_RATING_SHORT")
                        end

                        local spPenVal = string.match(text, "spell penetration by (%d+)")
                        if spPenVal then
                            score = score + (tonumber(spPenVal) or 0) * GetStatWeight("ITEM_MOD_SPELL_PENETRATION_SHORT")
                        end

                        local defVal = string.match(text, "defense rating by (%d+)") or string.match(text, "defense by (%d+)") or string.match(text, "Increased Defense %+(%d+)")
                        if defVal then
                            score = score + (tonumber(defVal) or 0) * GetStatWeight("ITEM_MOD_DEFENSE_SKILL_RATING_SHORT")
                        end

                        local dodgeVal = string.match(text, "dodge rating by (%d+)") or string.match(text, "dodge by (%d+)") or string.match(text, "dodge an attack by (%d+)")
                        if dodgeVal then
                            score = score + (tonumber(dodgeVal) or 0) * GetStatWeight("ITEM_MOD_DODGE_RATING_SHORT")
                        end

                        local parryVal = string.match(text, "parry rating by (%d+)") or string.match(text, "parry by (%d+)") or string.match(text, "parry an attack by (%d+)")
                        if parryVal then
                            score = score + (tonumber(parryVal) or 0) * GetStatWeight("ITEM_MOD_PARRY_RATING_SHORT")
                        end

                        local blockRVal = string.match(text, "block rating by (%d+)") or string.match(text, "block an attack by (%d+)")
                        if blockRVal then
                            score = score + (tonumber(blockRVal) or 0) * GetStatWeight("ITEM_MOD_BLOCK_RATING_SHORT")
                        end

                        local blockVVal = string.match(text, "block value.-by (%d+)") or string.match(text, "increases.-block value by (%d+)")
                        if blockVVal then
                            score = score + (tonumber(blockVVal) or 0) * GetStatWeight("ITEM_MOD_BLOCK_VALUE_SHORT")
                        end

                        local resVal = string.match(text, "resilience rating by (%d+)") or string.match(text, "resilience by (%d+)")
                        if resVal then
                            score = score + (tonumber(resVal) or 0) * GetStatWeight("ITEM_MOD_RESILIENCE_RATING_SHORT")
                        end

                        local spCritVal = string.match(text, "spell critical strike rating by (%d+)") or string.match(text, "spell critical strike by (%d+)") or string.match(text, "spell critical by (%d+)") or string.match(text, "critical strike with spells by (%d+)")
                        if spCritVal then
                            score = score + (tonumber(spCritVal) or 0) * GetStatWeight("ITEM_MOD_CRIT_SPELL_RATING_SHORT")
                        else
                            local critVal = string.match(text, "critical strike rating by (%d+)") or string.match(text, "critical strike by (%d+)")
                            if critVal then
                                score = score + (tonumber(critVal) or 0) * GetStatWeight("ITEM_MOD_CRIT_RATING_SHORT")
                            end
                        end

                        local spVal = string.match(text, "spell power by (%d+)") or string.match(text, "spell damage by up to (%d+)") or string.match(text, "spell damage and healing by up to (%d+)") or string.match(text, "damage and healing done by magical spells and effects by up to (%d+)") or string.match(text, "damage done by .-spells and effects by up to (%d+)")
                        if spVal then
                            score = score + (tonumber(spVal) or 0) * GetStatWeight("ITEM_MOD_SPELL_POWER_SHORT")
                        end

                        local healVal = string.match(text, "healing done by up to (%d+)") or string.match(text, "healing spells by up to (%d+)") or string.match(text, "healing done by spells and effects by up to (%d+)")
                        if healVal then
                            score = score + (tonumber(healVal) or 0) * GetStatWeight("ITEM_MOD_HEALING_DONE_SHORT")
                        end

                        local apVal = string.match(text, "Attack Power by (%d+)") or string.match(text, "attack power by (%d+)")
                        if apVal then
                            score = score + (tonumber(apVal) or 0) * GetStatWeight("ITEM_MOD_ATTACK_POWER_SHORT")
                        end

                        local mp5Val = string.match(text, "(%d+) mana per 5 sec") or string.match(text, "(%d+) mana every 5 sec")
                        if mp5Val then
                            score = score + (tonumber(mp5Val) or 0) * GetStatWeight("ITEM_MOD_POWER_REGEN0_SHORT")
                        end
                    end
                end
            end
        end
    end

    return score
end

-- Calculate total point score of an item based on stat weights
local function GetItemScore(itemLink)
    if not itemLink then return 0 end
    local GetStats = GetItemStats or (C_Item and C_Item.GetItemStats)
    
    local score = 0
    if GetStats then
        local stats = GetStats(itemLink)
        if stats then
            local healVal = stats["ITEM_MOD_HEALING_DONE"] or stats["ITEM_MOD_HEALING_DONE_SHORT"] or stats["ITEM_MOD_HEALING_STAT"] or stats["ITEM_MOD_SPELL_HEALING_DONE"]
            local dmgVal = stats["ITEM_MOD_SPELL_DAMAGE_DONE"] or stats["ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"]

            -- Handle split "+X Healing and +Y Damage" stats to prevent double counting
            if (healVal and healVal > 0) and (dmgVal and dmgVal > 0) then
                local healWeight = GetStatWeight("ITEM_MOD_HEALING_DONE_SHORT")
                local dmgWeight = GetStatWeight("ITEM_MOD_SPELL_POWER_SHORT")
                
                score = score + math.max(healVal * healWeight, dmgVal * dmgWeight)

                for statKey, statValue in pairs(stats) do
                    if statKey ~= "ITEM_MOD_HEALING_DONE" and statKey ~= "ITEM_MOD_HEALING_DONE_SHORT" and 
                       statKey ~= "ITEM_MOD_HEALING_STAT" and statKey ~= "ITEM_MOD_SPELL_HEALING_DONE" and
                       statKey ~= "ITEM_MOD_SPELL_DAMAGE_DONE" and statKey ~= "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" then
                        local weight = GetStatWeight(statKey)
                        score = score + (statValue * weight)
                    end
                end
            else
                for statKey, statValue in pairs(stats) do
                    local weight = GetStatWeight(statKey)
                    score = score + (statValue * weight)
                end
            end
        end
    end

    -- Fallback/supplement to tooltip scanning for random suffix items ("of the Eagle", "of the Bear", etc.)
    if score == 0 then
        score = GetItemScoreFromTooltip(itemLink)
    end

    -- Weapon DPS calculation (Melee & Ranged Weapons)
    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemEquipLoc or itemEquipLoc == "" then
        local _, _, _, itemEquipLocInstant = GetItemInfoInstant(itemLink)
        itemEquipLoc = itemEquipLocInstant
    end

    local isRanged = itemEquipLoc and (string.find(itemEquipLoc, "RANGED") or itemEquipLoc == "INVTYPE_THROWN")
    local isMeleeWpn = itemEquipLoc and (string.find(itemEquipLoc, "WEAPON") or itemEquipLoc == "INVTYPE_2HWEAPON")
    
    local dpsWeight = 0
    if isRanged then
        dpsWeight = GetStatWeight("ITEM_MOD_WEAPON_RANGED_DPS_SHORT")
    elseif isMeleeWpn then
        dpsWeight = GetStatWeight("ITEM_MOD_WEAPON_DPS_SHORT")
    end

    if dpsWeight > 0 then
        local scanLines = GetItemTooltipLines(itemLink)
        for i = 2, #scanLines do
            local txt = scanLines[i].left
            if txt then
                local dpsStr = string.match(txt, "%((%d+%.?%d*) damage per second%)") or 
                               string.match(txt, "%((%d+%.?%d*) damage per sec%)") or
                               string.match(txt, "(%d+%.?%d*) damage per second") or
                               string.match(txt, "(%d+%.?%d*) dps")
                if dpsStr then
                    local dps = tonumber(dpsStr) or 0
                    score = score + (dps * dpsWeight)
                    break
                end
            end
        end
    end

    return score
end

-- Helper to compute equipped score for a given equip location, handling 2H vs 1H weapon slot edge cases
local function GetEquippedStatsForLocation(itemEquipLoc, targetItemLink)
    local slots = slotMapping[itemEquipLoc]
    if not slots then return 999999, false, false end

    local mainHandLink = GetInventoryItemLink("player", 16)
    local mainHandEquipLoc = nil
    if mainHandLink then
        local _, _, _, _, _, _, _, _, mhLoc = GetItemInfo(mainHandLink)
        if not mhLoc or mhLoc == "" then
            local _, _, _, mhLocInstant = GetItemInfoInstant(mainHandLink)
            mhLoc = mhLocInstant
        end
        mainHandEquipLoc = mhLoc
    end

    -- Case 1: Target item is a 1H/OH weapon/shield, but player is currently wielding a 2H weapon in Slot 16
    if mainHandLink and mainHandEquipLoc == "INVTYPE_2HWEAPON" then
        if itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or 
           itemEquipLoc == "INVTYPE_WEAPONOFFHAND" or itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_HOLDABLE" then
            local eqScore = GetItemScore(mainHandLink)
            local isEquipped = false
            if targetItemLink then
                local eqID = GetItemInfoInstant(mainHandLink)
                local targetID = GetItemInfoInstant(targetItemLink)
                if eqID == targetID then isEquipped = true end
            end
            return eqScore, true, isEquipped
        end
    end

    -- Case 2: Target item is a 2H weapon, but player is currently dual-wielding 1H/OH weapons
    if itemEquipLoc == "INVTYPE_2HWEAPON" then
        local offHandLink = GetInventoryItemLink("player", 17)
        if mainHandLink and offHandLink then
            local totalEquippedScore = GetItemScore(mainHandLink) + GetItemScore(offHandLink)
            local isEquipped = false
            if targetItemLink then
                local eqID = GetItemInfoInstant(mainHandLink)
                local targetID = GetItemInfoInstant(targetItemLink)
                if eqID == targetID then isEquipped = true end
            end
            return totalEquippedScore, true, isEquipped
        end
    end

    -- Standard slot comparison (Armor, Rings, Trinkets, or matching weapon slots)
    local minEquippedScore = 999999
    local hasEquippedItem = false
    local isEquipped = false
    local targetID = targetItemLink and GetItemInfoInstant(targetItemLink)

    for _, slotID in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotID)
        if equippedLink then
            local eqScore = GetItemScore(equippedLink)
            if eqScore < minEquippedScore then
                minEquippedScore = eqScore
            end
            hasEquippedItem = true
            if targetID and GetItemInfoInstant(equippedLink) == targetID then
                isEquipped = true
            end
        else
            minEquippedScore = 0
            hasEquippedItem = true
        end
    end

    return minEquippedScore, hasEquippedItem, isEquipped
end

-- Map API stat key to config key and display label
local function GetMappedStatKey(statKey)
    if statKey == "ITEM_MOD_STRENGTH" or statKey == "ITEM_MOD_STRENGTH_SHORT" then return "ITEM_MOD_STRENGTH_SHORT", "Strength" end
    if statKey == "ITEM_MOD_AGILITY" or statKey == "ITEM_MOD_AGILITY_SHORT" then return "ITEM_MOD_AGILITY_SHORT", "Agility" end
    if statKey == "ITEM_MOD_STAMINA" or statKey == "ITEM_MOD_STAMINA_SHORT" then return "ITEM_MOD_STAMINA_SHORT", "Stamina" end
    if statKey == "ITEM_MOD_INTELLECT" or statKey == "ITEM_MOD_INTELLECT_SHORT" then return "ITEM_MOD_INTELLECT_SHORT", "Intellect" end
    if statKey == "ITEM_MOD_SPIRIT" or statKey == "ITEM_MOD_SPIRIT_SHORT" then return "ITEM_MOD_SPIRIT_SHORT", "Spirit" end
    if statKey == "ITEM_MOD_HEALING_DONE" or statKey == "ITEM_MOD_HEALING_DONE_SHORT" or statKey == "ITEM_MOD_HEALING_STAT" or statKey == "ITEM_MOD_SPELL_HEALING_DONE" then return "ITEM_MOD_HEALING_DONE_SHORT", "Healing Power" end
    if statKey == "ITEM_MOD_SPELL_POWER" or statKey == "ITEM_MOD_SPELL_POWER_SHORT" or statKey == "ITEM_MOD_SPELL_DAMAGE_DONE" or statKey == "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" then return "ITEM_MOD_SPELL_POWER_SHORT", "Spell Power" end
    if statKey == "ITEM_MOD_ATTACK_POWER" or statKey == "ITEM_MOD_ATTACK_POWER_SHORT" then return "ITEM_MOD_ATTACK_POWER_SHORT", "Attack Power" end
    if statKey == "ITEM_MOD_WEAPON_RANGED_DPS" or statKey == "ITEM_MOD_WEAPON_RANGED_DPS_SHORT" or string.find(statKey, "RANGED_DPS") then return "ITEM_MOD_WEAPON_RANGED_DPS_SHORT", "Ranged DPS" end
    if statKey == "ITEM_MOD_WEAPON_DPS" or statKey == "ITEM_MOD_WEAPON_DPS_SHORT" then return "ITEM_MOD_WEAPON_DPS_SHORT", "Melee Weapon DPS" end
    if statKey == "ITEM_MOD_EXPERTISE_RATING" or statKey == "ITEM_MOD_EXPERTISE_RATING_SHORT" or string.find(statKey, "EXPERTISE") then return "ITEM_MOD_EXPERTISE_RATING_SHORT", "Expertise" end
    if string.find(statKey, "CRIT_SPELL") or string.find(statKey, "SPELL_CRIT") or statKey == "ITEM_MOD_CRIT_SPELL_RATING_SHORT" then return "ITEM_MOD_CRIT_SPELL_RATING_SHORT", "Spell Crit" end
    if string.find(statKey, "CRIT") then return "ITEM_MOD_CRIT_RATING_SHORT", "Melee Crit" end
    if string.find(statKey, "POWER_REGEN") or string.find(statKey, "MANA_REGEN") then return "ITEM_MOD_POWER_REGEN0_SHORT", "MP5" end
    return nil, nil
end

-- Helper to extract weapon speed from item tooltip scanner
local function GetItemWeaponSpeed(itemLink)
    if not itemLink then return nil end
    local scanLines = GetItemTooltipLines(itemLink)
    for i = 1, #scanLines do
        local rightText = scanLines[i].right
        local leftText = scanLines[i].left

        if rightText then
            local speed = string.match(rightText, "Speed%s+(%d+%.?%d*)")
            if speed then return tonumber(speed) end
        end
        if leftText then
            local speed = string.match(leftText, "Speed%s+(%d+%.?%d*)")
            if speed then return tonumber(speed) end
        end
    end
    return nil
end

-- Check if an item contains any stat that is toggled OFF (disabled)
local function HasDisqualifiedStat(itemLink)
    if not itemLink or not MyAutoRollerCharDB then return false, nil end

    -- Check Weapon Speed Filters (Min 1H Speed / Min 2H Speed / Min Ranged Speed)
    local _, _, _, itemEquipLoc, _, classID = GetItemInfoInstant(itemLink)
    if classID == 2 then
        local speed = GetItemWeaponSpeed(itemLink)
        if speed then
            if itemEquipLoc == "INVTYPE_2HWEAPON" then
                local min2H = MyAutoRollerCharDB.minWeaponSpeed2H or 0
                if min2H > 0 and speed < min2H then
                    return true, string.format("Speed %.2f < Min 2H Speed %.2f", speed, min2H)
                end
            elseif itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then
                local min1H = MyAutoRollerCharDB.minWeaponSpeed1H or 0
                if min1H > 0 and speed < min1H then
                    return true, string.format("Speed %.2f < Min 1H Speed %.2f", speed, min1H)
                end
            elseif itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc == "INVTYPE_THROWN" then
                local minRanged = MyAutoRollerCharDB.minWeaponSpeedRanged or 0
                if minRanged > 0 and speed < minRanged then
                    return true, string.format("Speed %.2f < Min Ranged Speed %.2f", speed, minRanged)
                end
            end
        end
    end

    if not MyAutoRollerCharDB.statEnabled then return false, nil end

    local GetStats = GetItemStats or (C_Item and C_Item.GetItemStats)
    if GetStats then
        local stats = GetStats(itemLink)
        if stats then
            for statKey, statVal in pairs(stats) do
                if statVal and statVal > 0 then
                    local mappedKey, label = GetMappedStatKey(statKey)
                    if mappedKey and MyAutoRollerCharDB.statEnabled[mappedKey] == false then
                        return true, label
                    end
                end
            end
        end
    end

    local scanLines = GetItemTooltipLines(itemLink)
    if #scanLines > 0 then
        for i = 2, #scanLines do
            local text = scanLines[i].left
            if text and text ~= "" then
                if string.find(text, "%(%d+/%d+%)%s*$") then
                    break
                end
                if not string.find(text, "^%(%d+%)%s*Set:") then
                    local val, stat = string.match(text, "%+(%d+)%s+([%a%s]+)")
                    if val and stat then
                        if string.find(stat, "Strength") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_STRENGTH_SHORT"] == false then
                            return true, "Strength"
                        elseif string.find(stat, "Agility") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_AGILITY_SHORT"] == false then
                            return true, "Agility"
                        elseif string.find(stat, "Stamina") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_STAMINA_SHORT"] == false then
                            return true, "Stamina"
                        elseif string.find(stat, "Intellect") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_INTELLECT_SHORT"] == false then
                            return true, "Intellect"
                        elseif string.find(stat, "Spirit") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_SPIRIT_SHORT"] == false then
                            return true, "Spirit"
                        elseif string.find(stat, "Attack Power") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_ATTACK_POWER_SHORT"] == false then
                            return true, "Attack Power"
                        elseif string.find(stat, "Spell Power") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_SPELL_POWER_SHORT"] == false then
                            return true, "Spell Power"
                        elseif string.find(stat, "Healing") and MyAutoRollerCharDB.statEnabled["ITEM_MOD_HEALING_DONE_SHORT"] == false then
                            return true, "Healing Power"
                        end
                    end
                end
            end
        end
    end

    return false, nil
end

local _, playerClass = UnitClass("player")

-- Armor Subclass IDs (ClassID 4):
-- 0 = Misc, 1 = Cloth, 2 = Leather, 3 = Mail, 4 = Plate, 6 = Shield, 7 = Libram, 8 = Idol, 9 = Totem, 10 = Sigil
local ARMOR_NAME_TO_SUBCLASS = {
    ["Cloth"] = 1,
    ["Leather"] = 2,
    ["Mail"] = 3,
    ["Plate"] = 4,
    ["Shield"] = 6,
    ["Libram"] = 7,
    ["Idol"] = 8,
    ["Totem"] = 9,
    ["Sigil"] = 10,
}

local SUBCLASS_TO_ARMOR_NAME = {
    [1] = "Cloth",
    [2] = "Leather",
    [3] = "Mail",
    [4] = "Plate",
    [6] = "Shield",
    [7] = "Libram",
    [8] = "Idol",
    [9] = "Totem",
    [10] = "Sigil",
}

local ARMOR_SLOTS_REQUIRING_CLASS_ARMOR_TYPE = {
    ["INVTYPE_HEAD"] = true,
    ["INVTYPE_SHOULDER"] = true,
    ["INVTYPE_CHEST"] = true,
    ["INVTYPE_ROBE"] = true,
    ["INVTYPE_WAIST"] = true,
    ["INVTYPE_LEGS"] = true,
    ["INVTYPE_FEET"] = true,
    ["INVTYPE_WRIST"] = true,
    ["INVTYPE_HAND"] = true,
}

-- Strict Primary Armor Subclass per Class (only rolls Need on the character's current class armor tier)
local function GetPlayerPrimaryArmorSubclass(pClass)
    local level = (UnitLevel and UnitLevel("player")) or 60
    if pClass == "PRIEST" or pClass == "MAGE" or pClass == "WARLOCK" then
        return 1, "Cloth"
    elseif pClass == "ROGUE" or pClass == "DRUID" or pClass == "MONK" or pClass == "DEMONHUNTER" then
        return 2, "Leather"
    elseif pClass == "HUNTER" or pClass == "SHAMAN" or pClass == "EVOKER" then
        local knowsMail = (level >= 40) or (IsSpellKnown and IsSpellKnown(8737))
        if knowsMail then
            return 3, "Mail"
        else
            return 2, "Leather"
        end
    elseif pClass == "WARRIOR" or pClass == "PALADIN" then
        local knowsPlate = (level >= 40) or (IsSpellKnown and IsSpellKnown(750))
        if knowsPlate then
            return 4, "Plate"
        else
            return 3, "Mail"
        end
    elseif pClass == "DEATHKNIGHT" then
        return 4, "Plate"
    end
    return nil, nil
end

-- Weapon Subclass IDs (ClassID 2):
-- 0=1H Axe, 1=2H Axe, 2=Bow, 3=Gun, 4=1H Mace, 5=2H Mace, 6=Polearm, 7=1H Sword, 8=2H Sword,
-- 10=Staff, 13=Fist Weapon, 15=Dagger, 16=Thrown, 17=Spear, 18=Crossbow, 19=Wand
local USABLE_WEAPONS = {
    ["WARRIOR"]     = { [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [13]=true, [15]=true, [16]=true, [17]=true, [18]=true },
    ["PALADIN"]     = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [17]=true },
    ["HUNTER"]      = { [0]=true, [1]=true, [2]=true, [3]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true, [16]=true, [17]=true, [18]=true },
    ["ROGUE"]       = { [2]=true, [3]=true, [4]=true, [7]=true, [13]=true, [15]=true, [16]=true, [18]=true },
    ["PRIEST"]      = { [4]=true, [10]=true, [15]=true, [19]=true },
    ["DEATHKNIGHT"] = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [17]=true },
    ["SHAMAN"]      = { [0]=true, [1]=true, [4]=true, [5]=true, [10]=true, [13]=true, [15]=true },
    ["MAGE"]        = { [7]=true, [10]=true, [15]=true, [19]=true },
    ["WARLOCK"]     = { [7]=true, [10]=true, [15]=true, [19]=true },
    ["DRUID"]       = { [4]=true, [5]=true, [6]=true, [10]=true, [13]=true, [15]=true, [17]=true },
}

-- Strip WoW color codes from a tooltip line
local function StripTooltipColorCodes(str)
    if not str then return "" end
    local s = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    return s
end

-- Extract item stat presence flags from GetItemStats + Tooltip lines
local function GetItemStatFlags(itemLink, scanLines)
    local flags = {
        str = false, agi = false, sta = false, int = false, spi = false,
        ap = false, sp = false, heal = false, mp5 = false,
        meleeCrit = false, spellCrit = false, spellHaste = false, spellPen = false,
        def = false, dodge = false, parry = false, block = false,
        arp = false, exp = false,
    }

    local GetStats = GetItemStats or (C_Item and C_Item.GetItemStats)
    if GetStats then
        local stats = GetStats(itemLink)
        if stats then
            for k, v in pairs(stats) do
                if type(v) == "number" and v > 0 then
                    if k == "ITEM_MOD_STRENGTH" or k == "ITEM_MOD_STRENGTH_SHORT" then flags.str = true
                    elseif k == "ITEM_MOD_AGILITY" or k == "ITEM_MOD_AGILITY_SHORT" then flags.agi = true
                    elseif k == "ITEM_MOD_STAMINA" or k == "ITEM_MOD_STAMINA_SHORT" then flags.sta = true
                    elseif k == "ITEM_MOD_INTELLECT" or k == "ITEM_MOD_INTELLECT_SHORT" then flags.int = true
                    elseif k == "ITEM_MOD_SPIRIT" or k == "ITEM_MOD_SPIRIT_SHORT" then flags.spi = true
                    elseif string.find(k, "ATTACK_POWER") then flags.ap = true
                    elseif k == "ITEM_MOD_SPELL_POWER" or k == "ITEM_MOD_SPELL_POWER_SHORT" or k == "ITEM_MOD_SPELL_DAMAGE_DONE" or k == "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" then flags.sp = true
                    elseif k == "ITEM_MOD_HEALING_DONE" or k == "ITEM_MOD_HEALING_DONE_SHORT" or k == "ITEM_MOD_HEALING_STAT" or k == "ITEM_MOD_SPELL_HEALING_DONE" then flags.heal = true
                    elseif string.find(k, "POWER_REGEN") or string.find(k, "MANA_REGEN") then flags.mp5 = true
                    elseif string.find(k, "CRIT_SPELL") or string.find(k, "SPELL_CRIT") then flags.spellCrit = true
                    elseif string.find(k, "CRIT") then flags.meleeCrit = true
                    elseif string.find(k, "HASTE_SPELL") then flags.spellHaste = true
                    elseif string.find(k, "SPELL_PENETRATION") then flags.spellPen = true
                    elseif string.find(k, "DEFENSE") then flags.def = true
                    elseif string.find(k, "DODGE") then flags.dodge = true
                    elseif string.find(k, "PARRY") then flags.parry = true
                    elseif string.find(k, "BLOCK") then flags.block = true
                    elseif string.find(k, "ARMOR_PENETRATION") then flags.arp = true
                    elseif string.find(k, "EXPERTISE") then flags.exp = true
                    end
                end
            end
        end
    end

    scanLines = scanLines or GetItemTooltipLines(itemLink)
    for i = 2, #scanLines do
        local rawText = scanLines[i].left
        if rawText and rawText ~= "" then
            local text = StripTooltipColorCodes(rawText)
            if string.find(text, "%(%d+/%d+%)%s*$") then
                break
            end
            if not string.find(text, "^%(%d+%)%s*Set:") then
                local val, stat = string.match(text, "%+(%d+)%s+([%a%s]+)")
                if val and stat then
                    if string.find(stat, "Strength") then flags.str = true
                    elseif string.find(stat, "Agility") then flags.agi = true
                    elseif string.find(stat, "Stamina") then flags.sta = true
                    elseif string.find(stat, "Intellect") then flags.int = true
                    elseif string.find(stat, "Spirit") then flags.spi = true
                    elseif string.find(stat, "Attack Power") then flags.ap = true
                    elseif string.find(stat, "Spell Power") or string.find(stat, "Spell Damage") then flags.sp = true
                    elseif string.find(stat, "Healing") then flags.heal = true
                    elseif string.find(stat, "Defense") then flags.def = true
                    end
                else
                    local lower = string.lower(text)
                    if string.find(lower, "healing") and string.find(lower, "damage") and string.find(lower, "%+%d+") then
                        flags.sp = true
                        flags.heal = true
                    elseif string.find(lower, "damage and healing done by magical spells") or (string.find(lower, "damage done") and string.find(lower, "spell")) or string.find(lower, "spell power by") or string.find(lower, "spell damage by") then
                        flags.sp = true
                    elseif string.find(lower, "healing done by") or string.find(lower, "healing spells by") then
                        flags.heal = true
                    end
                    if string.find(lower, "attack power") then flags.ap = true end
                    if string.find(lower, "mana per 5") or string.find(lower, "mana every 5") then flags.mp5 = true end
                    if string.find(lower, "critical strike") then
                        if string.find(lower, "spell") then flags.spellCrit = true else flags.meleeCrit = true end
                    end
                    if string.find(lower, "spell haste") then flags.spellHaste = true end
                    if string.find(lower, "spell penetration") then flags.spellPen = true end
                    if string.find(lower, "defense") then flags.def = true end
                    if string.find(lower, "dodge") then flags.dodge = true end
                    if string.find(lower, "parry") then flags.parry = true end
                    if string.find(lower, "block value") or string.find(lower, "block rating") or string.find(lower, "chance to block") or string.find(lower, "block an attack") then flags.block = true end
                    if string.find(lower, "armor penetration") then flags.arp = true end
                    if string.find(lower, "expertise") then flags.exp = true end
                end
            end
        end
    end

    return flags
end

local function IsItemUsableByClass(itemLink)
    if not itemLink then return true, nil end

    local playerClassLoc, pClass = UnitClass("player")
    pClass = pClass or playerClass
    if not pClass then return true, nil end

    local itemID, itemType, itemSubType, itemEquipLoc, _, classID, subclassID = GetItemInfoInstant(itemLink)
    if not classID or not itemEquipLoc or itemEquipLoc == "" then
        local _, _, _, _, _, _, sType, _, eqLoc, _, _, cID, scID = GetItemInfo(itemLink)
        classID = classID or cID
        subclassID = subclassID or scID
        if (not itemEquipLoc or itemEquipLoc == "") and eqLoc then
            itemEquipLoc = eqLoc
        end
        if not itemSubType and sType then
            itemSubType = sType
        end
    end

    if itemEquipLoc == "INVTYPE_BAG" then
        return true, nil
    end

    local scanLines = GetItemTooltipLines(itemLink)

    -- 1. Check explicit Tooltip "Classes: ..." and "Races: ..." restrictions AND Red unusable equipment lines
    local classesPrefix = ITEM_CLASSES_ALLOWED and string.match(ITEM_CLASSES_ALLOWED, "^(.-)%%s") or "Classes:"
    local racesPrefix = ITEM_RACES_ALLOWED and string.match(ITEM_RACES_ALLOWED, "^(.-)%%s") or "Races:"
    local playerRaceLoc, playerRace = UnitRace("player")

    local tooltipArmorSubclass = nil
    local tooltipArmorName = nil

    for i = 2, #scanLines do
        local rawLeft = scanLines[i].left
        local rawRight = scanLines[i].right
        local leftText = StripTooltipColorCodes(rawLeft)
        local rightText = StripTooltipColorCodes(rawRight)

        if leftText ~= "" then
            -- Explicit "Classes: ..." check
            local classesList = string.match(leftText, "^Classes:%s*(.+)")
            if not classesList and classesPrefix and classesPrefix ~= "" then
                classesList = string.match(leftText, "^" .. classesPrefix .. "%s*(.+)")
            end
            if classesList then
                local foundMyClass = false
                local myLocLower = string.lower(playerClassLoc or "")
                local myFileLower = string.lower(pClass or "")
                for entry in string.gmatch(classesList, "([^,]+)") do
                    local trimmed = string.lower((string.gsub(entry, "^%s*(.-)%s*$", "%1")))
                    if trimmed == myLocLower or trimmed == myFileLower then
                        foundMyClass = true
                        break
                    end
                end
                if not foundMyClass then
                    return false, "Classes: " .. classesList
                end
            end

            -- Explicit "Races: ..." check
            local racesList = string.match(leftText, "^Races:%s*(.+)")
            if not racesList and racesPrefix and racesPrefix ~= "" then
                racesList = string.match(leftText, "^" .. racesPrefix .. "%s*(.+)")
            end
            if racesList and playerRaceLoc then
                local foundMyRace = false
                local myRaceLocLower = string.lower(playerRaceLoc or "")
                local myRaceFileLower = string.lower(playerRace or "")
                for entry in string.gmatch(racesList, "([^,]+)") do
                    local trimmed = string.lower((string.gsub(entry, "^%s*(.-)%s*$", "%1")))
                    if trimmed == myRaceLocLower or trimmed == myRaceFileLower then
                        foundMyRace = true
                        break
                    end
                end
                if not foundMyRace then
                    return false, "Races: " .. racesList
                end
            end
        end

        -- Check top equipment lines (lines 2-5) for armor subtype name and red unusable proficiencies
        if i <= 5 then
            if rightText ~= "" and not string.find(rightText, "^Speed%s+%d") then
                if ARMOR_NAME_TO_SUBCLASS[rightText] then
                    tooltipArmorSubclass = ARMOR_NAME_TO_SUBCLASS[rightText]
                    tooltipArmorName = rightText
                end
                if scanLines[i].rightRed then
                    return false, rightText
                end
            end
            if leftText ~= "" and ARMOR_NAME_TO_SUBCLASS[leftText] then
                tooltipArmorSubclass = ARMOR_NAME_TO_SUBCLASS[leftText]
                tooltipArmorName = leftText
                if scanLines[i].leftRed then
                    return false, leftText
                end
            elseif leftText ~= "" and scanLines[i].leftRed then
                if not string.find(leftText, "^Requires ") and not string.find(leftText, "Unique") then
                    return false, leftText
                end
            end
        end
    end

    -- 2. Check Held In Off-Hand (INVTYPE_HOLDABLE)
    if itemEquipLoc == "INVTYPE_HOLDABLE" then
        if pClass == "HUNTER" or pClass == "WARRIOR" or pClass == "ROGUE" or pClass == "DEATHKNIGHT" then
            return false, "Held In Off-Hand"
        end
        if pClass == "SHAMAN" or pClass == "PALADIN" or pClass == "DRUID" then
            local meleeDpsWeight = GetStatWeight("ITEM_MOD_WEAPON_DPS_SHORT")
            local apWeight = GetStatWeight("ITEM_MOD_ATTACK_POWER_SHORT")
            local agiWeight = GetStatWeight("ITEM_MOD_AGILITY_SHORT")
            local strWeight = GetStatWeight("ITEM_MOD_STRENGTH_SHORT")
            local spWeight = GetStatWeight("ITEM_MOD_SPELL_POWER_SHORT")
            local healWeight = GetStatWeight("ITEM_MOD_HEALING_DONE_SHORT")
            if (meleeDpsWeight > 0 or apWeight > 0 or agiWeight > 0 or strWeight > 0) and spWeight == 0 and healWeight == 0 then
                return false, "Held In Off-Hand (Melee Spec)"
            end
        end
    end

    -- 3. Check Shields (INVTYPE_SHIELD or Armor Subclass 6)
    if itemEquipLoc == "INVTYPE_SHIELD" or (classID == 4 and subclassID == 6) or tooltipArmorSubclass == 6 then
        if pClass ~= "WARRIOR" and pClass ~= "PALADIN" and pClass ~= "SHAMAN" then
            return false, "Shield"
        end
    end

    -- 4. Check Relics (INVTYPE_RELIC or Armor Subclass 7/8/9/10)
    local relicSubclass = (classID == 4 and subclassID and subclassID >= 7 and subclassID <= 10 and subclassID) or (tooltipArmorSubclass and tooltipArmorSubclass >= 7 and tooltipArmorSubclass <= 10 and tooltipArmorSubclass)
    if itemEquipLoc == "INVTYPE_RELIC" or relicSubclass then
        if relicSubclass == 7 and pClass ~= "PALADIN" then
            return false, "Libram (Paladin Only)"
        elseif relicSubclass == 8 and pClass ~= "DRUID" then
            return false, "Idol (Druid Only)"
        elseif relicSubclass == 9 and pClass ~= "SHAMAN" then
            return false, "Totem (Shaman Only)"
        elseif relicSubclass == 10 and pClass ~= "DEATHKNIGHT" then
            return false, "Sigil (Death Knight Only)"
        elseif pClass ~= "PALADIN" and pClass ~= "DRUID" and pClass ~= "SHAMAN" and pClass ~= "DEATHKNIGHT" then
            return false, "Relic"
        end
    end

    -- 5. Strict Class Primary Armor Type Check (Head, Shoulder, Chest, Robe, Waist, Legs, Feet, Wrist, Hands)
    if itemEquipLoc and ARMOR_SLOTS_REQUIRING_CLASS_ARMOR_TYPE[itemEquipLoc] then
        local actualArmorSubclass = (classID == 4 and subclassID and subclassID >= 1 and subclassID <= 4 and subclassID) or tooltipArmorSubclass
        local expectedArmorSubclass, expectedArmorName = GetPlayerPrimaryArmorSubclass(pClass)
        if actualArmorSubclass and expectedArmorSubclass and actualArmorSubclass ~= expectedArmorSubclass then
            local actualName = SUBCLASS_TO_ARMOR_NAME[actualArmorSubclass] or itemSubType or "Armor"
            return false, string.format("%s (Need %s)", actualName, expectedArmorName or "Class Armor")
        end
    end

    -- 6. Check Weapons (ClassID 2)
    if classID == 2 then
        local usableMap = USABLE_WEAPONS[pClass]
        if usableMap and subclassID then
            if not usableMap[subclassID] then
                return false, (itemSubType or "Weapon Type")
            end
        end
    end

    -- 7. Check Class-Incompatible Stats (prevent rolling Need on off-class stat items)
    local flags = GetItemStatFlags(itemLink, scanLines)
    local hasPhysicalStats = flags.str or flags.agi or flags.ap or flags.meleeCrit or flags.def or flags.dodge or flags.parry or flags.block or flags.arp or flags.exp
    local hasCasterStats = flags.int or flags.spi or flags.sp or flags.heal or flags.spellCrit or flags.spellHaste or flags.spellPen or flags.mp5

    if pClass == "WARRIOR" or pClass == "ROGUE" or pClass == "DEATHKNIGHT" then
        -- Non-mana physical classes never use caster stats
        if flags.int then return false, "Caster Stat (Intellect)" end
        if flags.sp then return false, "Caster Stat (Spell Power)" end
        if flags.heal then return false, "Caster Stat (Healing)" end
        if flags.spellCrit then return false, "Caster Stat (Spell Crit)" end
        if flags.spellHaste then return false, "Caster Stat (Spell Haste)" end
        if flags.spellPen then return false, "Caster Stat (Spell Penetration)" end
        if flags.mp5 then return false, "Caster Stat (MP5)" end
        if flags.spi and not hasPhysicalStats then
            return false, "Caster Stat (Spirit)"
        end
        if pClass == "ROGUE" then
            if flags.block or flags.def then
                return false, "Tank Stat (Defense/Block)"
            end
            if flags.str and not (flags.agi or flags.ap or flags.meleeCrit) and (not HasAnyCustomStatWeight() or GetStatWeight("ITEM_MOD_STRENGTH_SHORT") == 0) then
                return false, "Strength-Only Gear"
            end
        end
    elseif pClass == "MAGE" or pClass == "PRIEST" or pClass == "WARLOCK" then
        -- Pure caster classes never use physical melee/tank stats
        if flags.str then return false, "Melee Stat (Strength)" end
        if flags.agi then return false, "Melee Stat (Agility)" end
        if flags.ap then return false, "Melee Stat (Attack Power)" end
        if flags.arp then return false, "Melee Stat (Armor Pen)" end
        if flags.exp then return false, "Melee Stat (Expertise)" end
        if flags.def then return false, "Tank Stat (Defense)" end
        if flags.dodge then return false, "Tank Stat (Dodge)" end
        if flags.parry then return false, "Tank Stat (Parry)" end
        if flags.block then return false, "Tank Stat (Block)" end
        if (pClass == "MAGE" or pClass == "WARLOCK") and flags.heal and not flags.sp then
            return false, "Healer-Only Stat (Healing)"
        end
        -- Pure casters should never Need on a non-Wand weapon that has zero caster stats
        if classID == 2 and subclassID ~= 19 and not hasCasterStats then
            return false, "Physical Weapon (No Caster Stats)"
        end
    elseif pClass == "HUNTER" then
        if flags.sp then return false, "Caster Stat (Spell Power)" end
        if flags.heal then return false, "Caster Stat (Healing)" end
        if flags.spellCrit then return false, "Caster Stat (Spell Crit)" end
        if flags.spellHaste then return false, "Caster Stat (Spell Haste)" end
        if flags.spellPen then return false, "Caster Stat (Spell Penetration)" end
        if flags.def then return false, "Tank Stat (Defense)" end
        if flags.parry then return false, "Tank Stat (Parry)" end
        if flags.block then return false, "Tank Stat (Block)" end
        if flags.exp then return false, "Melee Stat (Expertise)" end
        if flags.str and not (flags.agi or flags.ap or flags.meleeCrit) and (not HasAnyCustomStatWeight() or GetStatWeight("ITEM_MOD_STRENGTH_SHORT") == 0) then
            return false, "Strength-Only Gear"
        end
        -- Hunters should not Need on a melee weapon that has zero stats (only raw melee DPS)
        local isMeleeWpn = itemEquipLoc and (itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_2HWEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND")
        if isMeleeWpn and not (flags.agi or flags.ap or flags.meleeCrit or flags.sta or flags.int) then
            return false, "Melee Weapon (No Hunter Stats)"
        end
    elseif pClass == "PALADIN" or pClass == "SHAMAN" or pClass == "DRUID" then
        if pClass == "DRUID" and (flags.parry or flags.block) then
            return false, "Tank Stat (Parry/Block)"
        end
        if pClass == "SHAMAN" and flags.parry then
            return false, "Tank Stat (Parry)"
        end
        if HasAnyCustomStatWeight() then
            local strW = GetStatWeight("ITEM_MOD_STRENGTH_SHORT")
            local agiW = GetStatWeight("ITEM_MOD_AGILITY_SHORT")
            local apW = GetStatWeight("ITEM_MOD_ATTACK_POWER_SHORT")
            local mDpsW = GetStatWeight("ITEM_MOD_WEAPON_DPS_SHORT")
            local defW = GetStatWeight("ITEM_MOD_DEFENSE_SKILL_RATING_SHORT")
            local spW = GetStatWeight("ITEM_MOD_SPELL_POWER_SHORT")
            local healW = GetStatWeight("ITEM_MOD_HEALING_DONE_SHORT")

            local isPhysSpec = (strW > 0 or agiW > 0 or apW > 0 or mDpsW > 0 or defW > 0) and (spW == 0 and healW == 0)
            local isCasterSpec = (spW > 0 or healW > 0) and (strW == 0 and agiW == 0 and apW == 0 and mDpsW == 0 and defW == 0)

            if isPhysSpec then
                if flags.sp or flags.heal or flags.spellCrit or flags.spellHaste or flags.mp5 then
                    return false, "Caster/Healer Gear (Physical Profile)"
                end
                if (flags.int or flags.spi) and not hasPhysicalStats then
                    return false, "Caster Stat Gear (Physical Profile)"
                end
            elseif isCasterSpec then
                if flags.str or flags.agi or flags.ap or flags.arp or flags.exp or flags.def or flags.dodge or flags.parry or flags.block then
                    return false, "Physical/Tank Gear (Caster Profile)"
                end
                if classID == 2 and not hasCasterStats then
                    return false, "Physical Weapon (Caster Profile)"
                end
            end
        end
    end

    return true, nil
end

-- Compare item link against equipped items in its mapped slot(s)
local function CheckIsUpgrade(itemLink, itemEquipLoc)
    if not itemLink then return false, 0, 0, nil end

    if not itemEquipLoc or itemEquipLoc == "" then
        local _, _, _, _, _, _, _, _, eqLoc = GetItemInfo(itemLink)
        if not eqLoc or eqLoc == "" then
            local _, _, _, eqLocInstant = GetItemInfoInstant(itemLink)
            eqLoc = eqLocInstant
        end
        itemEquipLoc = eqLoc
    end

    if not itemEquipLoc or not slotMapping[itemEquipLoc] then
        return false, 0, 0, nil
    end

    local isUsable, unUsableReason = IsItemUsableByClass(itemLink)
    if not isUsable then
        return false, 0, 0, "Cannot use " .. (unUsableReason or "item type")
    end

    local isDisqualified, disqStat = HasDisqualifiedStat(itemLink)
    if isDisqualified then
        return false, 0, 0, "Contains disabled stat: " .. disqStat
    end

    local minEquippedScore, hasEquippedItem, _ = GetEquippedStatsForLocation(itemEquipLoc, itemLink)
    local newScore = GetItemScore(itemLink)

    if newScore > 0 and (not hasEquippedItem or newScore > minEquippedScore) then
        return true, newScore, minEquippedScore, nil
    end

    return false, newScore, minEquippedScore, nil
end

-- Hook Tooltips to show MyAutoRoller weights score (Supports both Modern TooltipDataProcessor in WoWF 16001/12.x and Classic OnTooltipSetItem)
local function OnTooltipSetItemCallback(tooltip, data)
    if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    if tooltip == tooltipScanner then return end

    local link = nil
    if tooltip.GetItem then
        local _, l = tooltip:GetItem()
        link = l
    end
    if not link and data then
        if data.hyperlink then
            link = data.hyperlink
        elseif data.id then
            local _, l = GetItemInfo(data.id)
            link = l
        end
    end
    if not link then return end

    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(link)
    if not itemEquipLoc or itemEquipLoc == "" then
        local _, _, _, itemEquipLocInstant = GetItemInfoInstant(link)
        itemEquipLoc = itemEquipLocInstant
    end

    if itemEquipLoc and slotMapping[itemEquipLoc] then
        local isUsable, unUsableReason = IsItemUsableByClass(link)
        local isDisqualified, disqStat = HasDisqualifiedStat(link)
        local score = GetItemScore(link)

        if not isUsable then
            tooltip:AddDoubleLine("|cff00ff00MyAutoRoller Score:|r", string.format("%.2f (|cffff0000Unusable: %s|r)", score, unUsableReason or "Type"), 0, 1, 0, 1, 1, 1)
        elseif isDisqualified then
            tooltip:AddDoubleLine("|cff00ff00MyAutoRoller Score:|r", string.format("%.2f (|cffff0000Disabled: %s|r)", score, disqStat), 0, 1, 0, 1, 1, 1)
        else
            local minEquippedScore, hasEquipped, isEquipped = GetEquippedStatsForLocation(itemEquipLoc, link)

            if isEquipped then
                tooltip:AddDoubleLine("|cff00ff00MyAutoRoller Score:|r", string.format("%.2f (Equipped)", score), 0, 1, 0, 1, 1, 1)
            else
                if hasEquipped and minEquippedScore ~= 999999 then
                    local diff = score - minEquippedScore
                    local diffText = ""
                    if diff > 0 then
                        diffText = string.format(" (|cff00ff00+%.2f|r vs Equipped)", diff)
                    elseif diff < 0 then
                        diffText = string.format(" (|cffff0000%.2f|r vs Equipped)", diff)
                    else
                        diffText = " (Equal vs Equipped)"
                    end
                    tooltip:AddDoubleLine("|cff00ff00MyAutoRoller Score:|r", string.format("%.2f%s", score, diffText), 0, 1, 0, 1, 1, 1)
                else
                    tooltip:AddDoubleLine("|cff00ff00MyAutoRoller Score:|r", string.format("%.2f", score), 0, 1, 0, 1, 1, 1)
                end
            end
        end
        
        tooltip:Show()
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItemCallback)
else
    local function HookTooltip(tooltip)
        if tooltip and tooltip.HasScript and tooltip:HasScript("OnTooltipSetItem") then
            tooltip:HookScript("OnTooltipSetItem", OnTooltipSetItemCallback)
        end
    end
    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)
    HookTooltip(ShoppingTooltip1)
    HookTooltip(ShoppingTooltip2)
    if ShoppingTooltip3 then HookTooltip(ShoppingTooltip3) end
    if WorldMapCompareTooltip1 then HookTooltip(WorldMapCompareTooltip1) end
    if WorldMapCompareTooltip2 then HookTooltip(WorldMapCompareTooltip2) end
end

-- ============================================================================
-- LIVE LOOT ROLL TRACKER WINDOW SYSTEM
-- ============================================================================
local rollHistory = {}
local summaryRowPool = {}
local playerRowPool = {}
local UpdateLootTrackerUI

-- Create Movable Loot Tracker Window
local trackerFrame = CreateFrame("Frame", "MyAutoRollerLootTrackerFrame", UIParent, "BackdropTemplate")
trackerFrame:SetSize(310, 260)
trackerFrame:SetPoint("CENTER", 200, 0)
trackerFrame:SetMovable(true)
trackerFrame:EnableMouse(true)
trackerFrame:RegisterForDrag("LeftButton")
trackerFrame:SetScript("OnDragStart", trackerFrame.StartMoving)
trackerFrame:SetScript("OnDragStop", trackerFrame.StopMovingOrSizing)
trackerFrame:SetClampedToScreen(true)

trackerFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
trackerFrame:SetBackdropColor(0.08, 0.08, 0.1, 0.94)
trackerFrame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

-- Title Header
local trackerTitle = trackerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
trackerTitle:SetPoint("TOPLEFT", 12, -10)
trackerTitle:SetText("|cffffd100MyAutoRoller Loot Tracker|r")

-- Single Settings Cogwheel Button (Top Right)
local gearBtn = CreateFrame("Button", nil, trackerFrame)
gearBtn:SetSize(18, 18)
gearBtn:SetPoint("TOPRIGHT", -6, -6)
local gearTex = gearBtn:CreateTexture(nil, "ARTWORK")
gearTex:SetAllPoints()
gearTex:SetTexture("Interface\\WorldMap\\Gear_64")
gearTex:SetTexCoord(0, 0.5, 0, 0.5)
gearBtn:SetScript("OnClick", function()
    SlashCmdList["MYAUTOROLLER"]("")
end)
gearBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("MyAutoRoller Settings", 1, 1, 1)
    GameTooltip:AddLine("Click to open configuration options.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
gearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Auto-Hide Timer Manager (Hides frame 30 seconds after loot winner is declared)
local hideTimerTimer = nil
local function CancelHideTimer()
    if hideTimerTimer and hideTimerTimer.Cancel then
        hideTimerTimer:Cancel()
        hideTimerTimer = nil
    end
end

local function StartHideTimer()
    CancelHideTimer()
    if C_Timer and C_Timer.After then
        hideTimerTimer = C_Timer.After(30, function()
            if trackerFrame and trackerFrame:IsShown() then
                trackerFrame:Hide()
            end
        end)
    end
end

-- Make window resizable with dynamic bounds
trackerFrame:SetResizable(true)
if trackerFrame.SetResizeBounds then
    trackerFrame:SetResizeBounds(240, 150, 600, 600)
elseif trackerFrame.SetMinResize then
    trackerFrame:SetMinResize(240, 150)
    trackerFrame:SetMaxResize(600, 600)
end

-- Resize Grip Handle (Bottom-Right corner)
local resizeBtn = CreateFrame("Button", nil, trackerFrame)
resizeBtn:SetSize(16, 16)
resizeBtn:SetPoint("BOTTOMRIGHT", -2, 2)
local resizeTex = resizeBtn:CreateTexture(nil, "ARTWORK")
resizeTex:SetAllPoints()
resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        trackerFrame:StartSizing("BOTTOMRIGHT")
    end
end)
resizeBtn:SetScript("OnMouseUp", function(self, button)
    trackerFrame:StopMovingOrSizing()
    if UpdateLootTrackerUI then UpdateLootTrackerUI() end
end)
trackerFrame:SetScript("OnSizeChanged", function(self, width, height)
    if tScrollContent then
        tScrollContent:SetWidth(math.max(220, width - 40))
    end
    if UpdateLootTrackerUI then UpdateLootTrackerUI() end
end)

-- Scroll Container
local tScrollFrame = CreateFrame("ScrollFrame", "MyAutoRollerTrackerScrollFrame", trackerFrame, "UIPanelScrollFrameTemplate")
tScrollFrame:SetPoint("TOPLEFT", 8, -32)
tScrollFrame:SetPoint("BOTTOMRIGHT", -26, 8)

local tScrollContent = CreateFrame("Frame", "MyAutoRollerTrackerScrollContent", tScrollFrame)
tScrollContent:SetSize(270, 220)
tScrollFrame:SetScrollChild(tScrollContent)

-- Helper to find or add item roll record to history
local function GetOrCreateRollRecord(itemLink, itemName, texture, quality)
    local key = itemLink or itemName
    if not key then return nil end

    for _, record in ipairs(rollHistory) do
        if record.key == key or (record.itemLink and itemLink and record.itemLink == itemLink) then
            return record
        end
    end

    local cleanName = itemName or "Loot Item"
    if itemLink and string.find(itemLink, "%[.+%]") then
        cleanName = string.match(itemLink, "%[(.+)%]") or cleanName
    end

    local newRecord = {
        key = key,
        itemLink = itemLink or cleanName,
        itemName = cleanName,
        texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        quality = quality or 1,
        isExpanded = false,
        winnerName = nil,
        winnerRoll = nil,
        winnerType = nil,
        players = {}
    }
    table.insert(rollHistory, 1, newRecord)

    -- Cap history at 15 items
    if #rollHistory > 15 then
        table.remove(rollHistory, #rollHistory)
    end

    return newRecord
end

-- Helper to resolve class file name for group members by name
local function GetGroupUnitClass(playerName)
    if not playerName then return nil end
    if playerName == UnitName("player") then
        local _, classFile = UnitClass("player")
        return classFile
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitName(unit) == playerName then
                local _, classFile = UnitClass(unit)
                return classFile
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            if UnitName(unit) == playerName then
                local _, classFile = UnitClass(unit)
                return classFile
            end
        end
    end

    return nil
end

-- Class Color helper
local function GetClassColorHex(classFileName)
    if classFileName and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName] then
        local c = RAID_CLASS_COLORS[classFileName]
        return string.format("ff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    return "ffffff"
end

-- Render Loot Tracker Rows
UpdateLootTrackerUI = function()
    if not trackerFrame:IsShown() then return end

    for _, f in ipairs(summaryRowPool) do f:Hide() end
    for _, f in ipairs(playerRowPool) do f:Hide() end

    local currentY = 0
    local summaryIdx = 1
    local playerIdx = 1

    for itemIdx, record in ipairs(rollHistory) do
        local summaryFrame = summaryRowPool[summaryIdx]
        if not summaryFrame then
            summaryFrame = CreateFrame("Frame", nil, tScrollContent)
            summaryFrame:SetSize(270, 36)

            -- Background box
            local bg = summaryFrame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.12, 0.12, 0.15, 0.8)
            summaryFrame.bg = bg

            -- Expand/Collapse button (+ / -)
            local toggleBtn = CreateFrame("Button", nil, summaryFrame)
            toggleBtn:SetSize(16, 16)
            toggleBtn:SetPoint("LEFT", 4, 0)
            local toggleText = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            toggleText:SetPoint("CENTER", 0, 0)
            toggleBtn.text = toggleText
            summaryFrame.toggleBtn = toggleBtn

            -- Item Icon
            local icon = summaryFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(26, 26)
            icon:SetPoint("LEFT", toggleBtn, "RIGHT", 4, 0)
            summaryFrame.icon = icon

            -- Green Upgrade Indicator Overlay (Pawn-Style Electric Neon Green Arrow with Drop Shadow)
            local upgradeFrame = CreateFrame("Frame", nil, summaryFrame)
            upgradeFrame:SetSize(16, 16)
            upgradeFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", -4, 4)
            upgradeFrame:SetFrameLevel(summaryFrame:GetFrameLevel() + 10)

            -- Drop Shadow Outline for high contrast on bright/dark item icons
            local shadowTex = upgradeFrame:CreateTexture(nil, "BACKGROUND")
            shadowTex:SetSize(16, 16)
            shadowTex:SetPoint("CENTER", 1, -1)
            shadowTex:SetTexture("Interface\\PetPaperDollFrame\\UI-PetPaperDollFrame-UpArrow")
            shadowTex:SetVertexColor(0, 0, 0, 0.85)

            -- Electric Neon Green Arrow (Pawn Color #1eff00 / 0.1, 1.0, 0.1)
            local upgradeTex = upgradeFrame:CreateTexture(nil, "OVERLAY")
            upgradeTex:SetAllPoints()
            upgradeTex:SetTexture("Interface\\PetPaperDollFrame\\UI-PetPaperDollFrame-UpArrow")
            upgradeTex:SetVertexColor(0.12, 1.0, 0.12, 1.0)
            upgradeFrame.texture = upgradeTex

            upgradeFrame:EnableMouse(true)
            upgradeFrame:SetScript("OnEnter", function(self)
                if self.itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine("MyAutoRoller Upgrade!", 0.12, 1.0, 0.12)
                    GameTooltip:AddLine("This item scores higher than your equipped gear.", 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            upgradeFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

            summaryFrame.upgradeFrame = upgradeFrame

            -- Winner & Roll Info
            local winnerFS = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            winnerFS:SetPoint("RIGHT", -6, 0)
            winnerFS:SetJustifyH("RIGHT")
            summaryFrame.winnerFS = winnerFS

            -- Item Link (Anchored between icon and winnerFS to prevent overlap)
            local linkFS = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            linkFS:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            linkFS:SetPoint("RIGHT", winnerFS, "LEFT", -6, 0)
            linkFS:SetJustifyH("LEFT")
            linkFS:SetWordWrap(false)
            summaryFrame.linkFS = linkFS

            summaryRowPool[summaryIdx] = summaryFrame
        end
        summaryIdx = summaryIdx + 1

        summaryFrame:SetPoint("TOPLEFT", 0, currentY)
        summaryFrame:Show()

        summaryFrame.toggleBtn.text:SetText(record.isExpanded and "-" or "+")
        summaryFrame.toggleBtn:SetScript("OnClick", function()
            record.isExpanded = not record.isExpanded
            UpdateLootTrackerUI()
        end)

        summaryFrame.icon:SetTexture(record.texture)
        
        -- Check if item is an Upgrade for player and display Green Up Arrow
        local isUpgrade = false
        if record.itemLink then
            isUpgrade = CheckIsUpgrade(record.itemLink)
        end

        if isUpgrade then
            summaryFrame.upgradeFrame.itemLink = record.itemLink
            summaryFrame.upgradeFrame:Show()
        else
            summaryFrame.upgradeFrame.itemLink = nil
            summaryFrame.upgradeFrame:Hide()
        end
        
        -- Display item link with native quality color
        if record.itemLink and string.find(record.itemLink, "|c") then
            summaryFrame.linkFS:SetText(record.itemLink)
        else
            local qColor = "ffffff"
            if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[record.quality] then
                qColor = ITEM_QUALITY_COLORS[record.quality].hex or "ffffff"
            end
            summaryFrame.linkFS:SetText(string.format("|c%s%s|r", qColor, record.itemName))
        end

        if record.winnerName then
            local rText = record.winnerType or "Greed"
            summaryFrame.winnerFS:SetText(string.format("%s %s (%s)", record.winnerName, tostring(record.winnerRoll or ""), rText))
        else
            summaryFrame.winnerFS:SetText("|cff888888Rolling...|r")
        end

        currentY = currentY - 38

        -- Render expanded player list sorted by Roll Number (Highest to Lowest, Winner at Top)
        if record.isExpanded and record.players then
            local sortedPlayers = {}
            for pName, pData in pairs(record.players) do
                table.insert(sortedPlayers, { name = pName, data = pData })
            end

            table.sort(sortedPlayers, function(a, b)
                if a.data.isWinner then return true end
                if b.data.isWinner then return false end
                local numA = tonumber(a.data.rollNum) or -1
                local numB = tonumber(b.data.rollNum) or -1
                return numA > numB
            end)

            for _, pItem in ipairs(sortedPlayers) do
                local pName = pItem.name
                local pData = pItem.data
                local playerFrame = playerRowPool[playerIdx]
                if not playerFrame then
                    playerFrame = CreateFrame("Frame", nil, tScrollContent)
                    playerFrame:SetSize(270, 18)

                    local checkFS = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    checkFS:SetPoint("LEFT", 12, 0)
                    playerFrame.checkFS = checkFS

                    local nameFS = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    nameFS:SetPoint("LEFT", checkFS, "RIGHT", 4, 0)
                    nameFS:SetWidth(110)
                    nameFS:SetJustifyH("LEFT")
                    nameFS:SetWordWrap(false)
                    playerFrame.nameFS = nameFS

                    local rollTypeFS = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    rollTypeFS:SetPoint("LEFT", nameFS, "RIGHT", 6, 0)
                    rollTypeFS:SetWidth(65)
                    rollTypeFS:SetJustifyH("CENTER")
                    playerFrame.rollTypeFS = rollTypeFS

                    local rollNumFS = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    rollNumFS:SetPoint("RIGHT", -8, 0)
                    rollNumFS:SetJustifyH("RIGHT")
                    playerFrame.rollNumFS = rollNumFS

                    playerRowPool[playerIdx] = playerFrame
                end
                playerIdx = playerIdx + 1

                playerFrame:SetPoint("TOPLEFT", 0, currentY)
                playerFrame:Show()

                playerFrame.checkFS:SetText(pData.isWinner and "|cff00ff00v|r" or " ")
                
                local classFile = pData.class or GetGroupUnitClass(pName)
                local cHex = GetClassColorHex(classFile)
                playerFrame.nameFS:SetText(string.format("|c%s%s|r", cHex, pName))

                local rColor = "ffffd100"
                if pData.rollType == "Need" then rColor = "ff00ff00"
                elseif pData.rollType == "Pass" then rColor = "ff888888"
                elseif pData.rollType == "Disenchant" then rColor = "ff0070dd" end
                
                playerFrame.rollTypeFS:SetText(string.format("|c%s%s|r", rColor, pData.rollType or "Greed"))
                playerFrame.rollNumFS:SetText(tostring(pData.rollNum or "-"))

                currentY = currentY - 20
            end
        end
    end

    tScrollContent:SetHeight(math.max(220, math.abs(currentY)))
end

-- Core Addon Event Handling Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("START_LOOT_ROLL")
eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")
eventFrame:RegisterEvent("LOOT_ROLLS_COMPLETE")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
pcall(function() eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            -- Initialize Database (Account-wide)
            if not MyAutoRollerDB then MyAutoRollerDB = {} end
            if MyAutoRollerDB.enabled == nil then MyAutoRollerDB.enabled = defaultDB.enabled end
            if MyAutoRollerDB.bopSafety == nil then MyAutoRollerDB.bopSafety = defaultDB.bopSafety end
            if MyAutoRollerDB.boeSafety == nil then MyAutoRollerDB.boeSafety = defaultDB.boeSafety end
            if MyAutoRollerDB.chatAnnounce == nil then MyAutoRollerDB.chatAnnounce = defaultDB.chatAnnounce end
            if MyAutoRollerDB.needProfessions == nil then MyAutoRollerDB.needProfessions = defaultDB.needProfessions end
            if MyAutoRollerDB.showLootTracker == nil then MyAutoRollerDB.showLootTracker = defaultDB.showLootTracker end
            if MyAutoRollerDB.passIfNotUpgrade == nil then MyAutoRollerDB.passIfNotUpgrade = defaultDB.passIfNotUpgrade end

            -- Initialize Database (Character-specific)
            if not MyAutoRollerCharDB then MyAutoRollerCharDB = {} end
            if MyAutoRollerCharDB.statWeightEnabled == nil then MyAutoRollerCharDB.statWeightEnabled = defaultCharDB.statWeightEnabled end
            if not MyAutoRollerCharDB.profiles then MyAutoRollerCharDB.profiles = {} end

            -- Ensure "Default" profile exists (migrating existing weights if present)
            if not MyAutoRollerCharDB.profiles["Default"] then
                local defProf = {
                    statWeights = {},
                    statEnabled = {},
                    minWeaponSpeed1H = MyAutoRollerCharDB.minWeaponSpeed1H or defaultCharDB.minWeaponSpeed1H or 0.00,
                    minWeaponSpeed2H = MyAutoRollerCharDB.minWeaponSpeed2H or defaultCharDB.minWeaponSpeed2H or 0.00,
                    minWeaponSpeedRanged = MyAutoRollerCharDB.minWeaponSpeedRanged or defaultCharDB.minWeaponSpeedRanged or 0.00,
                }
                local srcWeights = MyAutoRollerCharDB.statWeights or defaultCharDB.statWeights
                for _, conf in ipairs(STATS_CONFIG) do
                    defProf.statWeights[conf.key] = srcWeights[conf.key] or defaultCharDB.statWeights[conf.key] or 0
                end
                local srcEnabled = MyAutoRollerCharDB.statEnabled or defaultCharDB.statEnabled
                for _, conf in ipairs(STATS_CONFIG) do
                    local en = srcEnabled[conf.key]
                    if en == nil then en = true end
                    defProf.statEnabled[conf.key] = en
                end
                MyAutoRollerCharDB.profiles["Default"] = defProf
            end

            -- Ensure all profiles have all required keys and stats
            for pName, pData in pairs(MyAutoRollerCharDB.profiles) do
                if not pData.statWeights then pData.statWeights = {} end
                if not pData.statEnabled then pData.statEnabled = {} end
                if pData.minWeaponSpeed1H == nil then pData.minWeaponSpeed1H = 0.00 end
                if pData.minWeaponSpeed2H == nil then pData.minWeaponSpeed2H = 0.00 end
                if pData.minWeaponSpeedRanged == nil then pData.minWeaponSpeedRanged = 0.00 end
                for _, conf in ipairs(STATS_CONFIG) do
                    if pData.statWeights[conf.key] == nil then
                        pData.statWeights[conf.key] = defaultCharDB.statWeights[conf.key] or 0
                    end
                    if pData.statEnabled[conf.key] == nil then
                        pData.statEnabled[conf.key] = true
                    end
                end
            end

            if not MyAutoRollerCharDB.currentProfile or not MyAutoRollerCharDB.profiles[MyAutoRollerCharDB.currentProfile] then
                MyAutoRollerCharDB.currentProfile = "Default"
            end

            -- Activate active profile
            SetActiveProfile(MyAutoRollerCharDB.currentProfile, true)

            if not MyAutoRollerDB.qualities then MyAutoRollerDB.qualities = {} end
            for q = 0, 5 do
                if MyAutoRollerDB.qualities[q] == nil then
                    MyAutoRollerDB.qualities[q] = defaultDB.qualities[q]
                end
            end

            -- Ensure Loot Tracker Frame is HIDDEN on startup (pops up only during active loot rolls)
            if trackerFrame then
                trackerFrame:Hide()
            end

            -- Update UI controls to reflect configuration
            UpdateUI()
            if UpdateSubPanelUI then UpdateSubPanelUI() end

            print(string.format("|cff00ff00MyAutoRoller Loaded!|r Active Profile: |cffffd000%s|r. Type |cff0070dd/mar|r or |cff0070dd/mar profile|r to configure.", MyAutoRollerCharDB.currentProfile))
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        local group = ... or (GetActiveTalentGroup and GetActiveTalentGroup())
        if group and MyAutoRollerCharDB and MyAutoRollerCharDB.profiles then
            local candidates = {
                "Spec " .. tostring(group),
                group == 1 and "Primary" or "Secondary",
                group == 1 and "Main Spec" or "Off Spec",
            }
            for _, cand in ipairs(candidates) do
                if MyAutoRollerCharDB.profiles[cand] then
                    SetActiveProfile(cand)
                    break
                end
            end
        end

    elseif event == "CANCEL_LOOT_ROLL" or event == "LOOT_ROLLS_COMPLETE" then
        StartHideTimer()

    elseif event == "CHAT_MSG_LOOT" then
        local msg = ...
        if not msg then return end

        -- Extract item link (handles color-coded links |cff......[Item]|r or plain [Item])
        local itemLink = string.match(msg, "(|c%x+|Hitem:[%d:-]+|h%[.+%]|h|r)") or string.match(msg, "(|c%x+%[.+%]|r)") or string.match(msg, "(%[.+%])")
        if not itemLink then return end

        local cleanItemName = string.match(itemLink, "%[(.+)%]") or itemLink

        -- 1. Check for player roll number (e.g. "Kitipurr rolls 80 for [Item] by Greed" or "Kitipurr rolled 80 for [Item]")
        local num = string.match(msg, "%sroll%w*%s+(%d+)%s") or string.match(msg, "%srolled%s+(%d+)%s") or string.match(msg, "%srolls%s+(%d+)%s")
        if num then
            local pName = string.match(msg, "^|c%x+([^|]+)|r%s+roll") or string.match(msg, "^([^%s|]+)%s+roll")
            if not pName then
                if string.find(msg, "^You roll") or string.find(msg, "^You rolled") then
                    pName = UnitName("player")
                end
            end

            if pName then
                local rType = "Greed"
                if string.find(msg, "Need") or string.find(msg, "by Need") then
                    rType = "Need"
                elseif string.find(msg, "Disenchant") or string.find(msg, "by Disenchant") then
                    rType = "Disenchant"
                elseif string.find(msg, "Pass") or string.find(msg, "passed") then
                    rType = "Pass"
                end

                local record = GetOrCreateRollRecord(itemLink, cleanItemName, nil, 2)
                if record then
                    local pClass = GetGroupUnitClass(pName)
                    record.players[pName] = { rollType = rType, rollNum = tonumber(num) or num, class = pClass, isWinner = false }
                    if MyAutoRollerDB and MyAutoRollerDB.showLootTracker and trackerFrame then
                        trackerFrame:Show()
                    end
                    UpdateLootTrackerUI()
                end
                return
            end
        end

        -- 2. Check for roll selection choice (e.g. "Kitipurr has selected Greed for: [Item]" or "Kitipurr passed on: [Item]")
        local pName, rType = string.match(msg, "^([^%s|]+)%s+has selected (%a+) for:")
        if not pName then
            pName = string.match(msg, "^|c%x+([^|]+)|r%s+has selected (%a+) for:")
        end
        if not pName then
            pName = string.match(msg, "^([^%s|]+)%s+passed on:") or string.match(msg, "^([^%s|]+)%s+passed on")
            rType = "Pass"
        end
        if not pName then
            if string.find(msg, "^You passed on:") or string.find(msg, "^You passed on") then
                pName = UnitName("player")
                rType = "Pass"
            end
        end

        if pName then
            local record = GetOrCreateRollRecord(itemLink, cleanItemName, nil, 2)
            if record then
                local pClass = GetGroupUnitClass(pName)
                if not record.players[pName] or record.players[pName].rollNum == "-" then
                    record.players[pName] = { rollType = rType or "Greed", rollNum = "-", class = pClass, isWinner = false }
                    if MyAutoRollerDB and MyAutoRollerDB.showLootTracker and trackerFrame then
                        trackerFrame:Show()
                    end
                    UpdateLootTrackerUI()
                end
            end
            return
        end

        -- 3. Check for roll winners (e.g. "Kitipurr won: [Item]" or "You won: [Item]")
        pName = string.match(msg, "^([^%s|]+)%s+won:") or string.match(msg, "^([^%s|]+)%s+wins:") or string.match(msg, "^([^%s|]+)%s+has won")
        if not pName then
            pName = string.match(msg, "^|c%x+([^|]+)|r%s+won:") or string.match(msg, "^|c%x+([^|]+)|r%s+wins:")
        end
        if not pName then
            if string.find(msg, "^You won:") or string.find(msg, "^You win:") or string.find(msg, "^You have won") then
                pName = UnitName("player")
            end
        end

        if pName then
            local record = GetOrCreateRollRecord(itemLink, cleanItemName, nil, 2)
            if record then
                record.winnerName = pName
                if record.players[pName] then
                    record.players[pName].isWinner = true
                    record.winnerRoll = record.players[pName].rollNum
                    record.winnerType = record.players[pName].rollType
                end
                if MyAutoRollerDB and MyAutoRollerDB.showLootTracker and trackerFrame then
                    trackerFrame:Show()
                end
                UpdateLootTrackerUI()
                StartHideTimer()
            end
            return
        end

    elseif event == "START_LOOT_ROLL" then
        local rollID, rollTime = ...
        if not MyAutoRollerDB or not MyAutoRollerDB.enabled then return end

        local function ProcessLootRoll(rID, retryCount)
            retryCount = retryCount or 0
            local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(rID)
            if not name then return end

            local itemLink = GetLootRollItemLink(rID)
            if not itemLink then return end

            -- Record active item in Loot Tracker history and auto-show tracker window
            CancelHideTimer()
            if MyAutoRollerDB and MyAutoRollerDB.showLootTracker and trackerFrame then
                trackerFrame:Show()
            end
            GetOrCreateRollRecord(itemLink, name, texture, quality)
            if UpdateLootTrackerUI then UpdateLootTrackerUI() end

            -- Check if item info is fully loaded from WoW server cache
            local itemName, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
            if not itemName and retryCount < 2 and C_Timer and C_Timer.After then
                if C_Item and C_Item.RequestLoadItemDataByID then
                    local id = GetItemInfoInstant(itemLink)
                    if id then pcall(C_Item.RequestLoadItemDataByID, id) end
                end
                C_Timer.After(0.2, function()
                    ProcessLootRoll(rID, retryCount + 1)
                end)
                return
            end

            if not itemEquipLoc or itemEquipLoc == "" then
                local _, _, _, itemEquipLocInstant = GetItemInfoInstant(itemLink)
                itemEquipLoc = itemEquipLocInstant
            end

            -- Handle Bind-on-Pickup Safety Check
            if bindOnPickUp and MyAutoRollerDB.bopSafety then
                if MyAutoRollerDB.chatAnnounce then
                    print(string.format("|cff00ff00MyAutoRoller|r: Skipped auto-rolling on Bind on Pickup item: %s", name))
                end
                return
            end

            -- Check if we should auto-Need based on stat weights
            if MyAutoRollerCharDB and MyAutoRollerCharDB.statWeightEnabled then
                if itemEquipLoc and slotMapping[itemEquipLoc] then
                    local isUpgrade, newScore, eqScore, disqStat = CheckIsUpgrade(itemLink, itemEquipLoc)
                    if isUpgrade then
                        if (not bindOnPickUp) and MyAutoRollerDB.boeSafety then
                            if MyAutoRollerDB.passIfNotUpgrade then
                                RollOnLoot(rID, 0)
                                if MyAutoRollerDB.chatAnnounce then
                                    print(string.format("|cff00ff00MyAutoRoller|r: Passed on BoE upgrade item %s (BoE Safety Enabled)", name))
                                end
                                return
                            elseif MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Skipped stat weight Need on BoE upgrade item: %s (BoE Safety Enabled)", name))
                            end
                        else
                            if canNeed then
                                RollOnLoot(rID, 1)
                                if MyAutoRollerDB.chatAnnounce then
                                    print(string.format("|cff00ff00MyAutoRoller|r: Automatically Needed on %s (Upgrade: %.2f > %.2f)", name, newScore, eqScore))
                                end
                                return
                            elseif MyAutoRollerDB.passIfNotUpgrade then
                                RollOnLoot(rID, 0)
                                if MyAutoRollerDB.chatAnnounce then
                                    print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (Upgrade, but cannot Need)", name))
                                end
                                return
                            else
                                if MyAutoRollerDB.chatAnnounce then
                                    print(string.format("|cff00ff00MyAutoRoller|r: Item %s is an upgrade (%.1f > %.1f) but cannot Need, falling back", name, newScore, eqScore))
                                end
                            end
                        end
                    else
                        if MyAutoRollerDB.passIfNotUpgrade then
                            RollOnLoot(rID, 0)
                            if MyAutoRollerDB.chatAnnounce then
                                if disqStat then
                                    print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (%s)", name, disqStat))
                                else
                                    print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (Not an Upgrade)", name))
                                end
                            end
                            return
                        elseif disqStat then
                            if MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Skipped stat weight Need on %s (%s)", name, disqStat))
                            end
                        end
                    end
                end
            end

            -- Check Profession Items (Recipes, Patterns, Schematics, Plans, Formulas, Manuals, Designs)
            local isRecipe, requiredProf, alreadyKnown, playerHasProf = ItemRequiresPlayerProfession(itemLink)
            if isRecipe then
                if playerHasProf then
                    if alreadyKnown then
                        if MyAutoRollerDB.passIfNotUpgrade then
                            RollOnLoot(rID, 0)
                            if MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (Requires %s, Already Known)", name, requiredProf or "Profession"))
                            end
                            return
                        elseif canGreed then
                            RollOnLoot(rID, 2)
                            if MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Automatically Greeded on %s (Requires %s, Already Known)", name, requiredProf or "Profession"))
                            end
                            return
                        end
                    else
                        if MyAutoRollerDB.needProfessions and canNeed then
                            RollOnLoot(rID, 1)
                            if MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Automatically Needed on %s (Requires %s, Unknown)", name, requiredProf or "Profession"))
                            end
                            return
                        end
                    end
                else
                    -- Player DOES NOT have this profession! Prevent Need and Pass/Greed instead!
                    if MyAutoRollerDB.passIfNotUpgrade then
                        RollOnLoot(rID, 0)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (Requires %s - Profession Not Learned)", name, requiredProf or "Unlearned Profession"))
                        end
                        return
                    elseif canGreed then
                        RollOnLoot(rID, 2)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Greeded on %s (Requires %s - Profession Not Learned)", name, requiredProf or "Unlearned Profession"))
                        end
                        return
                    end
                end
            end

            -- Check configured roll action for this item quality
            local action = MyAutoRollerDB.qualities[quality]
            if not action or action == "manual" then return end

            if action == "pass" then
                RollOnLoot(rID, 0)
                if MyAutoRollerDB.chatAnnounce then
                    print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s", name))
                end
            elseif action == "upgrade" then
                local isUpgrade = false
                local newScore, eqScore, disqStat
                if itemEquipLoc and slotMapping[itemEquipLoc] then
                    isUpgrade, newScore, eqScore, disqStat = CheckIsUpgrade(itemLink, itemEquipLoc)
                end

                if isUpgrade then
                    if (not bindOnPickUp) and MyAutoRollerDB.boeSafety then
                        if MyAutoRollerDB.passIfNotUpgrade then
                            RollOnLoot(rID, 0)
                            if MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Skipped Need on BoE upgrade item %s (BoE Safety Enabled). Passed instead", name))
                            end
                            return
                        elseif canGreed then
                            RollOnLoot(rID, 2)
                            if MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Skipped Need on BoE upgrade item %s (BoE Safety Enabled). Greeded instead", name))
                            end
                            return
                        end
                    else
                        if canNeed then
                            RollOnLoot(rID, 1)
                            if MyAutoRollerDB.chatAnnounce then
                                print(string.format("|cff00ff00MyAutoRoller|r: Automatically Needed on %s (Upgrade: %.1f > %.1f)", name, newScore, eqScore))
                            end
                            return
                        end
                    end
                end

                -- Not an upgrade or disqStat or non-gear: Roll Pass (if passIfNotUpgrade) or Greed!
                if MyAutoRollerDB.passIfNotUpgrade then
                    RollOnLoot(rID, 0)
                    if MyAutoRollerDB.chatAnnounce then
                        if disqStat then
                            print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (%s)", name, disqStat))
                        elseif isUpgrade == false and itemEquipLoc and slotMapping[itemEquipLoc] then
                            print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (Not an Upgrade)", name))
                        else
                            print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s", name))
                        end
                    end
                    return
                elseif canGreed then
                    RollOnLoot(rID, 2)
                    if MyAutoRollerDB.chatAnnounce then
                        if disqStat then
                            print(string.format("|cff00ff00MyAutoRoller|r: Greeded on %s (%s)", name, disqStat))
                        elseif isUpgrade == false and itemEquipLoc and slotMapping[itemEquipLoc] then
                            print(string.format("|cff00ff00MyAutoRoller|r: Greeded on %s (Not an Upgrade)", name))
                        else
                            print(string.format("|cff00ff00MyAutoRoller|r: Greeded on %s", name))
                        end
                    end
                    return
                end
            elseif action == "greed" then
                if canGreed then
                    RollOnLoot(rID, 2)
                    if MyAutoRollerDB.chatAnnounce then
                        print(string.format("|cff00ff00MyAutoRoller|r: Greeded on %s", name))
                    end
                    return
                end
            elseif action == "need" then
                local isUsable, unUsableReason = IsItemUsableByClass(itemLink)
                local isDisqualified, disqStat = HasDisqualifiedStat(itemLink)
                if not isUsable or isDisqualified then
                    local reason = (not isUsable and ("Cannot use " .. (unUsableReason or "item type"))) or ("Contains disabled stat: " .. tostring(disqStat))
                    if MyAutoRollerDB.passIfNotUpgrade then
                        RollOnLoot(rID, 0)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Skipped Need on %s (%s). Passed instead", name, reason))
                        end
                    elseif canGreed then
                        RollOnLoot(rID, 2)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Skipped Need on %s (%s). Greeded instead", name, reason))
                        end
                    end
                elseif (not bindOnPickUp) and MyAutoRollerDB.boeSafety then
                    if MyAutoRollerDB.passIfNotUpgrade then
                        RollOnLoot(rID, 0)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Skipped Need on BoE item %s (BoE Safety Enabled). Passed instead", name))
                        end
                    elseif canGreed then
                        RollOnLoot(rID, 2)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Skipped Need on BoE item %s (BoE Safety Enabled). Greeded instead", name))
                        end
                    end
                else
                    if canNeed then
                        RollOnLoot(rID, 1)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Needed on %s", name))
                        end
                    elseif MyAutoRollerDB.passIfNotUpgrade then
                        RollOnLoot(rID, 0)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Passed on %s (Cannot Need)", name))
                        end
                    elseif canGreed then
                        RollOnLoot(rID, 2)
                        if MyAutoRollerDB.chatAnnounce then
                            print(string.format("|cff00ff00MyAutoRoller|r: Greeded on %s (Cannot Need)", name))
                        end
                    end
                end
            elseif action == "disenchant" then
                if canDisenchant then
                    RollOnLoot(rID, 3)
                    if MyAutoRollerDB.chatAnnounce then
                        print(string.format("|cff00ff00MyAutoRoller|r: Disenchanted %s", name))
                    end
                elseif canGreed then
                    RollOnLoot(rID, 2)
                    if MyAutoRollerDB.chatAnnounce then
                        print(string.format("|cff00ff00MyAutoRoller|r: Disenchant not available. Greeded on %s instead", name))
                    end
                end
            end
        end

        ProcessLootRoll(rollID, 0)
    end
end)

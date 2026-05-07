TotemStomper = {}

TotemStomper.CURRENT_DB_VERSION = 1

function TotemStomperInitDB()
    defaultDB = {
        __version = TotemStomper.CURRENT_DB_VERSION,
        buttonWidth = 36,
        buttonHeight = 36,
        low_opacity = 0.4,
        high_opacity = 1,
        showduration_update_interval = 0.5,
        showDuration = true,
        moveable = true,
        macroReset = 15,
        totems = {
            { spell = "Windfury Totem", enabled = true },
            { spell = "Strength of Earth Totem", enabled = true },
            { spell = "Searing Totem", enabled = true },
            { spell = "Healing Stream Totem", enabled = false },
        }
    }
    
    local ok, needsReset = pcall(function()
        return not TotemStomperDB or TotemStomperDB.__version < TotemStomper.CURRENT_DB_VERSION
    end)

    if not ok or needsReset then
        print("|cff0070ddTotemStomper: Migrating settings...|r")
        TotemStomperDB = CopyTable(defaultDB)
    end
    
    TotemStomper.DB = TotemStomperDB
end

TotemStomper.ValidateDatabase = function()
    local playerLevel = UnitLevel("player")
    
    for i, data in ipairs(TotemStomper.DB.totems) do
        local spellName = data.spell
        local isValid = false
        
        -- Loop through our new options to see if the saved spell is allowed here
        for element, spells in pairs(TotemStomper.totemOptions) do
            for _, info in ipairs(spells) do
                if info.name == spellName then
                    -- Check expansion and level
                    local levelOk = playerLevel >= (info.minLevel or 1)
                    local versionOk = not (info.tbcOnly and not TotemStomper.IsTBC)
                    
                    if levelOk and versionOk then
                        isValid = true
                    end
                    break
                end
            end
            if isValid then break end
        end

        -- If it's not valid (e.g. TBC spell on Classic), reset it to a safe default
        if not isValid then
            print("|cff0070ddTotemStomper: Resetting invalid totem: " .. spellName .. "|r")
            data.spell = "Searing Totem" -- Or a sensible default for that slot
            data.enabled = false
        end
    end
end


TotemStomper.buttons = {}
TotemStomper.dropdown_shown = false

-- Version Detection
TotemStomper.IsTBC = select(4, GetBuildInfo()) >= 20000 -- TBC is version 2.x.x

-- Talent Helper: Returns true if the player has the specified talent
-- tab: 1 (Ele), 2 (Enh), 3 (Resto)
TotemStomper.HasTalent = function(tab, index)
    local _, _, _, _, rank = GetTalentInfo(tab, index)
    return rank and rank > 0
end

TotemStomper.totemOptions = {
    Earth = {
        { name = "Strength of Earth Totem", minLevel = 10 },
        { name = "Earthbind Totem", minLevel = 6 },
        { name = "Tremor Totem", minLevel = 18 },
        { name = "Stoneskin Totem", minLevel = 4 },
        { name = "Stoneclaw Totem", minLevel = 8 },
        { name = "Earth Elemental Totem", minLevel = 66, tbcOnly = true },
    },
    Fire  = {
        { name = "Searing Totem", minLevel = 10 },
        { name = "Fire Nova Totem", minLevel = 12 },
        { name = "Magma Totem", minLevel = 26 },
        { name = "Frost Resistance Totem", minLevel = 24 },
        { name = "Flametongue Totem", minLevel = 10 },
        -- Elemental Talent: Totem of Wrath
        { name = "Totem of Wrath", minLevel = 50, talent = {1, 20}, tbcOnly = true }, 
        { name = "Fire Elemental Totem", minLevel = 68, tbcOnly = true },
    },
    Water = {
        { name = "Healing Stream Totem", minLevel = 20 },
        { name = "Mana Spring Totem", minLevel = 26 },
        { name = "Disease Cleansing Totem", minLevel = 38 },
        { name = "Poison Cleansing Totem", minLevel = 22 },
        { name = "Fire Resistance Totem", minLevel = 28 },
        -- Resto Talent: Mana Tide
        { name = "Mana Tide Totem", minLevel = 40, talent = {3, 8} },
    },
    Air   = {
        { name = "Windfury Totem", minLevel = 32 },
        { name = "Grace of Air Totem", minLevel = 42 },
        { name = "Nature Resistance Totem", minLevel = 30 },
        { name = "Grounding Totem", minLevel = 30 },
        { name = "Windwall Totem", minLevel = 36 },
        { name = "Tranquil Air Totem", minLevel = 50 },
        { name = "Wrath of Air Totem", minLevel = 64, tbcOnly = true },
    },
}

TotemStomper.DropDownMenu = CreateFrame("Frame", "TotemStomperDropdown", UIParent, "UIDropDownMenuTemplate")

TotemStomper.UpdateTotemDurations = function()
    for i, btn in ipairs(TotemStomper.buttons) do
        local totem = TotemStomper.DB.totems[i]
        for slot = 1, 4 do
            local haveTotem, name, startTime, duration = GetTotemInfo(slot)
            if haveTotem and name:lower():find(totem.spell:lower(), 1, true) then
                btn.cooldown:SetCooldown(startTime, duration)
                break
            end
        end
    end
end

TotemStomper.handleMoveable = function()
    if not TotemStomper.DB.moveable then
        if TotemStomper.MainUI.dragText then
            TotemStomper.MainUI.dragText:Hide()
            TotemStomper.MainUI.dragText = nil
        end
        return
    end

    local dragText = CreateFrame("Frame", nil, TotemStomper.MainUI, "BackdropTemplate")
    dragText:SetSize(20, 20)
    dragText:SetPoint("TOPLEFT", TotemStomper.MainUI, "TOPLEFT", 0, 2 + TotemStomper.DB.buttonHeight / 2)
    dragText:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    dragText:SetBackdropColor(0, 0, 0, 0.6)

    local dragFont = dragText:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dragFont:SetAllPoints()
    dragFont:SetText("O")

    dragText:EnableMouse(true)
    dragText:RegisterForDrag("LeftButton")

    -- The Hover Tooltip logic
    dragText:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Lock TotemStomper", 1, 1, 1) -- Title
        GameTooltip:AddLine("Shift + Right-Click on any Totem to lock or unlock the frame", 1, 0.82, 0, true) -- Help text
        GameTooltip:Show()
    end)
    
    dragText:SetScript("OnLeave", function() 
        GameTooltip:Hide() 
    end)

    dragText:SetScript("OnDragStart", function() TotemStomper.MainUI:StartMoving() end)
    dragText:SetScript("OnDragStop", function() TotemStomper.MainUI:StopMovingOrSizing() end)
    
    TotemStomper.MainUI.dragText = dragText
end

TotemStomper.handleShowDuration = function()
    if TotemStomper.DB.showDuration then
        if not TotemStomper.TickerShowDuration then
            TotemStomper.TickerShowDuration = C_Timer.NewTicker(TotemStomper.DB.showduration_update_interval, TotemStomper.UpdateTotemDurations)
        end
    else
        if TotemStomper.TickerShowDuration then
            TotemStomper.TickerShowDuration:Cancel()
            TotemStomper.TickerShowDuration = nil
        end
        
        for _, btn in ipairs(TotemStomper.buttons) do
            if btn.cooldown then
                btn.cooldown:Clear()
            end
        end
    end
end

TotemStomper.ShowDropdown = function(menu, anchor)
    UIDropDownMenu_Initialize(TotemStomper.DropDownMenu, function(_, level)
        for _, item in ipairs(menu) do
            local info = UIDropDownMenu_CreateInfo()
            for k, v in pairs(item) do info[k] = v end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    ToggleDropDownMenu(1, nil, TotemStomper.DropDownMenu, anchor, 0, 0)
end

TotemStomper.BuildDropdownMenu = function(index)
    local menu = {}
    local playerLevel = UnitLevel("player")

    for element, spells in pairs(TotemStomper.totemOptions) do
        table.insert(menu, {
            text = "---- " .. element .. " ----",
            isTitle = true,
            notCheckable = true,
        })

        for _, data in ipairs(spells) do
            local isAvailable = true

            if data.tbcOnly and not TotemStomper.IsTBC then
                isAvailable = false
            end

            if isAvailable and data.minLevel and playerLevel < data.minLevel then
                isAvailable = false
            end

            if isAvailable and data.talent then
                if not TotemStomper.HasTalent(data.talent[1], data.talent[2]) then
                    isAvailable = false
                end
            end

            -- Only add if the player actually knows the spell (or can learn it)
            -- TODO: Use GetSpellInfo to verify existence in the spellbook
            if isAvailable then
                table.insert(menu, {
                    text = data.name,
                    icon = GetSpellTexture(data.name),
                    func = function()
                        TotemStomper.DB.totems[index].spell = data.name
                        TotemStomper.dropdown_shown = false
                        TotemStomper.RebuildTotemButtons()
                    end
                })
            end
        end
    end
    return menu
end

TotemStomper.CreateTotemButton = function(index, spell)
    -- Check if spell icons are loaded
    local icon = GetSpellTexture(spell)
    if not icon then
        C_Timer.After(1, function() TotemStomper.CreateTotemButton(index, spell) end)
        return
    end
    
    local btn = CreateFrame("Button", "TotemStomperBtn" .. spell, TotemStomper.MainUI, "SecureActionButtonTemplate, ActionButtonTemplate")
    btn:SetSize(TotemStomper.DB.buttonWidth, TotemStomper.DB.buttonHeight)
    btn:SetPoint("LEFT", (index - 1) * 40, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spell)

    btn:SetAlpha(TotemStomper.DB.totems[index].enabled and TotemStomper.DB.high_opacity or TotemStomper.DB.low_opacity)

    
    btn.icon:SetTexture(icon)

    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(btn)
    btn.cooldown:SetDrawEdge(false)
    btn.cooldown:SetDrawBling(false)
    btn.cooldown:SetReverse(true)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local _, _, _, _, _, _, spellID = GetSpellInfo(spell)
        if spellID then
            GameTooltip:SetHyperlink("spell:" .. spellID)
        else
            GameTooltip:SetText(spell)
        end
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    btn:SetScript("OnClick", function(self, button)
        if UnitAffectingCombat("player") then return end
        if button == "RightButton" then
            if IsShiftKeyDown() then
                TotemStomper.DB.moveable = not TotemStomper.DB.moveable
                TotemStomper.handleMoveable()
            else
                if TotemStomper.dropdown_shown then
                    CloseDropDownMenus()
                else
                    TotemStomper.ShowDropdown(TotemStomper.BuildDropdownMenu(index), self)
                end
                TotemStomper.dropdown_shown = not TotemStomper.dropdown_shown
            end
        else
            local entry = TotemStomper.DB.totems[index]
            entry.enabled = not entry.enabled
            self:SetAlpha(entry.enabled and TotemStomper.DB.high_opacity or TotemStomper.DB.low_opacity)
            TotemStomper.UpdateMacro()
        end
    end)

    TotemStomper.buttons[index] = btn
end

TotemStomper.RebuildTotemButtons = function()
    if UnitAffectingCombat("player") then return end
    for _, btn in ipairs(TotemStomper.buttons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    TotemStomper.buttons = {}
    for i, data in ipairs(TotemStomper.DB.totems) do
        TotemStomper.CreateTotemButton(i, data.spell)
    end
    TotemStomper.UpdateMacro()
end

TotemStomper.initMainUI = function()
    TotemStomper.MainUI = CreateFrame("Frame", "TotemStomperUI", UIParent, "BackdropTemplate")
    TotemStomper.MainUI:SetSize(TotemStomper.DB.buttonWidth * 4, TotemStomper.DB.buttonHeight)
    TotemStomper.MainUI:SetPoint("CENTER", TotemStomper.DB.buttonWidth * 4, TotemStomper.DB.buttonHeight * 2)
    TotemStomper.MainUI:SetMovable(true)
    TotemStomper.handleMoveable()
end

TotemStomper.UpdateMacro = function()
    local macroName = "TotemStomper"
    local resetTimer = TotemStomper.DB.macroReset or 15
    local body = "#showtooltip \n/castsequence reset=combat/" .. resetTimer .. " "

    for _, data in ipairs(TotemStomper.DB.totems) do
        if data.enabled then
            body = body .. data.spell .. ", "
        end
    end

    body = body:gsub(", $", "") -- remove trailing comma

    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then
        CreateMacro(macroName, "INV_MISC_QUESTIONMARK", body, true)
    else
        EditMacro(macroIndex, macroName, nil, body)
    end
end

-- Init routine
TotemStomper.InitTotemStomper = function()
    TotemStomper.initMainUI()
    TotemStomper.RebuildTotemButtons()
    TotemStomper.handleShowDuration()
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "TotemStomper" then
        TotemStomperInitDB()
        if TotemStomper.ValidateDatabase then
            TotemStomper.ValidateDatabase()
        end
        TotemStomper.InitTotemStomper()
        TotemStomper.UpdateMacro()
        self:UnregisterAllEvents()
        self:SetScript("OnEvent", nil)
        self:Hide()
        print("|cff0070ddTotemStomper ready to stomp!|r")
    end
end)

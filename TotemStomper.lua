TotemStomper = {}

TotemStomper.CURRENT_DB_VERSION = 1

function TotemStomperInitDB()
    defaultDB = {
        __version = 1,
        buttonWidth = 36,
        buttonHeight = 36,
        low_opacity = 0.4,
        high_opacity = 1,
        showduration_update_interval = 0.5,
        showDuration = true,
        moveable = true,
        totems = {
            { spell = "Healing Stream Totem", enabled = true },
            { spell = "Searing Totem", enabled = true },
            { spell = "Stoneskin Totem", enabled = true },
            { spell = "Windfury Totem", enabled = false },
        }
    }
    
    if not TotemStomperDB or TotemStomperDB.__version < TotemStomper.CURRENT_DB_VERSION then
        print("TotemStomper: Migrating settings...")
        TotemStomperDB = CopyTable(defaultDB)
    end
    TotemStomper.DB = TotemStomperDB
end


TotemStomper.buttons = {}
TotemStomper.dropdown_shown = false

TotemStomper.totemOptions = {
    Earth = { "Strength of Earth Totem", "Earthbind Totem", "Tremor Totem", "Stoneskin Totem", "Stoneclaw Totem" },
    Fire  = { "Searing Totem", "Fire Nova Totem", "Magma Totem", "Frost Resistance Totem", "Flametongue Totem" },
    Water = { "Healing Stream Totem", "Mana Spring Totem", "Disease Cleansing Totem", "Poison Cleansing Totem", "Fire Resistance Totem" },
    Air   = { "Windfury Totem", "Grace of Air Totem", "Nature resistance Totem", "Grounding Totem", "Windwall Totem", "Tranquil Air Totem" },
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
    dragFont:SetTextColor(1, 1, 1, 0.8)

    dragText:EnableMouse(true)
    dragText:RegisterForDrag("LeftButton")
    dragText:SetScript("OnDragStart", function() TotemStomper.MainUI:StartMoving() end)
    dragText:SetScript("OnDragStop", function() TotemStomper.MainUI:StopMovingOrSizing() end)
    TotemStomper.MainUI.dragText = dragText
end

TotemStomper.handleShowDuration = function()
    if TotemStomper.DB.showDuration then
        if not TotemStomper.TickerShowDuration then
            TotemStomper.TickerShowDuration = C_Timer.NewTicker(TotemStomper.DB.showduration_update_interval, TotemStomper.UpdateTotemDurations)
        end
    elseif TotemStomper.TickerShowDuration then
        TotemStomper.TickerShowDuration:Cancel()
        TotemStomper.TickerShowDuration = nil
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
    for element, spells in pairs(TotemStomper.totemOptions) do
        table.insert(menu, {
            text = "---- " .. element .. " ----",
            isTitle = true,
            notCheckable = true,
            disabled = true,
        })
        for _, spell in ipairs(spells) do
            table.insert(menu, {
                text = spell,
                icon = GetSpellTexture(spell),
                func = function()
                    TotemStomper.DB.totems[index].spell = spell
                    TotemStomper.dropdown_shown = false
                    TotemStomper.RebuildTotemButtons()
                end
            })
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
        print("Clicked", button)
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
    local body = "#showtooltip \n/castsequence reset=combat/15 "

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
        TotemStomper.InitTotemStomper()
        self:UnregisterAllEvents()
        self:SetScript("OnEvent", nil)
        self:Hide()
        print("|cff0070ddTotemStomper ready to stomp!|r")
    end
end)

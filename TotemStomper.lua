local dropdown_shown = false

-- Create Buttons
local buttons = {}

-- All possible totems per type (you can expand this list)
local totemOptions = {
    Earth = { "Strength of Earth Totem", "Earthbind Totem", "Tremor Totem", "Stoneskin Totem", "Stoneclaw Totem" },
    Fire  = { "Searing Totem", "Fire Nova Totem", "Magma Totem", "Frost Resistance Totem", "Flametongue Totem" },
    Water = { "Healing Stream Totem", "Mana Spring Totem", "Disease Cleansing Totem", "Poison Cleansing Totem", "Fire Resistance Totem" },
    Air   = { "Windfury Totem", "Grace of Air Totem", "Nature resistance Totem", "Grounding Totem", "Windwall Totem", "Tranquil Air Totem" },
}

TotemStomperDB = TotemStomperDB or {
    buttonWidth = 36,
    buttonHeight = 36,
    low_opacity = 0.4,
    high_opacity = 1,
    showTimers = true,
    totems = {
        { spell = "Healing Stream Totem", enabled = true },
        { spell = "Searing Totem", enabled = true },
        { spell = "Stoneskin Totem", enabled = false },
        { spell = "Windfury Totem", enabled = true },
    }
}

local function UpdateTotemDurations()
    for i, btn in ipairs(buttons) do
        local totem = TotemStomperDB.totems[i]
        local found = false
        for slot = 1, 4 do
            local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
            if haveTotem and string.find(name:lower(), totem.spell:lower(), 1, true) then
                local timeLeft = startTime + duration - GetTime()
                btn.cooldown:SetCooldown(startTime, duration)
                break
            end
        end
    end
end


-- Main UI Frame
local frame = CreateFrame("Frame", "TotemStomperUI", UIParent, "BackdropTemplate")
frame:SetSize(TotemStomperDB.buttonWidth * 8, TotemStomperDB.buttonHeight * 2)
frame:SetPoint("CENTER", 0, -100)   
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Create your own dropdown frame (global or local is fine)
local DropDownMenu = CreateFrame("Frame", "TotemStomperDropdown", UIParent, "UIDropDownMenuTemplate")

local function ShowDropdown(menu, anchor)
    -- Create a function to initialize the dropdown menu
    UIDropDownMenu_Initialize(DropDownMenu, function(self, level)
        for i, item in ipairs(menu) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.func = item.func
            info.icon = item.icon
            info.iconCoords = {0, 1, 0, 1}

            info.tooltipTitle = item.spell
            info.tooltipText = item.spell

            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Show the dropdown menu
    ToggleDropDownMenu(1, nil, DropDownMenu, anchor, 0, 0)
end

local function CreateTotemButton(index, spell)
    local btn = CreateFrame("Button", "TotemStomperBtn"..spell, frame, "SecureActionButtonTemplate, ActionButtonTemplate")
    btn:SetSize(TotemStomperDB.buttonWidth, TotemStomperDB.buttonHeight)
    btn:SetPoint("LEFT", (index - 1) * 40, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spell)
    btn:SetAlpha(TotemStomperDB.totems[index].enabled and TotemStomperDB.high_opacity or TotemStomperDB.low_opacity)
    
    local icon = GetSpellTexture(spell)
    if not icon then
        RebuildTotemButtons()
        return
    end

    btn.icon:SetTexture(icon or 1368)

    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(btn)
    btn.cooldown:SetDrawEdge(false)
    btn.cooldown:SetDrawBling(false)
    -- btn.cooldown:SetSwipeColor(0, 0, 0, 0.6)  -- optional: dark swipe effect
    btn.cooldown:SetReverse(true)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if spell then
            local spellName, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spell)
            if spellID then
                GameTooltip:SetHyperlink("spell:" .. spellID)
            else
                GameTooltip:SetText(spellName)
            end
            btn:SetAttribute("spell", spellID or spellName)
        end
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            local menu = {}

            -- Create a menu item for each spell
            for element, spells in pairs(totemOptions) do
                -- Add group header/separator
                table.insert(menu, {
                    text = "---- " .. element .. " ----",
                    isTitle = true,
                    notCheckable = true,
                    disabled = true,
                })
        
                -- Add spell entries
                for _, spell in ipairs(spells) do
                    local icon = GetSpellTexture(spell)
                    table.insert(menu, {
                        text = spell,
                        icon = icon,
                        func = function()
                            TotemStomperDB.totems[index].spell = spell
                            dropdown_shown = false
                            btn:SetAlpha(1)
                            UpdateMacro()
                            RebuildTotemButtons()
                        end,
                        notCheckable = false,
                    })
                end
            end

            if dropdown_shown then
                dropdown_shown = false
                CloseDropDownMenus()
            else
                dropdown_shown = true
                ShowDropdown(menu, self)
            end
        else
            TotemStomperDB.totems[index].enabled = not TotemStomperDB.totems[index].enabled
            self:SetAlpha(TotemStomperDB.totems[index].enabled and TotemStomperDB.high_opacity or TotemStomperDB.low_opacity)
            UpdateMacro()
        end
    end)

    -- CreateDropDownButton(btn, name, index)

    buttons[index] = btn
end

function RebuildTotemButtons()
    -- Remove old buttons
    for _, btn in pairs(buttons) do
        btn:Hide()
        btn:SetParent(nil)
        btn = nil
    end
    buttons = {}

    -- Create new buttons in order
    for i, data in ipairs(TotemStomperDB.totems) do
        CreateTotemButton(i, data.spell)
    end
end


function UpdateMacro()
    local macroName = "TotemStomper"
    local macroBody = "/castsequence reset=combat/15 "
    for _, totem in ipairs(TotemStomperDB.totems) do
        if totem.enabled then
            macroBody = macroBody .. totem.spell .. ","
        end
    end
    macroBody = macroBody:sub(1, -2) -- remove trailing comma

    local existingIndex = GetMacroIndexByName(macroName)
    if existingIndex > 0 then
        EditMacro(existingIndex, macroName, nil, macroBody)
    else
        CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroBody, true)
    end
end

C_Timer.After(1, function()
    RebuildTotemButtons()
    UpdateMacro()
    print("TotemStomper: Ready to stomp!")
end)

if TotemStomperDB.showTimers then
    C_Timer.NewTicker(1, UpdateTotemDurations)
end
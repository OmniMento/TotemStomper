if select(2, UnitClass("player")) ~= "SHAMAN" then return end

local addonName, addonTable = ...
local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local addonVersion = GetMetadata(addonName, "Version") or "0.0.1"

TotemStomper.OptionsPanel = CreateFrame("Frame", "TotemStomperOptions")
TotemStomper.OptionsPanel.name = "TotemStomper"

-- Register panel depending on API (Support for both Old and New WoW UI)
if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(TotemStomper.OptionsPanel)
else
    local category = Settings.RegisterCanvasLayoutCategory(TotemStomper.OptionsPanel, TotemStomper.OptionsPanel.name)
    Settings.RegisterAddOnCategory(category)
end
TotemStomper.OptionsPanel:Hide()

-- ===== Utility functions =====
TotemStomper.CreateCheckbox = function(name, label, tooltip, parent, onClick)
    local cb = CreateFrame("CheckButton", "TotemStomperOptCheckbox" .. name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb.label = _G[cb:GetName() .. "Text"]
    cb.label:SetText(label)
    cb.tooltipText = label
    cb.tooltipRequirement = tooltip
    cb:SetScript("OnClick", function(self)
        local val = self:GetChecked()
        onClick(self, val)
    end)
    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1, true)
        if tooltip then
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    cb.SetDisabled = function(self, disable)
        self:SetEnabled(not disable)
        self.label:SetFontObject(disable and 'GameFontDisable' or 'GameFontHighlight')
    end
    return cb
end

TotemStomper.OptionsWatchList = {}
TotemStomper.RegisterWatchedOption = function(checkbox, dbKey)
    table.insert(TotemStomper.OptionsWatchList, { checkbox = checkbox, dbKey = dbKey })
end

-- Track if options are already built so we don't duplicate them on every OnShow
local optionsBuilt = false

TotemStomper.CreateOptions = function()
    if optionsBuilt then return end
    
    local title = TotemStomper.OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addonName .. " v" .. addonVersion)

    local desc = TotemStomper.OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Totems will be stomped from left to right")
    
    local desc2 = TotemStomper.OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc2:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
    desc2:SetText("No reconfiguration during combat")

    -- Duration Checkbox
    local cbDuration = TotemStomper.CreateCheckbox("Duration", "Totem Duration", "Show duration text on totems", TotemStomper.OptionsPanel, function(_, val)
        TotemStomper.DB.showDuration = val
        TotemStomper.handleShowDuration()
    end)
    cbDuration:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -20)
    TotemStomper.RegisterWatchedOption(cbDuration, "showDuration")

    -- Moveable Checkbox
    local cbMoveable = TotemStomper.CreateCheckbox("Moveable", "Moveable (Shift Right Click on Totem)", "Allow moving the addon", TotemStomper.OptionsPanel, function(_, val)
        TotemStomper.DB.moveable = val
        TotemStomper.handleMoveable()
    end)
    cbMoveable:SetPoint("TOPLEFT", cbDuration, "BOTTOMLEFT", 0, -10)
    TotemStomper.RegisterWatchedOption(cbMoveable, "moveable")

    -- Macro Reset Slider
    local sliderReset = TotemStomper.CreateSlider("MacroReset", "Macro Reset Timer", 6, 30, TotemStomper.OptionsPanel, function(_, val)
        TotemStomper.DB.macroReset = val
        TotemStomper.UpdateMacro()
    end)
    sliderReset:SetPoint("TOPLEFT", cbMoveable, "BOTTOMLEFT", 10, -40)
    
    local sliderHelp = TotemStomper.OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sliderHelp:SetPoint("TOPLEFT", sliderReset, "BOTTOMLEFT", -10, -15)
    sliderHelp:SetText("Seconds of inactivity before the macro restarts at the first totem.\n(Min 6s recommended for GCD safety)")

    -- Logic to update slider position on show
    sliderReset:SetValue(TotemStomper.DB.macroReset or 15)
    
    optionsBuilt = true
end

-- ===== OnShow/OnHide Handler =====
TotemStomper.OptionsPanel:SetScript("OnShow", function(self)
    TotemStomper.CreateOptions() -- Only builds once
    
    -- Sync checkboxes with current DB values
    local function syncUI()
        for _, option in pairs(TotemStomper.OptionsWatchList) do
            option.checkbox:SetChecked(TotemStomper.DB[option.dbKey])
        end
    end
    
    syncUI()
    
    -- Optional: If you change settings via chat commands, this keeps the UI in sync
    TotemStomper.WatchlistUpdater = C_Timer.NewTicker(0.5, syncUI) 
end)

TotemStomper.OptionsPanel:SetScript("OnHide", function(self)
    if TotemStomper.WatchlistUpdater then
        TotemStomper.WatchlistUpdater:Cancel()
        TotemStomper.WatchlistUpdater = nil
    end
end)

TotemStomper.CreateSlider = function(name, label, minVal, maxVal, parent, onValueChanged)
    -- We use a basic frame to hold the slider to ensure textures don't conflict
    local slider = CreateFrame("Slider", "TS_Slider_" .. name, parent, "OptionsSliderTemplate")
    slider:SetSize(180, 17)
    
    -- Force the background via code to ensure it shows up
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.3) -- Subtle dark background for the track

    _G[slider:GetName() .. 'Text']:SetText(label)
    _G[slider:GetName() .. 'Low']:SetText(minVal)
    _G[slider:GetName() .. 'High']:SetText(maxVal)
    
    slider.valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slider.valueText:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    
    slider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        self.valueText:SetText(val .. "s")
        onValueChanged(self, val)
    end)
    
    -- Sync initial value
    local currentVal = TotemStomper.DB.macroReset or 15
    slider:SetValue(currentVal)
    slider.valueText:SetText(currentVal .. "s")

    return slider
end
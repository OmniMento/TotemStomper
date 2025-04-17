local addonName = ...
local addonVersion = GetAddOnMetadata(addonName, "Version") or "0.0.1"

TotemStomper.OptionsPanel = CreateFrame("Frame", "TotemStomperOptions")
TotemStomper.OptionsPanel.name = "TotemStomper"

-- Register panel depending on API
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
TotemStomper.CreateOptions = function()
    local title = TotemStomper.OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addonName .. " v" .. addonVersion)

    local desc = TotemStomper.OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Totems will be stomped from left to right")
    local desc2 = TotemStomper.OptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc2:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
    desc2:SetText("No reconfiguration during combat")

    local cbDuration = TotemStomper.CreateCheckbox("Duration", "Totem Duration", "Show duration text on totems", TotemStomper.OptionsPanel, function(_, val)
        TotemStomper.DB.showDuration = val
        TotemStomper.handleShowDuration()
    end)
    cbDuration:SetPoint("TOPLEFT", desc2, "BOTTOMLEFT", 0, -20)
    TotemStomper.RegisterWatchedOption(cbDuration, "showDuration")
    cbDuration:Show()

    local cbMoveable = TotemStomper.CreateCheckbox("Moveable", "Moveable (Shift Right Click on Totem)", "Allow moving the addon", TotemStomper.OptionsPanel, function(_, val)
        TotemStomper.DB.moveable = val
        TotemStomper.handleMoveable()
    end)
    cbMoveable:SetPoint("TOPLEFT", cbDuration, "BOTTOMLEFT", 0, -10)
    TotemStomper.RegisterWatchedOption(cbMoveable, "moveable")
    cbMoveable:Show()
end

-- ===== OnShow Handler =====
TotemStomper.OptionsPanel:SetScript("OnShow", function(self)
    TotemStomper.CreateOptions()
    local updateWatchedOptions = function()
        for _, option in pairs(TotemStomper.OptionsWatchList) do
            option.checkbox:SetChecked(TotemStomper.DB[option.dbKey])
        end
    end
    TotemStomper.WatchlistUpdater = C_Timer.NewTicker(0.1, updateWatchedOptions)
end)
TotemStomper.OptionsPanel:SetScript("OnHide", function(self)
    if TotemStomper.WatchlistUpdater then
        TotemStomper.WatchlistUpdater:Cancel()
    end
end)
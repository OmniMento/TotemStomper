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

-- ===== OnShow Handler =====
TotemStomper.OptionsPanel:SetScript("OnShow", function(self)
    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addonName .. " v" .. addonVersion)

    local desc = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Totems will be stomped from left to right")

    local cbDuration = TotemStomper.CreateCheckbox("Duration", "Totem Duration", "Show duration text on totems", self, function(_, val)
        TotemStomper.DB.showDuration = val
        TotemStomper.handleShowDuration()
    end)
    cbDuration:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    cbDuration:SetChecked(TotemStomper.DB.showDuration)
    cbDuration:Show()

    local cbMoveable = TotemStomper.CreateCheckbox("Moveable", "Moveable (Shift Right Click on Totem)", "Allow moving the addon", self, function(_, val)
        TotemStomper.DB.moveable = val
        TotemStomper.handleMoveable()
    end)
    cbMoveable:SetPoint("TOPLEFT", cbDuration, "BOTTOMLEFT", 0, -10)
    cbMoveable:SetChecked(TotemStomper.DB.moveable)
    cbMoveable:Show()
end)

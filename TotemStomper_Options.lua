-- Create the Options Panel
local optionsPanel = CreateFrame("Frame", "TotemStomperOptions", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "TotemStomper"

-- -- Title Label
-- local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
-- title:SetPoint("TOPLEFT", 16, -16)
-- title:SetText("TotemStomper Options")

-- -- Create Button Width Slider
-- local buttonWidthSlider = CreateFrame("Slider", "TotemStomperButtonWidthSlider", optionsPanel, "OptionsSliderTemplate")
-- buttonWidthSlider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -30)
-- buttonWidthSlider:SetMinMaxValues(20, 100)
-- buttonWidthSlider:SetValueStep(1)
-- buttonWidthSlider:SetValue(TotemStomperDB.buttonWidth)
-- buttonWidthSlider:SetWidth(200)

-- -- Label for Button Width
-- local buttonWidthLabel = buttonWidthSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
-- buttonWidthLabel:SetPoint("BOTTOMLEFT", buttonWidthSlider, "TOPLEFT", 0, 5)
-- buttonWidthLabel:SetText("Button Width")

-- -- Update the saved variable when the slider is changed
-- buttonWidthSlider:SetScript("OnValueChanged", function(self, value)
--     TotemStomperDB.buttonWidth = value
-- end)

C_Timer.After(2, function()
    print("TotemStomper Options loading...")
    InterfaceOptions_AddCategory(optionsPanel)
    print("TotemStomper Options loaded.")
end)
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "TBCSilvermoonMusic" then return end  -- FIXED: was "SilvermoonMusic"
    self:UnregisterEvent("ADDON_LOADED")

    SilvermoonMusicDB = SilvermoonMusicDB or {}
    if SilvermoonMusicDB.enabled  == nil then SilvermoonMusicDB.enabled  = true end
    if SilvermoonMusicDB.timeMode == nil then SilvermoonMusicDB.timeMode = 1    end

    local category = Settings.RegisterVerticalLayoutCategory("Silvermoon Music")

    -- Checkbox: enable/disable
    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "SilvermoonMusic_Enabled",
            "enabled",
            SilvermoonMusicDB,
            Settings.VarType.Boolean,
            "Enable Silvermoon Music",
            true
        )
        setting:SetValueChangedCallback(function(_, value)
            if SilvermoonMusic_Refresh then SilvermoonMusic_Refresh() end
        end)
        Settings.CreateCheckbox(
            category, setting,
            "Replace Silvermoon City's music with the original TBC tracks."
        )
    end

    -- Dropdown: track mode
    do
        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add(1, "Auto (use server time)")
            container:Add(2, "Always play Day track")
            container:Add(3, "Always play Night track")
            container:Add(4, "Always play Intro track")
            container:Add(5, "Random (picks a track each loop)")
            return container:GetData()
        end

        local setting = Settings.RegisterAddOnSetting(
            category,
            "SilvermoonMusic_TimeMode",
            "timeMode",
            SilvermoonMusicDB,
            Settings.VarType.Number,
            "Track Selection",
            1
        )
        setting:SetValueChangedCallback(function(_, value)
            if SilvermoonMusic_Refresh then SilvermoonMusic_Refresh() end
        end)
        Settings.CreateDropdown(
            category, setting, GetOptions,
            "Auto picks day/night by server time, or lock to one track."
        )
    end

    Settings.RegisterAddOnCategory(category)
end)
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "TBCSilvermoonMusic" then return end
    self:UnregisterEvent("ADDON_LOADED")

    SilvermoonMusicDB = SilvermoonMusicDB or {}
    if SilvermoonMusicDB.enabled   == nil then SilvermoonMusicDB.enabled   = true end
    if SilvermoonMusicDB.timeMode  == nil then SilvermoonMusicDB.timeMode  = 1    end
    if SilvermoonMusicDB.trackDelay == nil then SilvermoonMusicDB.trackDelay = 180 end  -- 3 min default

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

    -- Slider: delay between tracks
    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "SilvermoonMusic_TrackDelay",
            "trackDelay",
            SilvermoonMusicDB,
            Settings.VarType.Number,
            "Delay Between Tracks",
            180
        )
        local sliderOptions = Settings.CreateSliderOptions(0, 300, 15)
        sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value)
                if value == 0 then return "None" end
                if value < 60 then return value .. "s" end
                return string.format("%dm %ds", math.floor(value/60), value % 60)
            end)
        Settings.CreateSlider(
            category, setting, sliderOptions,
            "Silence between tracks in seconds. 0 = seamless loop. Default (180s) matches WoW's built-in zone music behavior."
        )
    end

    Settings.RegisterAddOnCategory(category)
end)
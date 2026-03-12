local SILVERMOON_MAP_ID = 2393
local TRACK_DAY   = 9793
local TRACK_NIGHT = 9794
local TRACK_INTRO = 9801  -- the zone-entry fanfare

local currentHandle = nil
local isSwitching   = false
local lastTrack = nil

local function IsInSilvermoon()
    return C_Map.GetBestMapForUnit("player") == SILVERMOON_MAP_ID
end

local function IsNight()
    local s = C_DateAndTime.GetSecondsUntilDailyReset()
    return s > 82800 or s <= 39600
end

local function ChooseTrack()
    local mode = SilvermoonMusicDB and SilvermoonMusicDB.timeMode or 1
    if mode == 2 then return TRACK_DAY   end
    if mode == 3 then return TRACK_NIGHT end
    if mode == 4 then return TRACK_INTRO end
    if mode == 5 then
        local tracks = { TRACK_DAY, TRACK_NIGHT, TRACK_INTRO }
        -- remove last played to avoid immediate repeat
        local pool = {}
        for _, t in ipairs(tracks) do
            if t ~= lastTrack then pool[#pool + 1] = t end
        end
        lastTrack = pool[math.random(#pool)]
        return lastTrack
    end
    return IsNight() and TRACK_NIGHT or TRACK_DAY
end

local function StartMusic()
    SetCVar("Sound_EnableMusic", 0)
    isSwitching = true
    local track = ChooseTrack()
    _, currentHandle = PlaySound(track, "Talking Head", true, true)
    C_Timer.After(4.5, function() isSwitching = false end)
end

local function StopMusic()
    if currentHandle then
        StopSound(currentHandle, 2000)
        C_Timer.After(2.1, function()
            SetCVar("Sound_EnableMusic", 1)
            currentHandle = nil
        end)
    end
end

function SilvermoonMusic_Refresh()
    if not SilvermoonMusicDB or not SilvermoonMusicDB.enabled then
        StopMusic()
        return
    end
    if IsInSilvermoon() then
        if currentHandle then StopSound(currentHandle, 0) end
        StartMusic()
    end
end

local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneFrame:SetScript("OnEvent", function(_, _, isLogin, isReload)
    local delay = (isLogin or isReload) and 2 or 0
    C_Timer.After(delay, function()
        if not SilvermoonMusicDB or not SilvermoonMusicDB.enabled then
            StopMusic()
            return
        end
        if IsInSilvermoon() then
            if currentHandle then StopSound(currentHandle, 0) end
            StartMusic()
        else
            StopMusic()
        end
    end)
end)

local loopFrame = CreateFrame("Frame")
loopFrame:RegisterEvent("SOUNDKIT_FINISHED")
loopFrame:SetScript("OnEvent", function(_, _, soundHandle)
    if isSwitching then return end
    if soundHandle ~= currentHandle then return end
    if not IsInSilvermoon() then return end
    if not SilvermoonMusicDB or not SilvermoonMusicDB.enabled then return end
    StartMusic()
end)

--Failsafe in case of crashes / disconnects (So audio doesn't cut out)
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    SetCVar("Sound_EnableMusic", 1)
end)

SLASH_TBCSILVERMOONMUSIC1 = "/sm"
SlashCmdList["TBCSILVERMOONMUSIC"] = function()
    Settings.OpenToCategory("Silvermoon Music")
end
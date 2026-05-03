local SILVERMOON_MAP_ID = 2393
local TRACK_DAY   = 9793
local TRACK_NIGHT = 9794
local TRACK_INTRO = 9801  -- the zone-entry fanfare

local currentHandle       = nil
local isSwitching         = false
local lastTrack           = nil
local musicMuted          = false
local userMusicEnabled    = true  -- player's preference before we overrode Sound_EnableMusic
local introOnEnterPending = false
local suppressCvarWatch   = false

local function IsInSilvermoon()
    return C_Map.GetBestMapForUnit("player") == SILVERMOON_MAP_ID
end

local function IsNight()
    local s = C_DateAndTime.GetSecondsUntilDailyReset()
    return s > 82800 or s <= 39600
end

local function ChooseTrack()
    if introOnEnterPending then
        introOnEnterPending = false
        return TRACK_INTRO
    end
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

-- Wrapper so CVAR_UPDATE ignores changes made by the addon itself.
-- C_Timer.After(0) defers the flag reset to after the current frame's events
-- fire, covering both synchronous and asynchronous CVAR_UPDATE dispatch.
local function SetMusicCVar(value)
    suppressCvarWatch = true
    SetCVar("Sound_EnableMusic", value)
    C_Timer.After(0, function() suppressCvarWatch = false end)
end

local function StartMusic()
    -- Capture user's preference only on a fresh start (not mid-loop track switches)
    if not musicMuted then
        userMusicEnabled = GetCVar("Sound_EnableMusic") ~= "0"
    end
    if not userMusicEnabled then return end  -- respect player's mute preference

    SetMusicCVar(0)
    musicMuted  = true
    isSwitching = true
    local track = ChooseTrack()
    _, currentHandle = PlaySound(track, "Talking Head", true, true)
    C_Timer.After(4.5, function() isSwitching = false end)
end

local function StopMusic()
    if currentHandle then
        StopSound(currentHandle, 2000)
        C_Timer.After(2.1, function()
            if musicMuted then
                SetMusicCVar(userMusicEnabled and 1 or 0)
                musicMuted = false
            end
            currentHandle = nil
        end)
    elseif musicMuted then
        -- No handle (e.g. mid-delay gap between tracks) but music is still muted
        SetMusicCVar(userMusicEnabled and 1 or 0)
        musicMuted = false
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
            introOnEnterPending = SilvermoonMusicDB.introOnEnter == true
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

    local delay = (SilvermoonMusicDB.trackDelay or 0)
    if delay > 0 then
        currentHandle = nil  -- mark as idle during the gap
        C_Timer.After(delay, function()
            if not IsInSilvermoon() then return end
            if not SilvermoonMusicDB or not SilvermoonMusicDB.enabled then return end
            StartMusic()
        end)
    else
        StartMusic()
    end
end)

-- React when the player toggles music in Settings while the addon is active.
-- suppressCvarWatch prevents us from reacting to our own SetMusicCVar calls.
local cvarFrame = CreateFrame("Frame")
cvarFrame:RegisterEvent("CVAR_UPDATE")
cvarFrame:SetScript("OnEvent", function(_, _, cvarName, value)
    if cvarName ~= "Sound_EnableMusic" or suppressCvarWatch then return end
    userMusicEnabled = value ~= "0"
    if not userMusicEnabled and musicMuted then
        -- player muted music while addon was playing (or in delay gap)
        if currentHandle then
            StopSound(currentHandle, 2000)
            currentHandle = nil
        end
        musicMuted = false
        -- Do not call SetMusicCVar — player just set it to 0 themselves
    end
end)

-- Failsafe in case of crashes / disconnects (so audio doesn't cut out).
-- Only restore the CVar if the addon was the one that changed it; otherwise
-- we'd overwrite a mute the player intentionally set and corrupt their saved preference.
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    if musicMuted then
        SetCVar("Sound_EnableMusic", 1)
    end
end)

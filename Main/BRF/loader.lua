repeat task.wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local CONFIG_URL = "https://raw.githubusercontent.com/nostrainu/Dump/refs/heads/main/Main/games.json"

local function fetchConfig()
    local success, result = pcall(game.HttpGet, game, CONFIG_URL)
    if success then
        local _, decodedData = pcall(HttpService.JSONDecode, HttpService, result)
        return decodedData
    else
        warn("[Loader] Failed to fetch database.")
    end
    return nil
end

local function loadRemoteScript(url)
    local success, content = pcall(game.HttpGet, game, url)
    if success and content then
        local func, err = loadstring(content)
        if func then
            local executeSuccess, executeErr = pcall(func)
            if not executeSuccess then
                warn("[Loader] Runtime error: " .. tostring(executeErr))
            end
        else
            warn("[Loader] Syntax error: " .. tostring(err))
        end
    else
        warn("[Loader] Failed to fetch script URL: " .. tostring(url))
    end
end

local gamesDb = fetchConfig()

if gamesDb then
    local placeIdStr = tostring(game.PlaceId)
    local gameIdStr = tostring(game.GameId)
    
    local gameData = gamesDb[placeIdStr] or gamesDb[gameIdStr]

    if gameData then
        print("[Loader] Initializing " .. gameData.Name .. "...")
        getgenv().uiActive = true
        
        for _, file in ipairs(gameData.Files) do
            loadRemoteScript(file.Url)
        end
    else
        warn("[Loader] Game not supported.")
    end
end
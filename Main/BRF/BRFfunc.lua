local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local defaultFOV = Camera.FieldOfView
local fovConnection

local function fov(active)
    if fovConnection then
        fovConnection:Disconnect()
        fovConnection = nil
    end
    if active then
        defaultFOV = Camera.FieldOfView
        fovConnection = Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
            if Camera.FieldOfView ~= defaultFOV then
                Camera.FieldOfView = defaultFOV
            end
        end)
    end
end
getgenv().fov = fov

--// Seed Roll
local Registry = require(ReplicatedStorage.Shared.Registry)
local RollSeeds = ReplicatedStorage.Remotes.RollSeeds
local BuySeed = ReplicatedStorage.Remotes.BuySeed

local plantNames = {}
for name, data in pairs(Registry.Plants) do
    if type(data) == "table" and data.RollChance and data.RollChance > 0 then
        table.insert(plantNames, name)
    end
end
table.sort(plantNames)
getgenv().plantNames = plantNames

local function hasSelectedSeeds()
    local selected = getgenv().SelectedSeeds
    if not selected then return false end
    for i, isSelected in pairs(selected) do
        if isSelected then
            return true
        end
    end
    return false
end
getgenv().hasSelectedSeeds = hasSelectedSeeds

local rollConnection
local function connectRollHandler()
    if rollConnection then rollConnection:Disconnect() end
    rollConnection = RollSeeds.OnClientEvent:Connect(function(seeds, animPool)
        local selected = getgenv().SelectedSeeds or {}
        local boughtAny = false

        for i, seedName in pairs(seeds) do
            if not getgenv().uiActive or not getgenv().AutoRollSeeds then break end
            if selected[seedName] then
                task.wait(2.5)
                if not getgenv().uiActive or not getgenv().AutoRollSeeds then break end
                BuySeed:FireServer(i)
                boughtAny = true
            end
        end

        if getgenv().AutoRollSeeds and getgenv().uiActive then
            task.wait(boughtAny and 3 or 4)
            if getgenv().uiActive and getgenv().AutoRollSeeds then
                pcall(function() RollSeeds:FireServer() end)
            end
        end
    end)
end
getgenv().connectRollHandler = connectRollHandler

fov(getgenv().AutoRollSeeds)
connectRollHandler()

task.spawn(function()
    while getgenv().uiActive do
        if getgenv().AutoRollSeeds then
            pcall(function() RollSeeds:FireServer() end)
            return
        end
        task.wait(1)
    end
end)

local function getPlot()
    local success, plot = pcall(function()
        return ReplicatedStorage.Remotes.Plot.GetPlot:InvokeServer()
    end)
    if success and plot then
        if not plot:GetAttribute("DataLoaded") then
            while not plot:GetAttribute("DataLoaded") do
                plot:GetAttributeChangedSignal("DataLoaded"):Wait()
            end
        end
        return plot
    end
    return nil
end

local function findFarmPlots(parent, list)
    list = list or {}
    for i, child in pairs(parent:GetChildren()) do
        if child.Name == "FarmPlot" then
            table.insert(list, child)
        else
            findFarmPlots(child, list)
        end
    end
    return list
end

local playerPlot = getPlot()
if playerPlot then
    getgenv().playerPlot = playerPlot
end

task.spawn(function()
    while getgenv().uiActive do
        if getgenv().AutoSellCrates then
            pcall(function()
                local plot = getgenv().playerPlot
                if plot then
                    local cratesFolder = plot:FindFirstChild("Crates")
                    if cratesFolder and #cratesFolder:GetChildren() > 0 then
                        local Event = game:GetService("ReplicatedStorage").Remotes.SellCrates
                        Event:FireServer()
                    end
                end
            end)
        end
        task.wait(1) 
    end
end)

--// Plot Unlock Loop
task.spawn(function()
    while getgenv().uiActive do
        if getgenv().AutoUnlockPlots then
            local plot = getgenv().playerPlot
            if plot then
                local farmPlots = findFarmPlots(plot)
                local unlockedAny = false
                
                for i, farmPlot in pairs(farmPlots) do
                    if unlockedAny then break end
                    
                    local floorName = farmPlot.Parent.Name
                    local isEnabled = false
                    
                    local selected = getgenv().SelectedFloors or {}
                    if floorName == "SecondFloor" then
                        isEnabled = selected["2nd Floor"]
                    elseif floorName == "ThirdFloor" then
                        isEnabled = selected["3rd Floor"]
                    elseif farmPlot.Parent == plot then
                        isEnabled = selected["1st Floor"]
                    end
                    
                    if isEnabled then
                        for i, slot in pairs(farmPlot:GetChildren()) do
                            if not slot:GetAttribute("Unlocked") then
                                local dirt = slot:FindFirstChild("Dirt")
                                if dirt then
                                    pcall(function()
                                        ReplicatedStorage.Remotes.UnlockPlot:FireServer(dirt)
                                    end)
                                    unlockedAny = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
            task.wait(2)
        else
            task.wait(1)
        end
    end
end)

--// Upgrade
task.spawn(function()
    while getgenv().uiActive do
        if getgenv().AutoBuyUpgrades then
            local plot = getgenv().playerPlot
            if plot then
                local activeFloors = {"Floor1"}
                if plot:FindFirstChild("SecondFloor") then
                    table.insert(activeFloors, "Floor2")
                end
                if plot:FindFirstChild("ThirdFloor") then
                    table.insert(activeFloors, "Floor3")
                end
                
                local boughtAny = false
                local plotUpgrades = getgenv().SelectedPlotUpgrades or {}
                
                --// Plot Upgrades
                for i, floor in pairs(activeFloors) do
                    if boughtAny then break end
                    
                    if plotUpgrades["Saw Range"] then
                        local success = ReplicatedStorage.Remotes.PlotUpgradeTransaction:InvokeServer("ExtraSawRange", floor)
                        if success then
                            boughtAny = true
                            break
                        end
                    end
                    if plotUpgrades["Sprinkler Range"] then
                        local success = ReplicatedStorage.Remotes.PlotUpgradeTransaction:InvokeServer("ExtraSprinklerRange", floor)
                        if success then
                            boughtAny = true
                            break
                        end
                    end
                    if plotUpgrades["Saw Yield"] then
                        local success = ReplicatedStorage.Remotes.PlotUpgradeTransaction:InvokeServer("ExtraYield", floor)
                        if success then
                            boughtAny = true
                            break
                        end
                    end
                    if plotUpgrades["Sprinkler Power"] then
                        local success = ReplicatedStorage.Remotes.PlotUpgradeTransaction:InvokeServer("ExtraPower", floor)
                        if success then
                            boughtAny = true
                            break
                        end
                    end
                end
                
                --// Global Upgrades
                if not boughtAny then
                    local globalUpgrades = getgenv().SelectedGlobalUpgrades or {}
                    
                    if globalUpgrades["Seed Rolls"] then
                        local success = ReplicatedStorage.Remotes.UpgradeSeedRolls:InvokeServer()
                        if success then
                            boughtAny = true
                        end
                    end
                    if not boughtAny and globalUpgrades["Seed Luck"] then
                        local success = ReplicatedStorage.Remotes.UpgradeSeedLuck:InvokeServer()
                        if success then
                            boughtAny = true
                        end
                    end
                    if not boughtAny and globalUpgrades["Farm Expansion"] then
                        local success = ReplicatedStorage.Remotes.UpgradeFarm:InvokeServer()
                        if success then
                            boughtAny = true
                        end
                    end
                end
            end
            task.wait(2)
        else
            task.wait(1)
        end
    end
end)

--// Playtime Rewards
local localClaimedMap = {}

local function getPlaytimeState()
    local success, state = pcall(function()
        return ReplicatedStorage.Remotes.GetPlaytimeRewardState:InvokeServer()
    end)
    return success and state or nil
end

local function updatePlaytimeUI(index)
    pcall(function()
        local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if not PlayerGui then return end
        
        local playtimeFrame = PlayerGui:FindFirstChild("MainUI")
            and PlayerGui.MainUI:FindFirstChild("Menus")
            and PlayerGui.MainUI.Menus:FindFirstChild("PlaytimeRewardsFrame")
            
        if playtimeFrame then
            local rewardUI = playtimeFrame.Main.Rewards:FindFirstChild(tostring(index))
            if rewardUI then
                if rewardUI:FindFirstChild("Btn") then
                    rewardUI.Btn.Visible = false
                end
                if rewardUI:FindFirstChild("ClaimedTxt") then
                    rewardUI.ClaimedTxt.Visible = true
                end
                if rewardUI:FindFirstChild("DayTxt") then
                    rewardUI.DayTxt.Visible = false
                end
                local icon = rewardUI:FindFirstChild("Icon")
                if icon and icon.HasTag and icon:HasTag("Wobble") then
                    pcall(function()
                        icon:RemoveTag("Wobble")
                        icon.Rotation = 0
                    end)
                end
            end
        end
    end)
end

local function claimPlaytimeReward(index)
    local success, result = pcall(function()
        return ReplicatedStorage.Remotes.ClaimPlaytimeReward:InvokeServer(index)
    end)
    if success and result then
        updatePlaytimeUI(index)
        return true
    end
    return false
end

task.spawn(function()
    while getgenv().uiActive do
        if getgenv().AutoClaimPlaytime then
            local state = getPlaytimeState()
            if state then
                local claimedMap = state.ClaimedMap or {}
                local earnedCount = state.EarnedCount or 0
                local timers = state.RewardTimers or {}

                for i = 1, 11 do
                    if claimedMap[tostring(i)] then
                        if not localClaimedMap[i] then
                            updatePlaytimeUI(i)
                            localClaimedMap[i] = true
                        end
                    elseif i <= earnedCount then
                        if claimPlaytimeReward(i) then
                            localClaimedMap[i] = true
                        end
                        task.wait(0.5)
                    end
                end

                local nextIndex = nil
                local nextWait = nil
                for i = 1, 11 do
                    if not claimedMap[tostring(i)] and i > earnedCount then
                        nextIndex = i
                        nextWait = timers[i] or 0
                        break
                    end
                end

                if nextIndex then
                    if nextWait > 0 then
                        local timeLeft = nextWait + 2
                        while timeLeft > 0 and getgenv().AutoClaimPlaytime and getgenv().uiActive do
                            task.wait(1)
                            timeLeft = timeLeft - 1
                        end
                    else
                        task.wait(5)
                    end
                else
                    task.wait(10)
                end
            else
                task.wait(10)
            end
        else
            task.wait(1)
        end
    end
end)

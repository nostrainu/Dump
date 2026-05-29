if game.PlaceId ~= 118821269826806 then return end

getgenv().gift = getgenv().gift ~= false
local un = getgenv().un or ""

local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local bag = lplr.PlayerGui.ScreenGui.Bag.ContentClip.Main._BagFrame
local remote = rs:WaitForChild("Msg"):WaitForChild("RemoteEvent"):WaitForChild("RemoteEvent")
local giftRemote = rs:WaitForChild("Msg"):WaitForChild("RemoteEvent"):WaitForChild("GiftRequest")
local vim = game:GetService("VirtualInputManager")
local tools = lplr.PlayerGui.ScreenGui.Main.Tools:WaitForChild("\229\183\165\229\133\183\230\160\143")

local function pressKey(keyCode)
    vim:SendKeyEvent(true, keyCode, false, game)
    task.wait()
    vim:SendKeyEvent(false, keyCode, false, game)
end

local function isSlot5Equipped()
    return tools:FindFirstChild("5") and tools["5"].Visible
end

local function getSlots()
    local slots = {}
    for i, v in pairs(bag:GetChildren()) do
        local idStr = v.Name:match("^BagSlot_(%d+)")
        if idStr then
            local equipIndicator = v:FindFirstChild("\232\163\133\229\164\135")
            if not (equipIndicator and equipIndicator.Visible) then
                table.insert(slots, tonumber(idStr))
            end
        end
    end
    return slots
end

local targetId = nil
local function getTarget()
    if targetId then return targetId end
    if un == "" then return nil end
    
    local success, id = pcall(function() return Players:GetUserIdFromNameAsync(un) end)
    if success and id then
        targetId = id
        return id
    end
    
    local player = Players:FindFirstChild(un)
    if player then
        targetId = player.UserId
        return player.UserId
    end
end

task.spawn(function()
    if #getSlots() == 0 then
        pressKey(Enum.KeyCode.Four)
        local start = os.clock()
        while #getSlots() == 0 and (os.clock() - start) < 2 do
            task.wait()
        end
    end

    while getgenv().gift do
        local target = getTarget()
        
        if not isSlot5Equipped() then
            local slots = getSlots()
            
            if #slots == 0 then
                getgenv().gift = false
                pressKey(Enum.KeyCode.Four)
                break
            end

            remote:FireServer("\232\163\133\229\164\135\231\137\169\229\147\129", {onlyID = slots[1]})
            task.wait()
        end

        pressKey(Enum.KeyCode.Five)
        task.wait()

        if target then
            giftRemote:FireServer(target)
            task.wait()
        end
        
        task.wait(0.05)
    end
end)

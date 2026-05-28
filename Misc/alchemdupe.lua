if game.PlaceId ~= 118821269826806 then return end

getgenv().gift = true
getgenv().delay = 5
--getgenv().amount = 0

un = "NuggetsKALB" 
local ids = {}

local Players = game:GetService("Players")

if un ~= "" then
    local player = Players:FindFirstChild(un)
    if player then
        table.insert(ids, player.UserId)
    end
end

task.spawn(function()
    while getgenv().gift do
        for i, v in pairs(ids) do
            game:GetService("ReplicatedStorage"):WaitForChild("Msg"):WaitForChild("RemoteEvent"):WaitForChild("GiftRequest"):FireServer(id)
            task.wait(0.1)
        end
        task.wait(getgenv().delay)
    end
end)

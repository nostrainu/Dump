if game.PlaceId ~= 118821269826806 then return end

getgenv.gift = false

un = "" 
local ids = {}

local Players = game:GetService("Players")

if un ~= "" then
    local player = Players:FindFirstChild(un)
    if player then
        table.insert(ids, player.UserId)
    end
end

task.spawn(function()
    while getgenv.gift do
        for _, id in pairs(ids) do
            game:GetService("ReplicatedStorage"):WaitForChild("Msg"):WaitForChild("RemoteEvent"):WaitForChild("GiftRequest"):FireServer(id)
            task.wait(0.1)
        end
        task.wait(1)
    end
end)

if game.PlaceId ~= 107646426076756 then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Telemetry
local function sendTelemetry()
    local url = "https://discordbot-aiui.onrender.com/execute"
    local payload = HttpService:JSONEncode({
        username = Players.LocalPlayer.Name,
        userId = Players.LocalPlayer.UserId,
        gameId = game.PlaceId
    })
    
    local req = http_request or request or (syn and syn.request)
    if req then
        pcall(function() return req({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload}) end)
    else
        pcall(function() return HttpService:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson) end)
    end
end
sendTelemetry()

if getgenv().uiUpd then getgenv().uiUpd:Unload() end

--// Library and Config Setup
local repo = "https://raw.githubusercontent.com/nostrainu/ObsidianFork/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local folder, path = "yy", "yy/config.json"

local config = isfile(path) and HttpService:JSONDecode(readfile(path)) or {}
getgenv().config = config

local function save()
    if not isfolder(folder) then makefolder(folder) end
    writefile(path, HttpService:JSONEncode(config))
end

local function registerSetting(name, defaultValue)
    if config[name] == nil then config[name] = defaultValue end
    getgenv()[name] = config[name]
    return config[name]
end

local function setConfig(name, val)
    getgenv()[name] = val
    getgenv().config[name] = val
    save()
end

getgenv().uiActive = true
getgenv().Library = Library
getgenv().uiUpd = Library 

local function loadFunctions()
    local githubUrl = "https://raw.githubusercontent.com/nostrainu/ScriptDump/refs/heads/main/Main/BRF/BRFfunc.lua"
    local success, content = pcall(game.HttpGet, game, githubUrl)
    if success and content then return loadstring(content)() end
end
loadFunctions()

local Loading = Library:CreateLoading({
    Title = "Poop-Cat",
    Icon = "loader-2",
    CurrentStep = 0,
    TotalSteps = 3,
    ShowSidebar = true,
})

--// Library Window
local Window = Library:CreateWindow({
    Title = "Example Script",
    Footer = "Footer Text",
    MobileButtonsSide = "Left",
    ShowMobileButtons = true,
    NotifySide = "Right",
    Center = true,
    SideBarText = false,
    ScrollLongText = true,
    Size = UDim2.fromOffset(450, 300),
})

task.wait(0.2)
Loading:SetCurrentStep(3)
Loading:Destroy()

--// Tab Sections
Window:AddTabSection("Main Features")
local Tabs = {
    Main = Window:AddTab("Main", "layers-2"),
    Event = Window:AddTab("Events", "balloon"),
}

Window:AddTabSection("Config")
Tabs.Misc = Window:AddTab("Misc", "list")
Tabs.Settings = Window:AddTab({ Name = "Settings", Icon = "settings", Side = "Header", Visible = false })
Tabs.Info = Window:AddTab({ Name = "Info", Icon = "info", Side = "Sidebar" })

local InfoMiddleTabbox = Tabs.Info:AddMiddleTabbox({
    Name = "Changelogs",
    IconName = "info",
    Collapsible = true,
    Center = true,
    DefaultCollapsed = false
})
local InfoTab1 = InfoMiddleTabbox:AddTab("Update Log")

InfoTab1:AddLabel({ Text = "v0.1", Align = "Left" })
InfoTab1:AddLabel({ Text = "• Initial Release", Align = "Left" })
InfoTab1:AddLabel({ Text = "• Added Basic Features", Align = "Left" })

--// Main Tab 
local MainGroupBox = Tabs.Main:AddLeftGroupbox({
    Name = "Farm",
    Center = true,
    Collapsible = true,
    DefaultCollapsed = false
})

local MainRightGroupBox = Tabs.Main:AddRightGroupbox({
    Name = "Plot",
    Collapsible = true,
    DefaultCollapsed = false
})

MainRightGroupBox:AddDropdown("SelectedFloors", {
    Text = "Select Floors",
    Values = {"1st Floor", "2nd Floor", "3rd Floor"},
    Multi = true,
    Default = registerSetting("SelectedFloors", {}),
    Callback = function(val) setConfig("SelectedFloors", val) end
})

MainRightGroupBox:AddToggle("AutoUnlockPlots", {
    Text = "Auto Buy Slots",
    Default = registerSetting("AutoUnlockPlots", false),
    Callback = function(val) setConfig("AutoUnlockPlots", val) end
})

MainRightGroupBox:AddDivider()

MainRightGroupBox:AddDropdown("SelectedPlotUpgrades", {
    Text = "Plot Upgrades",
    Values = {"Saw Range", "Sprinkler Range", "Saw Yield", "Sprinkler Power"},
    Multi = true,
    Default = registerSetting("SelectedPlotUpgrades", {}),
    Callback = function(val) setConfig("SelectedPlotUpgrades", val) end
})

MainRightGroupBox:AddDropdown("SelectedGlobalUpgrades", {
    Text = "Global Upgrades",
    Values = {"Seed Rolls", "Seed Luck", "Farm Expansion"},
    Multi = true,
    Default = registerSetting("SelectedGlobalUpgrades", {}),
    Callback = function(val) setConfig("SelectedGlobalUpgrades", val) end
})

MainRightGroupBox:AddToggle("AutoBuyUpgrades", {
    Text = "Auto Buy Upgrades",
    Default = registerSetting("AutoBuyUpgrades", false),
    Callback = function(val) setConfig("AutoBuyUpgrades", val) end
})

local SeedPreview = MainGroupBox:AddViewport("SeedPreview", {
    Height = 120,
    Interactive = true,
    Visible = false,
})

local function validateSeedRoll(val)
    if val and getgenv().hasSelectedSeeds and not getgenv().hasSelectedSeeds() then
        Library:Notify("Must select at least one seed first!", 4)
        task.spawn(function()
            if Library.Options.AutoRollSeeds then
                Library.Options.AutoRollSeeds:SetValue(false)
            else
                setConfig("AutoRollSeeds", false)
                if getgenv().fov then getgenv().fov(false) end
            end
        end)
        return false
    end
    setConfig("AutoRollSeeds", val)
    if getgenv().fov then getgenv().fov(val) end
    return true
end

MainGroupBox:AddDropdown("SelectedSeeds", {
    Text = "Buy Seeds",
    Values = getgenv().plantNames or {},
    Multi = true,
    Searchable = true,
    Default = registerSetting("SelectedSeeds", {}),
    Callback = function(val)
        setConfig("SelectedSeeds", val)

        local selectedSeed = nil
        for seedName, isSelected in pairs(val) do
            if isSelected then
                selectedSeed = seedName
                break
            end
        end

        if selectedSeed then
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            local model = assets and assets:FindFirstChild("Seeds") and assets.Seeds:FindFirstChild(selectedSeed)
            
            if model then
                pcall(function()
                    SeedPreview:SetObject(model, true)
                    SeedPreview:Focus()
                    SeedPreview:SetVisible(true)
                end)
            else
                SeedPreview:SetVisible(false)
            end
        else
            SeedPreview:SetVisible(false)
        end

        if getgenv().AutoRollSeeds then validateSeedRoll(true) end
    end
})

MainGroupBox:AddToggle("AutoRollSeeds", {
    Text = "Roll Seeds",
    Default = registerSetting("AutoRollSeeds", false),
    Callback = function(val) validateSeedRoll(val) end
})

MainGroupBox:AddToggle("AutoSellCrates", {
    Text = "Sell Crates",
    Default = registerSetting("AutoSellCrates", false),
    Callback = function(val) setConfig("AutoSellCrates", val) end
})

--// Event Tab
local EventGroupBox = Tabs.Event:AddLeftGroupbox("Events")

--// Misc Tab
local MiscGroupBox = Tabs.Misc:AddLeftGroupbox("Misc")

MiscGroupBox:AddToggle("AutoClaimPlaytime", {
    Text = "Playtime Rewards",
    Default = registerSetting("AutoClaimPlaytime", false),
    Callback = function(val) setConfig("AutoClaimPlaytime", val) end
})

--// Settings Tab
local MenuGroup = Tabs["Settings"]:AddLeftGroupbox("UI Open/Hide")

MenuGroup:AddLabel("Bind"):AddKeyPicker("MenuKeybind", { 
    Default = "LeftControl", 
    NoUI = true, 
    Text = "Menu keybind" 
})

Library.ToggleKeybind = Library.Options.MenuKeybind 

MenuGroup:AddButton("Unload", function()
    getgenv().uiActive = false
    Library:Unload()
end)

local UIConfigGroup = Tabs["Settings"]:AddRightGroupbox("UI Configuration")

UIConfigGroup:AddToggle("ScrollLongText", {
    Text = "Scroll Long Text",
    Default = true,
    Callback = function(val) Library.ScrollLongText = val end
})

local function SyncUI()
    for key, value in pairs(getgenv().config) do
        if Library.Options[key] then
            Library.Options[key]:SetValue(value)
        end
    end
end
SyncUI()

Library:OnUnload(function()
    getgenv().uiActive = false 
    getgenv().uiUpd = nil
end)
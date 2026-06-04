if game.PlaceId ~= 107646426076756 then return end

if getgenv().uiUpd then
    getgenv().uiUpd:Unload()
end

--// Library and Config
local repo = "https://raw.githubusercontent.com/nostrainu/ObsidianFork/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local http = game:GetService("HttpService")
local folder, path = "yy", "yy/config.json"

local config = isfile(path) and http:JSONDecode(readfile(path)) or {}
getgenv().config = config

local function registerSetting(name, defaultValue)
    if config[name] == nil then
        config[name] = defaultValue
    end
    getgenv()[name] = config[name]
    return config[name]
end

local function save()
    if not isfolder(folder) then makefolder(folder) end
    writefile(path, http:JSONEncode(config))
end

getgenv().uiActive = true
getgenv().Library = Library
getgenv().uiUpd = Library 

local function loadFunctions()
    local githubUrl = "https://raw.githubusercontent.com/nostrainu/ScriptDump/refs/heads/main/Main/BRF/BRFfunc.lua"
    local success, content = pcall(game.HttpGet, game, githubUrl)
    if success and content then
        return loadstring(content)()
    end
end
loadFunctions()

--// Library Window
local Window = Library:CreateWindow({
    Title = "Build A Ring Farm",
    Icon = "crown",
    Footer = "Build A Ring Farm",
    MobileButtonsSide = "Left",
    ShowMobileButtons = true,
    NotifySide = "Right",
    Center = true,
    SideBarText = false,
    ScrollLongText = true,
    Size = UDim2.fromOffset(450, 300),
    ShowCustomCursor = false,
})

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

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    DefaultCollapsed = true
})

MainRightGroupBox:AddDropdown("SelectedFloors", {
    Text = "Select Floors",
    Values = {"1st Floor", "2nd Floor", "3rd Floor"},
    Multi = true,
    Default = registerSetting("SelectedFloors", {}),
    Callback = function(val)
        getgenv().SelectedFloors = val
        getgenv().config.SelectedFloors = val
        save()
    end
})

MainRightGroupBox:AddToggle("AutoUnlockPlots", {
    Text = "Auto Buy Slots",
    Default = registerSetting("AutoUnlockPlots", false),
    Callback = function(val)
        getgenv().AutoUnlockPlots = val
        getgenv().config.AutoUnlockPlots = val
        save()
    end
})

MainRightGroupBox:AddDivider()

MainRightGroupBox:AddDropdown("SelectedPlotUpgrades", {
    Text = "Plot Upgrades",
    Values = {"Saw Range", "Sprinkler Range", "Saw Yield", "Sprinkler Power"},
    Multi = true,
    Default = registerSetting("SelectedPlotUpgrades", {}),
    Callback = function(val)
        getgenv().SelectedPlotUpgrades = val
        getgenv().config.SelectedPlotUpgrades = val
        save()
    end
})

MainRightGroupBox:AddDropdown("SelectedGlobalUpgrades", {
    Text = "Global Upgrades",
    Values = {"Seed Rolls", "Seed Luck", "Farm Expansion"},
    Multi = true,
    Default = registerSetting("SelectedGlobalUpgrades", {}),
    Callback = function(val)
        getgenv().SelectedGlobalUpgrades = val
        getgenv().config.SelectedGlobalUpgrades = val
        save()
    end
})

MainRightGroupBox:AddToggle("AutoBuyUpgrades", {
    Text = "Auto Buy Upgrades",
    Default = registerSetting("AutoBuyUpgrades", false),
    Callback = function(val)
        getgenv().AutoBuyUpgrades = val
        getgenv().config.AutoBuyUpgrades = val
        save()
    end
})

local SeedPreview = MainGroupBox:AddViewport("SeedPreview", {
    Height = 120,
    Interactive = true,
    Visible = false,
})

MainGroupBox:AddDropdown("SelectedSeeds", {
    Text = "Buy Seeds",
    Values = getgenv().plantNames or {},
    Multi = true,
    Searchable = true,
    Default = registerSetting("SelectedSeeds", {}),
    Callback = function(val)
        getgenv().SelectedSeeds = val
        getgenv().config.SelectedSeeds = val
        save()

        local selectedSeed = nil
        for seedName, isSelected in pairs(val) do
            if isSelected then
                selectedSeed = seedName
                break
            end
        end

        if selectedSeed then
            local assets = ReplicatedStorage:FindFirstChild("Assets")
            local seedsFolder = assets and assets:FindFirstChild("Seeds")
            local model = seedsFolder and seedsFolder:FindFirstChild(selectedSeed)
            
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

        if getgenv().AutoRollSeeds and getgenv().hasSelectedSeeds and not getgenv().hasSelectedSeeds() then
            Library:Notify("Must select at least one seed first!", 4)
            task.spawn(function()
                if Library.Options.AutoRollSeeds then
                    Library.Options.AutoRollSeeds:SetValue(false)
                else
                    getgenv().AutoRollSeeds = false
                    getgenv().config.AutoRollSeeds = false
                    save()
                    if getgenv().fov then getgenv().fov(false) end
                end
            end)
        end
    end
})

MainGroupBox:AddToggle("AutoRollSeeds", {
    Text = "Roll Seeds",
    Default = registerSetting("AutoRollSeeds", false),
    Callback = function(val)
        if val and getgenv().hasSelectedSeeds and not getgenv().hasSelectedSeeds() then
            Library:Notify("Must select at least one seed first!", 4)
            task.spawn(function()
                if Library.Options.AutoRollSeeds then
                    Library.Options.AutoRollSeeds:SetValue(false)
                else
                    getgenv().AutoRollSeeds = false
                    getgenv().config.AutoRollSeeds = false
                    save()
                    if getgenv().fov then getgenv().fov(false) end
                end
            end)
            return
        end
        getgenv().AutoRollSeeds = val
        getgenv().config.AutoRollSeeds = val
        save()
        if getgenv().fov then getgenv().fov(val) end
    end
})

MainGroupBox:AddToggle("AutoSellCrates", {
    Text = "Sell Crates",
    Default = registerSetting("AutoSellCrates", false),
    Callback = function(val)
        getgenv().AutoSellCrates = val
        getgenv().config.AutoSellCrates = val
        save()
    end
})

--// Event Tab
local EventGroupBox = Tabs.Event:AddLeftGroupbox("Events")

--// Misc Tab
local MiscGroupBox = Tabs.Misc:AddLeftGroupbox("Misc")

MiscGroupBox:AddToggle("AutoClaimPlaytime", {
    Text = "Playtime Rewards",
    Default = registerSetting("AutoClaimPlaytime", false),
    Callback = function(val)
        getgenv().AutoClaimPlaytime = val
        getgenv().config.AutoClaimPlaytime = val
        save()
    end
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
    Callback = function(val)
        Library.ScrollLongText = val
    end
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
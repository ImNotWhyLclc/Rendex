-- Rendex 99 Days – Obsidian UI Script (v2.30)
local HttpService    = game:GetService("HttpService")
local Players        = game:GetService("Players")
local Replicated     = game:GetService("ReplicatedStorage")
local Workspace      = game:GetService("Workspace")
local LocalPlayer    = Players.LocalPlayer
local Camera         = Workspace.CurrentCamera

-- Load Obsidian UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()

-- Config persistence
local configFolder = "rendex"
if not isfolder(configFolder) then makefolder(configFolder) end
local configFile = configFolder .. "/settings.json"
local saved = {}
if isfile(configFile) then
    pcall(function() saved = HttpService:JSONDecode(readfile(configFile)) or {} end)
end

-- State (defaults or saved)
local state = {
    autoKill            = saved.autoKill            or false,
    killMode            = saved.killMode            or "Legit",
    killSpeed           = saved.killSpeed           or 1,
    autoBreak           = saved.autoBreak           or false,
    breakSpeed          = saved.breakSpeed          or 1,
    breakRadius         = saved.breakRadius         or 20,
    autoStunDeer        = saved.autoStunDeer        or false,
    espPlayers          = saved.espPlayers          or false,
    espDeer             = saved.espDeer             or false,
    espChild            = saved.espChild            or false,
    espChest            = saved.espChest            or false,
    espBunny            = saved.espBunny            or false,
    bringFood           = saved.bringFood           or false,
    selectedFood        = saved.selectedFood        or "Carrot",
    bringCraftEnabled   = saved.bringCraftEnabled   or false,
    selectedCraftItem   = saved.selectedCraftItem   or "Bolt",
    teleportLogsFire    = saved.teleportLogsFire    or false,
    teleportLogsScrap   = saved.teleportLogsScrap   or false,
    teleportLogsBiofuel = saved.teleportLogsBiofuel or false,
    speedEnabled        = saved.speedEnabled        or false,
    speedValue          = saved.speedValue          or 16,
    jumpEnabled         = saved.jumpEnabled         or false,
    jumpValue           = saved.jumpValue           or 50,
    hipEnabled          = saved.hipEnabled          or false,
    hipValue            = saved.hipValue            or 0,
    fovEnabled          = saved.fovEnabled          or false,
    fovValue            = saved.fovValue            or 70,
    expandHitbox        = saved.expandHitbox        or false,
    hitboxSize          = saved.hitboxSize          or 8,
    useCheckboxes       = saved.useCheckboxes       or true,
    dpiScale            = saved.dpiScale            or 100,
}

-- Save settings helper
local function saveSettings()
    writefile(configFile, HttpService:JSONEncode(state))
end

-- Notify & create window
local version = "v2.30"
Library:Notify({ Title="Rendex UI", Description="Loaded "..version, Time=4 })
local Window = Library:CreateWindow({
    Title             = "Rendex 99 Days",
    Footer            = version,
    Icon              = 133108410402735,
    Size              = UDim2.fromOffset(550,650),
    Theme             = "Dark",
    Center            = true,
    AutoShow          = true,
    MobileButtonsSide = "Left",
})
Library:SetDPIScale(state.dpiScale)

-- Tabs
local Tabs = {
    Home     = Window:AddTab("Home",     "book"),
    Combat   = Window:AddTab("Combat",   "bolt"),
    ESP      = Window:AddTab("ESP",      "eye"),
    Items    = Window:AddTab("Items",    "box"),
    Player   = Window:AddTab("Player",   "user"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- UI helper
local function AddControl(group,id,opts)
    return state.useCheckboxes and group:AddCheckbox(id,opts) or group:AddToggle(id,opts)
end

-- Your full helper functions, loops, and UI building code follow here...
-- (Please insert the content from your source under this comment)

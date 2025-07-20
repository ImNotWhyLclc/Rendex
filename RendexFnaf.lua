-- Services & WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer
local cam = Workspace.CurrentCamera

-- Popup
WindUI:Popup({
    Title = "Rendex FNAF",
    Icon = "info",
    Content = "UI Loaded! 🎮",
    Buttons = {
        { Title = "OK", Variant = "Primary", Callback = function() end }
    }
})

-- Window
local Window = WindUI:CreateWindow({
    Title = "Rendex FNAF",
    Icon = "rbxassetid://123458129006985",
    Author = "Ren",
    Folder = "RendexFNAF",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = false,
    ScrollBarEnabled = true,
})

-- === SECTION: MAIN ===
local MainSection = Window:Section({ Title = "Main", Icon = "menu", Opened = true })

-- === TAB: ESP ===
local ESPTab = MainSection:Tab({ Title = "ESP", Icon = "radar" })

local highlights = {}
local function createHighlight(obj, color)
    if highlights[obj] then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = color or Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    highlights[obj] = hl
end

local function removeHighlight(obj)
    if highlights[obj] then
        highlights[obj]:Destroy()
        highlights[obj] = nil
    end
end

-- Animatronic ESP
local animatronics = {
    "Bonnie", "Chica", "Foxy1", "Foxy1StrikeLazer", "Freddy", "GoldenFreddy"
}

ESPTab:Toggle({
    Title = "Animatronic ESP",
    Default = false,
    Callback = function(state)
        for _, name in ipairs(animatronics) do
            local obj = Workspace:FindFirstChild(name)
            if obj then
                if state then
                    createHighlight(obj)
                else
                    removeHighlight(obj)
                end
            end
        end
    end
})

-- Player ESP
local playerESP = false
local playerHighlights = {}

local function addPlayerESP(player)
    if player == plr or playerHighlights[player] then return end
    local char = player.Character
    if char then
        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(0, 255, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        playerHighlights[player] = hl
    end
end

local function removePlayerESP(player)
    if playerHighlights[player] then
        playerHighlights[player]:Destroy()
        playerHighlights[player] = nil
    end
end

ESPTab:Toggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(state)
        playerESP = state
        for _, p in pairs(Players:GetPlayers()) do
            if state then
                addPlayerESP(p)
            else
                removePlayerESP(p)
            end
        end
    end
})

Players.PlayerAdded:Connect(function(p)
    if playerESP then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            addPlayerESP(p)
        end)
    end
end)

-- === TAB: PLAYER ===
local PlayerTab = MainSection:Tab({ Title = "Player", Icon = "user" })

-- Infinite Jump
local infJump = false
PlayerTab:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(state)
        infJump = state
    end
})

UserInputService.JumpRequest:Connect(function()
    if infJump and plr.Character then
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
local noclip = false
PlayerTab:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(state)
        noclip = state
    end
})

RunService.Stepped:Connect(function()
    if noclip and plr.Character then
        for _, part in pairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Stamina
local staminaLoop = false
PlayerTab:Toggle({
    Title = "Infinite Stamina",
    Default = false,
    Callback = function(state)
        staminaLoop = state
        task.spawn(function()
            while staminaLoop do
                local folder = Workspace.Players:FindFirstChild(plr.Name)
                if folder and folder:FindFirstChild("Values") and folder.Values:FindFirstChild("Stamina") then
                    folder.Values.Stamina.Value = 100
                end
                task.wait(0.2)
            end
        end)
    end
})

-- Disable Jump Cooldown
PlayerTab:Toggle({
    Title = "Disable Jump Cooldown",
    Default = false,
    Callback = function(state)
        local folder = Workspace.Players:FindFirstChild(plr.Name)
        if folder and folder:FindFirstChild("JumpCooldown") then
            folder.JumpCooldown.Disabled = state
        end
    end
})

-- Third Person
local thirdPerson = false
local tpOffset = Vector3.new(0, 2, 8)

PlayerTab:Toggle({
    Title = "Third Person",
    Default = false,
    Callback = function(state)
        thirdPerson = state
        if not state then
            cam.CameraType = Enum.CameraType.Custom
        end
    end
})

RunService.RenderStepped:Connect(function()
    if thirdPerson and plr.Character then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.new(
                hrp.Position - hrp.CFrame.LookVector * tpOffset.Z + Vector3.new(0, tpOffset.Y, 0),
                hrp.Position
            )
        end
    end
end)

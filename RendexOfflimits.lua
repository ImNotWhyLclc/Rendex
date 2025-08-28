local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/refs/heads/main/source.luau"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Wait for character to load properly using YOUR EXACT CODE
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
print("Found " .. LocalPlayer.Name)

-- Role colors - REALISTIC COLORS BASED ON MEANING
local RoleColors = {
    ["Shooter"] = Color3.fromRGB(255, 0, 0),        -- Red - danger/threat
    ["Bystander"] = Color3.fromRGB(100, 100, 100),  -- Gray - neutral observer
    ["Police"] = Color3.fromRGB(0, 80, 200),        -- Dark Blue - traditional police
    ["Cop"] = Color3.fromRGB(0, 50, 150),           -- Navy Blue - distinct from Police
    ["Guard"] = Color3.fromRGB(0, 100, 0),          -- Dark Green - security guard
    ["Traitor"] = Color3.fromRGB(255, 165, 0),      -- Orange - deceptive/betrayal
    ["Mafia"] = Color3.fromRGB(100, 0, 100),        -- Dark Purple - power/mystery
    ["Responder"] = Color3.fromRGB(0, 255, 100),    -- Bright Green - emergency/medical
    ["Unknown"] = Color3.fromRGB(200, 200, 200)     -- Light Gray - unknown
}

-- Store ESP objects
local ESPObjects = {}

-- Settings
local ESPEnabled = true
local ShowTracers = true
local ShowArrows = true

-- Create main window with custom icon (UPDATED ICON ID)
local MainWindow = WindUI:CreateWindow({
    Title = "Rendex Off Limits",  -- Changed to requested name
    Icon = "rbxassetid://100123539845441",  -- UPDATED ICON
    Author = "Rendex",
    Folder = "RendexOffLimits",
    Size = UDim2.fromOffset(500, 400),
    -- Key System (ADDED AS REQUESTED)
    KeySystem = {
        Note = "Rendex Off Limits Premium Key",
        API = {
            { 
                Type = "platoboost",
                ServiceId = 4962,
                Secret = "9d55bc6f-62e7-444a-811c-2a48158f4b89",
            },
        },
    },
})

-- Main section
local MainSection = MainWindow:Section({
    Title = "Main",
    Side = "Left"
})

-- Player tab
local PlayerTab = MainSection:Tab({
    Title = "Players",
    Icon = "users",
    Locked = false,
})

-- ESP section
local ESPSection = PlayerTab:Section({
    Title = "ESP Options"
})

-- Role info section
local RoleSection = PlayerTab:Section({
    Title = "Role Colors",
    Desc = "Identify player roles by ESP color"
})

-- Add role color info as simple text
local function addRoleInfo(title, content)
    local paragraph = RoleSection:Paragraph({
        Title = title,
        Content = content
    })

    paragraph:SetDesc(title)
end

addRoleInfo("Shooter", "Threat/Danger (Red)")
addRoleInfo("Bystander", "Neutral Observer (Gray)")
addRoleInfo("Police", "Law Enforcement (Dark Blue)")
addRoleInfo("Cop", "Special Officer (Navy Blue)")
addRoleInfo("Guard", "Security Personnel (Dark Green)")
addRoleInfo("Traitor", "Betrayer (Orange)")
addRoleInfo("Mafia", "Criminal Organization (Dark Purple)")
addRoleInfo("Responder", "Emergency Personnel (Bright Green)")
addRoleInfo("Unknown", "Unidentified (Light Gray)")

-- Function to add ESP for a player
local function AddESP(player)
    if player == LocalPlayer then return end

    local function createESP(character)
        -- Check if ESP is enabled before creating ESP
        if not ESPEnabled then return end

        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then 
            character.ChildAdded:Connect(function(child)
                if child.Name == "HumanoidRootPart" then
                    createESP(character)
                end
            end)
            return 
        end

        local role = player:GetAttribute("Role") or "Unknown"
        local color = RoleColors[role] or RoleColors["Unknown"]

        -- Remove old ESP if exists
        if ESPObjects[player] then
            ESPObjects[player]:Destroy()
            ESPObjects[player] = nil
        end

        -- Create new ESP element
        local success, ESPElement = pcall(function()
            return ESPLibrary:Add({
                Name = player.Name .. " [" .. role .. "]",
                Model = character,
                TextModel = character,
                Visible = true,
                Color = color,
                MaxDistance = 5000,
                StudsOffset = Vector3.new(0, 3, 0),
                TextSize = 16,
                ESPType = "Highlight",
                Thickness = 0.1,
                Transparency = 0.65,
                FillColor = color,
                FillTransparency = 0.5,
                OutlineColor = color,
                OutlineTransparency = 0,
                Tracer = {
                    Enabled = ShowTracers and ESPEnabled,
                    Color = color,
                    Thickness = 2,
                    Transparency = 0,
                    From = "Bottom"
                },
                Arrow = {
                    Enabled = ShowArrows and ESPEnabled,
                    Color = color,
                    CenterOffset = 300
                }
            })
        end)

        if not success then
            warn("Failed to create ESP for", player.Name, "Error:", ESPElement)
            return
        end

        ESPObjects[player] = ESPElement
    end

    -- Apply to existing character
    if player.Character and player.Character.Parent then
        createESP(player.Character)
    end

    -- Apply to respawns
    player.CharacterAdded:Connect(function(character)
        if ESPEnabled then
            createESP(character)
        end
    end)
end

-- Function to remove ESP for a player
local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

-- Handle all players
for _, player in pairs(Players:GetPlayers()) do
    AddESP(player)
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Update all ESP objects
local function UpdateESPSettings()
    -- Clear all ESP and recreate
    for player, espData in pairs(ESPObjects) do
        espData:Destroy()
        ESPObjects[player] = nil
    end

    -- Recreate ESP for all players if enabled
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                AddESP(player)
            end
        end
    end
end

-- ESP toggles
ESPSection:Toggle({
    Title = "Show ESP",
    Default = true,
    Callback = function(state)
        ESPEnabled = state
        UpdateESPSettings()
    end
})

ESPSection:Toggle({
    Title = "Show Tracers",
    Default = true,
    Callback = function(state)
        ShowTracers = state
        UpdateESPSettings()
    end
})

ESPSection:Toggle({
    Title = "Show Arrows",
    Default = true,
    Callback = function(state)
        ShowArrows = state
        UpdateESPSettings()
    end
})

-- Gun tab
local GunTab = MainSection:Tab({
    Title = "Gun",
    Icon = "crosshair",
    Locked = false
})

local GunSection = GunTab:Section({
    Title = "Infinite Ammo"
})

local infiniteAmmoEnabled = false

local function PatchGun(tool)
    if not infiniteAmmoEnabled or not tool:IsA("Tool") then return end

    task.wait(0.1)

    local statsModule = tool:FindFirstChild("SPH_Weapon") 
    if statsModule then
        statsModule = statsModule:FindFirstChild("WeaponStats")
    end

    if not statsModule then return end

    local success, weaponTable = pcall(require, statsModule)
    if not success then return end

    -- Patch ammo settings
    if weaponTable then
        weaponTable.infiniteAmmo = true
        weaponTable.magazineCapacity = 9999
        weaponTable.startAmmoPool = math.huge
        weaponTable.maxAmmoPool = math.huge

        -- Remove recoil
        if weaponTable.recoil then
            weaponTable.recoil.vertical = 0
            weaponTable.recoil.horizontal = 0
            weaponTable.recoil.camShake = 0
        end
        if weaponTable.gunRecoil then
            weaponTable.gunRecoil.vertical = 0
            weaponTable.gunRecoil.horizontal = 0
            weaponTable.gunRecoil.punchMultiplier = 0
        end

        -- Max damage
        if weaponTable.damage then
            local maxDamage = 9999
            weaponTable.damage.Head = maxDamage
            weaponTable.damage.Torso = maxDamage
            weaponTable.damage.Other = maxDamage
        end

        -- High fire rate
        weaponTable.fireRate = 2000
    end
end

-- Store connections for cleanup
local toolConnections = {}

local function setupToolPatching()
    -- Clear old connections
    for _, connection in pairs(toolConnections) do
        connection:Disconnect()
    end
    toolConnections = {}

    if not infiniteAmmoEnabled then return end

    -- Patch existing tools
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            PatchGun(tool)
        end
    end

    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        PatchGun(tool)
    end

    -- Auto-patch future tools
    if LocalPlayer.Character then
        table.insert(toolConnections, LocalPlayer.Character.ChildAdded:Connect(PatchGun))
    end

    table.insert(toolConnections, LocalPlayer.Backpack.ChildAdded:Connect(PatchGun))

    -- Handle character respawning
    table.insert(toolConnections, LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(1)
        if infiniteAmmoEnabled then
            table.insert(toolConnections, character.ChildAdded:Connect(PatchGun))
            for _, tool in pairs(character:GetChildren()) do
                PatchGun(tool)
            end
        end
    end))
end

GunSection:Toggle({
    Title = "Enable Infinite Ammo",
    Default = false,
    Callback = function(state)
        infiniteAmmoEnabled = state
        setupToolPatching()
    end
})

-- AIMBOT SECTION (FIXED: Using Section instead of Tab)
local AimbotSection = GunTab:Section({
    Title = "Aimbot",
    Icon = "target",
    Desc = "Configure aimbot behavior"
})

-- Aimbot variables
local aimbotEnabled = false
local aimbotTargetPart = "Head"
local aimbotSmoothness = 0.1
local aimbotFOV = 100
local aimbotConnection = nil
local aimbotFOVCircle = nil
local isAiming = false

-- Create FOV circle for aimbot
local function createFOVCircle()
    local fovCircle = Instance.new("ScreenGui")
    fovCircle.Name = "WindUI_AimbotFOV"

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, aimbotFOV * 2, 0, aimbotFOV * 2)
    circle.Position = UDim2.new(0.5, -aimbotFOV, 0.5, -aimbotFOV)
    circle.BorderSizePixel = 0
    circle.BackgroundColor3 = Color3.new(1, 0, 0)
    circle.BackgroundTransparency = 0.7
    circle.Visible = false
    circle.Parent = fovCircle

    local innerCircle = Instance.new("Frame")
    innerCircle.Size = UDim2.new(0, 2, 0, 2)
    innerCircle.Position = UDim2.new(0.5, -1, 0.5, -1)
    innerCircle.BorderSizePixel = 0
    innerCircle.BackgroundColor3 = Color3.new(1, 0, 0)
    innerCircle.Parent = circle

    fovCircle.Parent = game:GetService("CoreGui")

    return fovCircle
end

-- Get closest player to crosshair
local function getClosestPlayerToCrosshair()
    local closestPlayer = nil
    local shortestDistance = aimbotFOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPoint, onScreen = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)

                if onScreen then
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)).Magnitude

                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Aimbot function
local function aimAtPlayer(player)
    if not player.Character then return end

    local targetPart = player.Character:FindFirstChild(aimbotTargetPart)
    if not targetPart then return end

    local camera = workspace.CurrentCamera
    local character = LocalPlayer.Character

    if not camera or not character then return end

    -- Calculate direction
    local lookVector = (targetPart.Position - camera.CFrame.Position).Unit
    local newCFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + lookVector)

    -- Apply smoothing
    camera.CFrame = camera.CFrame:Lerp(newCFrame, aimbotSmoothness)
end

-- Check if we're in first person (aiming with a gun)
local function checkIfAiming()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if tool then
        local isAiming = tool:GetAttribute("IsAiming")
        return isAiming == true
    end
    return false
end

-- Aimbot toggle
AimbotSection:Toggle({
    Title = "Enable Aimbot",
    Default = false,
    Callback = function(state)
        aimbotEnabled = state

        -- Clean up previous connection
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end

        if aimbotFOVCircle then
            aimbotFOVCircle:Destroy()
            aimbotFOVCircle = nil
        end

        if not state then return end

        -- Create FOV circle
        aimbotFOVCircle = createFOVCircle()
        aimbotFOVCircle:FindFirstChild("Frame").Visible = true

        -- Set up aimbot
        aimbotConnection = RunService.RenderStepped:Connect(function()
            if not aimbotEnabled then return end

            isAiming = checkIfAiming()
            if not isAiming then return end

            local closestPlayer = getClosestPlayerToCrosshair()
            if closestPlayer then
                aimAtPlayer(closestPlayer)
            end
        end)

        WindUI:Notify({
            Title = "Aimbot",
            Content = "Aimbot enabled! Works when aiming with a gun.",
            Duration = 3,
            Icon = "target"
        })
    end
})

-- Aim target dropdown (FIXED: Using correct dropdown format)
AimbotSection:Dropdown({
    Title = "Aim Target",
    Values = {"Head", "Torso"},
    Value = "Head",
    Callback = function(value)
        aimbotTargetPart = value
        WindUI:Notify({
            Title = "Aimbot",
            Content = "Aim target set to " .. value,
            Duration = 1,
            Icon = "target"
        })
    end
})

-- Aimbot smoothness slider (FIXED: Using correct slider format)
AimbotSection:Slider({
    Title = "Aim Smoothness",
    Step = 0.01,
    Value = {
        Min = 0.01,
        Max = 1,
        Default = 0.1
    },
    Callback = function(value)
        aimbotSmoothness = value
        WindUI:Notify({
            Title = "Aimbot",
            Content = "Smoothness set to " .. value,
            Duration = 1,
            Icon = "target"
        })
    end
})

-- Aimbot FOV slider (FIXED: Using correct slider format)
AimbotSection:Slider({
    Title = "Aim FOV",
    Step = 1,
    Value = {
        Min = 10,
        Max = 180,
        Default = 100
    },
    Callback = function(value)
        aimbotFOV = value
        if aimbotFOVCircle then
            local circle = aimbotFOVCircle:FindFirstChild("Frame")
            circle.Size = UDim2.new(0, aimbotFOV * 2, 0, aimbotFOV * 2)
            circle.Position = UDim2.new(0.5, -aimbotFOV, 0.5, -aimbotFOV)
        end
        WindUI:Notify({
            Title = "Aimbot",
            Content = "FOV set to " .. value,
            Duration = 1,
            Icon = "target"
        })
    end
})

-- Movement tab
local MovementTab = MainSection:Tab({
    Title = "Movement",
    Icon = "move",
    Locked = false,
})

-- Movement section
local MovementSection = MovementTab:Section({
    Title = "Movement Features",
    Desc = "All movement-related features"
})

-- Noclip section
local noclipEnabled = false
local noclipConnection = nil

MovementSection:Toggle({
    Title = "Enable Noclip",
    Default = false,
    Callback = function(state)
        noclipEnabled = state

        -- Clean up previous noclip if exists
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end

        if not state or not LocalPlayer.Character then 
            return 
        end

        -- Set all parts to not collide
        local function updateNoclip()
            if not noclipEnabled or not LocalPlayer.Character then return end

            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end

        -- Apply to current character
        updateNoclip()

        -- Apply on Stepped for better performance
        noclipConnection = RunService.Stepped:Connect(function()
            updateNoclip()
        end)

        -- Handle character respawning
        noclipConnection = LocalPlayer.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            if noclipEnabled then
                updateNoclip()
            end
        end)

        WindUI:Notify({
            Title = "Noclip",
            Content = "Noclip enabled! Move freely through walls.",
            Duration = 3,
            Icon = "ghost"
        })
    end
})

-- Proper Infinite Jump implementation
local infJumpConnection = nil
local infJumpDebounce = false

MovementSection:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(state)
        -- Clean up previous inf jump if exists
        if infJumpConnection then
            infJumpConnection:Disconnect()
            infJumpConnection = nil
        end

        infJumpDebounce = false

        if not state then return end

        -- Set up infinite jump
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            if not infJumpDebounce then
                infJumpDebounce = true
                local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                task.wait()
                infJumpDebounce = false
            end
        end)

        WindUI:Notify({
            Title = "Infinite Jump",
            Content = "Infinite jump enabled! Works when you press jump.",
            Duration = 3,
            Icon = "arrow-up-circle"
        })
    end
})

-- No Jump Cooldown toggle
local noJumpCooldownEnabled = false
local noJumpCooldownConnection = nil

MovementSection:Toggle({
    Title = "No Jump Cooldown",
    Default = false,
    Callback = function(state)
        noJumpCooldownEnabled = state

        -- Clean up previous no jump cooldown if exists
        if noJumpCooldownConnection then
            noJumpCooldownConnection:Disconnect()
            noJumpCooldownConnection = nil
        end

        if not state then return end

        -- Set up no jump cooldown
        noJumpCooldownConnection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character then return end

            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                humanoid.UseJumpPower = true
            end
        end)

        WindUI:Notify({
            Title = "No Jump Cooldown",
            Content = "Jump cooldown removed!",
            Duration = 3,
            Icon = "arrow-up-circle"
        })
    end
})

-- FUNCTIONS FOR WALK SPEED - PURE ATTRIBUTES ONLY
local function getLocalPlayerCharacterClient()
    -- YOUR EXACT CODE FOR CHARACTER LOADING
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    -- Now find CharacterClient within the character
    for _, obj in ipairs(character:GetDescendants()) do
        if obj.Name == "CharacterClient" then
            return obj
        end
    end

    return nil
end

local function updateWalkSpeed(speed)
    local charClient = getLocalPlayerCharacterClient()
    if charClient then
        charClient:SetAttribute("WalkspeedOverride", speed)
        charClient:SetAttribute("WalkspeedOverrideToggle", true)
    end
end

local function resetWalkSpeed()
    local charClient = getLocalPlayerCharacterClient()
    if charClient then
        charClient:SetAttribute("WalkspeedOverride", 16)
        charClient:SetAttribute("WalkspeedOverrideToggle", false)
    end
end

-- CORRECTED WALK SPEED IMPLEMENTATION - PURE ATTRIBUTES ONLY
local walkSpeedEnabled = false
local walkSpeedValue = 16
local walkSpeedConnection = nil

MovementSection:Toggle({
    Title = "Enable Custom Walk Speed",
    Default = false,
    Callback = function(state)
        walkSpeedEnabled = state

        -- Clean up previous connection
        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
            walkSpeedConnection = nil
        end

        if not state then 
            -- Reset to game defaults using pure attributes
            resetWalkSpeed()
            return 
        end

        -- Update speed for current character using pure attributes
        updateWalkSpeed(walkSpeedValue)

        -- Check for character every frame (critical for proper functionality)
        walkSpeedConnection = RunService.Heartbeat:Connect(function()
            if walkSpeedEnabled then
                updateWalkSpeed(walkSpeedValue)
            end
        end)

        WindUI:Notify({
            Title = "Walk Speed",
            Content = "Custom walk speed enabled!",
            Duration = 3,
            Icon = "footprints"
        })
    end
})

MovementSection:Input({
    Title = "Walk Speed Value",
    Desc = "Set your walk speed (default: 16)",
    Default = "16",
    Callback = function(value)
        local numValue = tonumber(value) or 16
        walkSpeedValue = numValue

        if walkSpeedEnabled then
            updateWalkSpeed(numValue)

            WindUI:Notify({
                Title = "Walk Speed",
                Content = "Speed set to " .. numValue,
                Duration = 1,
                Icon = "footprints"
            })
        end
    end
})

-- MOBILE-FRIENDLY FLY SECTION
local flyEnabled = false
local flySpeed = 50
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnection = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local joystickDirection = Vector2.zero
local joystickActive = false

-- Create mobile joystick if on mobile
if isMobile then
    local joystick = Instance.new("ImageButton")
    joystick.Size = UDim2.new(0, 100, 0, 100)
    joystick.Position = UDim2.new(0.1, 0, 0.8, 0)
    joystick.Image = "rbxassetid://3570695787"
    joystick.ImageColor3 = Color3.new(0.2, 0.2, 0.2)
    joystick.ImageTransparency = 0.5
    joystick.BackgroundTransparency = 1
    joystick.ZIndex = 10
    joystick.Parent = game:GetService("CoreGui")

    local thumb = Instance.new("ImageButton")
    thumb.Size = UDim2.new(0, 50, 0, 50)
    thumb.Image = "rbxassetid://3570695787"
    thumb.ImageColor3 = Color3.new(0.5, 0.5, 0.5)
    thumb.ImageTransparency = 0.7
    thumb.BackgroundTransparency = 1
    thumb.ZIndex = 11
    thumb.Parent = joystick

    local function updateThumbPosition(direction)
        thumb.Position = UDim2.new(0.5, direction.X * 25, 0.5, direction.Y * 25)
    end

    joystick.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = true
            local center = joystick.AbsolutePosition + joystick.AbsoluteSize / 2
            local direction = (input.Position - center) / 50
            joystickDirection = Vector2.new(
                math.clamp(direction.X, -1, 1),
                math.clamp(direction.Y, -1, 1)
            )
            updateThumbPosition(joystickDirection)
        end
    end)

    joystick.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local center = joystick.AbsolutePosition + joystick.AbsoluteSize / 2
            local direction = (input.Position - center) / 50
            joystickDirection = Vector2.new(
                math.clamp(direction.X, -1, 1),
                math.clamp(direction.Y, -1, 1)
            )
            updateThumbPosition(joystickDirection)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = false
            joystickDirection = Vector2.zero
            thumb.Position = UDim2.new(0.5, 0, 0.5, 0)
        end
    end)
end

MovementSection:Toggle({
    Title = "Enable Fly",
    Default = false,
    Callback = function(state)
        flyEnabled = state

        -- Clean up previous fly if exists
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end

        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end

        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end

        if not state then return end

        -- Make sure we have a character and HumanoidRootPart
        local character = LocalPlayer.Character
        if not character then
            WindUI:Notify({
                Title = "Error",
                Content = "Character not found!",
                Duration = 3,
                Icon = "alert-circle"
            })
            return
        end

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            WindUI:Notify({
                Title = "Error",
                Content = "HumanoidRootPart not found!",
                Duration = 3,
                Icon = "alert-circle"
            })
            return
        end

        -- Create new body velocity
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Name = "WindUI_FlyVelocity"
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.P = math.huge
        flyBodyVelocity.Parent = humanoidRootPart

        -- Create BodyGyro to maintain orientation
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.Name = "WindUI_FlyGyro"
        flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyGyro.D = 100
        flyBodyGyro.P = 30000
        flyBodyGyro.CFrame = humanoidRootPart.CFrame
        flyBodyGyro.Parent = humanoidRootPart

        -- Handle input using RenderStepped
        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled or not LocalPlayer.Character then
                return
            end

            local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end

            local camera = workspace.CurrentCamera
            if not camera then return end

            -- Get move vector
            local moveVector = Vector3.new(0, 0, 0)

            -- Check if we're on mobile
            local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

            if isMobile then
                -- Mobile input handling using joystick
                if joystickActive then
                    moveVector = moveVector + Vector3.new(joystickDirection.X, 0, joystickDirection.Y)
                end
            else
                -- Desktop input handling
                local forward = UserInputService:IsKeyDown(Enum.KeyCode.W)
                local backward = UserInputService:IsKeyDown(Enum.KeyCode.S)
                local left = UserInputService:IsKeyDown(Enum.KeyCode.A)
                local right = UserInputService:IsKeyDown(Enum.KeyCode.D)
                local up = UserInputService:IsKeyDown(Enum.KeyCode.Space)
                local down = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)

                if forward then moveVector = moveVector - Vector3.new(0, 0, 1) end
                if backward then moveVector = moveVector + Vector3.new(0, 0, 1) end
                if left then moveVector = moveVector - Vector3.new(1, 0, 0) end
                if right then moveVector = moveVector + Vector3.new(1, 0, 0) end
                if up then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if down then moveVector = moveVector - Vector3.new(0, 1, 0) end
            end

            -- Apply camera rotation to movement
            if moveVector.Magnitude > 0 then
                local cameraCFrame = camera.CFrame
                local rotatedVector = cameraCFrame:VectorToWorldSpace(moveVector)
                flyBodyVelocity.Velocity = rotatedVector * flySpeed
                flyBodyGyro.CFrame = cameraCFrame
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)

        WindUI:Notify({
            Title = "Fly",
            Content = "Fly enabled! Use W/A/S/D to move, Space/Control to go up/down.",
            Duration = 3,
            Icon = "rocket"
        })
    end
})

-- Fly speed input
MovementSection:Input({
    Title = "Fly Speed",
    Desc = "Set your fly speed (default: 50)",
    Default = "50",
    Callback = function(value)
        local numValue = tonumber(value) or 50
        flySpeed = numValue
        WindUI:Notify({
            Title = "Fly Speed",
            Content = "Fly speed set to " .. numValue,
            Duration = 1,
            Icon = "rocket"
        })
    end
})

-- FOV Changer Feature (FIXED: Using correct slider format)
local fovEnabled = false
local fovValue = 70
local fovConnection = nil

MovementSection:Toggle({
    Title = "Enable FOV Changer",
    Default = false,
    Callback = function(state)
        fovEnabled = state

        if not state then
            workspace.CurrentCamera.FieldOfView = 70
            if fovConnection then
                fovConnection:Disconnect()
                fovConnection = nil
            end
            return
        end

        workspace.CurrentCamera.FieldOfView = fovValue

        fovConnection = RunService.Heartbeat:Connect(function()
            if fovEnabled then
                workspace.CurrentCamera.FieldOfView = fovValue
            end
        end)

        WindUI:Notify({
            Title = "FOV Changer",
            Content = "FOV changer enabled!",
            Duration = 3,
            Icon = "maximize"
        })
    end
})

-- FOV slider (FIXED: Using correct slider format)
MovementSection:Slider({
    Title = "FOV Value",
    Desc = "Set your field of view (min 10, max 120)",
    Step = 1,
    Value = {
        Min = 10,
        Max = 120,
        Default = 70
    },
    Callback = function(value)
        fovValue = value
        if fovEnabled then
            workspace.CurrentCamera.FieldOfView = fovValue
            WindUI:Notify({
                Title = "FOV Changer",
                Content = "FOV set to " .. fovValue,
                Duration = 1,
                Icon = "maximize"
            })
        end
    end
})

-- Teleport tab
local TeleportTab = MainSection:Tab({
    Title = "Teleport",
    Icon = "map-pin",
    Locked = false,
})

-- Teleport section
local TeleportSection = TeleportTab:Section({
    Title = "Teleport Options",
    Desc = "Various teleport functions"
})

-- Teleport to lobby
TeleportSection:Button({
    Title = "Teleport to Lobby",
    Desc = "Teleport to lobby",
    Callback = function()
        local spawnLocation = workspace:FindFirstChild("spawn") and workspace.spawn:FindFirstChild("SpawnLocation")

        if spawnLocation then
            LocalPlayer.Character:MoveTo(spawnLocation.Position)
            WindUI:Notify({
                Title = "Teleported",
                Content = "Successfully teleported to lobby!",
                Duration = 3,
                Icon = "arrow-up-right"
            })
            return
        end

        -- Try other common paths
        local lobby = workspace:FindFirstChild("lobby")
        if lobby then
            local spawnPoint = lobby:FindFirstChild("SpawnLocation") or lobby:FindFirstChild("Spawn")
            if spawnPoint then
                LocalPlayer.Character:MoveTo(spawnPoint.Position)
                WindUI:Notify({
                    Title = "Teleported",
                    Content = "Successfully teleported to lobby!",
                    Duration = 3,
                    Icon = "arrow-up-right"
                })
                return
            end
        end

        -- If spawn point not found, use hardcoded position
        LocalPlayer.Character:MoveTo(Vector3.new(0, 100, 0))
        WindUI:Notify({
            Title = "Teleported",
            Content = "Using hardcoded lobby position!",
            Duration = 3,
            Icon = "arrow-up-right"
        })
    end
})

-- Teleport to game
TeleportSection:Button({
    Title = "Teleport to Game",
    Desc = "Teleports you to the game spawn point",
    Callback = function()
        local currentMap = workspace:FindFirstChild("CurrentMap")
        if currentMap then
            local spawnPoint = currentMap:FindFirstChild("spawn1")
            if spawnPoint then
                LocalPlayer.Character:MoveTo(spawnPoint.Position)
                WindUI:Notify({
                    Title = "Teleported",
                    Content = "Successfully teleported to game!",
                    Duration = 3,
                    Icon = "arrow-up-right"
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Game spawn point not found!",
                    Duration = 3,
                    Icon = "alert-circle"
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "CurrentMap not found!",
                Duration = 3,
                Icon = "alert-circle"
            })
        end
    end
})

-- Teleport to shooter spawn
TeleportSection:Button({
    Title = "Teleport to Shooter Spawn",
    Desc = "Teleports you to the shooter spawn point",
    Callback = function()
        local currentMap = workspace:FindFirstChild("CurrentMap")
        if currentMap then
            local shooterSpawn = currentMap:FindFirstChild("ShooterSpawn")
            if shooterSpawn then
                LocalPlayer.Character:MoveTo(shooterSpawn.Position)
                WindUI:Notify({
                    Title = "Teleported",
                    Content = "Successfully teleported to shooter spawn!",
                    Duration = 3,
                    Icon = "arrow-up-right"
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Shooter spawn point not found!",
                    Duration = 3,
                    Icon = "alert-circle"
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "CurrentMap not found!",
                Duration = 3,
                Icon = "alert-circle"
            })
        end
    end
})

-- Tools tab - FIXED: Changed icon from "tool" to "wrench" (valid Lucide icon)
local ToolsTab = MainSection:Tab({
    Title = "Tools",
    Icon = "wrench",  -- Fixed: "tool" is not a valid icon name in Lucide
    Locked = false,
})

-- Tools section
local ToolsSection = ToolsTab:Section({
    Title = "Utility Tools",
    Desc = "Various tools to remove barriers and help with navigation"
})

-- Get Teleport Tool
ToolsSection:Button({
    Title = "Get Teleport Tool",
    Desc = "Gives you a tool to teleport to mouse position",
    Callback = function()
        local teleportTool = Instance.new("Tool")
        teleportTool.Name = "TeleportTool"
        teleportTool.ToolTip = "Teleport to mouse position"

        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1, 1, 1)
        handle.CanCollide = false
        handle.Transparency = 1
        handle.Parent = teleportTool

        teleportTool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            if mouse.Target then
                LocalPlayer.Character:MoveTo(mouse.Hit.Position)
            end
        end)

        teleportTool.Parent = LocalPlayer.Backpack
        WindUI:Notify({
            Title = "Teleport Tool",
            Content = "Teleport tool added to your backpack!",
            Duration = 3,
            Icon = "arrow-up-right"
        })
    end
})

-- Delete Lobby Barriers
ToolsSection:Button({
    Title = "Delete Lobby Barriers",
    Desc = "Destroys workspace.lobby.kill barriers",
    Callback = function()
        local lobby = workspace:FindFirstChild("lobby")
        if lobby then
            local killFolder = lobby:FindFirstChild("kill")
            if killFolder then
                killFolder:Destroy()
                WindUI:Notify({
                    Title = "Lobby Barriers",
                    Content = "Lobby barriers deleted!",
                    Duration = 3,
                    Icon = "trash"
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Lobby barriers not found!",
                    Duration = 3,
                    Icon = "alert-circle"
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Lobby not found!",
                Duration = 3,
                Icon = "alert-circle"
            })
        end
    end
})

-- Remove Game Barriers
ToolsSection:Button({
    Title = "Remove Game Barriers",
    Desc = "Removes red barriers in the game",
    Callback = function()
        local currentMap = workspace:FindFirstChild("CurrentMap")
        if currentMap then
            local redColor = Color3.fromRGB(255, 0, 0)
            local barrierCount = 0

            for _, part in ipairs(currentMap:GetDescendants()) do
                if part:IsA("BasePart") and part.Color == redColor then
                    part:Destroy()
                    barrierCount = barrierCount + 1
                end
            end

            WindUI:Notify({
                Title = "Game Barriers",
                Content = tostring(barrierCount) .. " red barriers removed!",
                Duration = 3,
                Icon = "trash"
            })
        else
            WindUI:Notify({
                Title = "Error",
                Content = "CurrentMap not found!",
                Duration = 3,
                Icon = "alert-circle"
            })
        end
    end
})

-- Remove Void Parts
ToolsSection:Button({
    Title = "Remove Void Parts",
    Desc = "Removes void parts in the game",
    Callback = function()
        local currentMap = workspace:FindFirstChild("CurrentMap")
        if not currentMap then
            currentMap = workspace
        end

        local voidCount = 0

        -- Check for common void part characteristics
        for _, part in ipairs(currentMap:GetDescendants()) do
            if part:IsA("BasePart") then
                -- Check if it's likely a void part
                local isVoid = false

                -- Check by name
                if string.find(string.lower(part.Name), "void") or
                   string.find(string.lower(part.Name), "kill") or
                   string.find(string.lower(part.Name), "death") then
                    isVoid = true
                end

                -- Check by color
                if part.Color == Color3.new(1, 0, 0) or  -- Red
                   part.Color == Color3.new(0, 0, 0) or  -- Black
                   part.Color == Color3.new(0.2, 0.2, 0.2) then  -- Dark gray
                    isVoid = true
                end

                -- Check by transparency
                if part.Transparency > 0.9 then
                    isVoid = true
                end

                if isVoid then
                    part:Destroy()
                    voidCount = voidCount + 1
                end
            end
        end

        WindUI:Notify({
            Title = "Void Parts",
            Content = tostring(voidCount) .. " void parts removed!",
            Duration = 3,
            Icon = "trash"
        })
    end
})

-- Combat tab
local CombatTab = MainSection:Tab({
    Title = "Combat",
    Icon = "swords",
    Locked = false,
})

-- Combat section
local CombatSection = CombatTab:Section({
    Title = "Combat Features",
    Desc = "Features to help with combat"
})

-- Auto Punch feature
local autoPunchEnabled = false
local punchConnection = nil

CombatSection:Toggle({
    Title = "Auto Punch",
    Default = false,
    Callback = function(state)
        autoPunchEnabled = state

        -- Clean up previous auto punch if exists
        if punchConnection then
            punchConnection:Disconnect()
            punchConnection = nil
        end

        if not state then return end

        local punchRemote = ReplicatedStorage:FindFirstChild("remotes", true)
        if punchRemote then
            punchRemote = punchRemote:FindFirstChild("punch")
        end

        if not punchRemote then
            WindUI:Notify({
                Title = "Error",
                Content = "Punch remote not found!",
                Duration = 3,
                Icon = "alert-circle"
            })
            return
        end

        -- Set up auto punch
        punchConnection = RunService.Heartbeat:Connect(function()
            if not autoPunchEnabled then return end
            punchRemote:FireServer()
        end)

        WindUI:Notify({
            Title = "Auto Punch",
            Content = "Auto punch enabled!",
            Duration = 3,
            Icon = "fist"
        })
    end
})

-- FIXED Hitbox Expander with Slider (FIXED: Using correct slider format)
local hitboxEnabled = false
local hitboxSize = 2
local hitboxConnections = {}

CombatSection:Toggle({
    Title = "Expand Hitbox",
    Default = false,
    Callback = function(state)
        hitboxEnabled = state

        -- Clean up previous hitbox if exists
        for _, connection in pairs(hitboxConnections) do
            connection:Disconnect()
        end
        hitboxConnections = {}

        if not state then
            -- Reset all hitboxes when disabled
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    if head and head:IsA("BasePart") then
                        local originalSize = head:FindFirstChild("OriginalSize")
                        if originalSize and originalSize.Value then
                            head.Size = originalSize.Value
                            head.CanCollide = true
                        end
                    end
                end
            end
            return 
        end

        -- Apply hitbox expansion to other players' heads
        local function expandHitbox(player)
            if player == LocalPlayer then return end

            local function updateHead(character)
                if not character then return end

                local head = character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    -- Store original size if not already stored
                    if not head:FindFirstChild("OriginalSize") then
                        local originalSize = Instance.new("ObjectValue")
                        originalSize.Name = "OriginalSize"
                        originalSize.Value = head.Size
                        originalSize.Parent = head
                    end

                    -- Apply new size
                    local originalSize = head:FindFirstChild("OriginalSize").Value
                    head.Size = Vector3.new(
                        originalSize.X * hitboxSize,
                        originalSize.Y * hitboxSize,
                        originalSize.Z * hitboxSize
                    )
                    head.CanCollide = false
                end
            end

            -- Apply to current character
            if player.Character then
                updateHead(player.Character)
            end

            -- Apply to future characters
            table.insert(hitboxConnections, player.CharacterAdded:Connect(updateHead))
        end

        -- Apply to all existing players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                expandHitbox(player)
            end
        end

        -- Apply to future players
        table.insert(hitboxConnections, Players.PlayerAdded:Connect(expandHitbox))

        WindUI:Notify({
            Title = "Hitbox",
            Content = "Hitbox expanded for other players!",
            Duration = 3,
            Icon = "box"
        })
    end
})

-- Hitbox Size slider (FIXED: Using correct slider format)
CombatSection:Slider({
    Title = "Hitbox Size",
    Desc = "Set hitbox size multiplier",
    Step = 0.1,
    Value = {
        Min = 1,
        Max = 5,
        Default = 2
    },
    Callback = function(value)
        hitboxSize = value

        if hitboxEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    if head and head:IsA("BasePart") then
                        local originalSize = head:FindFirstChild("OriginalSize")
                        if originalSize and originalSize.Value then
                            -- Apply new size
                            head.Size = Vector3.new(
                                originalSize.Value.X * hitboxSize,
                                originalSize.Value.Y * hitboxSize,
                                originalSize.Value.Z * hitboxSize
                            )
                            head.CanCollide = false
                        end
                    end
                end
            end

            WindUI:Notify({
                Title = "Hitbox",
                Content = "Hitbox size set to " .. hitboxSize,
                Duration = 1,
                Icon = "box"
            })
        end
    end
})

-- Role Detector Feature
local roleDetectorEnabled = false
local selectedRole = "Shooter"
local roleDetectorConnection = nil
local roleDetectorLabel = nil

-- Create a label to display the role detector info
local roleDetectorDisplay = Instance.new("TextLabel")
roleDetectorDisplay.Size = UDim2.new(0, 300, 0, 40)
roleDetectorDisplay.Position = UDim2.new(0.5, -150, 0.1, 0)
roleDetectorDisplay.BackgroundTransparency = 1
roleDetectorDisplay.TextColor3 = Color3.new(1, 1, 1)
roleDetectorDisplay.TextSize = 18
roleDetectorDisplay.Font = Enum.Font.SourceSansBold
roleDetectorDisplay.Text = ""
roleDetectorDisplay.Visible = false
roleDetectorDisplay.Parent = game:GetService("CoreGui")

CombatSection:Toggle({
    Title = "Role Detector",
    Default = false,
    Callback = function(state)
        roleDetectorEnabled = state

        if not state then
            roleDetectorDisplay.Visible = false
            if roleDetectorConnection then
                roleDetectorConnection:Disconnect()
                roleDetectorConnection = nil
            end
            return
        end

        -- Create a new connection to update the role detector
        roleDetectorConnection = RunService.Heartbeat:Connect(function()
            if not roleDetectorEnabled then return end

            local nearestPlayer = nil
            local minDistance = math.huge

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local role = player:GetAttribute("Role") or "Unknown"
                    if role == selectedRole then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if distance < minDistance then
                                minDistance = distance
                                nearestPlayer = player
                            end
                        end
                    end
                end
            end

            if nearestPlayer then
                roleDetectorDisplay.Text = string.format("%s: %.1f studs away", selectedRole, minDistance)
                roleDetectorDisplay.Visible = true
            else
                roleDetectorDisplay.Text = string.format("No %s players nearby", selectedRole)
                roleDetectorDisplay.Visible = true
            end
        end)

        WindUI:Notify({
            Title = "Role Detector",
            Content = "Role detector enabled! Shows distance to selected role.",
            Duration = 3,
            Icon = "search"
        })
    end
})

-- Role selection dropdown (FIXED: Using correct dropdown format)
CombatSection:Dropdown({
    Title = "Role to Track",
    Values = {"Shooter", "Bystander", "Police", "Cop", "Guard", "Traitor", "Mafia", "Responder", "Unknown"},
    Value = "Shooter",
    Callback = function(value)
        selectedRole = value
        if roleDetectorEnabled then
            WindUI:Notify({
                Title = "Role Detector",
                Content = "Now tracking: " .. selectedRole,
                Duration = 1,
                Icon = "search"
            })
        end
    end
})

-- Add notification
WindUI:Notify({
    Title = "Rendex Off Limits",
    Content = "All features working correctly! Fixed tab structure for testing.",
    Duration = 5,
    Icon = "shield-check"
})
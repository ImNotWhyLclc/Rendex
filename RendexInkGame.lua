-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:SetTheme("Dark")

-- Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr               = Players.LocalPlayer

-- Window & Tabs
local Window       = WindUI:CreateWindow({
    Title       = "Rendex Ink Game",
    Icon        = "ink-pen",
    Author      = "Ren",
    Folder      = "RendexInkGame",
    Size        = UDim2.fromOffset(600, 750),
    Transparent = false,
})
local HomeTab     = Window:Tab({ Title = "Home",     Icon = "house" })
local MainTab     = Window:Tab({ Title = "Main",     Icon = "layout-grid" })
local PlayerTab   = Window:Tab({ Title = "Player",   Icon = "user" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Toggle-UI Button
Window:EditOpenButton({
    Title        = "Toggle UI",
    Icon         = "menu",
    CornerRadius = UDim.new(0, 10),
    Draggable    = true,
    Callback     = function(open)
        if open then Window:SelectTab(1) end
    end,
})
Window:SelectTab(1)

-- Config system
local ConfigManager = Window.ConfigManager
local myConfig      = ConfigManager:CreateConfig("RendexInkGame")

-- Notification helper
local function notify(title, content, icon)
    WindUI:Notify({ Title = title, Content = content, Icon = icon or "zap", Duration = 3 })
end

-- ============ HOME ============
HomeTab:Paragraph({
    Title = "Welcome to Rendex Ink",
    Desc  = "Use the tabs above to access features. Don’t forget to Save your config!",
})

-- ============ MAIN ============
do
    local tab = MainTab

    -- 1) Safe Position
    tab:Button({
        Title    = "Teleport to Safe Position",
        Icon     = "shield-check",
        Callback = function()
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(197, 123, -92) end
        end,
    })

    -- 2) Piggy Bank
    tab:Button({
        Title    = "Teleport to Piggy Bank",
        Icon     = "piggy-bank",
        Callback = function()
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(200, 90, -94) end
        end,
    })

    -- 3) End of Glass Bridge
    tab:Button({
        Title    = "Teleport to End of Glass Bridge",
        Icon     = "flag",
        Callback = function()
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(-209, 521, -1533) end
        end,
    })

    -- 4) RLG End
    tab:Button({
        Title    = "Teleport to RLG End",
        Icon     = "map-pin",
        Callback = function()
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(-45, 1024, 105) end
        end,
    })

    -- Auto Tug of War
    local tugToggle = tab:Toggle({
        Title    = "Auto Tug of War",
        Icon     = "shuffle",
        Value    = false,
        Callback = function(v) _G.AutoTug = v end,
    })
    myConfig:Register("autoTug", tugToggle)
    RunService.RenderStepped:Connect(function()
        if _G.AutoTug then
            ReplicatedStorage.Remotes.TemporaryReachedBindable:FireServer({{QTEGood = true}})
        end
    end)

    -- Auto Skip Cutscenes
    local skipToggle = tab:Toggle({
        Title    = "Auto Skip Cutscenes",
        Icon     = "skip-forward",
        Value    = false,
        Callback = function(v) _G.AutoSkip = v end,
    })
    myConfig:Register("autoSkip", skipToggle)
    RunService.RenderStepped:Connect(function()
        if _G.AutoSkip then
            ReplicatedStorage.Remotes.DialogueRemote:FireServer("Skipped")
        end
    end)

    -- Glass Vision
    tab:Button({
        Title    = "Glass Vision",
        Icon     = "eye",
        Callback = function()
            local count  = 0
            local holder = workspace:FindFirstChild("GlassBridge")
                           and workspace.GlassBridge:FindFirstChild("GlassHolder")
            if holder then
                for _, pnl in ipairs(holder:GetChildren()) do
                    if pnl.Name:match("Cloned?Panel%d+") then
                        for _, modelName in ipairs({"glassmodel1","glassmodel2"}) do
                            local model = pnl:FindFirstChild(modelName)
                            if model then
                                for _, part in ipairs(model:GetDescendants()) do
                                    if part:IsA("BasePart")
                                    and part.Name == "glasspart"
                                    and (part:GetAttribute("exploitingisevil")
                                         or part:GetAttribute("delayedbreak")) then
                                        part.Color = Color3.new(1, 0, 0)
                                        count += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
            notify("Glass Vision", "Tinted "..count.." parts")
        end,
    })
end

-- ============ PLAYER ============
do
    local tab = PlayerTab

    -- Boost sliders
    for _, boostName in ipairs({"Damage Boost","Faster Sprint","Won Boost"}) do
        local defaultVal = 0
        local boostsFolder = plr:FindFirstChild("Boosts")
        if boostsFolder then
            local boostObj = boostsFolder:FindFirstChild(boostName)
            if boostObj and boostObj:IsA("NumberValue") then
                defaultVal = boostObj.Value
            end
        end

        local slider = tab:Slider({
            Title    = boostName,
            Value    = {Min = 0, Max = 100, Default = defaultVal},
            Callback = function(v)
                local b = plr:FindFirstChild("Boosts") and plr.Boosts:FindFirstChild(boostName)
                if b and b:IsA("NumberValue") then b.Value = v end
            end,
        })
        myConfig:Register("boost_"..boostName:gsub(" ",""), slider)
    end

    -- Infinite Jump
    local infJumpToggle = tab:Toggle({
        Title    = "Infinite Jump",
        Icon     = "arrow-up-right",
        Value    = false,
        Callback = function(v) _G.InfJump = v end,
    })
    myConfig:Register("infJump", infJumpToggle)
    UserInputService.JumpRequest:Connect(function()
        if _G.InfJump and plr.Character then
            plr.Character:FindFirstChildOfClass("Humanoid")
               :ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    -- NoClip
    local noclipToggle = tab:Toggle({
        Title    = "NoClip",
        Icon     = "slash",
        Value    = false,
        Callback = function(v) _G.NoClip = v end,
    })
    myConfig:Register("noClip", noclipToggle)
    RunService.Stepped:Connect(function()
        if _G.NoClip and plr.Character then
            for _, p in ipairs(plr.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)

    -- Anti-Fling
    local antiflingToggle = tab:Toggle({
        Title    = "Anti Fling",
        Icon     = "shield-off",
        Value    = false,
        Callback = function(v) _G.AntiFling = v end,
    })
    myConfig:Register("antiFling", antiflingToggle)
    RunService.Stepped:Connect(function()
        if _G.AntiFling then
            for _, other in ipairs(Players:GetPlayers()) do
                if other~=plr and other.Character then
                    for _, part in ipairs(other.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end
        end
    end)

    -- WalkFling (enhanced force + reliable toggling)
    local walkFlingConn
    local walkFlingToggle = tab:Toggle({
        Title    = "WalkFling",
        Icon     = "move",
        Value    = false,
        Callback = function(on)
            _G.WalkFling = on
            if walkFlingConn then
                walkFlingConn:Disconnect()
                walkFlingConn = nil
            end
            if on then
                walkFlingConn = RunService.Heartbeat:Connect(function()
                    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local vel = root.Velocity
                    root.Velocity = vel * 25000 + Vector3.new(0, 25000, 0)
                    RunService.RenderStepped:Wait()
                    root.Velocity = vel
                    RunService.Stepped:Wait()
                    root.Velocity = vel + Vector3.new(0, 0.2, 0)
                end)
            end
        end,
    })
    myConfig:Register("walkFling", walkFlingToggle)
end

-- ============ SETTINGS ============
do
    local tab = SettingsTab

    -- Anti-Mod Action dropdown
    local antiModAction = tab:Dropdown({
        Title   = "Anti-Mod Action",
        Values  = {"Off","Warn","Kick"},
        Value   = "Off",
        Multi   = false,
        Callback= function(v) _G.AntiModAction = v end,
    })
    myConfig:Register("antiModAction", antiModAction)

    -- PlayerAdded handler
    Players.PlayerAdded:Connect(function(p)
        local mods = {
            "Squares_64","squirrelzio","Zyutt","kyruomii","veraxi64",
            "BokNero","Voayn","LittleDyingDuck","o0llNOAHll0o",
            "DevZubb","o0llchangedll0o","Blankello","Friizti",
            "KillBoz_B","heartsformelusine","CalebRedux","Kiybiee"
        }
        if table.find(mods, p.Name) then
            if _G.AntiModAction == "Warn" then
                notify("Moderator Detected", p.Name, "alert-triangle")
            elseif _G.AntiModAction == "Kick" then
                p:Kick("Kicked by RendexInk Anti-Mod")
            end
        end
    end)

    -- Save / Load / Reset
    tab:Button({ Title="Save Config", Icon="save", Callback=function()
        local ok, err = pcall(function() myConfig:Save() end)
        notify("Config", ok and "Saved" or err)
    end })
    tab:Button({ Title="Load Config", Icon="download", Callback=function()
        local ok, err = pcall(function() myConfig:Load() end)
        notify("Config", ok and "Loaded" or err)
    end })
    tab:Button({ Title="Reset Config", Icon="refresh-ccw", Callback=function()
        local ok, err = pcall(function() myConfig:Reset() end)
        notify("Config", ok and "Reset" or err)
    end })
end

-- Load saved settings
pcall(function() myConfig:Load() end)
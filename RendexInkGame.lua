-- Full Rendex Ink Game Script with WindUI
-- Features: Stronger WalkFling (×200000), Play Emote Dropdown, Teleport to Injured Player, Kill Aura

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:SetTheme("Dark")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Title = "Rendex Ink Game",
    Icon = "ink-pen",
    Author = "Ren",
    Folder = "RendexInkGame",
    Size = UDim2.fromOffset(600, 800),
})
local HomeTab = Window:Tab({ Title = "Home", Icon = "house" })
local MainTab = Window:Tab({ Title = "Main", Icon = "layout-grid" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

Window:EditOpenButton({
    Title = "Toggle UI",
    Icon = "menu",
    Draggable = true,
    Callback = function(open) if open then Window:SelectTab(1) end end,
})
Window:SelectTab(1)

local myConfig = Window.ConfigManager:CreateConfig("RendexInkGame")
local function notify(title, content, icon)
    WindUI:Notify({ Title = title, Content = content, Icon = icon or "zap", Duration = 3 })
end

-- ============ MAIN ============
do
    local t = MainTab

    t:Button({
        Title = "Teleport to Injured Player",
        Icon = "cross",
        Callback = function()
            for _, p in ipairs(workspace.Live:GetChildren()) do
                local iw = p:FindFirstChild("InjuredWalking")
                if iw and (iw:GetAttribute("LegName") == "Left Leg" or iw:GetAttribute("LegName") == "Right Leg") then
                    local hrp = p:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local myRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then myRoot.CFrame = hrp.CFrame end
                        return
                    end
                end
            end
            notify("No Injured Player Found", "No players with InjuredWalking + LegName", "alert-triangle")
        end,
    })
end

-- ============ PLAYER ============
do
    local t = PlayerTab

    -- WalkFling
    do
        local conn
        local function startWF()
            if conn then conn:Disconnect() end
            conn = RunService.Heartbeat:Connect(function()
                local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local v = root.Velocity
                    root.Velocity = v * 200000 + Vector3.new(0, 200000, 0)
                    RunService.RenderStepped:Wait()
                    root.Velocity = v
                end
            end)
        end
        local function stopWF()
            if conn then conn:Disconnect(); conn = nil end
        end

        local wf = t:Toggle({
            Title = "WalkFling (x200k)",
            Icon = "move",
            Value = false,
            Callback = function(on)
                _G.WalkFling = on
                if on then startWF() else stopWF() end
            end,
        })
        myConfig:Register("walkFling", wf)

        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if _G.WalkFling then startWF() end
        end)
    end

    -- Play Emote Dropdown
    local emotes = {"RAT SPOTTED", "Laugh"}
    local selected = emotes[1]
    local dd = t:Dropdown({
        Title = "Select Emote",
        Values = emotes,
        Value = selected,
        Callback = function(v) selected = v end,
    })
    myConfig:Register("selectedEmote", dd)

    t:Button({
        Title = "Play Emote",
        Icon = "play-circle",
        Callback = function()
            ReplicatedStorage.Replication.Event:FireServer({
                event = "playEmote",
                emoteName = selected,
            })
        end,
    })

    -- Kill Aura
    local radius, damage = 10, 25
    local rS = t:Slider({
        Title = "Kill Aura Radius",
        Value = {Min=1, Max=50, Default=radius},
        Callback = function(v) radius = v end,
    })
    myConfig:Register("kaRadius", rS)

    local dS = t:Slider({
        Title = "Kill Aura Damage",
        Value = {Min=1, Max=100, Default=damage},
        Callback = function(v) damage = v end,
    })
    myConfig:Register("kaDamage", dS)

    t:Toggle({
        Title = "Kill Aura",
        Icon = "zap",
        Value = false,
        Callback = function(on)
            _G.KillAura = on
            if on then
                RunService.Heartbeat:Connect(function()
                    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    for _, o in ipairs(Players:GetPlayers()) do
                        if o ~= plr and o.Character then
                            local hrp = o.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - root.Position).Magnitude <= radius then
                                ReplicatedStorage.Remotes.DealDamage:FireServer(o, damage)
                            end
                        end
                    end
                end)
            end
        end,
    })
end

-- ============ SETTINGS ============
do
    local t = SettingsTab
    t:Button({Title = "Save Config", Icon = "save", Callback = function()
        local ok, err = pcall(myConfig.Save, myConfig)
        notify("Config", ok and "Saved" or err)
    end})
    t:Button({Title = "Load Config", Icon = "download", Callback = function()
        local ok, err = pcall(myConfig.Load, myConfig)
        notify("Config", ok and "Loaded" or err)
    end})
    t:Button({Title = "Reset Config", Icon = "refresh-ccw", Callback = function()
        local ok, err = pcall(myConfig.Reset, myConfig)
        notify("Config", ok and "Reset" or err)
    end})
end

-- Auto-load config
pcall(function() myConfig:Load() end)

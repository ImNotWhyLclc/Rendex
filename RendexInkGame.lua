-- Loader & Services
local WindUI        = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace     = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService   = game:GetService("HttpService")

local plr   = Players.LocalPlayer
local char  = plr.Character or plr.CharacterAdded:Wait()
local hrp   = char:WaitForChild("HumanoidRootPart")
local cam   = Workspace.CurrentCamera

-- Popup on Load
WindUI:Popup({
    Title   = "Rendex Ink Game",
    Icon    = "info",
    Content = "UI Loaded! 🔥",
    Buttons = {
        { Title = "OK", Variant = "Primary", Callback = function() end }
    }
})

-- Create Window
local Window = WindUI:CreateWindow({
    Title            = "Rendex Ink Game",
    Icon             = "rbxassetid://123458129006985",
    Author           = "Ren",
    Folder           = "RendexInkGame",
    Size             = UDim2.fromOffset(580, 460),
    Transparent      = true,
    Theme            = "Dark",
    Resizable        = true,
    SideBarWidth     = 200,
    HideSearchBar    = false,
    ScrollBarEnabled = true,
})

-- Notification
local function notify(t,c) WindUI:Notify({Title=t,Content=c,Duration=3}) end

-- FOV enforcement
local fovValue = 70
RunService.RenderStepped:Connect(function() cam.FieldOfView = fovValue end)

-- === MAIN SECTION ===
local Main = Window:Section({Title="Main",Icon="menu",Opened=true})

-- Teleports
do
    local tele = {Lobby=Vector3.new(197,54,-20),Stairway=Vector3.new(-213,186,313),
                  ["Piggy bank"]=Vector3.new(198,90,-97),["Inside piggy bank"]=Vector3.new(197,83,-93)}
    local tab = Main:Tab({Title="Teleports",Icon="map-pin"})
    local sel,preview,orig = "Lobby",false,cam.CFrame
    tab:Dropdown({Title="Location",Values={"Lobby","Stairway","Piggy bank","Inside piggy bank"},
        Callback=function(v) if preview then cam.CFrame=orig preview=false end sel=v end})
    tab:Button({Title="Preview teleport",Callback=function()
        if not preview then orig=cam.CFrame; cam.CFrame=CFrame.new(tele[sel]); preview=true
        else cam.CFrame=orig; preview=false end
    end})
    tab:Button({Title="Teleport",Callback=function()
        hrp.CFrame=CFrame.new(tele[sel])
        if preview then cam.CFrame=orig; preview=false end
        notify("Teleported","to "..sel)
    end})
end

-- Red Light Green Light
do
    local tab = Main:Tab({Title="Red Light Green Light",Icon="traffic-light"})
    tab:Button({Title="Teleport to end",Callback=function()
        hrp.CFrame=CFrame.new(-47,1025,139); notify("Teleported","to RLGL end")
    end})
end

-- Dalgona
do
    local tab = Main:Tab({Title="Dalgona",Icon="cookie"})
    tab:Button({Title="Auto complete Dalgona",Callback=function()
        local M=ReplicatedStorage.Modules.Games.DalgonaClient
        for _,f in ipairs(getreg()) do
            if typeof(f)=="function" and islclosure(f)
            and getfenv(f).script==M and getinfo(f).nups==73 then
                setupvalue(f,31,1e10); break
            end
        end
        notify("Dalgona","Completed")
    end})
end

-- Lights Out
do
    local tab = Main:Tab({Title="Lights Out",Icon="lightbulb-off"})
    tab:Button({Title="Teleport to safe position",Callback=function()
        hrp.CFrame=CFrame.new(196,122,-203); notify("Teleported","to safe spot")
    end})
end

-- Hide & Seek
do
    local tab = Main:Tab({Title="Hide and Seek",Icon="eye-off"})
    tab:Toggle({Title="Infinite Stamina",Callback=function(v)
        local s=Workspace.Live[plr.Name]:FindFirstChild("StaminaVal")
        if s then s.Value = v and 100 or 0 end
    end})
    tab:Toggle({Title="ESP Key",Callback=function(v)
        for _,n in ipairs({"DroppedKeyCircle","DroppedKeyTriangle","DroppedKeySquare"}) do
            for _,o in ipairs(Workspace.Effects:GetChildren()) do
                if o.Name==n then
                    if v then Instance.new("Highlight",o).FillColor=Color3.new(1,1,0)
                    else local h=o:FindFirstChildOfClass("Highlight"); if h then h:Destroy() end end
                end
            end
        end
    end})
    tab:Toggle({Title="ESP Hider",Callback=function(v)
        for _,p in ipairs(Players:GetPlayers()) do
            local m=Workspace.Live:FindFirstChild(p.Name)
            if m and m:FindFirstChild("Blue vest") then
                for _,part in ipairs(m:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local h=part:FindFirstChildOfClass("Highlight") or Instance.new("Highlight",part)
                        h.FillColor=Color3.fromRGB(0,162,255); h.Enabled=v
                    end
                end
            end
        end
    end})
    tab:Toggle({Title="ESP Seeker",Callback=function(v)
        for _,p in ipairs(Players:GetPlayers()) do
            local m=Workspace.Live:FindFirstChild(p.Name)
            if m and m:FindFirstChild("Red vest") then
                for _,part in ipairs(m:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local h=part:FindFirstChildOfClass("Highlight") or Instance.new("Highlight",part)
                        h.FillColor=Color3.fromRGB(255,0,0); h.Enabled=v
                    end
                end
            end
        end
    end})
end

-- Tug of War
do
    local tab = Main:Tab({Title="Tug of War",Icon="zap"})
    local conn
    tab:Toggle({Title="Auto Pull",Callback=function(v)
        if conn then conn:Disconnect(); conn=nil end
        if v then
            notify("Tug","Auto pull ON")
            conn = RunService.RenderStepped:Connect(function()
                for i=1,3 do ReplicatedStorage.Remotes.TemporaryReachedBindable:FireServer({PerfectQTE=true}) end
            end)
        else notify("Tug","Auto pull OFF") end
    end})
end

-- Jump Rope
do
    local tab = Main:Tab({Title="Jump Rope",Icon="repeat"})
    local conn
    local function getBal()
        local g=plr.PlayerGui.ImpactFrames
        if not g then return end
        local m=g.Main or g.balanceBarMainGui
        local ind=m and m.Indicator
        return ind and ind:FindFirstChildWhichIsA("NumberValue")
    end
    tab:Toggle({Title="Auto Balance",Callback=function(v)
        if conn then conn:Disconnect(); conn=nil; notify("Jump Rope","Balance OFF") end
        if v then
            notify("Jump Rope","Balance ON")
            conn = RunService.Heartbeat:Connect(function()
                local val=getBal(); if val then val.Value=0 end
            end)
        end
    end})
end

-- Glass Bridge
do
    local tab = Main:Tab({Title="Glass Bridge",Icon="grid"})
    tab:Button({Title="Glass Vision",Callback=function()
        for i=0,11 do
            local panel=Workspace.GlassBridge.GlassHolder:FindFirstChild("ClonedPanel"..i)
            if panel then
                for j=1,2 do
                    local gm=panel:FindFirstChild("glassmodel"..j)
                    local gp=gm and gm:FindFirstChild("glasspart")
                    if gp then
                        gp.BrickColor=(gp:GetAttribute("DelayedBreaking") or gp:GetAttribute("ActuallyKilling"))
                            and BrickColor.Red() or BrickColor.Green()
                    end
                end
            end
        end
        notify("Glass Bridge","Vision applied")
    end})
end

-- Mingle Tab (empty placeholder)
do
    local tab = Main:Tab({Title="Mingle",Icon="users"})
    tab:Paragraph({Title="Mingle",Desc="Feature coming soon!"})
end

-- Rebel
do
    local tab = Main:Tab({Title="Rebel",Icon="shield-alert"})
    tab:Toggle({Title="Rebel Guard ESP",Callback=function(v)
        for _,pre in ipairs({"RebelGuardDoesntAutoAggro","RebelGuardDoesntAggroTillLOSCantMove","HallwayGuardLosCantMove","HallwayGuardLosReq"}) do
            for i=1,500 do
                local mdl=Workspace.Live:FindFirstChild(pre..i)
                if mdl then for _,p in ipairs(mdl:GetChildren()) do
                    if p:IsA("BasePart") then
                        local h=p:FindFirstChildOfClass("Highlight") or Instance.new("Highlight",p)
                        h.FillColor=Color3.fromRGB(255,0,255); h.Enabled=v
                    end
                end end
            end
        end
    end})
end

-- === PLAYER SECTION ===
local PlayerSec = Window:Section({Title="Player",Icon="user",Opened=true})
do
    local tab = PlayerSec:Tab({Title="Player",Icon="zap"})
    tab:Toggle({Title="Free Dash",Callback=function(v)
        local b=plr.Boosts and plr.Boosts["Faster Sprint"]
        if b then b.Value=v and 5 or 0 end
    end})
    tab:Toggle({Title="Infinite Jump",Callback=function(v)
        if infConn then infConn:Disconnect() end
        if v then infConn=UserInputService.JumpRequest:Connect(function() char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end) end
    end})
    tab:Toggle({Title="Noclip",Callback=function(v)
        if nocConn then nocConn:Disconnect() end
        if v then nocConn=RunService.Stepped:Connect(function() for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end) end
    end})
    tab:Toggle({Title="Anti Ragdoll",Callback=function(v)
        if v then local h=char:FindFirstChildOfClass("Humanoid") if h then h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end end
    end})
    tab:Slider({Title="FOV",Value={Min=30,Max=120,Default=fovValue},Callback=function(val) fovValue=val; notify("FOV","Set to "..math.floor(val)) end})
    -- Combat Tab
    local ct = PlayerSec:Tab({Title="Combat",Icon="slash"})
    local target=nil; local dd = ct:Dropdown({Title="Select Target",Values={},Callback=function(v) target=v end})
    local function refreshPlayers()
        local t={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(t,p.Name) end
        end
        dd:Refresh(t)
    end
    ct:Button({Title="Refresh Targets",Callback=refreshPlayers})
    refreshPlayers()
    local neConn,selConn
    ct:Toggle({Title="Auto kill nearest",Callback=function(v)
        if neConn then neConn:Disconnect() end
        if v then
            notify("Combat","Auto nearest ON")
            neConn=RunService.Heartbeat:Connect(function()
                local cd,cp=math.huge,nil
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=plr and p.Character then
                        local d=(p.Character.HumanoidRootPart.Position-hrp.Position).Magnitude
                        if d<cd then cd,cp=d,p end
                    end
                end
                if cp then hrp.CFrame=cp.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,1.5) end
            end)
        else notify("Combat","Auto nearest OFF") end
    end})
    ct:Toggle({Title="Auto kill selected",Callback=function(v)
        if selConn then selConn:Disconnect() end
        if v and target then
            notify("Combat","Auto "..target.." ON")
            selConn=RunService.Heartbeat:Connect(function()
                local p=Players:FindFirstChild(target)
                if p and p.Character then hrp.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,1.5) end
            end)
        else notify("Combat","Auto selected OFF") end
    end})
end

-- Powers Tab
do
    local tab = PlayerSec:Tab({Title="Powers",Icon="bolt"})
    tab:Paragraph({Title="Note",Desc="Some powers might not work"})
    tab:Dropdown({Title="Equip Power",Values={"MEDIC","TRICKSTER","SUPER STRENGTH","BLACKFLASH","PHANTOM STEP","WEAPON SMUGGLER","SHARP SHOOTER","QUICKSLIVER","LIGHTNING GOD"},
        Callback=function(v) plr:SetAttribute("_EquippedPower",v); notify("Power","Equipped "..v) end})
end

-- === SETTINGS SECTION ===
local Settings = Window:Section({Title="Settings",Icon="settings",Opened=true})
-- Config Tab
do
    local ct = Settings:Tab({Title="Config",Icon="save"})
    local path="RendexInkGame/config.json"
    ct:Button({Title="Save Config",Callback=function()
        writefile(path,HttpService:JSONEncode({Theme=Window:GetTheme(),Trans=Window:GetTransparency(),FOV=fovValue}))
        notify("Config","Saved")
    end})
    ct:Button({Title="Load Config",Callback=function()
        if isfile(path) then local d=HttpService:JSONDecode(readfile(path))
            if d.Theme then Window:SetTheme(d.Theme) end
            if d.Trans~=nil then Window:ToggleTransparency(d.Trans) end
            if d.FOV then fovValue=d.FOV end
            notify("Config","Loaded")
        else notify("Config","No config found") end
    end})
end
-- Theme Tab
do
    local tt=Settings:Tab({Title="Theme",Icon="palette"})
    tt:Dropdown({Title="Select Theme",Values=WindUI:GetThemes(),Callback=function(v) Window:SetTheme(v) end})
    tt:Toggle({Title="Enable Transparency",Default=Window:GetTransparency(),Callback=function(v) Window:ToggleTransparency(v) end})
end
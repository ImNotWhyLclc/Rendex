-- Loader & Services
local WindUI            = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local plr  = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp  = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
local cam  = Workspace.CurrentCamera

-- Anti‐Cheat Bypass
do
    local mt = getrawmetatable(game)
    setreadonly(mt,false)
    local old = mt.__index
    mt.__index = function(self,k)
        if tostring(self)=="HumanoidRootPart" and k=="Velocity" then
            local v = old(self,k)
            if v.Magnitude>200 then return Vector3.new(0,0,0) end
            return v
        end
        return old(self,k)
    end
end

-- UI Setup
WindUI:Popup({Title="Rendex Ink Game",Icon="info",Content="UI Loaded! 🔥",Buttons={{Title="OK",Variant="Primary",Callback=function()end}}})
local Window        = WindUI:CreateWindow({
    Title="Rendex Ink Game", Icon="rbxassetid://123458129006985",
    Author="Ren", Folder="RendexInkGame",
    Size=UDim2.fromOffset(580,460), Transparent=true, Theme="Dark",
    Resizable=true, SideBarWidth=200, HideSearchBar=false, ScrollBarEnabled=true,
})
Window:EditOpenButton({
    Title="Open Rendex UI", Icon="monitor",
    CornerRadius=UDim.new(0,16), StrokeThickness=2,
    Color=ColorSequence.new(Color3.fromHex("FF0F7B"),Color3.fromHex("F89B29")),
    Draggable=true,
})
local MyConfig      = Window.ConfigManager:CreateConfig("RendexInkGame")
local function notify(t,c) WindUI:Notify({Title=t,Content=c,Duration=3}) end

-- FOV Enforcement
local fovValue,enforceFOV = 70,true
RunService:BindToRenderStep("FOVEnforce",Enum.RenderPriority.Camera.Value,function()
    if enforceFOV then cam.FieldOfView = fovValue end
end)

-- === MAIN SECTION ===
local Main = Window:Section({Title="Main",Icon="menu",Opened=true})

-- Teleports
do
    local tps = {
        Lobby=Vector3.new(197,54,-20),
        Stairway=Vector3.new(-213,186,313),
        ["Piggy bank"]=Vector3.new(198,90,-97),
        ["Inside piggy bank"]=Vector3.new(197,83,-93),
    }
    local teleTab = Main:Tab({Title="Teleports",Icon="map-pin"})
    local sel,preview,orig = "Lobby",false,cam.CFrame

    teleTab:Dropdown({
        Title="Location",Values={"Lobby","Stairway","Piggy bank","Inside piggy bank"},
        Scrollable=true,
        Callback=function(v)
            if preview then cam.CFrame=orig; preview=false end
            sel=v
        end
    })
    teleTab:Button({
        Title="Preview teleport",
        Callback=function()
            if not preview then
                orig = cam.CFrame
                cam.CFrame = CFrame.new(tps[sel])
                preview = true
            else
                cam.CFrame = orig
                preview = false
            end
        end
    })
    teleTab:Button({
        Title="Teleport",
        Callback=function()
            hrp.CFrame = CFrame.new(tps[sel])
            if preview then cam.CFrame=orig; preview=false end
            notify("Teleported","to "..sel)
        end
    })
end

-- Red Light Green Light
do
    local rlglTab = Main:Tab({Title="Red Light Green Light",Icon="traffic-light"})
    rlglTab:Button({
        Title="Teleport to end",
        Callback=function()
            hrp.CFrame=CFrame.new(-47,1025,139)
            notify("Teleported","to RLGL end")
        end
    })
end

-- Dalgona
do
    local dalgTab = Main:Tab({Title="Dalgona",Icon="cookie"})
    dalgTab:Button({
        Title="Auto complete Dalgona",
        Callback=function()
            local M=ReplicatedStorage.Modules.Games.DalgonaClient
            for _,f in ipairs(getreg()) do
                if typeof(f)=="function" and islclosure(f)
                  and getfenv(f).script==M and getinfo(f).nups==73 then
                    setupvalue(f,31,1e10); break
                end
            end
            notify("Dalgona","Completed")
        end
    })
end

-- Lights Out
do
    local loTab = Main:Tab({Title="Lights Out",Icon="lightbulb-off"})
    loTab:Button({
        Title="Teleport to safe position",
        Callback=function()
            hrp.CFrame=CFrame.new(196,122,-203)
            notify("Teleported","to safe spot")
        end
    })
end

-- Hide & Seek
do
    local hsTab = Main:Tab({Title="Hide & Seek",Icon="eye-off"})
    local function clearESP()
        for _,i in ipairs(Workspace:GetDescendants()) do
            if i.Name=="ESPHighlight" then i:Destroy() end
        end
    end
    local function hl(t,c)
        if t:IsA("Model") then t=t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart") end
        if t and t:IsA("BasePart") and not t:FindFirstChild("ESPHighlight") then
            local h=Instance.new("Highlight",t)
            h.Name, h.Adornee, h.FillColor, h.OutlineColor, h.DepthMode =
              "ESPHighlight",t,c,Color3.new(0,0,0),Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
    RunService:BindToRenderStep("HSESP",Enum.RenderPriority.Camera.Value,function()
        clearESP()
        local LR=Workspace:FindFirstChild("Live")
        local EF=Workspace:FindFirstChild("Effects")
        local MD=Workspace:FindFirstChild("HideAndSeekMap") and Workspace.HideAndSeekMap:FindFirstChild("NEWFIXEDDOORS")
        if _G.ESP_H and LR then
            for _,m in ipairs(LR:GetChildren()) do if m:FindFirstChild("BlueVest") then hl(m,Color3.new(0,0,1)) end end
        end
        if _G.ESP_S and LR then
            for _,m in ipairs(LR:GetChildren()) do if m:FindFirstChild("RedVest") then hl(m,Color3.new(1,0,0)) end end
        end
        if _G.RebelESP and LR then
            for _,pre in ipairs({"RebelGuardDoesntAutoAggro","RebelGuardDoesntAggroTillLOSCantMove","HallwayGuardLosCantMove","HallwayGuardLosReq"}) do
                for i=1,500 do
                    local g=LR:FindFirstChild(pre..i)
                    if g then for _,p in ipairs(g:GetChildren()) do if p:IsA("BasePart") then hl(p,Color3.new(1,0,0)) end end end
                end
            end
        end
        if _G.KeyESP and EF then
            for _,k in ipairs({"DroppedKeyCircle","DroppedKeySquare","DroppedKeyTriangle"}) do
                local f=EF:FindFirstChild(k)
                if f then for _,p in ipairs(f:GetChildren()) do if p:IsA("BasePart") then hl(p,Color3.new(1,1,0)) end end end
            end
        end
        if _G.ExitESP and MD then
            for fl=1,3 do
                local floor=MD:FindFirstChild("Floor"..fl)
                local ex=floor and floor:FindFirstChild("EXITDOORS")
                if ex then for _,d in ipairs(ex:GetChildren()) do if d:IsA("BasePart") then hl(d,Color3.new(0,1,0)) end end end
            end
        end
    end)
    hsTab:Toggle({Title="ESP Hider",Icon="eye",Value=false,Callback=function(v)_G.ESP_H=v end})
    hsTab:Toggle({Title="ESP Seeker",Icon="target",Value=false,Callback=function(v)_G.ESP_S=v end})
    hsTab:Toggle({Title="Rebel Guard ESP",Icon="shield-off",Value=false,Callback=function(v)_G.RebelESP=v end})
    hsTab:Toggle({Title="ESP Key",Icon="key",Value=false,Callback=function(v)_G.KeyESP=v end})
    hsTab:Toggle({Title="ESP Exit Doors",Icon="door-open",Value=false,Callback=function(v)_G.ExitESP=v end})
end

-- Tug of War
do
    local tugTab,tugConn = Main:Tab({Title="Tug of War",Icon="zap"}),nil
    tugTab:Toggle({Title="Auto Pull",Value=false,Callback=function(v)
        if tugConn then tugConn:Disconnect(); tugConn=nil end
        if v then
            notify("Tug","Auto pull ON")
            tugConn=RunService.RenderStepped:Connect(function()
                ReplicatedStorage.Remotes.TemporaryReachedBindable:FireServer({GameQTE=true})
            end)
        else notify("Tug","Auto pull OFF") end
    end})
end

-- Jump Rope
do
    local jrTab,jrConn = Main:Tab({Title="Jump Rope",Icon="repeat"}),nil
    local function getBal()
        local g=plr.PlayerGui:FindFirstChild("ImpactFrames"); if not g then return end
        local m=g.Main or g.balanceBarMainGui
        return m and m.Indicator and m.Indicator:FindFirstChildWhichIsA("NumberValue")
    end
    jrTab:Toggle({Title="Auto Balance",Value=false,Callback=function(v)
        if jrConn then jrConn:Disconnect(); jrConn=nil; notify("Jump Rope","Balance OFF") end
        if v then
            notify("Jump Rope","Balance ON")
            jrConn=RunService.Heartbeat:Connect(function()
                local val=getBal(); if val then val.Value=0 end
            end)
        end
    end})
    jrTab:Button({Title="Teleport to end",Callback=function()
        hrp.CFrame=CFrame.new(724,197,922); notify("Jump Rope","Teleported to end")
    end})
    jrTab:Button({Title="Teleport to end (safe)",Callback=function()
        hrp.CFrame=CFrame.new(725,197,925); notify("Jump Rope","Teleported to safe end")
    end})
end

-- Glass Bridge
do
    local gbTab = Main:Tab({Title="Glass Bridge",Icon="grid"})
    gbTab:Button({Title="Glass Vision",Callback=function()
        for i=0,11 do
            local p=Workspace.GlassBridge.GlassHolder:FindFirstChild("ClonedPanel"..i)
            if p then
                for j=1,2 do
                    local gm=p:FindFirstChild("glassmodel"..j)
                    local gp=gm and gm:FindFirstChild("glasspart")
                    if gp then
                        gp.BrickColor=(gp:GetAttribute("DelayedBreaking") or gp:GetAttribute("ActuallyKilling")) and BrickColor.Red() or BrickColor.Green()
                    end
                end
            end
        end
        notify("Glass Bridge","Vision applied")
    end})
end

-- Mingle
do
    local mgTab=Main:Tab({Title="Mingle",Icon="users"})
    local active,conns,loops=false,{},{}
    local function disconnectAll()
        for _,c in ipairs(conns) do c:Disconnect() end; conns={}
        for _,l in ipairs(loops) do l:Disconnect() end; loops={}
    end
    local function follow(r)
        local c=RunService.Heartbeat:Connect(function()
            if active and r and r.Parent then r:FireServer() end
        end)
        table.insert(loops,c)
    end
    local function scanChar(ch)
        local c=ch.ChildAdded:Connect(function(child)
            if child.Name=="RemoteForQTE" and active then follow(child) end
        end)
        table.insert(conns,c)
        for _,o in ipairs(ch:GetChildren()) do
            if o.Name=="RemoteForQTE" and active then follow(o) end
        end
    end
    mgTab:Toggle({Title="Auto Choke & Escape",Value=false,Callback=function(v)
        active=v
        if v then
            if plr.Character then scanChar(plr.Character) end
            local c=plr.CharacterAdded:Connect(scanChar)
            table.insert(conns,c)
        else disconnectAll() end
    end})
end

-- === PLAYER & COMBAT ===
local PlayerSec = Window:Section({Title="Player",Icon="user",Opened=true})

-- Player Tab
do
    local playerTab = PlayerSec:Tab({Title="Player",Icon="zap"})

    -- Player ESP
    local espH={}
    local function clearPESP()
        for _,h in ipairs(espH) do if h.Parent then h:Destroy() end end; espH={}
    end
    playerTab:Toggle({Title="Player ESP",Value=false,Callback=function(v)
        clearPESP(); RunService:UnbindFromRenderStep("PESPLoop")
        if v then
            RunService:BindToRenderStep("PESPLoop",Enum.RenderPriority.Character.Value,function()
                clearPESP()
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=plr and p.Character then
                        local root=p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
                        if root then
                            local h=Instance.new("Highlight",root)
                            h.Adornee=root; h.FillColor=Color3.fromRGB(0,255,255); h.OutlineColor=Color3.fromRGB(0,128,128)
                            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                            table.insert(espH,h)
                        end
                    end
                end
            end)
        end
    end})

    -- Anti Stun
    playerTab:Toggle({Title="Anti Stun",Value=false,Callback=function(v)
        if v then
            RunService:BindToRenderStep("AntiStun",Enum.RenderPriority.Character.Value,function()
                local l=Workspace.Live:FindFirstChild(plr.Name)
                if l then local s=l:FindFirstChild("Stun") if s then s:Destroy() end end
            end)
        else
            RunService:UnbindFromRenderStep("AntiStun")
        end
    end})

    -- Anti Ragdoll
    playerTab:Toggle({Title="Anti Ragdoll",Value=false,Callback=function(v)
        if v then
            RunService:BindToRenderStep("AntiRagdoll",Enum.RenderPriority.Character.Value,function()
                local l=Workspace.Live:FindFirstChild(plr.Name)
                if l then local r=l:FindFirstChild("Ragdoll") if r then r:Destroy() end end
            end)
        else
            RunService:UnbindFromRenderStep("AntiRagdoll")
        end
    end})

    -- Instant Proximity Prompts
    local PromptButtonHoldBegan = nil
    playerTab:Toggle({Title="Instant PP",Value=false,Callback=function(v)
        if PromptButtonHoldBegan then
            PromptButtonHoldBegan:Disconnect()
            PromptButtonHoldBegan=nil
        end
        if v then
            if fireproximityprompt then
                PromptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
                    fireproximityprompt(prompt)
                end)
            else
                notify("Incompatible Exploit","Missing fireproximityprompt")
            end
        end
    end})

    -- FOV Enforcement
    playerTab:Toggle({Title="Enable FOV Enforcement",Value=enforceFOV,Callback=function(v) enforceFOV=v end})

    -- Infinite Jump
    local ijConn
    playerTab:Toggle({Title="Infinite Jump",Value=false,Callback=function(v)
        if ijConn then ijConn:Disconnect() end
        if v then
            ijConn=UserInputService.JumpRequest:Connect(function()
                char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end)
        end
    end})

    -- Noclip
    local nocConn
    playerTab:Toggle({Title="Noclip",Value=false,Callback=function(v)
        if nocConn then nocConn:Disconnect() end
        if v then
            nocConn=RunService.Stepped:Connect(function()
                for _,p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide=false end
                end
            end)
        end
    end})

    -- Anti Fling (one‐time)
    local afConns = {}
    playerTab:Toggle({Title="Anti Fling",Value=false,Callback=function(v)
        for _,c in ipairs(afConns) do c:Disconnect() end; afConns={}
        if v then
            local function disableOnChar(ch)
                for _,part in ipairs(ch:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide=false end
                end
            end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=plr and p.Character then disableOnChar(p.Character) end
                local c=p.CharacterAdded:Connect(disableOnChar); table.insert(afConns,c)
            end
        end
    end})

    -- Walk Fling (original pattern)
    local walkFlinging=false
    local function getRoot(c) return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") end
    playerTab:Toggle({Title="Walk Fling",Value=false,Callback=function(v)
        walkFlinging=v
        if v then
            for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
            spawn(function()
                local humanoid=char:FindFirstChildWhichIsA("Humanoid")
                if humanoid then humanoid.Died:Connect(function() walkFlinging=false end) end
                local movel=0.1
                repeat
                    RunService.Heartbeat:Wait()
                    local c=plr.Character; local r=c and getRoot(c)
                    while not (c and c.Parent and r and r.Parent) do
                        RunService.Heartbeat:Wait()
                        c=plr.Character; r=c and getRoot(c)
                    end
                    local vel=r.Velocity
                    r.Velocity=vel*10000+Vector3.new(0,10000,0)
                    RunService.RenderStepped:Wait()
                    if walkFlinging then r.Velocity=vel end
                    RunService.Stepped:Wait()
                    if walkFlinging then r.Velocity=vel+Vector3.new(0,movel,0); movel=-movel end
                until walkFlinging==false
            end)
        end
    end})

    -- FOV Slider
    playerTab:Slider({Title="FOV",Value={Min=30,Max=120,Default=fovValue},Callback=function(v)
        fovValue=v; if enforceFOV then cam.FieldOfView=v end; notify("FOV","Set to "..math.floor(v))
    end})
end

-- Combat Tab (with Spectate + Stop Spectating)
do
    local combatTab = PlayerSec:Tab({Title="Combat",Icon="slash"})
    local target,connN,connS

    -- Spectate
    local specDD = combatTab:Dropdown({
        Title="Spectate Player",Values={},Scrollable=true,
        Callback=function(name)
            local p=Players:FindFirstChild(name)
            if p and p.Character then
                cam.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid")
            end
        end
    })
    combatTab:Button({Title="Refresh Spectate List",Callback=function()
        local list={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=plr then table.insert(list,p.Name) end
        end
        specDD:Refresh(list)
    end})
    combatTab:Button({Title="Stop Spectating",Callback=function()
        cam.CameraSubject = char:FindFirstChildOfClass("Humanoid")
    end})

    -- Auto kill nearest
    combatTab:Toggle({Title="Auto kill nearest",Value=false,Callback=function(v)
        if connN then connN:Disconnect() end
        if v then
            notify("Combat","Auto nearest ON")
            connN = RunService.Heartbeat:Connect(function()
                local cd,cp=math.huge,nil
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d=(p.Character.HumanoidRootPart.Position-hrp.Position).Magnitude
                        if d<cd then cd,cp=d,p end
                    end
                end
                if cp then hrp.CFrame=cp.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,1.5) end
            end)
        else notify("Combat","Auto nearest OFF") end
    end})

    -- Auto kill selected
    combatTab:Toggle({Title="Auto kill selected",Value=false,Callback=function(v)
        if connS then connS:Disconnect() end
        if v and target then
            notify("Combat","Auto "..target.." ON")
            connS = RunService.Heartbeat:Connect(function()
                local p=Players:FindFirstChild(target)
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = p.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,1.5)
                end
            end)
        else notify("Combat","Auto selected OFF") end
    end})

    -- Select target dropdown
    combatTab:Dropdown({Title="Select Target",Values={},Scrollable=true,Callback=function(v) target=v end})
    combatTab:Button({Title="Refresh Targets",Callback=function()
        local t={}
        for _,p in ipairs(Players:GetPlayers()) do if p~=plr then table.insert(t,p.Name) end end
        combatTab:GetChildren()[#combatTab:GetChildren()].Values=t
    end})

    -- Mod MP5 Bullets
    local mp5=combatTab:Input({Title="Mod MP5 Bullets",Placeholder="Enter value",Callback=function(v)
        local n=tonumber(v)
        if n then _G.DesiredBullets=n; notify("MP5","Force "..n) end
    end})
    MyConfig:Register("modMP5Bullets",mp5)

    -- Infinite Stamina
    combatTab:Toggle({Title="Infinite Stamina",Value=false,Callback=function(v)_G.InfStam=v end})
    MyConfig:Register("combatInfStam",combatTab)

    RunService.Heartbeat:Connect(function()
        if _G.InfStam then
            local l=Workspace.Live:FindFirstChild(plr.Name)
            if l and l:FindFirstChild("StaminaVal") then l.StaminaVal.Value=100 end
        end
        if _G.DesiredBullets then
            local l=Workspace.Live:FindFirstChild(plr.Name)
            if l then local m=l:FindFirstChild("InfoMP5Client") if m and m:FindFirstChild("Bullets") then m.Bullets.Value=_G.DesiredBullets end end
        end
    end)
end

-- Powers Tab
do
    local pwTab = PlayerSec:Tab({Title="Powers",Icon="bolt"})
    pwTab:Paragraph({Title="Note",Desc="Some powers might not work"})
    local powers={"MEDIC","TRICKSTER","SUPER STRENGTH","BLACKFLASH","PHANTOM STEP","WEAPON SMUGGLER","SHARP SHOOTER","QUICKSLIVER","LIGHTNING GOD"}
    local pwDD=pwTab:Dropdown({Title="Equip Power",Values=powers,Scrollable=true,Callback=function(v)
        plr:SetAttribute("_EquippedPower",v); notify("Power","Equipped "..v)
    end})
    MyConfig:Register("equippedPower",pwDD)
end

-- Settings Section
local Settings = Window:Section({Title="Settings",Icon="settings",Opened=true})

-- Config Tab
do
    local cfgTab = Settings:Tab({Title="Config",Icon="save"})
    cfgTab:Button({Title="Save Config",Callback=function() MyConfig:Save(); notify("Config","Saved") end})
    cfgTab:Button({Title="Load Config",Callback=function() MyConfig:Load(); notify("Config","Loaded") end})
end

-- Theme Tab
do
    local themeTab = Settings:Tab({Title="Theme",Icon="palette"})
    local themes={}
    for name,_ in pairs(WindUI:GetThemes()) do table.insert(themes,name) end
    local td=themeTab:Dropdown({Title="Select Theme",Values=themes,Scrollable=true,Multi=false,AllowNone=false,Callback=function(t) WindUI:SetTheme(t) end})
    td:Select(WindUI:GetCurrentTheme())
    local tt=themeTab:Toggle({Title="Toggle Window Transparency",Value=WindUI:GetTransparency(),Callback=function(v) Window:ToggleTransparency(v) end})
    MyConfig:Register("transparency",tt)
end

-- Auto-load config
MyConfig:Load()
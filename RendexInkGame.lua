-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:SetTheme("Dark")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

-- Version fetch
local version = "Unknown"
pcall(function()
	local v = game:HttpGet("https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/refs/heads/main/RendexInkGame.Version")
	if v and #v > 0 then version = v:match("(%S+)") end
end)

local changelogText = [[
• Stronger WalkFling  
• Emote dropdown with Play Emote button  
• Boost sliders, Infinite Jump, NoClip, Anti-Fling  
• Glass Vision, Auto Tug, Skip Cutscene, Kill Aura
]]

-- UI Setup
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

-- Config system
local myConfig = Window.ConfigManager:CreateConfig("RendexInkGame")
local function notify(title, content, icon)
	WindUI:Notify({ Title = title, Content = content, Icon = icon or "zap", Duration = 3 })
end

-- ============ HOME ============
HomeTab:Paragraph({
	Title = "Rendex Ink Game • Version " .. version,
	Desc = changelogText,
})

-- ============ MAIN ============
do
	local t = MainTab

	-- Teleport buttons
	for _, v in ipairs({
		{"Safe Position", "shield-check", CFrame.new(197,123,-92)},
		{"Piggy Bank", "piggy-bank", CFrame.new(200,90,-94)},
		{"End of Glass Bridge", "flag", CFrame.new(-209,521,-1533)},
		{"RLG End", "map-pin", CFrame.new(-45,1024,105)},
	}) do
		t:Button({
			Title = "Teleport to " .. v[1],
			Icon = v[2],
			Callback = function()
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = v[3] end
			end,
		})
	end

	-- Auto Tug of War
	do
		local conn
		local tg = t:Toggle({
			Title = "Auto Tug of War",
			Icon = "shuffle",
			Value = false,
			Callback = function(on)
				if conn then conn:Disconnect() end
				if on then
					conn = RunService.Heartbeat:Connect(function()
						for i = 1, 100 do
							ReplicatedStorage.Remotes.TemporaryReachedBindable:FireServer({{QTEGood=true}})
						end
					end)
				end
			end,
		})
		myConfig:Register("autoTug", tg)
	end

	-- Auto Skip
	do
		local sk = t:Toggle({
			Title = "Auto Skip Cutscenes",
			Icon = "skip-forward",
			Value = false,
			Callback = function(v) _G.AutoSkip = v end,
		})
		myConfig:Register("autoSkip", sk)
		RunService.RenderStepped:Connect(function()
			if _G.AutoSkip then
				ReplicatedStorage.Remotes.DialogueRemote:FireServer("Skipped")
			end
		end)
	end

	-- Glass Vision
	t:Button({
		Title = "Glass Vision",
		Icon = "eye",
		Callback = function()
			local count = 0
			local holder = workspace:FindFirstChild("GlassBridge")
				and workspace.GlassBridge:FindFirstChild("GlassHolder")
			if holder then
				for _, pnl in ipairs(holder:GetChildren()) do
					if pnl.Name:match("Cloned?Panel%d+") then
						for _, mName in ipairs({"glassmodel1", "glassmodel2"}) do
							local m = pnl:FindFirstChild(mName)
							if m then
								for _, part in ipairs(m:GetDescendants()) do
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
			notify("Glass Vision", "Tinted " .. count .. " parts")
		end,
	})
end

-- ============ PLAYER ============
do
	local t = PlayerTab

	-- Boosts
	for _, name in ipairs({"Damage Boost","Faster Sprint","Won Boost"}) do
		local def = (plr:FindFirstChild("Boosts") and plr.Boosts:FindFirstChild(name) or {Value=0}).Value
		local s = t:Slider({
			Title = name,
			Value = {Min=0, Max=100, Default=def},
			Callback = function(v)
				local b = plr:FindFirstChild("Boosts") and plr.Boosts:FindFirstChild(name)
				if b then b.Value = v end
			end,
		})
		myConfig:Register("boost_" .. name:gsub(" ",""), s)
	end

	-- Infinite Jump
	do
		local ij = t:Toggle({
			Title = "Infinite Jump",
			Icon = "arrow-up-right",
			Value = false,
			Callback = function(v) _G.InfJump = v end,
		})
		myConfig:Register("infJump", ij)
		UserInputService.JumpRequest:Connect(function()
			if _G.InfJump and plr.Character then
				plr.Character:FindFirstChildOfClass("Humanoid")
				   :ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end

	-- NoClip
	do
		local nc = t:Toggle({
			Title = "NoClip",
			Icon = "slash",
			Value = false,
			Callback = function(v) _G.NoClip = v end,
		})
		myConfig:Register("noClip", nc)
		RunService.Stepped:Connect(function()
			if _G.NoClip and plr.Character then
				for _, p in ipairs(plr.Character:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end

	-- Anti-Fling
	do
		local af = t:Toggle({
			Title = "Anti Fling",
			Icon = "shield-off",
			Value = false,
			Callback = function(v) _G.AntiFling = v end,
		})
		myConfig:Register("antiFling", af)
		RunService.Stepped:Connect(function()
			if _G.AntiFling then
				for _, o in ipairs(Players:GetPlayers()) do
					if o ~= plr and o.Character then
						for _, p in ipairs(o.Character:GetDescendants()) do
							if p:IsA("BasePart") then p.CanCollide = false end
						end
					end
				end
			end
		end)
	end

	-- WalkFling (very strong)
	do
		local conn
		local function startWF()
			if conn then conn:Disconnect() end
			conn = RunService.Heartbeat:Connect(function()
				local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local v = root.Velocity
					root.Velocity = v * 999999 + Vector3.new(0, 999999, 0)
					RunService.RenderStepped:Wait()
					root.Velocity = v
				end
			end)
		end
		local function stopWF()
			if conn then conn:Disconnect(); conn = nil end
		end
		local wf = t:Toggle({
			Title = "WalkFling",
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

	-- Emote Play Dropdown
	do
		local selected = "RAT SPOTTED"
		local d = t:Dropdown({
			Title = "Emote",
			Values = {"RAT SPOTTED", "Laugh"},
			Value = selected,
			Multi = false,
			Callback = function(v)
				selected = v
			end,
		})
		myConfig:Register("selectedEmote", d)

		t:Button({
			Title = "Play Emote",
			Icon = "play",
			Callback = function()
				local ev = ReplicatedStorage:FindFirstChild("Replication")
				       and ReplicatedStorage.Replication:FindFirstChild("Event")
				if ev then
					ev:FireServer({ event = "playEmote", emoteName = selected })
				else
					notify("Error", "Emote Remote not found", "x")
				end
			end,
		})
	end
end

-- ============ SETTINGS ============
do
	local t = SettingsTab
	local am = t:Dropdown({
		Title = "Anti-Mod Action",
		Values = {"Off", "Warn", "Kick"},
		Value = "Off",
		Multi = false,
		Callback = function(v) _G.AntiModAction = v end,
	})
	myConfig:Register("antiModAction", am)

	t:Button({Title = "Save Config",   Icon = "save",      Callback = function()
		local ok, err = pcall(myConfig.Save, myConfig)
		notify("Config", ok and "Saved" or err)
	end})
	t:Button({Title = "Load Config",   Icon = "download",  Callback = function()
		local ok, err = pcall(myConfig.Load, myConfig)
		notify("Config", ok and "Loaded" or err)
	end})
	t:Button({Title = "Reset Config",  Icon = "refresh-ccw", Callback = function()
		local ok, err = pcall(myConfig.Reset, myConfig)
		notify("Config", ok and "Reset" or err)
	end})
end

-- Load saved config
pcall(function() myConfig:Load() end)
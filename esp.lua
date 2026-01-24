if not game:IsLoaded() then game.Loaded:Wait() end
getgenv().test = 35
local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local MainESP = {
	Container = {},
	TracerOrigins = {
		Top = Vector2.new(Camera.ViewportSize.X / 2, 0),
		Middle = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2),
		Bottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y),
	},
	Options = {
		Enabled = false,
		Box = false,
		Health = false,
		Tracer = false,
		TracerOrigin = "Bottom",
		Name = false,
		Distance = false,
		Direction = false,
		Skeleton = false,
		TextOutline = false,
		Color = Color3.new(1, 1, 1),
		UseTeamColor = true,
		Rainbow = false,
		Font = 1,
		FontSize = 20,
		TeamCheck = false,
		BoxThickness = 0,
		TracerThickness = 0,
		DirectionThickness = 0,
		SkeletonThickness = 0,
		Bounties = false,
	},
	ObjectOptions = {
		Enabled = false,
		Tracer = false,
		TextOutline = false,
		Distance = false,
		Name = false,
		Font = 1,
		FontSize = 20,
		Rainbow = false,
		Color = Color3.fromRGB(255, 255, 0),
		TracerOrigin = "Bottom",
		TracerThickness = 0,
	},
	_colorCache = {},
	_positionCache = {},
}

function MainESP.CreateBox()
	local box = Drawing.new("Square")
	box.Thickness = 1
	box.Filled = false
	box.Visible = false
	box.ZIndex = 1
	return box
end

function MainESP.CreateLine()
	local line = Drawing.new("Line")
	line.Thickness = 1
	line.Visible = false
	line.ZIndex = 1
	return line
end

function MainESP.CreateText()
	local text = Drawing.new("Text")
	text.Center = true
	text.Outline = false
	text.Font = Drawing.Fonts.UI
	text.Size = 16
	text.Visible = false
	text.ZIndex = 2
	return text
end

function MainESP.WTVP(pos)
	return Camera:WorldToViewportPoint(pos)
end

function MainESP.GetHealth(player)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local h = player.Character.Humanoid
		return h.Health, h.MaxHealth
	end
	return 0, 100
end

function MainESP:PlayerAlive(player)
	local health = self.GetHealth(player)
	return health > 0 and player.Character:FindFirstChild("HumanoidRootPart")
end

function MainESP.GetDistanceFromPlayer(player, pos)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		return (player.Character.HumanoidRootPart.Position - pos).Magnitude
	end
	return math.huge
end

function MainESP:GetColor(player, useTeamColor, rainbow, defaultColor)
	local t = tick()
	local key = player and tostring(player.UserId) or "default"
	if useTeamColor and player and player.Team then
		return player.Team.TeamColor.Color
	elseif rainbow then
		if not self._colorCache[key] or t - (self._colorCache[key].time or 0) > 0.033 then
			self._colorCache[key] = { color = Color3.fromHSV(t * 35 % 1, 1, 1), time = t }
		end
		return self._colorCache[key].color
	else
		return defaultColor
	end
end

local CullingSystem = {
	maxRenderDistance = 2000,
	nearDistance = 500,
	farDistance = 1000,
}

function CullingSystem:ShouldRenderPlayer(player)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
	local dist = MainESP.GetDistanceFromPlayer(player, (MainESP:PlayerAlive(LocalPlayer) and LocalPlayer.Character.HumanoidRootPart.Position) or Camera.CFrame.Position)
	return dist <= self.maxRenderDistance, dist
end

function CullingSystem:GetDetailLevel(dist)
	if dist <= self.nearDistance then return "full"
	elseif dist <= self.farDistance then return "medium"
	else return "minimal" end
end

local CacheManager = { maxCacheAge = 30, cleanupInterval = 10, lastCleanup = 0 }

function CacheManager:CleanupCaches()
	local now = tick()
	if now - self.lastCleanup < self.cleanupInterval then return end
	for k in pairs(MainESP._positionCache) do
		if now - MainESP._positionCache[k].time > self.maxCacheAge then
			MainESP._positionCache[k] = nil
		end
	end
	for k in pairs(MainESP._colorCache) do
		if MainESP._colorCache[k].time and now - MainESP._colorCache[k].time > self.maxCacheAge then
			MainESP._colorCache[k] = nil
		end
	end
	self.lastCleanup = now
end

function MainESP:GetCachedPosition(part, partName, player, forceUpdate)
	local t = tick()
	local key = (player and tostring(player.UserId) or "unknown") .. "_" .. tostring(part) .. "_" .. partName
	if not forceUpdate and MainESP._positionCache[key] and t - MainESP._positionCache[key].time < 0.016 then
		return MainESP._positionCache[key].pos, MainESP._positionCache[key].onScreen
	end
	local pos, onScreen = self.WTVP(part.Position)
	MainESP._positionCache[key] = { pos = pos, onScreen = onScreen, time = t }
	return pos, onScreen
end

function MainESP:CreateSkeleton()
	return {
		HeadToNeck = self.CreateLine(),
		NeckToRightUpperArm = self.CreateLine(),
		NeckToLeftUpperArm = self.CreateLine(),
		RightUpperArmToRightLowerArm = self.CreateLine(),
		LeftUpperArmToLeftLowerArm = self.CreateLine(),
		RightLowerArmToRightHand = self.CreateLine(),
		LeftLowerArmToLeftHand = self.CreateLine(),
		NeckToLowerTorso = self.CreateLine(),
		LowerTorsoToRightUpperLeg = self.CreateLine(),
		LowerTorsoToLeftUpperLeg = self.CreateLine(),
		RightUpperLegToRightLowerLeg = self.CreateLine(),
		LeftUpperLegToLeftLowerLeg = self.CreateLine(),
		RightLowerLegToRightFoot = self.CreateLine(),
		LeftLowerLegToLeftFoot = self.CreateLine(),
	}
end

function MainESP:UpdateSkeleton(playerESP, player, onScreen)
	if not self.Options.Skeleton or not onScreen or not player.Character then
		for _, line in pairs(playerESP.Skeleton) do if line.Visible ~= nil then line.Visible = false end end
		return
	end
	local char = player.Character
	local head = char:FindFirstChild("Head")
	if not head then
		for _, line in pairs(playerESP.Skeleton) do if line.Visible ~= nil then line.Visible = false end end
		return
	end
	local color = self:GetColor(player, self.Options.UseTeamColor, self.Options.Rainbow, self.Options.Color)
	local headPos = self:GetCachedPosition(head, "Head", player)
	if char:FindFirstChild("UpperTorso") then
		local UT = char.UpperTorso
		local LT = char.LowerTorso
		local RUA = char.RightUpperArm
		local RLA = char.RightLowerArm
		local LUA = char.LeftUpperArm
		local LLA = char.LeftLowerArm
		local RUL = char.RightUpperLeg
		local RLL = char.RightLowerLeg
		local RF = char.RightFoot
		local LUL = char.LeftUpperLeg
		local LLL = char.LeftLowerLeg
		local LF = char.LeftFoot
		if UT and LT and RUA and RLA and LUA and LLA and RUL and RLL and RF and LUL and LLL and LF then
			local UTp = self:GetCachedPosition(UT, "UpperTorso", player)
			local LTp = self:GetCachedPosition(LT, "LowerTorso", player)
			local RUAp = self:GetCachedPosition(RUA, "RightUpperArm", player)
			local RLA_p = self:GetCachedPosition(RLA, "RightLowerArm", player)
			local LUAp = self:GetCachedPosition(LUA, "LeftUpperArm", player)
			local LLA_p = self:GetCachedPosition(LLA, "LeftLowerArm", player)
			local RULp = self:GetCachedPosition(RUL, "RightUpperLeg", player)
			local RLLp = self:GetCachedPosition(RLL, "RightLowerLeg", player)
			local RFp = self:GetCachedPosition(RF, "RightFoot", player)
			local LULp = self:GetCachedPosition(LUL, "LeftUpperLeg", player)
			local LLLp = self:GetCachedPosition(LLL, "LeftLowerLeg", player)
			local LFp = self:GetCachedPosition(LF, "LeftFoot", player)
			local neck = Vector2.new(UTp.X, (headPos.Y + UTp.Y) / 2)
			playerESP.Skeleton.HeadToNeck.From = Vector2.new(headPos.X, headPos.Y)
			playerESP.Skeleton.HeadToNeck.To = neck
			playerESP.Skeleton.HeadToNeck.Color = color
			playerESP.Skeleton.HeadToNeck.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.HeadToNeck.Visible = true
			playerESP.Skeleton.NeckToRightUpperArm.From = neck
			playerESP.Skeleton.NeckToRightUpperArm.To = Vector2.new(RUAp.X, RUAp.Y)
			playerESP.Skeleton.NeckToRightUpperArm.Color = color
			playerESP.Skeleton.NeckToRightUpperArm.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.NeckToRightUpperArm.Visible = true
			playerESP.Skeleton.NeckToLeftUpperArm.From = neck
			playerESP.Skeleton.NeckToLeftUpperArm.To = Vector2.new(LUAp.X, LUAp.Y)
			playerESP.Skeleton.NeckToLeftUpperArm.Color = color
			playerESP.Skeleton.NeckToLeftUpperArm.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.NeckToLeftUpperArm.Visible = true
			playerESP.Skeleton.RightUpperArmToRightLowerArm.From = Vector2.new(RUAp.X, RUAp.Y)
			playerESP.Skeleton.RightUpperArmToRightLowerArm.To = Vector2.new(RLA_p.X, RLA_p.Y)
			playerESP.Skeleton.RightUpperArmToRightLowerArm.Color = color
			playerESP.Skeleton.RightUpperArmToRightLowerArm.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.RightUpperArmToRightLowerArm.Visible = true
			playerESP.Skeleton.LeftUpperArmToLeftLowerArm.From = Vector2.new(LUAp.X, LUAp.Y)
			playerESP.Skeleton.LeftUpperArmToLeftLowerArm.To = Vector2.new(LLA_p.X, LLA_p.Y)
			playerESP.Skeleton.LeftUpperArmToLeftLowerArm.Color = color
			playerESP.Skeleton.LeftUpperArmToLeftLowerArm.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.LeftUpperArmToLeftLowerArm.Visible = true
			playerESP.Skeleton.NeckToLowerTorso.From = neck
			playerESP.Skeleton.NeckToLowerTorso.To = Vector2.new(LTp.X, LTp.Y)
			playerESP.Skeleton.NeckToLowerTorso.Color = color
			playerESP.Skeleton.NeckToLowerTorso.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.NeckToLowerTorso.Visible = true
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.From = Vector2.new(LTp.X, LTp.Y)
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.To = Vector2.new(RULp.X, RULp.Y)
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.Color = color
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.Visible = true
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.From = Vector2.new(LTp.X, LTp.Y)
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.To = Vector2.new(LULp.X, LULp.Y)
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Color = color
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Visible = true
			playerESP.Skeleton.RightUpperLegToRightLowerLeg.From = Vector2.new(RULp.X, RULp.Y)
			playerESP.Skeleton.RightUpperLegToRightLowerLeg.To = Vector2.new(RLLp.X, RLLp.Y)
			playerESP.Skeleton.RightUpperLegToRightLowerLeg.Color = color
			playerESP.Skeleton.RightUpperLegToRightLowerLeg.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.RightUpperLegToRightLowerLeg.Visible = true
			playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.From = Vector2.new(LULp.X, LULp.Y)
			playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.To = Vector2.new(LLLp.X, LLLp.Y)
			playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.Color = color
			playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.Visible = true
			playerESP.Skeleton.RightLowerLegToRightFoot.From = Vector2.new(RLLp.X, RLLp.Y)
			playerESP.Skeleton.RightLowerLegToRightFoot.To = Vector2.new(RFp.X, RFp.Y)
			playerESP.Skeleton.RightLowerLegToRightFoot.Color = color
			playerESP.Skeleton.RightLowerLegToRightFoot.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.RightLowerLegToRightFoot.Visible = true
			playerESP.Skeleton.LeftLowerLegToLeftFoot.From = Vector2.new(LLLp.X, LLLp.Y)
			playerESP.Skeleton.LeftLowerLegToLeftFoot.To = Vector2.new(LFp.X, LFp.Y)
			playerESP.Skeleton.LeftLowerLegToLeftFoot.Color = color
			playerESP.Skeleton.LeftLowerLegToLeftFoot.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.LeftLowerLegToLeftFoot.Visible = true
			if char:FindFirstChild("RightHand") and char:FindFirstChild("LeftHand") then
				local RHp = self:GetCachedPosition(char.RightHand, "RightHand", player)
				local LHp = self:GetCachedPosition(char.LeftHand, "LeftHand", player)
				playerESP.Skeleton.RightLowerArmToRightHand.From = Vector2.new(RLA_p.X, RLA_p.Y)
				playerESP.Skeleton.RightLowerArmToRightHand.To = Vector2.new(RHp.X, RHp.Y)
				playerESP.Skeleton.RightLowerArmToRightHand.Color = color
				playerESP.Skeleton.RightLowerArmToRightHand.Thickness = self.Options.SkeletonThickness
				playerESP.Skeleton.RightLowerArmToRightHand.Visible = true
				playerESP.Skeleton.LeftLowerArmToLeftHand.From = Vector2.new(LLA_p.X, LLA_p.Y)
				playerESP.Skeleton.LeftLowerArmToLeftHand.To = Vector2.new(LHp.X, LHp.Y)
				playerESP.Skeleton.LeftLowerArmToLeftHand.Color = color
				playerESP.Skeleton.LeftLowerArmToLeftHand.Thickness = self.Options.SkeletonThickness
				playerESP.Skeleton.LeftLowerArmToLeftHand.Visible = true
			else
				playerESP.Skeleton.RightLowerArmToRightHand.Visible = false
				playerESP.Skeleton.LeftLowerArmToLeftHand.Visible = false
			end
		else
			for _, line in pairs(playerESP.Skeleton) do if line.Visible ~= nil then line.Visible = false end end
		end
	else
		local torso = char:FindFirstChild("Torso")
		local RA = char:FindFirstChild("Right Arm")
		local LA = char:FindFirstChild("Left Arm")
		local RL = char:FindFirstChild("Right Leg")
		local LL = char:FindFirstChild("Left Leg")
		if torso and RA and LA and RL and LL then
			local torsoP = self:GetCachedPosition(torso, "Torso", player)
			local RAp = self:GetCachedPosition(RA, "RightArm", player)
			local LAp = self:GetCachedPosition(LA, "LeftArm", player)
			local RLp = self:GetCachedPosition(RL, "RightLeg", player)
			local LLp = self:GetCachedPosition(LL, "LeftLeg", player)
			local neck = Vector2.new(torsoP.X, (headPos.Y + torsoP.Y) / 2)
			playerESP.Skeleton.HeadToNeck.From = Vector2.new(headPos.X, headPos.Y)
			playerESP.Skeleton.HeadToNeck.To = neck
			playerESP.Skeleton.HeadToNeck.Color = color
			playerESP.Skeleton.HeadToNeck.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.HeadToNeck.Visible = true
			playerESP.Skeleton.NeckToRightUpperArm.From = neck
			playerESP.Skeleton.NeckToRightUpperArm.To = Vector2.new(RAp.X, RAp.Y)
			playerESP.Skeleton.NeckToRightUpperArm.Color = color
			playerESP.Skeleton.NeckToRightUpperArm.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.NeckToRightUpperArm.Visible = true
			playerESP.Skeleton.NeckToLeftUpperArm.From = neck
			playerESP.Skeleton.NeckToLeftUpperArm.To = Vector2.new(LAp.X, LAp.Y)
			playerESP.Skeleton.NeckToLeftUpperArm.Color = color
			playerESP.Skeleton.NeckToLeftUpperArm.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.NeckToLeftUpperArm.Visible = true
			playerESP.Skeleton.NeckToLowerTorso.From = neck
			playerESP.Skeleton.NeckToLowerTorso.To = Vector2.new(torsoP.X, torsoP.Y)
			playerESP.Skeleton.NeckToLowerTorso.Color = color
			playerESP.Skeleton.NeckToLowerTorso.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.NeckToLowerTorso.Visible = true
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.From = Vector2.new(torsoP.X, torsoP.Y)
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.To = Vector2.new(RLp.X, RLp.Y)
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.Color = color
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.LowerTorsoToRightUpperLeg.Visible = true
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.From = Vector2.new(torsoP.X, torsoP.Y)
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.To = Vector2.new(LLp.X, LLp.Y)
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Color = color
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Thickness = self.Options.SkeletonThickness
			playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Visible = true
			playerESP.Skeleton.RightUpperArmToRightLowerArm.Visible = false
			playerESP.Skeleton.LeftUpperArmToLeftLowerArm.Visible = false
			playerESP.Skeleton.RightLowerArmToRightHand.Visible = false
			playerESP.Skeleton.LeftLowerArmToLeftHand.Visible = false
			playerESP.Skeleton.RightUpperLegToRightLowerLeg.Visible = false
			playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.Visible = false
			playerESP.Skeleton.RightLowerLegToRightFoot.Visible = false
			playerESP.Skeleton.LeftLowerLegToLeftFoot.Visible = false
		else
			for _, line in pairs(playerESP.Skeleton) do if line.Visible ~= nil then line.Visible = false end end
		end
	end
end

function MainESP:CreateESP(player, obj, customName, customPred)
	if player then
		local esp = {
			IsPlayer = true,
			Box = self.CreateBox(),
			Health = self.CreateBox(),
			Tracer = self.CreateLine(),
			Name = self.CreateText(),
			Distance = self.CreateText(),
			Direction = self.CreateLine(),
			Skeleton = self:CreateSkeleton(),
			Connections = {},
			_BoxDimensions = { width = 0, height = 0, x = 0, y = 0 },
		}
		if game.PlaceId == 606849621 then esp.Bounties = self.CreateText() end
		self.Container[player] = esp
	elseif obj then
		local esp = {
			Info = self.CreateText(),
			Tracer = self.CreateLine(),
			Connections = {},
		}
		self.Container[obj] = esp
		esp.Connections.AncestryConnection = obj.AncestryChanged:Connect(function()
			if not obj:IsDescendantOf(workspace) then self:RemoveESP(obj) end
		end)
		esp.Connections.RenderConnection = RunService.RenderStepped:Connect(function()
			if not obj:IsDescendantOf(workspace) or (customPred and not customPred(obj)) then
				esp.Info.Visible = false
				esp.Tracer.Visible = false
				return
			end
			if self.ObjectOptions.Enabled then
				local rootPos, onScreen = self.WTVP(obj.Position)
				local color = self:GetColor(nil, false, self.ObjectOptions.Rainbow, self.ObjectOptions.Color)
				if self.ObjectOptions.Tracer and rootPos.Z > 0 then
					esp.Tracer.From = self.TracerOrigins[self.ObjectOptions.TracerOrigin]
					esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
					esp.Tracer.Color = color
					esp.Tracer.Thickness = self.ObjectOptions.TracerThickness
					esp.Tracer.Visible = true
				else
					esp.Tracer.Visible = false
				end
				if onScreen and (self.ObjectOptions.Name or self.ObjectOptions.Distance) then
					local name = self.ObjectOptions.Name and (customName or obj.Name) or ""
					local dist = ""
					if self.ObjectOptions.Distance then
						dist = "[" .. tostring(math.round(self.GetDistanceFromPlayer(LocalPlayer, obj.Position))) .. " studs]"
					end
					esp.Info.Text = name .. dist
					esp.Info.Position = Vector2.new(rootPos.X, rootPos.Y)
					esp.Info.Color = color
					esp.Info.Font = self.ObjectOptions.Font
					esp.Info.Size = self.ObjectOptions.FontSize
					esp.Info.Outline = self.ObjectOptions.TextOutline
					esp.Info.OutlineColor = Color3.fromRGB(0, 0, 0)
					esp.Info.Visible = true
				else
					esp.Info.Visible = false
				end
			else
				esp.Info.Visible = false
				esp.Tracer.Visible = false
			end
		end)
	end
end

function MainESP:HidePlayerESP(esp)
	for k, v in pairs(esp) do
		if k == "Skeleton" then
			for _, line in pairs(v) do line.Visible = false end
		elseif k ~= "Connections" and k ~= "IsPlayer" then
			v.Visible = false
		end
	end
end

function MainESP:RemoveESP(val)
	local cont = self.Container[val]
	if not cont then return end
	local name = type(val) == "userdata" and val.Name or tostring(val)
	for k in pairs(self._colorCache) do if k:find(name, 1, true) then self._colorCache[k] = nil end end
	for k in pairs(self._positionCache) do if k:find(name, 1, true) then self._positionCache[k] = nil end end
	if cont.Connections then
		for _, conn in pairs(cont.Connections) do if conn and conn.Connected then conn:Disconnect() end end
		cont.Connections = nil
	end
	for _, el in pairs(cont) do
		pcall(function()
			if type(el) == "table" then
				for _, line in pairs(el) do pcall(function() line:Destroy() end) end
			else
				el:Destroy()
			end
		end)
	end
	self.Container[val] = nil
end

local ESPPerformance = {
	lastUpdate = 0,
	interval = 1/45,
	fpsHistory = {},
	fpsHistorySize = 60,
	fpsSum = 0,
	averageFPS = 60,
	lastOptimize = 0,
	targetFPS = 55,
	minInterval = 1/30,
	maxInterval = 1/120,
	adjustmentRate = 0.1,
	stabilityThreshold = 10,
}

local function updateFPSAverage()
	local fps = math.min(1 / Stats.FrameTime, 200)
	table.insert(ESPPerformance.fpsHistory, fps)
	ESPPerformance.fpsSum = ESPPerformance.fpsSum + fps
	if #ESPPerformance.fpsHistory > ESPPerformance.fpsHistorySize then
		local overflow = #ESPPerformance.fpsHistory - ESPPerformance.fpsHistorySize
		for _ = 1, overflow do
			ESPPerformance.fpsSum = ESPPerformance.fpsSum - table.remove(ESPPerformance.fpsHistory, 1)
		end
	end
	if #ESPPerformance.fpsHistory > 0 then
		ESPPerformance.averageFPS = ESPPerformance.fpsSum / #ESPPerformance.fpsHistory
	end
end

local globalRenderConnection = RunService.RenderStepped:Connect(function()
	local now = tick()
	updateFPSAverage()
	CacheManager:CleanupCaches()
	if now - ESPPerformance.lastOptimize >= 0.5 then
		local avg = ESPPerformance.averageFPS
		if #ESPPerformance.fpsHistory >= math.min(10, ESPPerformance.fpsHistorySize) then
			if avg < ESPPerformance.targetFPS - ESPPerformance.stabilityThreshold then
				ESPPerformance.interval = math.min(ESPPerformance.interval * (1 + ESPPerformance.adjustmentRate), ESPPerformance.minInterval)
			elseif avg > ESPPerformance.targetFPS + ESPPerformance.stabilityThreshold then
				ESPPerformance.interval = math.max(ESPPerformance.interval * (1 - ESPPerformance.adjustmentRate), ESPPerformance.maxInterval)
			end
		end
		ESPPerformance.lastOptimize = now
	end
	if now - ESPPerformance.lastUpdate < ESPPerformance.interval then return end
	ESPPerformance.lastUpdate = now
	for player, playerESP in pairs(MainESP.Container) do
		if playerESP.IsPlayer then
			if not player or not player.Parent then
				MainESP:RemoveESP(player)
				continue
			end
			local shouldRender, dist = CullingSystem:ShouldRenderPlayer(player)
			if not shouldRender then
				MainESP:HidePlayerESP(playerESP)
				continue
			end
			local detail = CullingSystem:GetDetailLevel(dist)
			if MainESP.Options.Enabled and (not MainESP.Options.TeamCheck or not player.Team or LocalPlayer.Team ~= player.Team) and MainESP:PlayerAlive(player) and player.Character then
				local char = player.Character
				local root = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
				local head = char:FindFirstChild("Head")
				if not root or not head then
					MainESP:HidePlayerESP(playerESP)
					continue
				end
				local rootPos, onScreen = MainESP:GetCachedPosition(root, "RootPart", player, true)
				local headPos = MainESP:GetCachedPosition(head, "Head", player)
				local topPos = MainESP.WTVP(root.Position + Vector3.new(0, select(2, char:GetBoundingBox()).Y, 0))
				local bottomPos = MainESP.WTVP(root.Position - Vector3.new(0, select(2, char:GetBoundingBox()).Y, 0))
				local color = MainESP:GetColor(player, MainESP.Options.UseTeamColor, MainESP.Options.Rainbow, MainESP.Options.Color)
				local boxWidth = 3000 / rootPos.Z
				local boxHeight = topPos.Y - bottomPos.Y
				local boxX = rootPos.X - boxWidth / 2
				local boxY = rootPos.Y - boxHeight / 2
				local dims = playerESP._BoxDimensions
				dims.width, dims.height, dims.x, dims.y = boxWidth, boxHeight, boxX, boxY
				local infoX
				if detail == "minimal" then
					if MainESP.Options.Name and onScreen then
						infoX = dims.x + dims.width / 2
						playerESP.Name.Text = player.DisplayName
						if MainESP.Options.Distance and onScreen then
							playerESP.Name.Text = playerESP.Name.Text .. "\n[" .. tostring(math.round(dist)) .. " studs]"
						end
						playerESP.Name.Position = Vector2.new(infoX, topPos.Y - 25)
						playerESP.Name.Color = color
						playerESP.Name.Font = MainESP.Options.Font
						playerESP.Name.Size = MainESP.Options.FontSize
						playerESP.Name.Outline = MainESP.Options.TextOutline
						playerESP.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
						playerESP.Name.Visible = true
					else
						playerESP.Name.Visible = false
					end
					playerESP.Box.Visible = false
					playerESP.Health.Visible = false
					playerESP.Distance.Visible = false
					playerESP.Direction.Visible = false
					playerESP.Tracer.Visible = false
					for _, line in pairs(playerESP.Skeleton) do line.Visible = false end
				else
					if MainESP.Options.Box and onScreen then
						playerESP.Box.Size = Vector2.new(boxWidth, boxHeight)
						playerESP.Box.Position = Vector2.new(boxX, boxY)
						playerESP.Box.Color = color
						playerESP.Box.Thickness = MainESP.Options.BoxThickness
						playerESP.Box.Visible = true
					else
						playerESP.Box.Visible = false
					end
					if MainESP.Options.Health and onScreen and playerESP.Box.Visible and detail == "full" then
						local health, max = MainESP.GetHealth(player)
						local perc = health / max
						local w = dims.width * 0.15
						local h = dims.height * perc
						local ox = dims.width * 0.150
						playerESP.Health.Size = Vector2.new(w, h)
						playerESP.Health.Position = Vector2.new(dims.x - ox, dims.y)
						playerESP.Health.Color = Color3.fromHSV(perc * 0.3, 1, 1)
						playerESP.Health.Filled = true
						playerESP.Health.Visible = true
					else
						playerESP.Health.Visible = false
					end
					if MainESP.Options.Tracer and rootPos.Z > 0 and detail == "full" then
						local UT = char:FindFirstChild("UpperTorso")
						local neck = UT and Vector2.new(MainESP:GetCachedPosition(UT, "UpperTorso", player).X, (headPos.Y + MainESP:GetCachedPosition(UT, "UpperTorso", player).Y) / 2) or Vector2.new(rootPos.X, (headPos.Y + rootPos.Y) / 2)
						playerESP.Tracer.From = MainESP.TracerOrigins[MainESP.Options.TracerOrigin]
						playerESP.Tracer.To = Vector2.new(neck.X, neck.Y)
						playerESP.Tracer.Color = color
						playerESP.Tracer.Thickness = MainESP.Options.TracerThickness
						playerESP.Tracer.Visible = true
					else
						playerESP.Tracer.Visible = false
					end
					if MainESP.Options.Name and onScreen then
						infoX = dims.x + dims.width / 2
						playerESP.Name.Text = player.DisplayName
						playerESP.Name.Position = Vector2.new(infoX, topPos.Y - 25)
						playerESP.Name.Color = color
						playerESP.Name.Font = MainESP.Options.Font
						playerESP.Name.Size = MainESP.Options.FontSize
						playerESP.Name.Outline = MainESP.Options.TextOutline
						playerESP.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
						playerESP.Name.Visible = true
					else
						playerESP.Name.Visible = false
					end
					if MainESP.Options.Bounties and onScreen and game.PlaceId == 606849621 then
						local getDisplayName = function(name)
							for _, p in pairs(Players:GetPlayers()) do
								if p.DisplayName == name then return p.Name end
							end
							return nil
						end
						local formatBounty = function(displayname)
							local username = getDisplayName(displayname)
							if username then
								local module = require(game.ReplicatedStorage.Bounty.BountyBoardService)
								for _, bounty in pairs(module.Bounties) do
									if bounty.Name == username then
										return "Bounty: " .. tostring(bounty.Bounty)
									end
								end
							end
							return ""
						end
						infoX = dims.x + dims.width / 2
						playerESP.Bounties.Text = formatBounty(player.DisplayName)
						playerESP.Bounties.Position = Vector2.new(infoX, topPos.Y - getgenv().test)
						playerESP.Bounties.Color = Color3.fromRGB(255, 255, 0)
						playerESP.Bounties.Font = MainESP.Options.Font
						playerESP.Bounties.Size = MainESP.Options.FontSize
						playerESP.Bounties.Outline = MainESP.Options.TextOutline
						playerESP.Bounties.OutlineColor = Color3.fromRGB(0, 0, 0)
						playerESP.Bounties.Visible = true
					else
						playerESP.Bounties.Visible = false
					end
					if MainESP.Options.Distance and onScreen then
						infoX = dims.x + dims.width / 2
						playerESP.Distance.Text = "[" .. tostring(math.round(dist)) .. " studs]"
						playerESP.Distance.Position = Vector2.new(infoX, dims.y - dims.height * 0.1)
						playerESP.Distance.Color = color
						playerESP.Distance.Font = MainESP.Options.Font
						playerESP.Distance.Size = MainESP.Options.FontSize
						playerESP.Distance.Outline = MainESP.Options.TextOutline
						playerESP.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
						playerESP.Distance.Visible = true
					else
						playerESP.Distance.Visible = false
					end
					if MainESP.Options.Direction and onScreen and detail == "full" then
						local offset = MainESP.WTVP((head.CFrame * CFrame.new(0, 0, -head.Size.Z)).Position)
						playerESP.Direction.From = Vector2.new(headPos.X, headPos.Y)
						playerESP.Direction.To = Vector2.new(offset.X, offset.Y)
						playerESP.Direction.Color = color
						playerESP.Direction.Thickness = MainESP.Options.DirectionThickness
						playerESP.Direction.Visible = true
					else
						playerESP.Direction.Visible = false
					end
					MainESP:UpdateSkeleton(playerESP, player, onScreen and detail == "full")
				end
			else
				MainESP:HidePlayerESP(playerESP)
			end
		end
	end
end)

local CompatibilityFuncs = {
	[292439477] = function()
		for _, v in pairs(getgc(true)) do
			if type(v) == "function" and islclosure(v) then
				local c = getconstants(v)
				if getinfo(v).name == "gethealth" and table.find(c, "alive") then
					MainESP.GetHealth = v
				end
			elseif type(v) == "table" and rawget(v, "getbodyparts") then
				getgenv().PF_Replication = v
			end
		end
		RunService.Stepped:Connect(function()
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					local body = getgenv().PF_Replication.getbodyparts(p)
					if body and rawget(body, "rootpart") then
						p.Character = body.rootpart.Parent
					else
						p.Character = nil
					end
				end
			end
		end)
	end,
	[286090429] = function()
		MainESP.GetHealth = function(p)
			return p.NRPBS.Health.Value, 100
		end
	end,
	[142823291] = function()
		local m = Instance.new("Team")
		m.Name = "Murderer"
		m.TeamColor = BrickColor.new("Bright red")
		m.Parent = game.Teams
		local s = Instance.new("Team")
		s.Name = "Sheriff"
		s.TeamColor = BrickColor.new("Bright blue")
		s.Parent = game.Teams
		local i = Instance.new("Team")
		i.Name = "Innocent"
		i.TeamColor = BrickColor.new("Bright green")
		i.Parent = game.Teams
		task.spawn(function()
			while true do
				local success, data = pcall(function()
					return game.ReplicatedStorage.GetPlayerData:InvokeServer()
				end)
				if success and data then
					for _, p in pairs(Players:GetPlayers()) do
						if data[p.Name] and data[p.Name].Role then
							p.Team = game.Teams[data[p.Name].Role]
						else
							p.Team = i
						end
					end
				end
				task.wait(1)
			end
		end)
	end,
}

if CompatibilityFuncs[game.PlaceId] then
	CompatibilityFuncs[game.PlaceId]()
end

Players.PlayerAdded:Connect(function(p)
	MainESP:CreateESP(p)
end)

Players.PlayerRemoving:Connect(function(p)
	MainESP:RemoveESP(p)
end)

for _, p in pairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then
		MainESP:CreateESP(p)
	end
end

return MainESP, CullingSystem

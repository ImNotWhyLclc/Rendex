if not game:IsLoaded() or not game.Loaded then game.Loaded:Wait() end
getgenv().test = 35

local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local Services = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
	Stats = game:GetService("Stats"),
}

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

function MainESP.CreateCircle()
    local circle = Drawing.new("Circle")
    circle.Filled = false
    circle.NumSides = 12
    circle.Radius = 4
    circle.Thickness = 1
    circle.Visible = false
    circle.ZIndex = 1
    return circle
end

function MainESP.WTVP(position)
    return Camera:WorldToViewportPoint(position)
end

function MainESP.GetHealth(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        return humanoid.Health, humanoid.MaxHealth
    end
    return 0, 100
end

function MainESP:PlayerAlive(player)
    local health = self.GetHealth(player)
    return health > 0 and player.Character:FindFirstChild("HumanoidRootPart")
end

function MainESP.GetDistanceFromPlayer(player, position)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return (player.Character.HumanoidRootPart.Position - position).Magnitude
    end
    return math.huge
end

function MainESP:GetColor(player, useTeamColor, rainbow, defaultColor)
    local currentTime = tick()
    local cacheKey = player and tostring(player.UserId) or "default"
    
    if useTeamColor and player and player.Team then
        return player.Team.TeamColor.Color
    elseif rainbow then
        if not self._colorCache[cacheKey] or currentTime - (self._colorCache[cacheKey].time or 0) > 0.033 then
            self._colorCache[cacheKey] = {
                color = Color3.fromHSV(currentTime * 35 % 255/255, 1, 1),
                time = currentTime
            }
        end
        return self._colorCache[cacheKey].color
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
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end

	local distance = MainESP.GetDistanceFromPlayer(player, 
		MainESP:PlayerAlive(LocalPlayer) and LocalPlayer.Character.HumanoidRootPart.Position or Camera.CFrame.Position)
    
    if distance > self.maxRenderDistance then
        return false
    end
    
    return true, distance
end

function CullingSystem:GetDetailLevel(distance)
    if distance <= self.nearDistance then
        return "full"
    elseif distance <= self.farDistance then
        return "medium"
    else
        return "minimal"
    end
end

local CacheManager = {
    maxCacheAge = 30,
    cleanupInterval = 10,
    lastCleanup = 0,
}

function CacheManager:CleanupCaches()
    local now = tick()
    if now - self.lastCleanup < self.cleanupInterval then
        return
    end
    
    local positionKeysToRemove = {}
    for key, data in pairs(MainESP._positionCache) do
        if now - data.time > self.maxCacheAge then
            table.insert(positionKeysToRemove, key)
        end
    end
    
    for _, key in pairs(positionKeysToRemove) do
        MainESP._positionCache[key] = nil
    end
    
    local colorKeysToRemove = {}
    for key, data in pairs(MainESP._colorCache) do
        if data.time and now - data.time > self.maxCacheAge then
            table.insert(colorKeysToRemove, key)
        end
    end
    
    for _, key in pairs(colorKeysToRemove) do
        MainESP._colorCache[key] = nil
    end
    
    self.lastCleanup = now
end

function MainESP:GetCachedPosition(part, partName, player, forceUpdate)
    local currentTime = tick()
    local playerKey = player and tostring(player.UserId) or "unknown"
    local cacheKey = playerKey .. "_" .. tostring(part) .. "_" .. partName
    
    if not forceUpdate and self._positionCache[cacheKey] and 
       currentTime - self._positionCache[cacheKey].time < 0.016 then
        return self._positionCache[cacheKey].pos, self._positionCache[cacheKey].onScreen
    end
    
    local pos, onScreen = self.WTVP(part.Position)
    self._positionCache[cacheKey] = {
        pos = pos,
        onScreen = onScreen,
        time = currentTime
    }
    
    return pos, onScreen
end

function MainESP:CreateSkeleton()
    local skeleton = {
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
    return skeleton
end

function MainESP:UpdateSkeleton(playerESP, player, onScreen)
    if not self.Options.Skeleton or not onScreen or not player.Character then
        for _, line in pairs(playerESP.Skeleton) do
            if line and line.Visible ~= nil then
                line.Visible = false
            end
        end
        return
    end
    
    local character = player.Character
    local head = character:FindFirstChild("Head")
    if not head then
        for _, line in pairs(playerESP.Skeleton) do
            if line and line.Visible ~= nil then
                line.Visible = false
            end
        end
        return
    end
    
    local color = self:GetColor(player, self.Options.UseTeamColor, self.Options.Rainbow, self.Options.Color)
    local headPos = MainESP:GetCachedPosition(head, "Head", player)
    
    if character:FindFirstChild("UpperTorso") then
        local upperTorso = character:FindFirstChild("UpperTorso")
        local lowerTorso = character:FindFirstChild("LowerTorso")
        local rightUpperArm = character:FindFirstChild("RightUpperArm")
        local rightLowerArm = character:FindFirstChild("RightLowerArm")
        local leftUpperArm = character:FindFirstChild("LeftUpperArm")
        local leftLowerArm = character:FindFirstChild("LeftLowerArm")
        local rightUpperLeg = character:FindFirstChild("RightUpperLeg")
        local rightLowerLeg = character:FindFirstChild("RightLowerLeg")
        local rightFoot = character:FindFirstChild("RightFoot")
        local leftUpperLeg = character:FindFirstChild("LeftUpperLeg")
        local leftLowerLeg = character:FindFirstChild("LeftLowerLeg")
        local leftFoot = character:FindFirstChild("LeftFoot")
        
        if upperTorso and lowerTorso and rightUpperArm and rightLowerArm and 
           leftUpperArm and leftLowerArm and rightUpperLeg and rightLowerLeg and 
           rightFoot and leftUpperLeg and leftLowerLeg and leftFoot then
            
            local upperTorsoPos = MainESP:GetCachedPosition(upperTorso, "UpperTorso", player)
            local lowerTorsoPos = MainESP:GetCachedPosition(lowerTorso, "LowerTorso", player)
            local rightUpperArmPos = MainESP:GetCachedPosition(rightUpperArm, "RightUpperArm", player)
            local rightLowerArmPos = MainESP:GetCachedPosition(rightLowerArm, "RightLowerArm", player)
            local leftUpperArmPos = MainESP:GetCachedPosition(leftUpperArm, "LeftUpperArm", player)
            local leftLowerArmPos = MainESP:GetCachedPosition(leftLowerArm, "LeftLowerArm", player)
            local rightUpperLegPos = MainESP:GetCachedPosition(rightUpperLeg, "RightUpperLeg", player)
            local rightLowerLegPos = MainESP:GetCachedPosition(rightLowerLeg, "RightLowerLeg", player)
            local rightFootPos = MainESP:GetCachedPosition(rightFoot, "RightFoot", player)
            local leftUpperLegPos = MainESP:GetCachedPosition(leftUpperLeg, "LeftUpperLeg", player)
            local leftLowerLegPos = MainESP:GetCachedPosition(leftLowerLeg, "LeftLowerLeg", player)
            local leftFootPos = MainESP:GetCachedPosition(leftFoot, "LeftFoot", player)
            
            local neckPos = Vector2.new(upperTorsoPos.X, (headPos.Y + upperTorsoPos.Y) / 2)
            
            playerESP.Skeleton.HeadToNeck.From = Vector2.new(headPos.X, headPos.Y)
            playerESP.Skeleton.HeadToNeck.To = neckPos
            playerESP.Skeleton.HeadToNeck.Color = color
            playerESP.Skeleton.HeadToNeck.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.HeadToNeck.Visible = true
            
            playerESP.Skeleton.NeckToRightUpperArm.From = neckPos
            playerESP.Skeleton.NeckToRightUpperArm.To = Vector2.new(rightUpperArmPos.X, rightUpperArmPos.Y)
            playerESP.Skeleton.NeckToRightUpperArm.Color = color
            playerESP.Skeleton.NeckToRightUpperArm.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.NeckToRightUpperArm.Visible = true
            
            playerESP.Skeleton.NeckToLeftUpperArm.From = neckPos
            playerESP.Skeleton.NeckToLeftUpperArm.To = Vector2.new(leftUpperArmPos.X, leftUpperArmPos.Y)
            playerESP.Skeleton.NeckToLeftUpperArm.Color = color
            playerESP.Skeleton.NeckToLeftUpperArm.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.NeckToLeftUpperArm.Visible = true
            
            playerESP.Skeleton.RightUpperArmToRightLowerArm.From = Vector2.new(rightUpperArmPos.X, rightUpperArmPos.Y)
            playerESP.Skeleton.RightUpperArmToRightLowerArm.To = Vector2.new(rightLowerArmPos.X, rightLowerArmPos.Y)
            playerESP.Skeleton.RightUpperArmToRightLowerArm.Color = color
            playerESP.Skeleton.RightUpperArmToRightLowerArm.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.RightUpperArmToRightLowerArm.Visible = true
            
            playerESP.Skeleton.LeftUpperArmToLeftLowerArm.From = Vector2.new(leftUpperArmPos.X, leftUpperArmPos.Y)
            playerESP.Skeleton.LeftUpperArmToLeftLowerArm.To = Vector2.new(leftLowerArmPos.X, leftLowerArmPos.Y)
            playerESP.Skeleton.LeftUpperArmToLeftLowerArm.Color = color
            playerESP.Skeleton.LeftUpperArmToLeftLowerArm.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.LeftUpperArmToLeftLowerArm.Visible = true
            
            playerESP.Skeleton.NeckToLowerTorso.From = neckPos
            playerESP.Skeleton.NeckToLowerTorso.To = Vector2.new(lowerTorsoPos.X, lowerTorsoPos.Y)
            playerESP.Skeleton.NeckToLowerTorso.Color = color
            playerESP.Skeleton.NeckToLowerTorso.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.NeckToLowerTorso.Visible = true
            
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.From = Vector2.new(lowerTorsoPos.X, lowerTorsoPos.Y)
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.To = Vector2.new(rightUpperLegPos.X, rightUpperLegPos.Y)
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.Color = color
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.Visible = true
            
            playerESP.Skeleton.LowerTorsoToLeftUpperLeg.From = Vector2.new(lowerTorsoPos.X, lowerTorsoPos.Y)
            playerESP.Skeleton.LowerTorsoToLeftUpperLeg.To = Vector2.new(leftUpperLegPos.X, leftUpperLegPos.Y)
            playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Color = color
            playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.LowerTorsoToLeftUpperLeg.Visible = true
            
            playerESP.Skeleton.RightUpperLegToRightLowerLeg.From = Vector2.new(rightUpperLegPos.X, rightUpperLegPos.Y)
            playerESP.Skeleton.RightUpperLegToRightLowerLeg.To = Vector2.new(rightLowerLegPos.X, rightLowerLegPos.Y)
            playerESP.Skeleton.RightUpperLegToRightLowerLeg.Color = color
            playerESP.Skeleton.RightUpperLegToRightLowerLeg.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.RightUpperLegToRightLowerLeg.Visible = true
            
            playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.From = Vector2.new(leftUpperLegPos.X, leftUpperLegPos.Y)
            playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.To = Vector2.new(leftLowerLegPos.X, leftLowerLegPos.Y)
            playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.Color = color
            playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.LeftUpperLegToLeftLowerLeg.Visible = true
            
            playerESP.Skeleton.RightLowerLegToRightFoot.From = Vector2.new(rightLowerLegPos.X, rightLowerLegPos.Y)
            playerESP.Skeleton.RightLowerLegToRightFoot.To = Vector2.new(rightFootPos.X, rightFootPos.Y)
            playerESP.Skeleton.RightLowerLegToRightFoot.Color = color
            playerESP.Skeleton.RightLowerLegToRightFoot.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.RightLowerLegToRightFoot.Visible = true
            
            playerESP.Skeleton.LeftLowerLegToLeftFoot.From = Vector2.new(leftLowerLegPos.X, leftLowerLegPos.Y)
            playerESP.Skeleton.LeftLowerLegToLeftFoot.To = Vector2.new(leftFootPos.X, leftFootPos.Y)
            playerESP.Skeleton.LeftLowerLegToLeftFoot.Color = color
            playerESP.Skeleton.LeftLowerLegToLeftFoot.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.LeftLowerLegToLeftFoot.Visible = true
            
            if character:FindFirstChild("RightHand") and character:FindFirstChild("LeftHand") then
                local rightHand = character.RightHand
                local leftHand = character.LeftHand
                local rightHandPos = MainESP:GetCachedPosition(rightHand, "RightHand", player)
                local leftHandPos = MainESP:GetCachedPosition(leftHand, "LeftHand", player)
                
                playerESP.Skeleton.RightLowerArmToRightHand.From = Vector2.new(rightLowerArmPos.X, rightLowerArmPos.Y)
                playerESP.Skeleton.RightLowerArmToRightHand.To = Vector2.new(rightHandPos.X, rightHandPos.Y)
                playerESP.Skeleton.RightLowerArmToRightHand.Color = color
                playerESP.Skeleton.RightLowerArmToRightHand.Thickness = self.Options.SkeletonThickness
                playerESP.Skeleton.RightLowerArmToRightHand.Visible = true
                
                playerESP.Skeleton.LeftLowerArmToLeftHand.From = Vector2.new(leftLowerArmPos.X, leftLowerArmPos.Y)
                playerESP.Skeleton.LeftLowerArmToLeftHand.To = Vector2.new(leftHandPos.X, leftHandPos.Y)
                playerESP.Skeleton.LeftLowerArmToLeftHand.Color = color
                playerESP.Skeleton.LeftLowerArmToLeftHand.Thickness = self.Options.SkeletonThickness
                playerESP.Skeleton.LeftLowerArmToLeftHand.Visible = true
            else
                playerESP.Skeleton.RightLowerArmToRightHand.Visible = false
                playerESP.Skeleton.LeftLowerArmToLeftHand.Visible = false
            end
        else
            for _, line in pairs(playerESP.Skeleton) do
                if line and line.Visible ~= nil then
                    line.Visible = false
                end
            end
        end
        
    else
        local torso = character:FindFirstChild("Torso")
        local rightArm = character:FindFirstChild("Right Arm")
        local leftArm = character:FindFirstChild("Left Arm")
        local rightLeg = character:FindFirstChild("Right Leg")
        local leftLeg = character:FindFirstChild("Left Leg")
        
        if torso and rightArm and leftArm and rightLeg and leftLeg then
            local rootPos = MainESP:GetCachedPosition(torso, "Torso", player)
            local rightArmPos = MainESP:GetCachedPosition(rightArm, "RightArm", player)
            local leftArmPos = MainESP:GetCachedPosition(leftArm, "LeftArm", player)
            local rightLegPos = MainESP:GetCachedPosition(rightLeg, "RightLeg", player)
            local leftLegPos = MainESP:GetCachedPosition(leftLeg, "LeftLeg", player)
            
            local neckPos = Vector2.new(rootPos.X, (headPos.Y + rootPos.Y) / 2)
            
            playerESP.Skeleton.HeadToNeck.From = Vector2.new(headPos.X, headPos.Y)
            playerESP.Skeleton.HeadToNeck.To = neckPos
            playerESP.Skeleton.HeadToNeck.Color = color
            playerESP.Skeleton.HeadToNeck.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.HeadToNeck.Visible = true
            
            playerESP.Skeleton.NeckToRightUpperArm.From = neckPos
            playerESP.Skeleton.NeckToRightUpperArm.To = Vector2.new(rightArmPos.X, rightArmPos.Y)
            playerESP.Skeleton.NeckToRightUpperArm.Color = color
            playerESP.Skeleton.NeckToRightUpperArm.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.NeckToRightUpperArm.Visible = true
            
            playerESP.Skeleton.NeckToLeftUpperArm.From = neckPos
            playerESP.Skeleton.NeckToLeftUpperArm.To = Vector2.new(leftArmPos.X, leftArmPos.Y)
            playerESP.Skeleton.NeckToLeftUpperArm.Color = color
            playerESP.Skeleton.NeckToLeftUpperArm.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.NeckToLeftUpperArm.Visible = true
            
            playerESP.Skeleton.NeckToLowerTorso.From = neckPos
            playerESP.Skeleton.NeckToLowerTorso.To = Vector2.new(rootPos.X, rootPos.Y)
            playerESP.Skeleton.NeckToLowerTorso.Color = color
            playerESP.Skeleton.NeckToLowerTorso.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.NeckToLowerTorso.Visible = true
            
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.From = Vector2.new(rootPos.X, rootPos.Y)
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.To = Vector2.new(rightLegPos.X, rightLegPos.Y)
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.Color = color
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.Thickness = self.Options.SkeletonThickness
            playerESP.Skeleton.LowerTorsoToRightUpperLeg.Visible = true
            
            playerESP.Skeleton.LowerTorsoToLeftUpperLeg.From = Vector2.new(rootPos.X, rootPos.Y)
            playerESP.Skeleton.LowerTorsoToLeftUpperLeg.To = Vector2.new(leftLegPos.X, leftLegPos.Y)
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
            for _, line in pairs(playerESP.Skeleton) do
                if line and line.Visible ~= nil then
                    line.Visible = false
                end
            end
        end
    end
end

function MainESP:CreateESP(player, object, customName, customPredicate)
    if player then
        local PlayerESP = {
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

        if game.PlaceId == 606849621 then
            PlayerESP.Bounties = self.CreateText()
        end
        
        self.Container[player] = PlayerESP
        
    elseif object then
        local ObjectESP = {
            Info = self.CreateText(),
            Tracer = self.CreateLine(),
            Connections = {},
        }
        
        self.Container[object] = ObjectESP
        
        ObjectESP.Connections.AncestryConnection = object.AncestryChanged:Connect(function()
            if not object:IsDescendantOf(workspace) then
                self:RemoveESP(object)
            end
        end)
        
        ObjectESP.Connections.RenderConnection = Services.RunService.RenderStepped:Connect(function()
            if not object:IsDescendantOf(workspace) or 
               (customPredicate and not customPredicate(object)) then
                ObjectESP.Info.Visible = false
                ObjectESP.Tracer.Visible = false
                return
            end
            
            if self.ObjectOptions.Enabled then
                local rootPos, onScreen = self.WTVP(object.Position)
                local color = self:GetColor(nil, false, self.ObjectOptions.Rainbow, self.ObjectOptions.Color)
                
                if self.ObjectOptions.Tracer and rootPos.Z > 0 then
                    ObjectESP.Tracer.From = self.TracerOrigins[self.ObjectOptions.TracerOrigin]
                    ObjectESP.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    ObjectESP.Tracer.Color = color
                    ObjectESP.Tracer.Thickness = self.ObjectOptions.TracerThickness
                    ObjectESP.Tracer.Visible = true
                else
                    ObjectESP.Tracer.Visible = false
                end
                
                if onScreen and (self.ObjectOptions.Name or self.ObjectOptions.Distance) then
                    local name = self.ObjectOptions.Name and (customName or object.Name) or ""
                    local distance = ""
                    
                    if self.ObjectOptions.Distance then
                        local dist = math.round(self.GetDistanceFromPlayer(LocalPlayer, object.Position))
                        distance = "\n[" .. tostring(dist) .. " studs]"
                    end
                    
                    ObjectESP.Info.Text = name .. distance
                    ObjectESP.Info.Position = Vector2.new(rootPos.X, rootPos.Y)
                    ObjectESP.Info.Color = color
                    ObjectESP.Info.Font = self.ObjectOptions.Font
                    ObjectESP.Info.Size = self.ObjectOptions.FontSize
                    ObjectESP.Info.Outline = self.ObjectOptions.TextOutline
                    ObjectESP.Info.OutlineColor = Color3.fromRGB(0, 0, 0)
                    ObjectESP.Info.Visible = true
                else
                    ObjectESP.Info.Visible = false
                end
            else
                ObjectESP.Info.Visible = false
                ObjectESP.Tracer.Visible = false
            end
        end)
    end
end

function MainESP:HidePlayerESP(playerESP)
    for elementName, element in pairs(playerESP) do
        if elementName == "Skeleton" then
            for _, line in pairs(element) do
                line.Visible = false
            end
        elseif elementName ~= "Connections" and elementName ~= "IsPlayer" then
            element.Visible = false
        end
    end
end

function MainESP:RemoveESP(value)
    local container = self.Container[value]
    if not container then return end
    
    local playerName = type(value) == "userdata" and value.Name or tostring(value)
    
    for key in pairs(self._colorCache) do
        if key:find(playerName) then
            self._colorCache[key] = nil
        end
    end
    
    for key in pairs(self._positionCache) do
        if key:find(playerName) then
            self._positionCache[key] = nil
        end
    end
    
    if container.Connections then
        for _, connection in pairs(container.Connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        container.Connections = nil
    end
    
    for elementName, element in pairs(container) do
		pcall(function()
			for _, line in pairs(element) do
				pcall(function() line:Destroy() end)
			end
		end)

		pcall(function() element:Destroy() end)
    end
    
    self.Container[value] = nil
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
    local currentFPS = math.min(1 / Services.Stats.FrameTime, 200)
    
    table.insert(ESPPerformance.fpsHistory, currentFPS)
    ESPPerformance.fpsSum = ESPPerformance.fpsSum + currentFPS
    
    if #ESPPerformance.fpsHistory > ESPPerformance.fpsHistorySize then
		local overflow = #ESPPerformance.fpsHistory - ESPPerformance.fpsHistorySize
		for _ = 1, overflow do
			ESPPerformance.fpsSum -= table.remove(ESPPerformance.fpsHistory, 1)
		end
	end
    
    if #ESPPerformance.fpsHistory > 0 then
        ESPPerformance.averageFPS = ESPPerformance.fpsSum / #ESPPerformance.fpsHistory
    end
end

local globalRenderConnection = Services.RunService.RenderStepped:Connect(function()
    local now = tick()
    
    updateFPSAverage()

	CacheManager:CleanupCaches()
    
    if now - ESPPerformance.lastOptimize >= 0.5 then
        local currentAvgFPS = ESPPerformance.averageFPS
        
        if #ESPPerformance.fpsHistory >= math.min(10, ESPPerformance.fpsHistorySize) then
            if currentAvgFPS < ESPPerformance.targetFPS - ESPPerformance.stabilityThreshold then
                local adjustment = 1 + ESPPerformance.adjustmentRate
                ESPPerformance.interval = math.min(ESPPerformance.interval * adjustment, ESPPerformance.minInterval)
            elseif currentAvgFPS > ESPPerformance.targetFPS + ESPPerformance.stabilityThreshold then
                local adjustment = 1 - ESPPerformance.adjustmentRate
                ESPPerformance.interval = math.max(ESPPerformance.interval * adjustment, ESPPerformance.maxInterval)
            end
        end
        
        ESPPerformance.lastOptimize = now
    end
    
    if now - ESPPerformance.lastUpdate < ESPPerformance.interval then
        return 
    end
    ESPPerformance.lastUpdate = now
    
    for player, playerESP in pairs(MainESP.Container) do
        if playerESP.IsPlayer then
            if not player or not player.Parent then
                MainESP:RemoveESP(player)
                continue
            end

            local shouldRender, distance = CullingSystem:ShouldRenderPlayer(player)
            if not shouldRender then
                MainESP:HidePlayerESP(playerESP)
                continue
            end
            
            local detailLevel = CullingSystem:GetDetailLevel(distance)

            if MainESP.Options.Enabled and 
               (not MainESP.Options.TeamCheck or not player.Team or LocalPlayer.Team ~= player.Team) and 
               MainESP:PlayerAlive(player) and player.Character then
                
                local character = player.Character
                local rootPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
                local head = character:FindFirstChild("Head")
                local characterSizeHalved = select(2, character:GetBoundingBox()) / 2
                
                if not rootPart or not head then
                    MainESP:HidePlayerESP(playerESP)
                    continue
                end
                
                local rootPos, onScreen = MainESP:GetCachedPosition(rootPart, "RootPart", player, true)
				local headPos = MainESP:GetCachedPosition(head, "Head", player)
                local topPos = MainESP.WTVP(rootPart.Position + Vector3.new(0, characterSizeHalved.Y, 0))
                local bottomPos = MainESP.WTVP(rootPart.Position - Vector3.new(0, characterSizeHalved.Y, 0))
                
                local color = MainESP:GetColor(player, MainESP.Options.UseTeamColor, MainESP.Options.Rainbow, MainESP.Options.Color)

                local boxWidth = 3000 / rootPos.Z
                local boxHeight = topPos.Y - bottomPos.Y
                local boxX = rootPos.X - boxWidth / 2
                local boxY = rootPos.Y - boxHeight / 2
                
                playerESP._BoxDimensions.width = boxWidth
                playerESP._BoxDimensions.height = boxHeight
                playerESP._BoxDimensions.x = boxX
                playerESP._BoxDimensions.y = boxY

                local dims = playerESP._BoxDimensions
                local infoX

                if detailLevel == "minimal" then
                    if MainESP.Options.Name and onScreen then
                        local dynamicOffsetY = dims.height * 1.1
                        if not infoX then
                            infoX = dims.x + dims.width / 2
                        end

                        playerESP.Name.Text = player.DisplayName
                        if MainESP.Options.Distance and onScreen then
                            playerESP.Name.Text ..= "\n" .. "[" .. tostring(math.round(distance)) .. " studs]"
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
                    for _, line in pairs(playerESP.Skeleton) do
                        line.Visible = false
                    end
                    continue
                end
                
                if MainESP.Options.Box and onScreen then
                    playerESP.Box.Size = Vector2.new(boxWidth, boxHeight)
                    playerESP.Box.Position = Vector2.new(boxX, boxY)
                    playerESP.Box.Color = color
                    playerESP.Box.Thickness = MainESP.Options.BoxThickness
                    playerESP.Box.Visible = true
                else
                    playerESP.Box.Visible = false
                end

				local dims = playerESP._BoxDimensions
                
				if MainESP.Options.Health and onScreen and playerESP.Box.Visible and detailLevel == "full" then
					local health, maxHealth = MainESP.GetHealth(player)
					local healthPerc = health / maxHealth

					local healthWidth = dims.width * 0.15
					local healthHeight = dims.height * healthPerc
					local offsetX = dims.width * 0.150

					playerESP.Health.Size = Vector2.new(healthWidth, healthHeight)
					playerESP.Health.Position = Vector2.new(dims.x - offsetX, dims.y)
					playerESP.Health.Color = Color3.fromHSV(healthPerc * 0.3, 1, 1)
					playerESP.Health.Filled = true
					playerESP.Health.Visible = true
				else
					playerESP.Health.Visible = false
				end
                
                if MainESP.Options.Tracer and rootPos.Z > 0 and detailLevel == "full" then
                    local upperTorso, neckPos = character:FindFirstChild("UpperTorso")
                    if upperTorso then
                        local upperTorsoPos = MainESP:GetCachedPosition(upperTorso, "UpperTorso", player)
                        neckPos = Vector2.new(upperTorsoPos.X, (headPos.Y + upperTorsoPos.Y) / 2)
                    else
                        neckPos = Vector2.new(rootPos.X, (headPos.Y + rootPos.Y) / 2)
                    end

                    playerESP.Tracer.From = MainESP.TracerOrigins[MainESP.Options.TracerOrigin]
                    playerESP.Tracer.To = Vector2.new(neckPos.X, neckPos.Y)
                    playerESP.Tracer.Color = color
                    playerESP.Tracer.Thickness = MainESP.Options.TracerThickness
                    playerESP.Tracer.Visible = true
                else
                    playerESP.Tracer.Visible = false
                end
                
                if MainESP.Options.Name and onScreen then
                    if not infoX then
                        infoX = dims.x + dims.width / 2
                    end
                    
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

                if MainESP.Options.Bounties and onScreen and game.PlaceId == 606849621 then -- Jb
                    if not infoX then
                        infoX = dims.x + dims.width / 2
                    end

                    local getUsernameFromDisplayName = (function(name)
                        for i,v in next, game:GetService("Players"):GetPlayers() do
                            if v.DisplayName == name then
                                return v.Name
                            end
                        end
                        return nil
                    end)

                    local format = (function(displayname)
                        local uh = getUsernameFromDisplayName(displayname)
                        if uh then
                            local module = require(game:GetService("ReplicatedStorage").Bounty.BountyBoardService)
                            for i,v in next, module.Bounties do
                                if v.Name == uh then
                                    return "Bounty: ".. tostring(v.Bounty)
                                end
                            end
                        end
                        return ""
                    end)
                    
                    playerESP.Bounties.Text = format(player.DisplayName)
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
					local dynamicOffsetY = dims.height * 0.1
                    if not infoX then
                        infoX = dims.x + dims.width / 2
                    end

					playerESP.Distance.Text = "[" .. tostring(math.round(distance)) .. " studs]"
					playerESP.Distance.Position = Vector2.new(infoX, dims.y - dynamicOffsetY)
					playerESP.Distance.Color = color
					playerESP.Distance.Font = MainESP.Options.Font
					playerESP.Distance.Size = MainESP.Options.FontSize
					playerESP.Distance.Outline = MainESP.Options.TextOutline
					playerESP.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
					playerESP.Distance.Visible = true
				else
					playerESP.Distance.Visible = false
				end
                
                if MainESP.Options.Direction and onScreen and detailLevel == "full" then
                    local offset = MainESP.WTVP((head.CFrame * CFrame.new(0, 0, -head.Size.Z)).Position)
                    playerESP.Direction.From = Vector2.new(headPos.X, headPos.Y)
                    playerESP.Direction.To = Vector2.new(offset.X, offset.Y)
                    playerESP.Direction.Color = color
                    playerESP.Direction.Thickness = MainESP.Options.DirectionThickness
                    playerESP.Direction.Visible = true
                else
                    playerESP.Direction.Visible = false
                end
                
                MainESP:UpdateSkeleton(playerESP, player, onScreen and detailLevel == "full")
                
            else
                MainESP:HidePlayerESP(playerESP)
            end
        end
    end
end)

local CompatibilityFuncs = {
    [292439477] = function() -- Phantom Forces
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" and islclosure(v) then
                local constants = getconstants(v)
                if getinfo(v).name == "gethealth" and table.find(constants, "alive") then
                    MainESP.GetHealth = v
                end
            elseif type(v) == "table" and rawget(v, "getbodyparts") then
                getgenv().PF_Replication = v
            end
        end
        
        Services.RunService.Stepped:Connect(function()
            for _, player in pairs(Services.Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local body = getgenv().PF_Replication.getbodyparts(player)
                    if body and rawget(body, "rootpart") then
                        player.Character = body.rootpart.Parent
                    else
                        player.Character = nil
                    end
                end
            end
        end)
    end,
    
    [286090429] = function() -- Arsenal
        MainESP.GetHealth = function(player)
            return player.NRPBS.Health.Value, 100
        end
    end,
    
    [142823291] = function() -- Murder Mystery 2
        local murderTeam = Instance.new("Team")
        murderTeam.Name = "Murderer"
        murderTeam.TeamColor = BrickColor.new("Bright red")
        murderTeam.Parent = game.Teams
        
        local sheriffTeam = Instance.new("Team")
        sheriffTeam.Name = "Sheriff" 
        sheriffTeam.TeamColor = BrickColor.new("Bright blue")
        sheriffTeam.Parent = game.Teams
        
        local innocentTeam = Instance.new("Team")
        innocentTeam.Name = "Innocent"
        innocentTeam.TeamColor = BrickColor.new("Bright green")
        innocentTeam.Parent = game.Teams
        
        task.spawn(function()
            while true do
                local success, playerData = pcall(function()
                    return Services.ReplicatedStorage.GetPlayerData:InvokeServer()
                end)
                
                if success and playerData then
                    for _, player in pairs(Services.Players:GetPlayers()) do
                        if playerData[player.Name] and playerData[player.Name].Role then
                            player.Team = game.Teams[playerData[player.Name].Role]
                        else
                            player.Team = innocentTeam
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

Services.Players.PlayerAdded:Connect(function(player)
    MainESP:CreateESP(player)
end)

Services.Players.PlayerRemoving:Connect(function(player)
    MainESP:RemoveESP(player.Name)
end)

for _, player in pairs(Services.Players:GetPlayers()) do
    if player ~= LocalPlayer then
        MainESP:CreateESP(player)
    end
end

return MainESP, CullingSystem

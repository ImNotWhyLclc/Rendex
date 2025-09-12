-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Player = game:GetService("Players").LocalPlayer

-- Functions to get car and tune module
local function getCar()
    return workspace:FindFirstChild(Player.Name .. "Car")
end

local function getTunerParts()
    local car = getCar()
    if not car then return end
    local custom = car:FindFirstChild("Customization")
    local module = car:FindFirstChild("A-Chassis Tune")
    local seat = car:FindFirstChild("DriveSeat")
    if not (custom and module and seat) then return end
    return car, custom, require(module), seat
end

local CurrentCar, Customization, Tune, DriveSeat = getTunerParts()
if not (CurrentCar and Customization and Tune and DriveSeat) then return warn("Missing car components") end

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Rendex Car Tuner",
    Icon = "car",
    Folder = "RendexTuner",
    Size = UDim2.fromOffset(580, 500),
    Theme = "Dark"
})

-- Tabs
local Tabs = {
    Engine = Window:Tab({ Title = "Engine" }),
    Suspension = Window:Tab({ Title = "Suspension" }),
    Transmission = Window:Tab({ Title = "Transmission" }),
    Tires = Window:Tab({ Title = "Tires" }),
    Steering = Window:Tab({ Title = "Steering" }),
    Misc = Window:Tab({ Title = "Extras" })
}

-- Slider helper
local function slider(tab, title, min, max, default, step, desc, callback)
    tab:Slider({
        Title = title,
        Description = desc,
        Step = step,
        Value = { Min = min, Max = max, Default = default },
        Callback = callback
    })
end

-- Engine sliders
slider(Tabs.Engine, "Horsepower", 100, 5000, Tune.Horsepower, 2, "Controls acceleration and top speed", function(v)
    if Customization:FindFirstChild("Horsepower") then Customization.Horsepower.Value = v end
    Tune.Horsepower = v
end)

slider(Tabs.Engine, "Brake Force", 0.5, 5000, Tune.BrakeForce or 2700, 2, "Controls brake strength", function(v)
    if Customization:FindFirstChild("BrakeForce") then Customization.BrakeForce.Value = v end
    Tune.BrakeForce = v
end)

slider(Tabs.Engine, "Throttle Accel", 0.01, 0.2, Tune.ThrotAccel, 0.01, "Throttle acceleration", function(v) Tune.ThrotAccel = v end)
slider(Tabs.Engine, "Throttle Decel", 0.01, 0.5, Tune.ThrotDecel, 0.01, "Throttle deceleration", function(v) Tune.ThrotDecel = v end)
slider(Tabs.Engine, "Brake Accel", 0.01, 0.5, Tune.BrakeAccel, 0.01, "Brake application speed", function(v) Tune.BrakeAccel = v end)

-- Transmission
Tabs.Transmission:Dropdown({
    Title = "Transmission Mode",
    Description = "Auto / Semi / Manual",
    Values = { "Auto", "Semi", "Manual" },
    Default = Tune.TransModes and Tune.TransModes[1] or "Semi",
    Callback = function(mode)
        if table.find(Tune.TransModes, mode) == nil then table.insert(Tune.TransModes, mode) end
    end
})

slider(Tabs.Transmission, "Final Drive", 1, 6, Tune.FinalDrive, 0.1, "Final drive ratio", function(v) Tune.FinalDrive = v end)

-- Gear Ratios
local selectedGear = 1
Tabs.Transmission:Dropdown({
    Title = "Select Gear",
    Values = { "Gear 1", "Gear 2", "Gear 3", "Gear 4", "Gear 5", "Gear 6", "Gear 7", "Gear 8" },
    Default = "Gear 1",
    Callback = function(v) selectedGear = tonumber(v:match("%d+")) or 1 end
})
slider(Tabs.Transmission, "Gear Ratio", 0.2, 5, Tune.Ratios[selectedGear] or 1, 0.01, "Adjust acceleration per gear", function(v)
    Tune.Ratios[selectedGear] = v
end)

-- Suspension
slider(Tabs.Suspension, "FSus Length", 0.7, 3, Tune.FSusLength, 0.01, "Front suspension ride height", function(v) Tune.FSusLength = v end)
slider(Tabs.Suspension, "RSus Length", 0.7, 3, Tune.RSusLength, 0.01, "Rear suspension ride height", function(v) Tune.RSusLength = v end)

Tabs.Suspension:Toggle({
    Title = "Visible Springs",
    Type = "Checkbox",
    Default = Tune.SusVisible,
    Callback = function(v) Tune.SusVisible = v end
})

Tabs.Suspension:Dropdown({
    Title = "Air Sus Preset",
    Description = "Preset suspension height",
    Values = { "Slammed", "Normal", "Lifted" },
    Default = "Normal",
    Callback = function(preset)
        local min, max = 1.7, 2.2
        if preset == "Slammed" then min, max = 0.7, 1.7 end
        if preset == "Lifted" then min, max = 2.4, 3.0 end
        local wheels = { "FL", "FR", "RL", "RR" }
        for _, wheel in ipairs(wheels) do
            local spring = CurrentCar:FindFirstChild("Wheels")[wheel].SuspensionGeometry.Spring
            spring.MinLength = min
            spring.MaxLength = max
        end
    end
})

-- Tires
local TireStats = DriveSeat:FindFirstChild("TireStats")
if TireStats then
    for _, name in ipairs({ "Ffriction","Ffweight","Fwear","Fminfriction","Rfriction","Rfweight","Rwear","Rminfriction","TCS" }) do
        local stat = TireStats:FindFirstChild(name)
        if stat and stat:IsA("NumberValue") then
            slider(Tabs.Tires, "Tire "..name, -100, 100, stat.Value, 1, "Custom tire property", function(v) stat.Value = v end)
        end
    end
end

-- Steering
slider(Tabs.Steering, "Steer Ratio", 5, 20, Tune.SteerRatio, 0.1, "Amount of steering angle", function(v) Tune.SteerRatio = v end)
slider(Tabs.Steering, "Steer Speed", 0.01, 0.3, Tune.SteerSpeed, 0.01, "How fast you steer", function(v) Tune.SteerSpeed = v end)
slider(Tabs.Steering, "Return Speed", 0.01, 0.3, Tune.ReturnSpeed, 0.01, "Wheel return speed", function(v) Tune.ReturnSpeed = v end)
slider(Tabs.Steering, "Ackerman", 0, 1, Tune.Ackerman, 0.01, "Turning difference between wheels", function(v) Tune.Ackerman = v end)

-- Misc toggles
Tabs.Misc:Toggle({ Title = "Enable ABS", Default = Tune.ABSEnabled, Callback = function(v) Tune.ABSEnabled = v end })
Tabs.Misc:Toggle({ Title = "Enable TCS", Default = Tune.TCSEnabled, Callback = function(v) Tune.TCSEnabled = v end })
Tabs.Misc:Toggle({ Title = "Quick Shifter", Default = Tune.ShiftUpTime <= 0.05, Callback = function(v)
    Tune.ShiftUpTime = v and 0.05 or 0.2
    Tune.ShiftDnTime = v and 0.05 or 0.2
end })

-- Mode presets
Tabs.Misc:Dropdown({
    Title = "Mode Preset",
    Values = { "Race", "Drift", "Grip", "Street" },
    Callback = function(preset)
        if preset == "Drift" then
            Tune.Config = "RWD"
            Tune.TransModes = { "Semi" }
        elseif preset == "Grip" then
            Tune.Config = "AWD"
            Tune.TransModes = { "Auto" }
        elseif preset == "Race" then
            Tune.Config = "AWD"
            Tune.TransModes = { "Manual" }
        else
            Tune.Config = "FWD"
            Tune.TransModes = { "Auto" }
        end
    end
})

-- Update loop for car changes
task.spawn(function()
    while task.wait(1) do
        local car, cust, tune, seat = getTunerParts()
        if car and car ~= CurrentCar then
            CurrentCar, Customization, Tune, DriveSeat = car, cust, tune, seat
            print("Car rebound")
        end
    end
end)

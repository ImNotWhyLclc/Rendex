local base = "https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/refs/heads/main/"

local hm = {
    [245662005] = "Games/Jailbreak.luau",
    [372226183] = "Games/FleeTheFacility.luau",
    [2440500124] = "Games/Doors.luau",
    [10509848467] = "Games/Demise.luau",
    [254394801] = "Games/KAT.luau",
    [7326934954] = "Games/Rendex99NITF.luau"
}

local yay = {
    [2449081] = "Games/DoorsLobby.luau"
}

local file = yay[game.PlaceId] or hm[game.GameId]

if not file then
    warn("* Rendex * Unsupported Game:", game.GameId, "Place:", game.PlaceId)
    return
end

local success, err = pcall(function()
    local source = game:HttpGet(base .. file)
    local func = loadstring(source)

    if not func then
        error("Failed to compile " .. file)
    end

    func()
end)

if success then
    print("* Rendex * Loaded:", file)
else
    warn("* Rendex * Failed:", file)
    warn(err)
end

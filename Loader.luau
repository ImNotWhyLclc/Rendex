local base = "https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/refs/heads/main/"

local hm = {
    [606849621] = "Games/Jailbreak.luau",
    [17190407811] = "Games/Jailbreak.luau",
    [108098425719662] = "Games/Jailbreak.luau",
    [621129760] = "Games/KAT.luau",
    [126371807511901] = "Games/Rendex99NITF.luau",
    [126509999114328] = "Games/Rendex99NITF.luau",
    [127742093697776] = "Games/RendexPVB.luau"
}

local file = hm[game.PlaceId]

if not file then
    warn("* Rendex * Unsupported PlaceId:", game.PlaceId)
    return
end

local success, err = pcall(function()
    loadstring(game:HttpGet(base .. file))()
end)

if success then
    print("* Rendex * Loaded:", file)
else
    warn("* Rendex * Failed:", err)
end

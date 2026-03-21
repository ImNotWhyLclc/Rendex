local base = "https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/main/"
local hm = {
    [606849621] = "Games/Jailbreak.luau",
    [17190407811] = "Games/Jailbreak.luau",
    [108098425719662] = "Games/Jailbreak.luau",
    [126371807511901] = "Games/Rendex99NITF.luau",
    [126509999114328] = "Games/Rendex99NITF.luau",
    [127742093697776] = "Games/RendexPVB.luau"
}
local file = hm[game.PlaceId]
local so, tuff = pcall(function()
    return loadstring(game:HttpGet(base..file))()
end)
if so then
    print("* Rendex * Loaded:", file)
else
    warn("* Rendex * Failed:", tuff)
end

local base = "https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/main/"
local hm = {
    [126371807511901] = "Games/Rendex99NITF.luau" -- 99nitf party update
    [126509999114328] = "Games/Rendex99NITF.luau" -- 99nitf normal
    [606849621] = "Games/RendexJB.luau", -- jb
    [17190407811] = "Games/RendexJB.luau", -- jb voice chat
    [127742093697776] = "Games/RendexPVB.luau" -- pvb
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

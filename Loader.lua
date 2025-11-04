local base = "https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/main/"
local hm = {
    [606849621] = "Games/RendexJB.lua", -- jb
    [127742093697776] = "Games/RendexPVB.lua" -- pvb
}
local file = hm[game.PlaceId]
local so, tuff = pcall(function()
    return loadstring(game:HttpGet(base..file))()
end)
if so then
    print("[Rendex] Loaded:", file)
else
    warn("[Rendex] Failed:", tuff)
end

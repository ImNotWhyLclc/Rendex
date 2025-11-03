local base = "https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/main/"
local hm = {
    [606849621] = "games/jailbreak-break.luau",
    [17516596118] = "games/hypershot.lua"
}
local file = hm[game.PlaceId]
local so, tuff = pcall(function()
    return loadstring(game:HttpGet(base..file))()
end)
if ok then
    print("[Rendex] Loaded:", file)
else
    warn("[Rendex] Failed:", tuff)
end

-- Rendex 99 Days – Obsidian UI Loader (v2.30)
-- This file will fetch and execute the full v2.30 script.

local url = "https://raw.githubusercontent.com/ImNotWhyLclc/Rendex/main/rendex%2099%20days.lua"
local response = game:HttpGet(url)
assert(response and #response > 0, "Failed to download Rendex script")
loadstring(response)()

-- ==========================================
-- DQYMON ESP - UNIVERSAL LOADER
-- Loads all modules from GitHub and executes
-- ==========================================

local githubRaw = "https://raw.githubusercontent.com/afs-rake/dqymon/alpha/"

local function loadModule(filename)
    local response = game:HttpGet(githubRaw .. filename)
    local fn = loadstring(response)
    if not fn then 
        error("Failed to load " .. filename)
    end
    return fn()
end

-- Load dependencies in order
print("[DQYMON] Loading Constants...")
_G.DqymonConstants = loadModule("dqymon_constants.lua")

print("[DQYMON] Loading UI Library...")
_G.DqymonUILibrary = loadModule("dqymon_ui.lua")

print("[DQYMON] Loading Config System...")
_G.DqymonConfigSystem = loadModule("dqymon_config.lua")

print("[DQYMON] Loading Main Script...")
loadModule("dqymon-esp.lua")

print("[DQYMON] Script loaded successfully!")

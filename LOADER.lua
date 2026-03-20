-- ==========================================
-- DQYMON ESP - UNIVERSAL LOADER
-- Loads all modules from GitHub and executes
-- Mobile & Desktop Compatible
-- Enhanced error logging for Delta/mobile
-- ==========================================

print("\n========================================")
print("[DQYMON] ESP LOADER v2.0")
print("========================================\n")

local githubRaw = "https://raw.githubusercontent.com/afs-rake/dqymon/alpha/"
local loadedModules = {}

local function SafeHttpGet(url)
    print("[DQYMON] Fetching: " .. url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        local errMsg = tostring(response)
        print("[DQYMON] ❌ HttpGet failed: " .. errMsg)
        return nil, errMsg
    end
    
    if not response or response == "" then
        print("[DQYMON] ❌ Empty response from " .. url)
        return nil, "Empty response"
    end
    
    print("[DQYMON] ✅ Downloaded " .. #response .. " bytes")
    return response
end

local function loadModule(filename)
    print("\n[DQYMON] Loading: " .. filename .. "...")
    
    local url = githubRaw .. filename
    local response, httpErr = SafeHttpGet(url)
    
    if not response then
        error("[DQYMON] Failed to fetch " .. filename .. ": " .. (httpErr or "unknown error"))
    end
    
    print("[DQYMON] Parsing Lua...")
    local fn, parseErr = loadstring(response)
    
    if not fn then
        error("[DQYMON] Failed to parse " .. filename .. ": " .. (parseErr or "unknown error"))
    end
    
    print("[DQYMON] Executing " .. filename .. "...")
    local success, result = pcall(fn)
    
    if not success then
        error("[DQYMON] Execution error in " .. filename .. ": " .. tostring(result))
    end
    
    if result == nil then
        error("[DQYMON] " .. filename .. " did not return a value")
    end
    
    print("[DQYMON] ✅ Successfully loaded " .. filename)
    loadedModules[filename] = result
    return result
end

-- Load with comprehensive error handling
local function Main()
    print("[DQYMON] Starting module load sequence...\n")
    
    -- Load Constants
    print("======== CONSTANTS ========")
    _G.DqymonConstants = loadModule("dqymon_constants.lua")
    
    local isMobile = _G.DqymonConstants.IsMobile
    print("\n[DQYMON] Platform: " .. (isMobile and "📱 MOBILE" or "🖥️ DESKTOP"))
    
    -- Load Utils (depends on Constants)
    print("\n======== UTILITIES ========")
    _G.DqymonUtils = loadModule("dqymon_utils.lua")
    
    -- Load UI Library (depends on Constants)
    print("\n======== UI LIBRARY ========")
    _G.DqymonUILibrary = loadModule("dqymon_ui.lua")
    
    -- Load Config System (depends on Constants)
    print("\n======== CONFIG SYSTEM ========")
    _G.DqymonConfigSystem = loadModule("dqymon_config.lua")
    
    -- Load Main Script (depends on all above)
    print("\n======== MAIN SCRIPT ========")
    loadModule("dqymon-esp.lua")
    
    -- Success!
    print("\n========================================")
    print("[DQYMON] ✅ ALL MODULES LOADED SUCCESSFULLY!")
    print("========================================\n")
    
    if isMobile then
        print("[DQYMON] 📱 MOBILE CONTROLS:")
        print("  • Press MENU button (top-left) to toggle UI")
        print("  • Press AIM button (top-right) and hold to aimbot")
    else
        print("[DQYMON] 🖥️ DESKTOP CONTROLS:")
        print("  • Press the menu keybind to toggle UI")
        print("  • Hold mouse button to aimbot")
    end
    
    -- Print UNC capability report
    print("\n" .. _G.DqymonUtils.GetCapabilityReport())
end

-- Execute with global error handling
local success, err = pcall(Main)

if not success then
    print("\n❌ ❌ ❌ DQYMON LOADER ERROR ❌ ❌ ❌")
    print("\nError Details:")
    print(tostring(err))
    print("\nDebugging Info:")
    print("  • Loaded Modules: " .. table.concat(table.keys(loadedModules) or {"none"}, ", "))
    print("  • Game: " .. game:GetFullName())
    print("  • Executor: Delta Exploit (assumed)")
    print("\nTroubleshooting:")
    print("  1. Check internet connection")
    print("  2. Verify GitHub is not blocked")
    print("  3. Try again in a few seconds")
    print("  4. Check if Delta has HttpGet enabled in settings")
    print("\n" .. string.rep("=", 40))
end

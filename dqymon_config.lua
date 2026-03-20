--[[
    DqymonESP - Configuration System
    Handles config loading, saving, and auto-mapping to UI elements
]]

local Constants = require(script.Parent:FindFirstChild("dqymon_constants") or error("Missing dqymon_constants"))

local ConfigSystem = {}

-- ==========================================
-- CONFIG CLASS
-- ==========================================
function ConfigSystem:New(configName, defaultConfig)
    local self = setmetatable({}, {__index = ConfigSystem})
    
    self.configName = configName
    self.defaultConfig = defaultConfig
    self.currentConfig = {}
    self.updaters = {}
    
    -- Initialize with defaults
    for key, value in pairs(defaultConfig) do
        self.currentConfig[key] = value
    end
    
    return self
end

-- ==========================================
-- UPDATER REGISTRATION
-- ==========================================
function ConfigSystem:RegisterUpdater(configKey, updaterFunction)
    if not self.updaters[configKey] then
        self.updaters[configKey] = {}
    end
    table.insert(self.updaters[configKey], updaterFunction)
end

function ConfigSystem:RegisterUIUpdaters(uiUpdaters)
    -- Auto-map UI updaters based on their names
    for toggleName, updateFunc in pairs(uiUpdaters.Toggles or {}) do
        -- Convert UI element names to config keys
        -- "Enable Aimbot" -> "aimEnabled", "Show FOV" -> "showFov", etc.
        local configKey = self:UINameToConfigKey(toggleName)
        if self.defaultConfig[configKey] ~= nil then
            self:RegisterUpdater(configKey, updateFunc)
        end
    end
    
    for sliderName, updateFunc in pairs(uiUpdaters.Sliders or {}) do
        local configKey = self:UINameToConfigKey(sliderName)
        if self.defaultConfig[configKey] ~= nil then
            self:RegisterUpdater(configKey, updateFunc)
        end
    end
    
    for dropdownName, updateFunc in pairs(uiUpdaters.Dropdowns or {}) do
        local configKey = self:UINameToConfigKey(dropdownName)
        if self.defaultConfig[configKey] ~= nil then
            self:RegisterUpdater(configKey, updateFunc)
        end
    end
end

-- ==========================================
-- CONFIG UTILITIES
-- ==========================================
function ConfigSystem:UINameToConfigKey(uiName)
    -- Convert UI display names to config keys
    -- "Enable Aimbot" -> "aimEnabled"
    -- "Show FOV" -> "showFov"
    
    local mapping = {
        ["Enable Aimbot"] = "aimEnabled",
        ["Target Part"] = "aimPart",
        ["Prediction (Velocity)"] = "prediction",
        ["Show FOV"] = "showFov",
        ["Wall Check"] = "wallCheck",
        ["Team Check"] = "teamCheck",
        ["FOV Size"] = "fov",
        ["Smoothness"] = "smoothing",
        ["Dynamic Headshot %"] = "headshotChance",
        ["Enable ESP"] = "espEnabled",
        ["2D Box"] = "espBox",
        ["Health Bar"] = "espHealth",
        ["Tracers"] = "espTracer",
        ["Names"] = "espNames",
        ["Distance"] = "espDistance",
        ["Chams (Highlight)"] = "espHighlight",
        ["Watermark"] = "watermark",
        ["Target Info"] = "targetInfo",
    }
    
    return mapping[uiName] or uiName
end

function ConfigSystem:Get(key)
    return self.currentConfig[key]
end

function ConfigSystem:Set(key, value, skipUpdaters)
    self.currentConfig[key] = value
    
    if not skipUpdaters and self.updaters[key] then
        for _, updateFunc in ipairs(self.updaters[key]) do
            pcall(updateFunc, value)
        end
    end
end

-- ==========================================
-- FILE OPERATIONS (Mobile & Desktop Compatible)
-- ==========================================
function ConfigSystem:Save()
    local Constants = self.Constants or require(script.Parent:FindFirstChild("dqymon_constants"))
    local isMobile = Constants.IsMobile
    
    if not writefile then
        return false, isMobile and "Mobile: Config save not supported on this executor" or "Executor doesn't support writefile"
    end
    
    local httpService = game:GetService("HttpService")
    local success, json = pcall(function()
        return httpService:JSONEncode(self.currentConfig)
    end)
    
    if not success then
        return false, "Failed to encode config"
    end
    
    local writeSuccess, writeErr = pcall(function()
        writefile(self.configName, json)
    end)
    
    if not writeSuccess then
        return false, "Failed to write file: " .. tostring(writeErr)
    end
    
    return true, "Config saved successfully"
end

function ConfigSystem:Load()
    local Constants = self.Constants or require(script.Parent:FindFirstChild("dqymon_constants"))
    local isMobile = Constants.IsMobile
    
    if not readfile or not isfile then
        return false, isMobile and "Mobile: Config load not supported on this executor" or "Executor doesn't support file operations"
    end
    
    if not isfile(self.configName) then
        return false, "Config file not found"
    end
    
    local httpService = game:GetService("HttpService")
    
    local readSuccess, json = pcall(function()
        return readfile(self.configName)
    end)
    
    if not readSuccess then
        return false, "Failed to read config file"
    end
    
    local decodeSuccess, decoded = pcall(function()
        return httpService:JSONDecode(json)
    end)
    
    if not decodeSuccess or type(decoded) ~= "table" then
        return false, "Failed to decode config"
    end
    
    -- Merge decoded config with current config
    for key, value in pairs(decoded) do
        if self.defaultConfig[key] ~= nil then
            self.currentConfig[key] = value
        end
    end
    
    -- Trigger all updaters
    self:ApplyAllUpdaters()
    
    return true, "Config loaded successfully"
end

function ConfigSystem:ApplyAllUpdaters()
    for configKey, updateFuncs in pairs(self.updaters) do
        local value = self.currentConfig[configKey]
        for _, updateFunc in ipairs(updateFuncs) do
            pcall(updateFunc, value)
        end
    end
end

-- ==========================================
-- AUTO-SAVE HELPER
-- ==========================================
function ConfigSystem:SetupAutoSave(debounceTime)
    debounceTime = debounceTime or 1
    local lastSaveTime = 0
    
    return function(key, value)
        self:Set(key, value)
        
        local currentTime = tick()
        if currentTime - lastSaveTime >= debounceTime then
            self:Save()
            lastSaveTime = currentTime
        end
    end
end

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
function ConfigSystem:Reset()
    for key, value in pairs(self.defaultConfig) do
        self.currentConfig[key] = value
    end
    self:ApplyAllUpdaters()
end

function ConfigSystem:Export()
    return self.currentConfig
end

function ConfigSystem:Import(importedConfig)
    for key, value in pairs(importedConfig) do
        if self.defaultConfig[key] ~= nil then
            self.currentConfig[key] = value
        end
    end
    self:ApplyAllUpdaters()
end

return ConfigSystem

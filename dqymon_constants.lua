--[[
    DqymonESP - Constants & Theme
    Central location for all colors, theme values, and configuration defaults
    Mobile & Desktop compatible
]]

local Constants = {}

-- ==========================================
-- PLATFORM DETECTION
-- ==========================================
Constants.IsMobile = game:GetService("UserInputService").TouchEnabled
Constants.IsDesktop = not Constants.IsMobile

-- ==========================================
-- UNC CAPABILITY DETECTION
-- ==========================================
local function DetectCapabilities()
    local caps = {
        HasSetRawMetatable = false,
        HasGetRawMetatable = false,
        HasDebugGetInfo = false,
        HasDebugSetLocal = false,
        HasNewCClosure = false,
    }
    
    -- Test setrawmetatable
    pcall(function()
        local t = {}
        setrawmetatable(t, {})
        caps.HasSetRawMetatable = true
    end)
    
    -- Test getrawmetatable
    pcall(function()
        local t = {}
        getrawmetatable("")
        caps.HasGetRawMetatable = true
    end)
    
    -- Test debug.getinfo
    pcall(function()
        if debug and debug.getinfo then
            debug.getinfo(1)
            caps.HasDebugGetInfo = true
        end
    end)
    
    -- Test debug.setlocal (safely - don't actually modify)
    pcall(function()
        if debug and debug.setlocal then
            caps.HasDebugSetLocal = true
        end
    end)
    
    -- Test newcclosure (wraps functions)
    pcall(function()
        if newcclosure then
            newcclosure(function() end)
            caps.HasNewCClosure = true
        end
    end)
    
    -- Summary: Full UNC = has most/all, Partial = has some, None = has none
    local unc_count = (caps.HasSetRawMetatable and 1 or 0) + 
                      (caps.HasGetRawMetatable and 1 or 0) + 
                      (caps.HasDebugGetInfo and 1 or 0) + 
                      (caps.HasDebugSetLocal and 1 or 0) + 
                      (caps.HasNewCClosure and 1 or 0)
    
    if unc_count >= 4 then
        caps.Level = "FULL_UNC"
    elseif unc_count >= 2 then
        caps.Level = "PARTIAL_UNC"
    else
        caps.Level = "NO_UNC"
    end
    
    return caps
end

Constants.Capabilities = DetectCapabilities()

-- ==========================================
-- COLORS & THEME
-- ==========================================
Constants.Colors = {
    -- Primary
    Primary = Color3.fromRGB(0, 255, 255),      -- Cyan
    Secondary = Color3.fromRGB(0, 200, 200),    -- Darker cyan
    Tertiary = Color3.fromRGB(0, 150, 150),     -- Even darker
    
    -- UI Backgrounds
    BgDark = Color3.fromRGB(18, 18, 18),
    BgMedium = Color3.fromRGB(25, 25, 25),
    BgLight = Color3.fromRGB(28, 28, 28),
    BgPanel = Color3.fromRGB(20, 20, 20),
    BgInputField = Color3.fromRGB(35, 35, 35),
    
    -- Text
    TextDark = Color3.fromRGB(150, 150, 150),
    TextMedium = Color3.fromRGB(200, 200, 200),
    TextLight = Color3.fromRGB(255, 255, 255),
    
    -- Health/Status
    HealthGood = Color3.fromRGB(0, 255, 0),
    HealthLow = Color3.fromRGB(255, 0, 0),
    HealthBar = Color3.fromRGB(20, 20, 20),
    
    -- Special
    White = Color3.fromRGB(255, 255, 255),
    DarkGray = Color3.fromRGB(40, 40, 40),
    MediumGray = Color3.fromRGB(50, 50, 50),
}

-- ==========================================
-- UI SIZING CONSTANTS (Responsive)
-- ==========================================
local isMobile = Constants.IsMobile
Constants.UI = {
    -- Window sizing (responsive to device)
    MainWindowSize = isMobile and UDim2.new(0, 280, 0, 380) or UDim2.new(0, 350, 0, 420),
    MainWindowPos = isMobile and UDim2.new(0.5, -140, 0.5, -190) or UDim2.new(0.5, -175, 0.5, -210),
    TopBarHeight = 40,
    TabBarHeight = 35,
    CornerRadius = UDim.new(0, 8),
    BorderThickness = 1.5,
    
    -- Toggle/Button sizing
    ToggleHeight = 35,
    SliderHeight = 45,
    DropdownHeight = 35,
    ButtonHeight = 35,
    SectionHeight = 20,
    
    -- Padding
    PaddingStandard = UDim.new(0, 8),
    PaddingSmall = UDim.new(0, 5),
    PaddingLarge = UDim.new(0, 10),
}

-- ==========================================
-- DEFAULT CONFIGURATION
-- ==========================================
Constants.DefaultConfig = {
    -- Aimbot
    aimEnabled = false,
    aimPart = "Dynamic",
    prediction = 0,
    
    -- Aimbot Settings
    showFov = true,
    teamCheck = true,
    wallCheck = true,
    fov = 150,
    smoothing = 0.6,
    headshotChance = 50,
    
    -- Silent Aim (Mobile/UNC feature)
    silentAimEnabled = false,
    silentAimMode = "Camera",  -- "Camera" or "Silent"
    
    -- ESP
    espEnabled = false,
    espHighlight = true,
    espBox = false,
    espHealth = false,
    espTracer = false,
    espNames = false,
    espDistance = false,
    
    -- Misc
    targetInfo = true,
    watermark = true,
    menuKeybind = Enum.KeyCode.RightShift,
}

-- ==========================================
-- UI ELEMENT CONFIGURATIONS
-- ==========================================
Constants.LoadingScreen = {
    Width = 300,
    Height = 100,
    Duration = 1.0,
    FadeOutDuration = 0.5,
}

Constants.Watermark = {
    Width = 0,
    Height = 25,
    Position = UDim2.new(0, 20, 0, 20),
    AutomaticSize = Enum.AutomaticSize.X,
}

Constants.TargetUI = {
    Width = 180,
    Height = 60,
    Position = UDim2.new(0.5, 100, 0.5, 50),
}

-- ==========================================
-- ANIMATION TWEENS
-- ==========================================
Constants.Animations = {
    FastTween = TweenInfo.new(0.1),
    FastDuration = 0.1,
    
    MediumTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
    MediumDuration = 0.2,
    
    SlowTween = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    SlowDuration = 0.5,
    
    LoadingTween = TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    LoadingDuration = 1.0,
}

-- ==========================================
-- ESP CONSTANTS
-- ==========================================
Constants.ESP = {
    BoxStrokeThickness = 1.5,
    HealthBarWidth = 3,
    HealthBarOffset = 6,
    TracerWidth = 1,
    TextSize = 11,
    HighlightFillTransparency = 0.5,
}

return Constants

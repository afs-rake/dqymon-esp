--[[
    DqymonESP - Constants & Theme
    Central location for all colors, theme values, and configuration defaults
]]

local Constants = {}

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
-- UI SIZING CONSTANTS
-- ==========================================
Constants.UI = {
    MainWindowSize = UDim2.new(0, 350, 0, 420),
    MainWindowPos = UDim2.new(0.5, -175, 0.5, -210),
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
    MediumTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
    SlowTween = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    LoadingTween = TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
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

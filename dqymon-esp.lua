--[[
    DqymonESP - Main Script
    Refactored for modularity, stability, and performance
]]

local success, err = pcall(function()
    -- ==========================================
    -- DEPENDENCY LOADING
    -- ==========================================
    local Constants, UILibrary, ConfigSystem, Utils
    
    -- Try require() first (for module placement in Roblox)
    if script.Parent then
        pcall(function()
            Constants = require(script.Parent:FindFirstChild("dqymon_constants"))
            UILibrary = require(script.Parent:FindFirstChild("dqymon_ui"))
            ConfigSystem = require(script.Parent:FindFirstChild("dqymon_config"))
            Utils = require(script.Parent:FindFirstChild("dqymon_utils"))
        end)
    end
    
    -- Fall back to _G (for HttpGet/Loader usage)
    Constants = Constants or _G.DqymonConstants or error("Missing dqymon_constants")
    UILibrary = UILibrary or _G.DqymonUILibrary or error("Missing dqymon_ui")
    ConfigSystem = ConfigSystem or _G.DqymonConfigSystem or error("Missing dqymon_config")
    Utils = Utils or _G.DqymonUtils or error("Missing dqymon_utils")
    
    -- Print capability report
    print(Utils.GetCapabilityReport())
    
    -- ==========================================
    -- SERVICES & VARIABLES
    -- ==========================================
    local plrs = game:GetService("Players")
    local lplr = plrs.LocalPlayer
    local cam = workspace.CurrentCamera
    local runService = game:GetService("RunService")
    local uis = game:GetService("UserInputService")
    local ts = game:GetService("TweenService")
    local stats = game:GetService("Stats")
    local mouse = lplr:GetMouse()
    local coreGui = game:GetService("CoreGui") or lplr:FindFirstChild("PlayerGui")
    
    if coreGui:FindFirstChild("GhostMenu") then
        coreGui.GhostMenu:Destroy()
    end
    
    -- State management
    local lockedTarget = nil
    local currentTargetChar = nil
    local connections = {}
    local espObjects = {}
    local switchTimer = 0

    local sg = Instance.new("ScreenGui")
    sg.Name = "GhostMenu"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = coreGui

    -- ==========================================
    -- LOADING SCREEN
    -- ==========================================
    local function ShowLoadingScreen()
        local loadFrame = Instance.new("Frame", sg)
        loadFrame.Size = UDim2.new(0, Constants.LoadingScreen.Width, 0, Constants.LoadingScreen.Height)
        loadFrame.Position = UDim2.new(0.5, -Constants.LoadingScreen.Width/2, 0.5, -Constants.LoadingScreen.Height/2)
        loadFrame.BackgroundColor3 = Constants.Colors.BgDark
        loadFrame.BorderSizePixel = 0
        Instance.new("UICorner", loadFrame).CornerRadius = Constants.UI.CornerRadius
        
        local loadStroke = Instance.new("UIStroke", loadFrame)
        loadStroke.Color = Constants.Colors.Primary
        loadStroke.Thickness = 1.5
        
        local loadTitle = Instance.new("TextLabel", loadFrame)
        loadTitle.Size = UDim2.new(1, 0, 0, 40)
        loadTitle.Position = UDim2.new(0, 0, 0, 10)
        loadTitle.BackgroundTransparency = 1
        loadTitle.Text = "DQYMON ESP"
        loadTitle.TextColor3 = Constants.Colors.Primary
        loadTitle.Font = Enum.Font.GothamBlack
        loadTitle.TextSize = 20
        
        local loadSub = Instance.new("TextLabel", loadFrame)
        loadSub.Size = UDim2.new(1, 0, 0, 20)
        loadSub.Position = UDim2.new(0, 0, 0, 40)
        loadSub.BackgroundTransparency = 1
        loadSub.Text = "Initializing Auto-Load System..."
        loadSub.TextColor3 = Constants.Colors.TextDark
        loadSub.Font = Enum.Font.Gotham
        loadSub.TextSize = 12
        
        local barBg = Instance.new("Frame", loadFrame)
        barBg.Size = UDim2.new(0.8, 0, 0, 6)
        barBg.Position = UDim2.new(0.1, 0, 0.75, 0)
        barBg.BackgroundColor3 = Constants.Colors.MediumGray
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
        
        local barFill = Instance.new("Frame", barBg)
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = Constants.Colors.Primary
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
        
        ts:Create(barFill, Constants.Animations.LoadingTween, {Size = UDim2.new(1, 0, 1, 0)}):Play()
        task.wait(Constants.LoadingScreen.Duration)
        
        ts:Create(loadFrame, Constants.Animations.SlowTween, {BackgroundTransparency = 1}):Play()
        loadStroke:Destroy()
        ts:Create(loadTitle, Constants.Animations.SlowTween, {TextTransparency = 1}):Play()
        ts:Create(loadSub, Constants.Animations.SlowTween, {TextTransparency = 1}):Play()
        ts:Create(barBg, Constants.Animations.SlowTween, {BackgroundTransparency = 1}):Play()
        ts:Create(barFill, Constants.Animations.SlowTween, {BackgroundTransparency = 1}):Play()
        task.wait(Constants.Animations.SlowTween.Length or 0.5)
        loadFrame:Destroy()
    end
    
    ShowLoadingScreen()
    -- ==========================================
    -- INITIALIZE CONFIG SYSTEM
    -- ==========================================
    local configSystem = ConfigSystem:New("DqymonESP_Config.json", Constants.DefaultConfig)
    
    -- ==========================================
    -- UI COMPONENTS
    -- ==========================================
    local watermark = Instance.new("TextLabel", sg)
    watermark.Size = UDim2.new(0, 0, 0, Constants.Watermark.Height)
    watermark.AutomaticSize = Enum.AutomaticSize.X
    watermark.Position = Constants.Watermark.Position
    watermark.BackgroundColor3 = Constants.Colors.BgPanel
    watermark.BackgroundTransparency = 0.3
    watermark.TextColor3 = Constants.Colors.TextLight
    watermark.Font = Enum.Font.GothamSemibold
    watermark.TextSize = 12
    watermark.Text = "DqymonESP | FPS: -- | Ping: --"
    watermark.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", watermark).CornerRadius = Constants.UI.CornerRadius
    
    local wmPadding = Instance.new("UIPadding", watermark)
    wmPadding.PaddingLeft = Constants.UI.PaddingLarge
    wmPadding.PaddingRight = Constants.UI.PaddingLarge
    
    local wmStroke = Instance.new("UIStroke", watermark)
    wmStroke.Color = Constants.Colors.Primary
    wmStroke.Thickness = 1
    
    -- Target Info UI
    local targetUI = Instance.new("Frame", sg)
    targetUI.Size = UDim2.new(0, Constants.TargetUI.Width, 0, Constants.TargetUI.Height)
    targetUI.Position = Constants.TargetUI.Position
    targetUI.BackgroundColor3 = Constants.Colors.BgPanel
    targetUI.BackgroundTransparency = 0.2
    targetUI.Visible = false
    Instance.new("UICorner", targetUI).CornerRadius = Constants.UI.CornerRadius
    Instance.new("UIStroke", targetUI).Color = Constants.Colors.Primary
    
    local tName = Instance.new("TextLabel", targetUI)
    tName.Size = UDim2.new(1, -10, 0, 20)
    tName.Position = UDim2.new(0, 10, 0, 5)
    tName.BackgroundTransparency = 1
    tName.TextColor3 = Constants.Colors.Primary
    tName.Font = Enum.Font.GothamBold
    tName.TextSize = 13
    tName.TextXAlignment = Enum.TextXAlignment.Left
    
    local tHealth = Instance.new("TextLabel", targetUI)
    tHealth.Size = UDim2.new(1, -10, 0, 20)
    tHealth.Position = UDim2.new(0, 10, 0, 25)
    tHealth.BackgroundTransparency = 1
    tHealth.TextColor3 = Constants.Colors.TextLight
    tHealth.Font = Enum.Font.Gotham
    tHealth.TextSize = 12
    tHealth.TextXAlignment = Enum.TextXAlignment.Left
    
    -- FOV Circle
    local fovCircle = Instance.new("Frame", sg)
    fovCircle.Size = UDim2.new(0, configSystem:Get("fov") * 2, 0, configSystem:Get("fov") * 2)
    fovCircle.Position = UDim2.new(0.5, -configSystem:Get("fov"), 0.5, -configSystem:Get("fov"))
    fovCircle.BackgroundColor3 = Constants.Colors.White
    fovCircle.BackgroundTransparency = 0.9
    fovCircle.BorderSizePixel = 0
    fovCircle.Visible = configSystem:Get("showFov")
    Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", fovCircle).Color = Constants.Colors.Primary
    
    -- =========================================                   
    -- CREATE MAIN UI WINDOW
    -- ==========================================
    local MainUI = UILibrary:CreateWindow("DQYMON ESP", sg, connections)
    
    local TabAimbot = MainUI:CreateTab("Aimbot")
    local TabVisuals = MainUI:CreateTab("Visuals")
    local TabMisc = MainUI:CreateTab("Misc")
    local TabSettings = MainUI:CreateTab("Settings")
    
    -- ==========================================
    -- SETUP UI ELEMENTS & CONFIG MAPPING
    -- ==========================================
    
    -- AIMBOT TAB
    TabAimbot:CreateSection("Main Control")
    TabAimbot:CreateToggle("Enable Aimbot", configSystem:Get("aimEnabled"), function(val) configSystem:Set("aimEnabled", val) end)
    TabAimbot:CreateDropdown("Target Part", {"Head", "Torso", "Dynamic"}, (function() local p = configSystem:Get("aimPart"); if p == "Head" then return 1 elseif p == "Torso" then return 2 else return 3 end end)(), function(val) configSystem:Set("aimPart", val) end)
    TabAimbot:CreateSlider("Prediction (Velocity)", 0, 10, configSystem:Get("prediction") * 10, function(val) configSystem:Set("prediction", val / 10) end)
    
    TabAimbot:CreateSection("Settings")
    TabAimbot:CreateToggle("Show FOV", configSystem:Get("showFov"), function(val) 
        configSystem:Set("showFov", val)
        fovCircle.Visible = val 
    end)
    TabAimbot:CreateToggle("Wall Check", configSystem:Get("wallCheck"), function(val) configSystem:Set("wallCheck", val) end)
    TabAimbot:CreateToggle("Team Check", configSystem:Get("teamCheck"), function(val) configSystem:Set("teamCheck", val) end)
    TabAimbot:CreateSlider("FOV Size", 50, 500, configSystem:Get("fov"), function(val) 
        configSystem:Set("fov", val)
        fovCircle.Size = UDim2.new(0, val * 2, 0, val * 2)
    end)
    TabAimbot:CreateSlider("Smoothness", 10, 100, configSystem:Get("smoothing") * 100, function(val) configSystem:Set("smoothing", val / 100) end)
    TabAimbot:CreateSlider("Dynamic Headshot %", 0, 100, configSystem:Get("headshotChance"), function(val) configSystem:Set("headshotChance", val) end)
    
    -- Silent Aim (Mobile/UNC only)
    if Constants.Capabilities.Level == "FULL_UNC" then
        TabAimbot:CreateSection("Silent Aim (Mobile UNC)")
        TabAimbot:CreateToggle("Enable Silent Aim", configSystem:Get("silentAimEnabled"), function(val) configSystem:Set("silentAimEnabled", val) end)
        TabAimbot:CreateDropdown("Silent Aim Mode", {"Camera", "Silent"}, (function() local m = configSystem:Get("silentAimMode"); return m == "Silent" and 2 or 1 end)(), function(val) configSystem:Set("silentAimMode", val) end)
    end
    
    -- VISUALS TAB
    TabVisuals:CreateSection("Master Switch")
    TabVisuals:CreateToggle("Enable ESP", configSystem:Get("espEnabled"), function(val) configSystem:Set("espEnabled", val) end)
    
    TabVisuals:CreateSection("ESP Elements")
    TabVisuals:CreateToggle("2D Box", configSystem:Get("espBox"), function(val) configSystem:Set("espBox", val) end)
    TabVisuals:CreateToggle("Health Bar", configSystem:Get("espHealth"), function(val) configSystem:Set("espHealth", val) end)
    TabVisuals:CreateToggle("Tracers", configSystem:Get("espTracer"), function(val) configSystem:Set("espTracer", val) end)
    TabVisuals:CreateToggle("Names", configSystem:Get("espNames"), function(val) configSystem:Set("espNames", val) end)
    TabVisuals:CreateToggle("Distance", configSystem:Get("espDistance"), function(val) configSystem:Set("espDistance", val) end)
    TabVisuals:CreateToggle("Chams (Highlight)", configSystem:Get("espHighlight"), function(val) configSystem:Set("espHighlight", val) end)
    
    -- MISC TAB
    TabMisc:CreateSection("Overlays")
    TabMisc:CreateToggle("Watermark", configSystem:Get("watermark"), function(val) 
        configSystem:Set("watermark", val)
        watermark.Visible = val 
    end)
    TabMisc:CreateToggle("Target Info", configSystem:Get("targetInfo"), function(val) 
        configSystem:Set("targetInfo", val)
        if not val then targetUI.Visible = false end 
    end)
    
    -- SETTINGS TAB
    TabSettings:CreateSection("Configuration Profiles")
    
    TabSettings:CreateButton("Save Config", function(btn)
        local saveSuccess = configSystem:Save()
        btn.Text = saveSuccess and "Config Saved!" or "Save Failed!"
        task.wait(1.5)
        btn.Text = "Save Config"
    end)
    
    TabSettings:CreateButton("Load Config", function(btn)
        local loadSuccess = configSystem:Load()
        btn.Text = loadSuccess and "Config Loaded!" or "No Config Found!"
        task.wait(1.5)
        btn.Text = "Load Config"
    end)
    
    TabSettings:CreateButton("Reset to Defaults", function(btn)
        configSystem:Reset()
        btn.Text = "Reset Complete!"
        task.wait(1.5)
        btn.Text = "Reset to Defaults"
    end)
    
    TabSettings:CreateSection("Destruction")
    TabSettings:CreateButton("Unload Script", function()
        for _, conn in ipairs(connections) do 
            pcall(function() conn:Disconnect() end)
        end
        for _, obj in pairs(espObjects) do
            if obj.box then pcall(function() obj.box:Destroy() end) end
            if obj.healthBg then pcall(function() obj.healthBg:Destroy() end) end
            if obj.tracer then pcall(function() obj.tracer:Destroy() end) end
            if obj.text then pcall(function() obj.text:Destroy() end) end
            if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
        end
        sg:Destroy()
    end)
    
    -- ==========================================
    -- REGISTER UI UPDATERS WITH CONFIG
    -- ==========================================
    configSystem:RegisterUIUpdaters(MainUI.UIUpdaters)
    
    -- Auto-load config
    task.spawn(function()
        task.wait(0.5)
        configSystem:Load()
    end)
    
    -- ==========================================
    -- MENU TOGGLE (Desktop & Mobile compatible)
    -- ==========================================
    if Constants.IsDesktop then
        -- Desktop: Keyboard toggle
        table.insert(connections, uis.InputBegan:Connect(function(input, gpe)
            if not gpe and input.KeyCode == configSystem:Get("menuKeybind") and MainUI.MainFrame then 
                MainUI.MainFrame.Visible = not MainUI.MainFrame.Visible 
            end
        end))
    else
        -- Mobile: Add on-screen toggle button
        local toggleBtn = Instance.new("TextButton", sg)
        toggleBtn.Size = UDim2.new(0, 60, 0, 60)
        toggleBtn.Position = UDim2.new(0, 10, 0, 10)
        toggleBtn.BackgroundColor3 = Constants.Colors.Primary
        toggleBtn.BackgroundTransparency = 0.3
        toggleBtn.TextColor3 = Constants.Colors.TextLight
        toggleBtn.Text = "MENU"
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 11
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", toggleBtn).Color = Constants.Colors.Primary
        
        table.insert(connections, toggleBtn.MouseButton1Click:Connect(function()
            if MainUI.MainFrame then 
                MainUI.MainFrame.Visible = not MainUI.MainFrame.Visible 
            end
        end))
    end
    
    -- ==========================================
    -- ESP CORE LOGIC
    -- ==========================================
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local function UpdateRaycastFilter()
        if lplr and lplr.Character then 
            rayParams.FilterDescendantsInstances = {lplr.Character, cam}
        end
    end
    
    UpdateRaycastFilter()
    table.insert(connections, lplr.CharacterAdded:Connect(UpdateRaycastFilter))
    
    local function IsVisible(targetPart)
        if not configSystem:Get("wallCheck") or not targetPart then 
            return not targetPart and false or true 
        end
        
        local result = workspace:Raycast(cam.CFrame.Position, targetPart.Position - cam.CFrame.Position, rayParams)
        return not result or result.Instance:IsDescendantOf(targetPart.Parent)
    end
    
    local function CreateESPUI(plr)
        local objects = {}
        
        local box = Instance.new("Frame", sg)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color = Constants.Colors.Primary
        boxStroke.Thickness = Constants.ESP.BoxStrokeThickness
        objects.box = box
        
        local healthBg = Instance.new("Frame", sg)
        healthBg.BackgroundColor3 = Constants.Colors.HealthBar
        healthBg.BorderSizePixel = 0
        local healthFill = Instance.new("Frame", healthBg)
        healthFill.BackgroundColor3 = Constants.Colors.HealthGood
        healthFill.BorderSizePixel = 0
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.AnchorPoint = Vector2.new(0, 1)
        healthFill.Position = UDim2.new(0, 0, 1, 0)
        objects.healthBg = healthBg
        objects.healthFill = healthFill
        
        local tracer = Instance.new("Frame", sg)
        tracer.BackgroundColor3 = Constants.Colors.Primary
        tracer.BorderSizePixel = 0
        tracer.Size = UDim2.new(0, Constants.ESP.TracerWidth, 0, 0)
        tracer.AnchorPoint = Vector2.new(0.5, 0)
        objects.tracer = tracer
        
        local text = Instance.new("TextLabel", sg)
        text.BackgroundTransparency = 1
        text.TextColor3 = Constants.Colors.TextLight
        text.Font = Enum.Font.GothamBold
        text.TextSize = Constants.ESP.TextSize
        Instance.new("UIStroke", text).Thickness = 1
        objects.text = text
        
        return objects
    end
    
    local function GetBoundingBox(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        
        local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
        if not onScreen then return nil end
        
        local head = char:FindFirstChild("Head")
        local headPos = head and cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2, 0))
        local legPos = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        
        local height = legPos.Y - headPos.Y
        local width = height / 2
        
        return { x = headPos.X - (width / 2), y = headPos.Y, w = width, h = height, onScreen = onScreen }
    end
    
    -- ==========================================
    -- RENDER LOOP
    -- ==========================================
    local fpsCount = 0
    local lastTime = tick()
    
    table.insert(connections, runService.RenderStepped:Connect(function(dt)
        fpsCount = fpsCount + 1
        
        -- Update watermark
        if tick() - lastTime >= 1 then
            local pingStr = tostring(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            local ping = string.split(pingStr, ".")[1]
            if configSystem:Get("watermark") then
                watermark.Text = string.format("DqymonESP | FPS: %d | Ping: %sms", fpsCount, ping)
            end
            fpsCount = 0
            lastTime = tick()
        end
        
    -- ==========================================
    -- AIMBOT ACTIVATION (Desktop vs Mobile)
    -- ==========================================
    local aimActive = false
    
    if Constants.IsDesktop then
        -- Desktop: Mouse button press
        table.insert(connections, uis.InputBegan:Connect(function(input, gpe)
            if not gpe and input.UserInputType == Enum.UserInputType.MouseButton1 then
                aimActive = configSystem:Get("aimEnabled")
            end
        end))
        
        table.insert(connections, uis.InputEnded:Connect(function(input, gpe)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                aimActive = false
            end
        end))
    else
        -- Mobile: Add on-screen aimbot toggle button
        local aimBtn = Instance.new("TextButton", sg)
        aimBtn.Size = UDim2.new(0, 60, 0, 60)
        aimBtn.Position = UDim2.new(1, -80, 0, 10)
        aimBtn.BackgroundColor3 = Constants.Colors.Secondary
        aimBtn.BackgroundTransparency = 0.3
        aimBtn.TextColor3 = Constants.Colors.TextLight
        aimBtn.Text = "AIM"
        aimBtn.Font = Enum.Font.GothamBold
        aimBtn.TextSize = 11
        Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", aimBtn).Color = Constants.Colors.Secondary
        
        table.insert(connections, aimBtn.MouseButton1Down:Connect(function()
            aimActive = configSystem:Get("aimEnabled")
            aimBtn.BackgroundTransparency = 0.1  -- Visual feedback
        end))
        
        table.insert(connections, aimBtn.MouseButton1Up:Connect(function()
            aimActive = false
            aimBtn.BackgroundTransparency = 0.3  -- Reset
        end))
    end
    
    -- FOV circle position (use mouse on desktop, center on mobile)
    table.insert(connections, runService.RenderStepped:Connect(function()
        if Constants.IsDesktop then
            fovCircle.Position = UDim2.new(0, mouse.X - configSystem:Get("fov"), 0, mouse.Y - configSystem:Get("fov"))
        else
            -- Mobile: Center FOV circle on screen
            fovCircle.Position = UDim2.new(0, cam.ViewportSize.X/2 - configSystem:Get("fov"), 0, cam.ViewportSize.Y/2 - configSystem:Get("fov"))
        end
    end))
    
    -- ==========================================
    -- AIMBOT LOGIC (Desktop & Mobile compatible)
    -- ==========================================
        
        -- ESP Rendering
        for _, plr in pairs(plrs:GetPlayers()) do
            if plr ~= lplr then
                if not espObjects[plr.UserId] then 
                    espObjects[plr.UserId] = CreateESPUI(plr) 
                end
                
                local esp = espObjects[plr.UserId]
                local char = plr.Character
                local isTeammate = configSystem:Get("teamCheck") and plr.Team ~= nil and plr.Team == lplr.Team
                
                if configSystem:Get("espEnabled") and char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and not isTeammate then
                    local bounds = GetBoundingBox(char)
                    
                    if bounds and bounds.onScreen then
                        -- 2D Box
                        if configSystem:Get("espBox") then
                            esp.box.Position = UDim2.new(0, bounds.x, 0, bounds.y)
                            esp.box.Size = UDim2.new(0, bounds.w, 0, bounds.h)
                            esp.box.Visible = true
                        else 
                            esp.box.Visible = false 
                        end
                        
                        -- Health Bar
                        if configSystem:Get("espHealth") then
                            local healthPct = char.Humanoid.Health / char.Humanoid.MaxHealth
                            esp.healthBg.Position = UDim2.new(0, bounds.x - Constants.ESP.HealthBarOffset, 0, bounds.y)
                            esp.healthBg.Size = UDim2.new(0, Constants.ESP.HealthBarWidth, 0, bounds.h)
                            esp.healthFill.Size = UDim2.new(1, 0, healthPct, 0)
                            esp.healthFill.BackgroundColor3 = Color3.fromRGB(255 - (healthPct * 255), healthPct * 255, 0)
                            esp.healthBg.Visible = true
                        else 
                            esp.healthBg.Visible = false 
                        end
                        
                        -- Names & Distance
                        if configSystem:Get("espNames") or configSystem:Get("espDistance") then
                            local txt = ""
                            if configSystem:Get("espNames") then txt = txt .. plr.Name .. "\n" end
                            if configSystem:Get("espDistance") then
                                local dist = math.floor((cam.CFrame.Position - char.HumanoidRootPart.Position).Magnitude)
                                txt = txt .. "[" .. dist .. "m]"
                            end
                            esp.text.Text = txt
                            esp.text.Position = UDim2.new(0, bounds.x + (bounds.w/2) - 50, 0, bounds.y - 25)
                            esp.text.Size = UDim2.new(0, 100, 0, 20)
                            esp.text.Visible = true
                        else 
                            esp.text.Visible = false 
                        end
                        
                        -- Tracers
                        if configSystem:Get("espTracer") then
                            local startPoint = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                            local endPoint = Vector2.new(bounds.x + (bounds.w/2), bounds.y + bounds.h)
                            local distance = (endPoint - startPoint).Magnitude
                            
                            esp.tracer.Position = UDim2.new(0, startPoint.X, 0, startPoint.Y)
                            esp.tracer.Size = UDim2.new(0, Constants.ESP.TracerWidth, 0, distance)
                            
                            local angle = math.deg(math.atan2(endPoint.Y - startPoint.Y, endPoint.X - startPoint.X)) + 90
                            esp.tracer.Rotation = angle
                            esp.tracer.Visible = true
                        else 
                            esp.tracer.Visible = false 
                        end
                        
                        -- Highlight
                        if configSystem:Get("espHighlight") then
                            if not esp.highlight then
                                esp.highlight = Instance.new("Highlight")
                                esp.highlight.FillColor = Constants.Colors.Primary
                                esp.highlight.OutlineColor = Constants.Colors.White
                                esp.highlight.FillTransparency = Constants.ESP.HighlightFillTransparency
                                esp.highlight.Parent = char
                            end
                            esp.highlight.Enabled = true
                        elseif esp.highlight then 
                            esp.highlight.Enabled = false 
                        end
                    else
                        esp.box.Visible = false
                        esp.healthBg.Visible = false
                        esp.text.Visible = false
                        esp.tracer.Visible = false
                        if esp.highlight then esp.highlight.Enabled = false end
                    end
                else
                    esp.box.Visible = false
                    esp.healthBg.Visible = false
                    esp.text.Visible = false
                    esp.tracer.Visible = false
                    if esp.highlight then esp.highlight.Enabled = false end
                end
            end
        end
        
        -- ==========================================
        -- AIMBOT LOGIC (Desktop & Mobile compatible)
        -- ==========================================
        if aimActive then
            -- Get center or mouse position based on platform
            local aimOrigin = Constants.IsDesktop and Vector2.new(mouse.X, mouse.Y) or Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            
            if currentTargetChar and currentTargetChar:FindFirstChild("Humanoid") and currentTargetChar.Humanoid.Health > 0 then
                local hrp = currentTargetChar:FindFirstChild("HumanoidRootPart")
                local head = currentTargetChar:FindFirstChild("Head")
                
                if hrp and head then
                    if configSystem:Get("aimPart") == "Head" then 
                        lockedTarget = head
                    elseif configSystem:Get("aimPart") == "Torso" then 
                        lockedTarget = hrp
                    else
                        switchTimer = switchTimer + dt
                        if switchTimer >= 0.2 then
                            switchTimer = 0
                            lockedTarget = (math.random(1, 100) <= configSystem:Get("headshotChance")) and head or hrp
                        end
                    end
                    
                    if lockedTarget then
                        local targetVelocity = hrp.AssemblyLinearVelocity
                        local predictedPos = lockedTarget.Position + (targetVelocity * configSystem:Get("prediction"))
                        local pos, onScreen = cam:WorldToViewportPoint(predictedPos)
                        local dist = (Vector2.new(pos.X, pos.Y) - aimOrigin).Magnitude
                        
                        if not onScreen or dist > configSystem:Get("fov") or not IsVisible(lockedTarget) then
                            currentTargetChar = nil
                            lockedTarget = nil
                        end
                    end
                else 
                    currentTargetChar = nil
                    lockedTarget = nil 
                end
            end
            
            if not currentTargetChar then
                local bestDist = configSystem:Get("fov")
                local bestChar = nil
                
                for _, plr in pairs(plrs:GetPlayers()) do
                    if plr ~= lplr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                        local isTeammate = configSystem:Get("teamCheck") and plr.Team ~= nil and plr.Team == lplr.Team
                        if isTeammate then continue end
                        
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                            local mDist = (Vector2.new(pos.X, pos.Y) - aimOrigin).Magnitude
                            
                            if onScreen and mDist < bestDist and IsVisible(hrp) then
                                bestDist = mDist
                                bestChar = plr.Character
                            end
                        end
                    end
                end
                
                if bestChar then
                    currentTargetChar = bestChar
                    local tPart = bestChar:FindFirstChild("HumanoidRootPart")
                    if configSystem:Get("aimPart") == "Head" then 
                        tPart = bestChar:FindFirstChild("Head") 
                    end
                    lockedTarget = tPart
                end
            end
            
            if lockedTarget and currentTargetChar then
                local hrp = currentTargetChar:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local predictedPos = lockedTarget.Position + (hrp.AssemblyLinearVelocity * configSystem:Get("prediction"))
                    
                    -- Silent Aim handling
                    if configSystem:Get("silentAimEnabled") then
                        Utils.SetSilentAimTarget(predictedPos)
                        
                        if configSystem:Get("silentAimMode") == "Silent" then
                            -- Pure silent aim: Don't move camera at all
                            -- Silent aim target is set for hit detection hooks
                        else
                            -- Camera mode: Move camera for visual aid on mobile
                            local targetCFrame = CFrame.new(cam.CFrame.Position, predictedPos)
                            local smoothFactor = math.clamp(configSystem:Get("smoothing") * (dt * 60), 0, 1)
                            Utils.OptimizedCameraLerp(cam, cam.CFrame, targetCFrame, smoothFactor)
                        end
                    else
                        -- Regular visible aimbot
                        local targetCFrame = CFrame.new(cam.CFrame.Position, predictedPos)
                        local smoothFactor = math.clamp(configSystem:Get("smoothing") * (dt * 60), 0, 1)
                        Utils.OptimizedCameraLerp(cam, cam.CFrame, targetCFrame, smoothFactor)
                    end
                    
                    if configSystem:Get("targetInfo") then
                        local targetPlayer = plrs:GetPlayerFromCharacter(currentTargetChar)
                        local hp = math.floor(currentTargetChar.Humanoid.Health)
                        local dist = math.floor((cam.CFrame.Position - currentTargetChar.HumanoidRootPart.Position).Magnitude)
                        
                        tName.Text = "Target: " .. (targetPlayer and targetPlayer.Name or "Unknown")
                        tHealth.Text = "HP: " .. hp .. " | Dist: " .. dist .. "m"
                        targetUI.Visible = true
                    else 
                        targetUI.Visible = false 
                    end
                end
            else 
                targetUI.Visible = false 
            end
        else 
            currentTargetChar = nil
            lockedTarget = nil
            switchTimer = 0
            targetUI.Visible = false 
        end
    end))
    
    -- Cleanup ESP objects when players leave
    table.insert(connections, plrs.PlayerRemoving:Connect(function(plr)
        if espObjects[plr.UserId] then
            for _, obj in pairs(espObjects[plr.UserId]) do 
                pcall(function() obj:Destroy() end)
            end
            espObjects[plr.UserId] = nil
        end
    end))

end)

if not success then 
    print("\n❌ ❌ ❌ DQYMON ESP ERROR ❌ ❌ ❌")
    print("Error Details:")
    print(tostring(err))
    print("\nStack Trace:")
    print(debug.traceback())
    print(string.rep("=", 40))
    warn("DqymonESP Error: " .. tostring(err))
else
    print("\n✅ ✅ ✅ DQYMON ESP LOADED ✅ ✅ ✅\n")
end
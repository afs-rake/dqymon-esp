--[[
    DqymonESP
]]

local success, err = pcall(function()
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
    local httpService = game:GetService("HttpService")
    local mouse = lplr:GetMouse()
    local coreGui = game:GetService("CoreGui") or lplr:FindFirstChild("PlayerGui")
    
    if coreGui:FindFirstChild("GhostMenu") then
        coreGui.GhostMenu:Destroy()
    end

    local configs = {
        aimEnabled = false, aimPart = "Dynamic", prediction = 0,
        showFov = true, teamCheck = true, wallCheck = true,
        fov = 150, smoothing = 0.6, headshotChance = 50,
        espEnabled = false, espHighlight = true, espBox = false,
        espHealth = false, espTracer = false, espNames = false, espDistance = false,
        targetInfo = true, watermark = true,
        menuKeybind = Enum.KeyCode.RightShift
    }

    local UIUpdaters = { Toggles = {}, Sliders = {}, Dropdowns = {} }
    local lockedTarget = nil
    local currentTargetChar = nil
    local connections = {}
    local espObjects = {}

    local sg = Instance.new("ScreenGui")
    sg.Name = "GhostMenu"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = coreGui

    -- ==========================================
    -- 0. LOADING UI SYSTEM 
    -- ==========================================
    local loadFrame = Instance.new("Frame", sg)
    loadFrame.Size = UDim2.new(0, 300, 0, 100)
    loadFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    loadFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    loadFrame.BorderSizePixel = 0
    Instance.new("UICorner", loadFrame).CornerRadius = UDim.new(0, 8)
    local loadStroke = Instance.new("UIStroke", loadFrame)
    loadStroke.Color = Color3.fromRGB(0, 200, 200)
    loadStroke.Thickness = 1.5

    local loadTitle = Instance.new("TextLabel", loadFrame)
    loadTitle.Size = UDim2.new(1, 0, 0, 40)
    loadTitle.Position = UDim2.new(0, 0, 0, 10)
    loadTitle.BackgroundTransparency = 1
    loadTitle.Text = "DQYMON ESP"
    loadTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
    loadTitle.Font = Enum.Font.GothamBlack
    loadTitle.TextSize = 20

    local loadSub = Instance.new("TextLabel", loadFrame)
    loadSub.Size = UDim2.new(1, 0, 0, 20)
    loadSub.Position = UDim2.new(0, 0, 0, 40)
    loadSub.BackgroundTransparency = 1
    loadSub.Text = "Initializing Auto-Load System..."
    loadSub.TextColor3 = Color3.fromRGB(150, 150, 150)
    loadSub.Font = Enum.Font.Gotham
    loadSub.TextSize = 12

    local barBg = Instance.new("Frame", loadFrame)
    barBg.Size = UDim2.new(0.8, 0, 0, 6)
    barBg.Position = UDim2.new(0.1, 0, 0.75, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame", barBg)
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    ts:Create(barFill, TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    task.wait(1.0)

    ts:Create(loadFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    loadStroke:Destroy()
    ts:Create(loadTitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    ts:Create(loadSub, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    ts:Create(barBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    ts:Create(barFill, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    task.wait(0.5)
    loadFrame:Destroy()

    -- ==========================================
    -- 1. WATERMARK & TARGET INFO 
    -- ==========================================
    local watermark = Instance.new("TextLabel", sg)
    watermark.Size = UDim2.new(0, 0, 0, 25)
    watermark.AutomaticSize = Enum.AutomaticSize.X
    watermark.Position = UDim2.new(0, 20, 0, 20)
    watermark.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    watermark.BackgroundTransparency = 0.3
    watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
    watermark.Font = Enum.Font.GothamSemibold
    watermark.TextSize = 12
    watermark.Text = "DqymonESP | FPS: -- | Ping: --"
    watermark.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", watermark).CornerRadius = UDim.new(0, 6)
    
    local wmPadding = Instance.new("UIPadding", watermark)
    wmPadding.PaddingLeft = UDim.new(0, 10)
    wmPadding.PaddingRight = UDim.new(0, 10)
    local wmStroke = Instance.new("UIStroke", watermark)
    wmStroke.Color = Color3.fromRGB(0, 255, 255)
    wmStroke.Thickness = 1
    
    local targetUI = Instance.new("Frame", sg)
    targetUI.Size = UDim2.new(0, 180, 0, 60)
    targetUI.Position = UDim2.new(0.5, 100, 0.5, 50)
    targetUI.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    targetUI.BackgroundTransparency = 0.2
    targetUI.Visible = false
    Instance.new("UICorner", targetUI).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", targetUI).Color = Color3.fromRGB(0, 255, 255)
    
    local tName = Instance.new("TextLabel", targetUI)
    tName.Size = UDim2.new(1, -10, 0, 20)
    tName.Position = UDim2.new(0, 10, 0, 5)
    tName.BackgroundTransparency = 1
    tName.TextColor3 = Color3.fromRGB(0, 255, 255)
    tName.Font = Enum.Font.GothamBold
    tName.TextSize = 13
    tName.TextXAlignment = Enum.TextXAlignment.Left
    
    local tHealth = Instance.new("TextLabel", targetUI)
    tHealth.Size = UDim2.new(1, -10, 0, 20)
    tHealth.Position = UDim2.new(0, 10, 0, 25)
    tHealth.BackgroundTransparency = 1
    tHealth.TextColor3 = Color3.fromRGB(255, 255, 255)
    tHealth.Font = Enum.Font.Gotham
    tHealth.TextSize = 12
    tHealth.TextXAlignment = Enum.TextXAlignment.Left

    -- ==========================================
    -- 2. PREMIUM UI LIBRARY
    -- ==========================================
    local Library = {}
    local activeWindow = nil

    local function MakeDraggable(topbarobject, object)
        local dragging, dragInput, mousePos, framePos
        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; mousePos = input.Position; framePos = object.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        table.insert(connections, uis.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                object.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            end
        end))
    end

    function Library:CreateWindow(titleText)
        local Window = {}
        local mainFrame = Instance.new("Frame", sg)
        mainFrame.Size = UDim2.new(0, 350, 0, 420) 
        mainFrame.Position = UDim2.new(0.5, -175, 0.5, -210)
        mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        mainFrame.BorderSizePixel = 0
        mainFrame.ClipsDescendants = true
        Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
        
        local dropShadow = Instance.new("UIStroke", mainFrame)
        dropShadow.Color = Color3.fromRGB(0, 200, 200)
        dropShadow.Thickness = 1.5
        dropShadow.Transparency = 0.5

        activeWindow = mainFrame

        local topBar = Instance.new("Frame", mainFrame)
        topBar.Size = UDim2.new(1, 0, 0, 40)
        topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        topBar.BorderSizePixel = 0
        Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)
        local topBarFix = Instance.new("Frame", topBar)
        topBarFix.Size = UDim2.new(1, 0, 0, 8)
        topBarFix.Position = UDim2.new(0, 0, 1, -8)
        topBarFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        topBarFix.BorderSizePixel = 0

        local title = Instance.new("TextLabel", topBar)
        title.Size = UDim2.new(1, 0, 1, 0)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = titleText
        title.TextColor3 = Color3.fromRGB(0, 255, 255)
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Center

        MakeDraggable(topBar, mainFrame)

        local tabBar = Instance.new("Frame", mainFrame)
        tabBar.Size = UDim2.new(1, 0, 0, 35)
        tabBar.Position = UDim2.new(0, 0, 0, 40)
        tabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        tabBar.BorderSizePixel = 0

        local tabLayout = Instance.new("UIListLayout", tabBar)
        tabLayout.FillDirection = Enum.FillDirection.Horizontal
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local contentArea = Instance.new("Frame", mainFrame)
        contentArea.Size = UDim2.new(1, 0, 1, -75)
        contentArea.Position = UDim2.new(0, 0, 0, 75)
        contentArea.BackgroundTransparency = 1

        local activeTabScroll = nil
        local activeTabText = nil
        local activeTabLine = nil
        local firstTab = true

        mainFrame.Size = UDim2.new(0, 350, 0, 0)
        ts:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 420)}):Play()

        function Window:CreateTab(tabName)
            local Tab = {}
            local tabBtn = Instance.new("TextButton", tabBar)
            tabBtn.Size = UDim2.new(0.25, 0, 1, 0) 
            tabBtn.BackgroundTransparency = 1
            tabBtn.Text = ""
            
            local tabText = Instance.new("TextLabel", tabBtn)
            tabText.Size = UDim2.new(1, 0, 1, 0)
            tabText.BackgroundTransparency = 1
            tabText.Text = tabName
            tabText.TextColor3 = Color3.fromRGB(150, 150, 150)
            tabText.Font = Enum.Font.GothamSemibold
            tabText.TextSize = 13
            
            local tabLine = Instance.new("Frame", tabBtn)
            tabLine.Size = UDim2.new(0.6, 0, 0, 2) 
            tabLine.AnchorPoint = Vector2.new(0.5, 0)
            tabLine.Position = UDim2.new(0.5, 0, 1, -2)
            tabLine.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
            tabLine.BorderSizePixel = 0
            tabLine.Visible = false

            local container = Instance.new("ScrollingFrame", contentArea)
            container.Size = UDim2.new(1, 0, 1, 0)
            container.BackgroundTransparency = 1
            container.BorderSizePixel = 0
            container.ScrollBarThickness = 3
            container.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
            container.Visible = false

            local layout = Instance.new("UIListLayout", container)
            layout.Padding = UDim.new(0, 8)
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.SortOrder = Enum.SortOrder.LayoutOrder

            Instance.new("UIPadding", container).PaddingTop = UDim.new(0, 10)
            Instance.new("UIPadding", container).PaddingBottom = UDim.new(0, 10)

            tabBtn.MouseButton1Click:Connect(function()
                if activeTabScroll then activeTabScroll.Visible = false end
                if activeTabText then activeTabText.TextColor3 = Color3.fromRGB(150, 150, 150) end
                if activeTabLine then activeTabLine.Visible = false end

                container.Visible = true
                tabText.TextColor3 = Color3.fromRGB(0, 255, 255)
                tabLine.Visible = true

                activeTabScroll = container
                activeTabText = tabText
                activeTabLine = tabLine
            end)

            if firstTab then
                container.Visible = true; tabText.TextColor3 = Color3.fromRGB(0, 255, 255); tabLine.Visible = true
                activeTabScroll = container; activeTabText = tabText; activeTabLine = tabLine
                firstTab = false
            end

            function Tab:CreateSection(sectionName)
                local sec = Instance.new("TextLabel", container)
                sec.Size = UDim2.new(0.9, 0, 0, 20)
                sec.BackgroundTransparency = 1
                sec.Text = "  " .. sectionName
                sec.TextColor3 = Color3.fromRGB(0, 200, 200)
                sec.Font = Enum.Font.GothamBold
                sec.TextSize = 12
                sec.TextXAlignment = Enum.TextXAlignment.Left
                
                local line = Instance.new("Frame", sec)
                line.Size = UDim2.new(1, 0, 0, 1)
                line.Position = UDim2.new(0, 0, 1, 0)
                line.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                line.BorderSizePixel = 0
            end

            function Tab:CreateToggle(toggleText, defaultState, callback)
                local state = defaultState
                local toggleBtn = Instance.new("TextButton", container)
                toggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
                toggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                toggleBtn.Text = ""
                toggleBtn.AutoButtonColor = false
                Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

                local label = Instance.new("TextLabel", toggleBtn)
                label.Size = UDim2.new(1, -50, 1, 0)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = toggleText
                label.TextColor3 = Color3.fromRGB(200, 200, 200)
                label.Font = Enum.Font.GothamSemibold
                label.TextSize = 13
                label.TextXAlignment = Enum.TextXAlignment.Left

                local switchBg = Instance.new("Frame", toggleBtn)
                switchBg.Size = UDim2.new(0, 36, 0, 18)
                switchBg.Position = UDim2.new(1, -46, 0.5, -9)
                switchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 200) or Color3.fromRGB(50, 50, 50)
                Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

                local switchDot = Instance.new("Frame", switchBg)
                switchDot.Size = UDim2.new(0, 14, 0, 14)
                switchDot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                switchDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Instance.new("UICorner", switchDot).CornerRadius = UDim.new(1, 0)

                local function UpdateVisual(newState)
                    state = newState
                    ts:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 200, 200) or Color3.fromRGB(50, 50, 50)}):Play()
                    ts:Create(switchDot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
                    ts:Create(label, TweenInfo.new(0.2), {TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)}):Play()
                end

                toggleBtn.MouseButton1Click:Connect(function()
                    UpdateVisual(not state)
                    callback(state)
                end)
                
                UIUpdaters.Toggles[toggleText] = UpdateVisual

                layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
                end)
            end

            function Tab:CreateSlider(sliderText, min, max, default, callback)
                local sliderFrame = Instance.new("Frame", container)
                sliderFrame.Size = UDim2.new(0.9, 0, 0, 45)
                sliderFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 6)

                local label = Instance.new("TextLabel", sliderFrame)
                label.Size = UDim2.new(1, -20, 0, 20)
                label.Position = UDim2.new(0, 10, 0, 5)
                label.BackgroundTransparency = 1
                label.Text = sliderText .. ": " .. tostring(default)
                label.TextColor3 = Color3.fromRGB(200, 200, 200)
                label.Font = Enum.Font.GothamSemibold
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left

                local sliderBg = Instance.new("Frame", sliderFrame)
                sliderBg.Size = UDim2.new(1, -20, 0, 6)
                sliderBg.Position = UDim2.new(0, 10, 0, 30)
                sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

                local sliderFill = Instance.new("Frame", sliderBg)
                sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
                Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
                
                local sliderBtn = Instance.new("TextButton", sliderBg)
                sliderBtn.Size = UDim2.new(1, 0, 1, 0)
                sliderBtn.BackgroundTransparency = 1
                sliderBtn.Text = ""

                local dragging = false
                sliderBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                uis.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                
                local function UpdateVisual(val)
                    local mathClamp = math.clamp((val - min) / (max - min), 0, 1)
                    label.Text = sliderText .. ": " .. tostring(val)
                    ts:Create(sliderFill, TweenInfo.new(0.1), {Size = UDim2.new(mathClamp, 0, 1, 0)}):Play()
                end

                table.insert(connections, uis.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mathClamp = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                        local value = math.floor(min + ((max - min) * mathClamp))
                        UpdateVisual(value)
                        callback(value)
                    end
                end))

                UIUpdaters.Sliders[sliderText] = UpdateVisual
                
                layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
                end)
            end

            function Tab:CreateDropdown(dropText, options, defaultIndex, callback)
                local dropFrame = Instance.new("Frame", container)
                dropFrame.Size = UDim2.new(0.9, 0, 0, 35)
                dropFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                dropFrame.ClipsDescendants = true
                Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)

                local mainBtn = Instance.new("TextButton", dropFrame)
                mainBtn.Size = UDim2.new(1, 0, 0, 35)
                mainBtn.BackgroundTransparency = 1
                mainBtn.Text = ""

                local label = Instance.new("TextLabel", mainBtn)
                label.Size = UDim2.new(1, -30, 1, 0)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = dropText .. ": " .. options[defaultIndex]
                label.TextColor3 = Color3.fromRGB(200, 200, 200)
                label.Font = Enum.Font.GothamSemibold
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left

                local icon = Instance.new("TextLabel", mainBtn)
                icon.Size = UDim2.new(0, 20, 0, 20)
                icon.Position = UDim2.new(1, -25, 0.5, -10)
                icon.BackgroundTransparency = 1
                icon.Text = "+"
                icon.TextColor3 = Color3.fromRGB(0, 200, 200)
                icon.Font = Enum.Font.GothamBold
                icon.TextSize = 16

                local optionContainer = Instance.new("Frame", dropFrame)
                optionContainer.Size = UDim2.new(1, 0, 1, -35)
                optionContainer.Position = UDim2.new(0, 0, 0, 35)
                optionContainer.BackgroundTransparency = 1

                local opLayout = Instance.new("UIListLayout", optionContainer)
                opLayout.SortOrder = Enum.SortOrder.LayoutOrder

                local isOpen = false
                mainBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    icon.Text = isOpen and "-" or "+"
                    local targetSize = isOpen and UDim2.new(0.9, 0, 0, 35 + (opLayout.AbsoluteContentSize.Y)) or UDim2.new(0.9, 0, 0, 35)
                    ts:Create(dropFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
                end)

                local function UpdateVisual(opt)
                    label.Text = dropText .. ": " .. opt
                end

                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton", optionContainer)
                    optBtn.Size = UDim2.new(1, 0, 0, 30)
                    optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                    optBtn.Text = "  " .. opt
                    optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 12
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left

                    optBtn.MouseButton1Click:Connect(function()
                        UpdateVisual(opt)
                        callback(opt)
                        isOpen = false
                        icon.Text = "+"
                        ts:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.9, 0, 0, 35)}):Play()
                    end)
                end

                UIUpdaters.Dropdowns[dropText] = UpdateVisual

                layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
                end)
            end

            function Tab:CreateButton(btnText, callback)
                local btn = Instance.new("TextButton", container)
                btn.Size = UDim2.new(0.9, 0, 0, 35)
                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
                btn.Text = btnText
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 13
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

                btn.MouseButton1Click:Connect(function()
                    ts:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 200, 200)}):Play()
                    task.wait(0.1)
                    ts:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 150, 150)}):Play()
                    callback(btn) 
                end)
            end

            return Tab
        end
        return Window
    end

    -- ==========================================
    -- 3. INITIALIZE UI & CONFIG LOGIC
    -- ==========================================
    local fovCircle = Instance.new("Frame", sg)
    fovCircle.Size = UDim2.new(0, configs.fov * 2, 0, configs.fov * 2)
    fovCircle.Position = UDim2.new(0.5, -configs.fov, 0.5, -configs.fov)
    fovCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovCircle.BackgroundTransparency = 0.9
    fovCircle.BorderSizePixel = 0
    fovCircle.Visible = configs.showFov
    Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", fovCircle).Color = Color3.fromRGB(0, 255, 255)

    local MainUI = Library:CreateWindow("DQYMON ESP")
    
    local TabAimbot = MainUI:CreateTab("Aimbot")
    local TabVisuals = MainUI:CreateTab("Visuals")
    local TabMisc = MainUI:CreateTab("Misc")
    local TabSettings = MainUI:CreateTab("Settings")

    local function refreshESP()
        for _, plr in pairs(plrs:GetPlayers()) do
            if plr ~= lplr and plr.Character then
                local isTeammate = (plr.Team ~= nil and plr.Team == lplr.Team)
                local h = plr.Character:FindFirstChild("GhostESP")
                if h then h.Enabled = configs.espHighlight and configs.espEnabled and not (configs.teamCheck and isTeammate) end
            end
        end
    end

    -- TABS: AIMBOT
    TabAimbot:CreateSection("Main Control")
    TabAimbot:CreateToggle("Enable Aimbot", configs.aimEnabled, function(val) configs.aimEnabled = val end)
    TabAimbot:CreateDropdown("Target Part", {"Head", "Torso", "Dynamic"}, 3, function(val) configs.aimPart = val end)
    TabAimbot:CreateSlider("Prediction (Velocity)", 0, 10, configs.prediction * 10, function(val) configs.prediction = val / 10 end)
    
    TabAimbot:CreateSection("Settings")
    TabAimbot:CreateToggle("Show FOV", configs.showFov, function(val) configs.showFov = val; fovCircle.Visible = val end)
    TabAimbot:CreateToggle("Wall Check", configs.wallCheck, function(val) configs.wallCheck = val end)
    TabAimbot:CreateToggle("Team Check", configs.teamCheck, function(val) configs.teamCheck = val; refreshESP() end)
    TabAimbot:CreateSlider("FOV Size", 50, 500, configs.fov, function(val) 
        configs.fov = val; fovCircle.Size = UDim2.new(0, val * 2, 0, val * 2)
    end)
    TabAimbot:CreateSlider("Smoothness", 10, 100, configs.smoothing * 100, function(val) configs.smoothing = val / 100 end)
    TabAimbot:CreateSlider("Dynamic Headshot %", 0, 100, configs.headshotChance, function(val) configs.headshotChance = val end)

    -- TABS: VISUALS
    TabVisuals:CreateSection("Master Switch")
    TabVisuals:CreateToggle("Enable ESP", configs.espEnabled, function(val) configs.espEnabled = val; refreshESP() end)
    
    TabVisuals:CreateSection("ESP Elements")
    TabVisuals:CreateToggle("2D Box", configs.espBox, function(val) configs.espBox = val end)
    TabVisuals:CreateToggle("Health Bar", configs.espHealth, function(val) configs.espHealth = val end)
    TabVisuals:CreateToggle("Tracers", configs.espTracer, function(val) configs.espTracer = val end)
    TabVisuals:CreateToggle("Names", configs.espNames, function(val) configs.espNames = val end)
    TabVisuals:CreateToggle("Distance", configs.espDistance, function(val) configs.espDistance = val end)
    TabVisuals:CreateToggle("Chams (Highlight)", configs.espHighlight, function(val) configs.espHighlight = val; refreshESP() end)

    -- TABS: MISC
    TabMisc:CreateSection("Overlays")
    TabMisc:CreateToggle("Watermark", configs.watermark, function(val) configs.watermark = val; watermark.Visible = val end)
    TabMisc:CreateToggle("Target Info", configs.targetInfo, function(val) configs.targetInfo = val; if not val then targetUI.Visible = false end end)

    -- TABS: SETTINGS & CONFIG SYSTEM
    TabSettings:CreateSection("Configuration Profiles")
    local configName = "DqymonESP_Config.json"

    -- FUNGSI LOAD CONFIG (Bisa dipanggil manual/otomatis)
    local function LoadConfig()
        if readfile and isfile and isfile(configName) then
            local succ, json = pcall(function() return readfile(configName) end)
            if succ then
                local succ2, decoded = pcall(function() return httpService:JSONDecode(json) end)
                if succ2 and type(decoded) == "table" then
                    for k, v in pairs(decoded) do configs[k] = v end
                    
                    if UIUpdaters.Toggles["Enable Aimbot"] then UIUpdaters.Toggles["Enable Aimbot"](configs.aimEnabled) end
                    if UIUpdaters.Toggles["Show FOV"] then UIUpdaters.Toggles["Show FOV"](configs.showFov) end
                    if UIUpdaters.Toggles["Wall Check"] then UIUpdaters.Toggles["Wall Check"](configs.wallCheck) end
                    if UIUpdaters.Toggles["Team Check"] then UIUpdaters.Toggles["Team Check"](configs.teamCheck) end
                    if UIUpdaters.Toggles["Enable ESP"] then UIUpdaters.Toggles["Enable ESP"](configs.espEnabled) end
                    if UIUpdaters.Toggles["2D Box"] then UIUpdaters.Toggles["2D Box"](configs.espBox) end
                    if UIUpdaters.Toggles["Health Bar"] then UIUpdaters.Toggles["Health Bar"](configs.espHealth) end
                    if UIUpdaters.Toggles["Tracers"] then UIUpdaters.Toggles["Tracers"](configs.espTracer) end
                    if UIUpdaters.Toggles["Names"] then UIUpdaters.Toggles["Names"](configs.espNames) end
                    if UIUpdaters.Toggles["Distance"] then UIUpdaters.Toggles["Distance"](configs.espDistance) end
                    if UIUpdaters.Toggles["Chams (Highlight)"] then UIUpdaters.Toggles["Chams (Highlight)"](configs.espHighlight) end
                    if UIUpdaters.Toggles["Watermark"] then UIUpdaters.Toggles["Watermark"](configs.watermark) end
                    if UIUpdaters.Toggles["Target Info"] then UIUpdaters.Toggles["Target Info"](configs.targetInfo) end
                    
                    if UIUpdaters.Sliders["FOV Size"] then UIUpdaters.Sliders["FOV Size"](configs.fov) end
                    if UIUpdaters.Sliders["Smoothness"] then UIUpdaters.Sliders["Smoothness"](configs.smoothing * 100) end
                    if UIUpdaters.Sliders["Dynamic Headshot %"] then UIUpdaters.Sliders["Dynamic Headshot %"](configs.headshotChance) end
                    if UIUpdaters.Sliders["Prediction (Velocity)"] then UIUpdaters.Sliders["Prediction (Velocity)"](configs.prediction * 10) end
                    if UIUpdaters.Dropdowns["Target Part"] then UIUpdaters.Dropdowns["Target Part"](configs.aimPart) end
                    
                    fovCircle.Visible = configs.showFov
                    fovCircle.Size = UDim2.new(0, configs.fov * 2, 0, configs.fov * 2)
                    watermark.Visible = configs.watermark
                    refreshESP()
                    return true
                end
            end
        end
        return false
    end

    TabSettings:CreateButton("Save Config", function(btn)
        if writefile then
            local succ, json = pcall(function() return httpService:JSONEncode(configs) end)
            if succ then
                writefile(configName, json)
                btn.Text = "Config Saved!"
                task.wait(1.5)
                btn.Text = "Save Config"
            end
        else
            btn.Text = "Executor Not Supported!"
            task.wait(1.5)
            btn.Text = "Save Config"
        end
    end)

    TabSettings:CreateButton("Load Config", function(btn)
        if LoadConfig() then
            btn.Text = "Config Loaded!"
            task.wait(1.5)
            btn.Text = "Load Config"
        else
            btn.Text = "No Config Found!"
            task.wait(1.5)
            btn.Text = "Load Config"
        end
    end)

    TabSettings:CreateSection("Destruction")
    TabSettings:CreateButton("Unload Script", function()
        for _, conn in ipairs(connections) do conn:Disconnect() end
        for _, obj in pairs(espObjects) do
            if obj.box then obj.box:Destroy() end
            if obj.healthBg then obj.healthBg:Destroy() end
            if obj.tracer then obj.tracer:Destroy() end
            if obj.text then obj.text:Destroy() end
            if obj.highlight then obj.highlight:Destroy() end
        end
        sg:Destroy()
    end)

    -- AUTO-LOAD CONFIG EXECUTION
    task.spawn(function()
        LoadConfig()
    end)

    table.insert(connections, uis.InputBegan:Connect(function(i, gpe)
        if not gpe and i.KeyCode == configs.menuKeybind and activeWindow then 
            activeWindow.Visible = not activeWindow.Visible 
        end
    end))

    -- ==========================================
    -- 4. CORE LOGIC & ESP RENDER
    -- ==========================================
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    
    local function updateRaycastFilter()
        if lplr.Character then rayParams.FilterDescendantsInstances = {lplr.Character, cam} end
    end
    updateRaycastFilter()
    table.insert(connections, lplr.CharacterAdded:Connect(updateRaycastFilter))

    local function isVisible(targetPart)
        if not configs.wallCheck then return true end
        if not targetPart then return false end
        local result = workspace:Raycast(cam.CFrame.Position, targetPart.Position - cam.CFrame.Position, rayParams)
        return not result or result.Instance:IsDescendantOf(targetPart.Parent)
    end

    local function createESPUI(plr)
        local objects = {}
        
        local box = Instance.new("Frame", sg)
        box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color = Color3.fromRGB(0, 255, 255)
        boxStroke.Thickness = 1.5
        objects.box = box

        local healthBg = Instance.new("Frame", sg)
        healthBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        healthBg.BorderSizePixel = 0
        local healthFill = Instance.new("Frame", healthBg)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.AnchorPoint = Vector2.new(0, 1)
        healthFill.Position = UDim2.new(0, 0, 1, 0)
        objects.healthBg = healthBg
        objects.healthFill = healthFill

        local tracer = Instance.new("Frame", sg)
        tracer.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        tracer.BorderSizePixel = 0
        tracer.Size = UDim2.new(0, 1, 0, 0)
        tracer.AnchorPoint = Vector2.new(0.5, 0)
        objects.tracer = tracer

        local text = Instance.new("TextLabel", sg)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 11
        Instance.new("UIStroke", text).Thickness = 1
        objects.text = text

        return objects
    end

    local function getBoundingBox(char)
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

    local switchTimer = 0
    local fpsCount = 0
    local lastTime = tick()

    table.insert(connections, runService.RenderStepped:Connect(function(dt)
        fpsCount = fpsCount + 1
        if tick() - lastTime >= 1 then
            local ping = string.split(tostring(stats.Network.ServerStatsItem["Data Ping"]:GetValue()), ".")[1]
            watermark.Text = string.format("DqymonESP | FPS: %d | Ping: %sms", fpsCount, ping)
            fpsCount = 0; lastTime = tick()
        end

        fovCircle.Position = UDim2.new(0, mouse.X - configs.fov, 0, mouse.Y - configs.fov)
        
        for _, plr in pairs(plrs:GetPlayers()) do
            if plr ~= lplr then
                if not espObjects[plr.Name] then espObjects[plr.Name] = createESPUI(plr) end
                local esp = espObjects[plr.Name]
                local char = plr.Character
                local isTeammate = (configs.teamCheck and plr.Team ~= nil and plr.Team == lplr.Team)

                if configs.espEnabled and char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and not isTeammate then
                    local bounds = getBoundingBox(char)
                    
                    if bounds and bounds.onScreen then
                        if configs.espBox then
                            esp.box.Position = UDim2.new(0, bounds.x, 0, bounds.y)
                            esp.box.Size = UDim2.new(0, bounds.w, 0, bounds.h)
                            esp.box.Visible = true
                        else esp.box.Visible = false end

                        if configs.espHealth then
                            local healthPct = char.Humanoid.Health / char.Humanoid.MaxHealth
                            esp.healthBg.Position = UDim2.new(0, bounds.x - 6, 0, bounds.y)
                            esp.healthBg.Size = UDim2.new(0, 3, 0, bounds.h)
                            esp.healthFill.Size = UDim2.new(1, 0, healthPct, 0)
                            esp.healthFill.BackgroundColor3 = Color3.fromRGB(255 - (healthPct * 255), healthPct * 255, 0)
                            esp.healthBg.Visible = true
                        else esp.healthBg.Visible = false end

                        if configs.espNames or configs.espDistance then
                            local txt = ""
                            if configs.espNames then txt = txt .. plr.Name .. "\n" end
                            if configs.espDistance then 
                                local dist = math.floor((cam.CFrame.Position - char.HumanoidRootPart.Position).Magnitude)
                                txt = txt .. "[" .. dist .. "m]"
                            end
                            esp.text.Text = txt
                            esp.text.Position = UDim2.new(0, bounds.x + (bounds.w/2) - 50, 0, bounds.y - 25)
                            esp.text.Size = UDim2.new(0, 100, 0, 20)
                            esp.text.Visible = true
                        else esp.text.Visible = false end

                        if configs.espTracer then
                            local startPoint = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                            local endPoint = Vector2.new(bounds.x + (bounds.w/2), bounds.y + bounds.h)
                            local distance = (endPoint - startPoint).Magnitude
                            
                            esp.tracer.Position = UDim2.new(0, startPoint.X, 0, startPoint.Y)
                            esp.tracer.Size = UDim2.new(0, 1, 0, distance)
                            
                            local angle = math.deg(math.atan2(endPoint.Y - startPoint.Y, endPoint.X - startPoint.X)) + 90
                            esp.tracer.Rotation = angle
                            esp.tracer.Visible = true
                        else esp.tracer.Visible = false end

                        if configs.espHighlight then
                            if not esp.highlight then
                                esp.highlight = Instance.new("Highlight")
                                esp.highlight.FillColor = Color3.fromRGB(0, 255, 255)
                                esp.highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                esp.highlight.FillTransparency = 0.5
                                esp.highlight.Parent = char
                            end
                            esp.highlight.Enabled = true
                        elseif esp.highlight then esp.highlight.Enabled = false end

                    else
                        esp.box.Visible = false; esp.healthBg.Visible = false; esp.text.Visible = false; esp.tracer.Visible = false
                        if esp.highlight then esp.highlight.Enabled = false end
                    end
                else
                    esp.box.Visible = false; esp.healthBg.Visible = false; esp.text.Visible = false; esp.tracer.Visible = false
                    if esp.highlight then esp.highlight.Enabled = false end
                end
            end
        end

        if configs.aimEnabled and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            if currentTargetChar and currentTargetChar:FindFirstChild("Humanoid") and currentTargetChar.Humanoid.Health > 0 then
                local hrp = currentTargetChar:FindFirstChild("HumanoidRootPart")
                local head = currentTargetChar:FindFirstChild("Head")
                
                if hrp and head then
                    if configs.aimPart == "Head" then lockedTarget = head
                    elseif configs.aimPart == "Torso" then lockedTarget = hrp
                    else 
                        switchTimer = switchTimer + dt
                        if switchTimer >= 0.2 then
                            switchTimer = 0
                            lockedTarget = (math.random(1, 100) <= configs.headshotChance) and head or hrp
                        end
                    end

                    if lockedTarget then
                        local targetVelocity = hrp.AssemblyLinearVelocity
                        local predictedPos = lockedTarget.Position + (targetVelocity * configs.prediction)

                        local pos, onScreen = cam:WorldToViewportPoint(predictedPos)
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        
                        if not onScreen or dist > configs.fov or not isVisible(lockedTarget) then 
                            currentTargetChar = nil; lockedTarget = nil 
                        end
                    end
                else currentTargetChar = nil; lockedTarget = nil end
            else currentTargetChar = nil; lockedTarget = nil end

            if not currentTargetChar then
                local bestDist = configs.fov
                local bestChar = nil
                
                for _, plr in pairs(plrs:GetPlayers()) do
                    if plr ~= lplr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                        local isTeammate = (configs.teamCheck and plr.Team ~= nil and plr.Team == lplr.Team)
                        if isTeammate then continue end
                        
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                            local mDist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                            
                            if onScreen and mDist < bestDist and isVisible(hrp) then 
                                bestDist = mDist; bestChar = plr.Character
                            end
                        end
                    end
                end
                
                if bestChar then
                    currentTargetChar = bestChar
                    local tPart = bestChar:FindFirstChild("HumanoidRootPart")
                    if configs.aimPart == "Head" then tPart = bestChar:FindFirstChild("Head") end
                    lockedTarget = tPart
                end
            end

            if lockedTarget and currentTargetChar then 
                local hrp = currentTargetChar:FindFirstChild("HumanoidRootPart")
                local predictedPos = lockedTarget.Position + (hrp.AssemblyLinearVelocity * configs.prediction)

                local smoothFactor = math.clamp(configs.smoothing * (dt * 60), 0, 1)
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, predictedPos), smoothFactor) 
                
                if configs.targetInfo then
                    local targetPlayer = plrs:GetPlayerFromCharacter(currentTargetChar)
                    local hp = math.floor(currentTargetChar.Humanoid.Health)
                    local dist = math.floor((cam.CFrame.Position - currentTargetChar.HumanoidRootPart.Position).Magnitude)
                    
                    tName.Text = "Target: " .. (targetPlayer and targetPlayer.Name or "Unknown")
                    tHealth.Text = "HP: " .. hp .. " | Dist: " .. dist .. "m"
                    targetUI.Visible = true
                else targetUI.Visible = false end
            else targetUI.Visible = false end
            
        else currentTargetChar = nil; lockedTarget = nil; switchTimer = 0; targetUI.Visible = false end
    end))

    table.insert(connections, plrs.PlayerRemoving:Connect(function(plr)
        if espObjects[plr.Name] then
            for _, obj in pairs(espObjects[plr.Name]) do obj:Destroy() end
            espObjects[plr.Name] = nil
        end
    end))

end)

if not success then warn("DqymonESP Error: " .. tostring(err)) end
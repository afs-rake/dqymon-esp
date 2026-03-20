--[[
    DqymonESP - UI Library
    Reusable UI component system for creating menus and interface elements
]]

local Constants = require(script.Parent:FindFirstChild("dqymon_constants") or error("Missing dqymon_constants"))

local UILibrary = {}
UILibrary.__index = UILibrary

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function MakeDraggable(topBarObject, windowObject, connections)
    local dragging = false
    local dragInput = nil
    local mousePos = nil
    local framePos = nil
    
    topBarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = windowObject.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    topBarObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    local uis = game:GetService("UserInputService")
    local dragConnection = uis.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - mousePos
            windowObject.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
    
    table.insert(connections, dragConnection)
end

-- ==========================================
-- WINDOW CLASS
-- ==========================================
function UILibrary:CreateWindow(titleText, screenGui, connections)
    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.ActiveTabScroll = nil
    Window.ActiveTabText = nil
    Window.ActiveTabLine = nil
    Window.UIUpdaters = {
        Toggles = {},
        Sliders = {},
        Dropdowns = {}
    }
    
    local ts = game:GetService("TweenService")
    
    -- Main Window Frame
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = Constants.UI.MainWindowPos
    mainFrame.BackgroundColor3 = Constants.Colors.BgDark
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner", mainFrame)
    corner.CornerRadius = Constants.UI.CornerRadius
    
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Constants.Colors.Secondary
    stroke.Thickness = Constants.UI.BorderThickness
    stroke.Transparency = 0.5
    
    Window.MainFrame = mainFrame
    
    -- Top Bar
    local topBar = Instance.new("Frame", mainFrame)
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, Constants.UI.TopBarHeight)
    topBar.BackgroundColor3 = Constants.Colors.BgMedium
    topBar.BorderSizePixel = 0
    
    local topBarFix = Instance.new("Frame", topBar)
    topBarFix.Size = UDim2.new(1, 0, 0, 8)
    topBarFix.Position = UDim2.new(0, 0, 1, -8)
    topBarFix.BackgroundColor3 = Constants.Colors.BgMedium
    topBarFix.BorderSizePixel = 0
    
    local title = Instance.new("TextLabel", topBar)
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Constants.Colors.Primary
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Center
    
    MakeDraggable(topBar, mainFrame, connections)
    
    -- Tab Bar
    local tabBar = Instance.new("Frame", mainFrame)
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, Constants.UI.TabBarHeight)
    tabBar.Position = UDim2.new(0, 0, 0, Constants.UI.TopBarHeight)
    tabBar.BackgroundColor3 = Constants.Colors.BgPanel
    tabBar.BorderSizePixel = 0
    
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Content Area
    local contentArea = Instance.new("Frame", mainFrame)
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -(Constants.UI.TopBarHeight + Constants.UI.TabBarHeight))
    contentArea.Position = UDim2.new(0, 0, 0, Constants.UI.TopBarHeight + Constants.UI.TabBarHeight)
    contentArea.BackgroundTransparency = 1
    
    -- Animate window in
    ts:Create(mainFrame, Constants.Animations.SlowTween, {Size = Constants.UI.MainWindowSize}):Play()
    
    function Window:CreateTab(tabName)
        local Tab = {}
        
        -- Tab Button
        local tabBtn = Instance.new("TextButton", tabBar)
        tabBtn.Name = tabName .. "Btn"
        tabBtn.Size = UDim2.new(0.25, 0, 1, 0)
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        
        local tabText = Instance.new("TextLabel", tabBtn)
        tabText.Size = UDim2.new(1, 0, 1, 0)
        tabText.BackgroundTransparency = 1
        tabText.Text = tabName
        tabText.TextColor3 = Constants.Colors.TextDark
        tabText.Font = Enum.Font.GothamSemibold
        tabText.TextSize = 13
        
        local tabLine = Instance.new("Frame", tabBtn)
        tabLine.Name = "Underline"
        tabLine.Size = UDim2.new(0.6, 0, 0, 2)
        tabLine.AnchorPoint = Vector2.new(0.5, 0)
        tabLine.Position = UDim2.new(0.5, 0, 1, -2)
        tabLine.BackgroundColor3 = Constants.Colors.Primary
        tabLine.BorderSizePixel = 0
        tabLine.Visible = false
        
        -- Tab Container
        local container = Instance.new("ScrollingFrame", contentArea)
        container.Name = tabName .. "Container"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = Constants.Colors.Primary
        container.Visible = false
        
        local layout = Instance.new("UIListLayout", container)
        layout.Padding = Constants.UI.PaddingStandard
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local padding = Instance.new("UIPadding", container)
        padding.PaddingTop = Constants.UI.PaddingLarge
        padding.PaddingBottom = Constants.UI.PaddingLarge
        
        -- Tab Switching
        tabBtn.MouseButton1Click:Connect(function()
            if Window.ActiveTabScroll then Window.ActiveTabScroll.Visible = false end
            if Window.ActiveTabText then Window.ActiveTabText.TextColor3 = Constants.Colors.TextDark end
            if Window.ActiveTabLine then Window.ActiveTabLine.Visible = false end
            
            container.Visible = true
            tabText.TextColor3 = Constants.Colors.Primary
            tabLine.Visible = true
            
            Window.ActiveTabScroll = container
            Window.ActiveTabText = tabText
            Window.ActiveTabLine = tabLine
        end)
        
        -- Set first tab as active
        if not Window.ActiveTab then
            container.Visible = true
            tabText.TextColor3 = Constants.Colors.Primary
            tabLine.Visible = true
            Window.ActiveTabScroll = container
            Window.ActiveTabText = tabText
            Window.ActiveTabLine = tabLine
            Window.ActiveTab = Tab
        end
        
        -- Update canvas size on layout change
        local function UpdateCanvasSize()
            container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)
        
        -- ==========================================
        -- TAB UI ELEMENTS
        -- ==========================================
        
        function Tab:CreateSection(sectionName)
            local sec = Instance.new("TextLabel", container)
            sec.Size = UDim2.new(0.9, 0, 0, Constants.UI.SectionHeight)
            sec.BackgroundTransparency = 1
            sec.Text = "  " .. sectionName
            sec.TextColor3 = Constants.Colors.Secondary
            sec.Font = Enum.Font.GothamBold
            sec.TextSize = 12
            sec.TextXAlignment = Enum.TextXAlignment.Left
            
            local line = Instance.new("Frame", sec)
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 1, 0)
            line.BackgroundColor3 = Constants.Colors.DarkGray
            line.BorderSizePixel = 0
        end
        
        function Tab:CreateToggle(toggleText, defaultState, callback)
            local state = defaultState
            local toggleBtn = Instance.new("TextButton", container)
            toggleBtn.Size = UDim2.new(0.9, 0, 0, Constants.UI.ToggleHeight)
            toggleBtn.BackgroundColor3 = Constants.Colors.BgLight
            toggleBtn.Text = ""
            toggleBtn.AutoButtonColor = false
            
            Instance.new("UICorner", toggleBtn).CornerRadius = Constants.UI.CornerRadius
            
            local label = Instance.new("TextLabel", toggleBtn)
            label.Size = UDim2.new(1, -50, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = toggleText
            label.TextColor3 = Constants.Colors.TextMedium
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            
            local switchBg = Instance.new("Frame", toggleBtn)
            switchBg.Size = UDim2.new(0, 36, 0, 18)
            switchBg.Position = UDim2.new(1, -46, 0.5, -9)
            switchBg.BackgroundColor3 = state and Constants.Colors.Secondary or Constants.Colors.MediumGray
            Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
            
            local switchDot = Instance.new("Frame", switchBg)
            switchDot.Size = UDim2.new(0, 14, 0, 14)
            switchDot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            switchDot.BackgroundColor3 = Constants.Colors.White
            Instance.new("UICorner", switchDot).CornerRadius = UDim.new(1, 0)
            
            local function UpdateVisual(newState)
                state = newState
                ts:Create(switchBg, Constants.Animations.FastTween, {BackgroundColor3 = state and Constants.Colors.Secondary or Constants.Colors.MediumGray}):Play()
                ts:Create(switchDot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
                ts:Create(label, Constants.Animations.FastTween, {TextColor3 = state and Constants.Colors.TextLight or Constants.Colors.TextMedium}):Play()
            end
            
            toggleBtn.MouseButton1Click:Connect(function()
                UpdateVisual(not state)
                callback(state)
            end)
            
            Window.UIUpdaters.Toggles[toggleText] = UpdateVisual
        end
        
        function Tab:CreateSlider(sliderText, min, max, default, callback)
            local sliderFrame = Instance.new("Frame", container)
            sliderFrame.Size = UDim2.new(0.9, 0, 0, Constants.UI.SliderHeight)
            sliderFrame.BackgroundColor3 = Constants.Colors.BgLight
            Instance.new("UICorner", sliderFrame).CornerRadius = Constants.UI.CornerRadius
            
            local label = Instance.new("TextLabel", sliderFrame)
            label.Size = UDim2.new(1, -20, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = sliderText .. ": " .. tostring(default)
            label.TextColor3 = Constants.Colors.TextMedium
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            
            local sliderBg = Instance.new("Frame", sliderFrame)
            sliderBg.Size = UDim2.new(1, -20, 0, 6)
            sliderBg.Position = UDim2.new(0, 10, 0, 30)
            sliderBg.BackgroundColor3 = Constants.Colors.MediumGray
            Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
            
            local sliderFill = Instance.new("Frame", sliderBg)
            sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            sliderFill.BackgroundColor3 = Constants.Colors.Primary
            Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
            
            local sliderBtn = Instance.new("TextButton", sliderBg)
            sliderBtn.Size = UDim2.new(1, 0, 1, 0)
            sliderBtn.BackgroundTransparency = 1
            sliderBtn.Text = ""
            
            local dragging = false
            local uis = game:GetService("UserInputService")
            
            sliderBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            
            uis.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            local function UpdateVisual(val)
                local mathClamp = math.clamp((val - min) / (max - min), 0, 1)
                label.Text = sliderText .. ": " .. tostring(math.floor(val))
                ts:Create(sliderFill, Constants.Animations.FastTween, {Size = UDim2.new(mathClamp, 0, 1, 0)}):Play()
            end
            
            local inputConnection = uis.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mathClamp = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + ((max - min) * mathClamp))
                    UpdateVisual(value)
                    callback(value)
                end
            end)
            
            table.insert(connections, inputConnection)
            Window.UIUpdaters.Sliders[sliderText] = UpdateVisual
        end
        
        function Tab:CreateDropdown(dropText, options, defaultIndex, callback)
            local dropFrame = Instance.new("Frame", container)
            dropFrame.Size = UDim2.new(0.9, 0, 0, Constants.UI.DropdownHeight)
            dropFrame.BackgroundColor3 = Constants.Colors.BgLight
            dropFrame.ClipsDescendants = true
            Instance.new("UICorner", dropFrame).CornerRadius = Constants.UI.CornerRadius
            
            local mainBtn = Instance.new("TextButton", dropFrame)
            mainBtn.Size = UDim2.new(1, 0, 0, Constants.UI.DropdownHeight)
            mainBtn.BackgroundTransparency = 1
            mainBtn.Text = ""
            
            local label = Instance.new("TextLabel", mainBtn)
            label.Size = UDim2.new(1, -30, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = dropText .. ": " .. options[defaultIndex]
            label.TextColor3 = Constants.Colors.TextMedium
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            
            local icon = Instance.new("TextLabel", mainBtn)
            icon.Size = UDim2.new(0, 20, 0, 20)
            icon.Position = UDim2.new(1, -25, 0.5, -10)
            icon.BackgroundTransparency = 1
            icon.Text = "+"
            icon.TextColor3 = Constants.Colors.Secondary
            icon.Font = Enum.Font.GothamBold
            icon.TextSize = 16
            
            local optionContainer = Instance.new("Frame", dropFrame)
            optionContainer.Size = UDim2.new(1, 0, 1, -Constants.UI.DropdownHeight)
            optionContainer.Position = UDim2.new(0, 0, 0, Constants.UI.DropdownHeight)
            optionContainer.BackgroundTransparency = 1
            
            local opLayout = Instance.new("UIListLayout", optionContainer)
            opLayout.SortOrder = Enum.SortOrder.LayoutOrder
            
            local isOpen = false
            
            mainBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                icon.Text = isOpen and "-" or "+"
                local targetSize = isOpen and UDim2.new(0.9, 0, 0, Constants.UI.DropdownHeight + opLayout.AbsoluteContentSize.Y) or UDim2.new(0.9, 0, 0, Constants.UI.DropdownHeight)
                ts:Create(dropFrame, Constants.Animations.MediumTween, {Size = targetSize}):Play()
            end)
            
            local function UpdateVisual(opt)
                label.Text = dropText .. ": " .. opt
            end
            
            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton", optionContainer)
                optBtn.Size = UDim2.new(1, 0, 0, 30)
                optBtn.BackgroundColor3 = Constants.Colors.BgInputField
                optBtn.Text = "  " .. opt
                optBtn.TextColor3 = Constants.Colors.TextMedium
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 12
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                
                optBtn.MouseButton1Click:Connect(function()
                    UpdateVisual(opt)
                    callback(opt)
                    isOpen = false
                    icon.Text = "+"
                    ts:Create(dropFrame, Constants.Animations.MediumTween, {Size = UDim2.new(0.9, 0, 0, Constants.UI.DropdownHeight)}):Play()
                end)
            end
            
            Window.UIUpdaters.Dropdowns[dropText] = UpdateVisual
        end
        
        function Tab:CreateButton(btnText, callback)
            local btn = Instance.new("TextButton", container)
            btn.Size = UDim2.new(0.9, 0, 0, Constants.UI.ButtonHeight)
            btn.BackgroundColor3 = Constants.Colors.Tertiary
            btn.Text = btnText
            btn.TextColor3 = Constants.Colors.TextLight
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            Instance.new("UICorner", btn).CornerRadius = Constants.UI.CornerRadius
            
            btn.MouseButton1Click:Connect(function()
                ts:Create(btn, Constants.Animations.FastTween, {BackgroundColor3 = Constants.Colors.Secondary}):Play()
                task.wait(0.1)
                ts:Create(btn, Constants.Animations.FastTween, {BackgroundColor3 = Constants.Colors.Tertiary}):Play()
                callback(btn)
            end)
        end
        
        table.insert(Window.Tabs, Tab)
        return Tab
    end
    
    return Window
end

return UILibrary

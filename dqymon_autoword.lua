--[[
    Dqymon Auto-Word V28 (Deep Research Edition)
    
    Massive Fixes:
    - UI Overlap Fix: Memperbaiki bug ListLayout yang hancur sehingga teks menumpuk.
    - Deep Scanner: Membaca teks hingga ke dalam descendant UI untuk memastikan prompt terdeteksi.
    - Time-State Retype: Menggantikan deteksi "X Merah" dengan sistem yang jauh lebih akurat (Jika prompt tidak berganti selama 2 detik = Salah/Ditolak -> Auto Retype).
    - Perfect Backspace: Jeda VIM disesuaikan agar tidak menumpuk ketikan.
]]

local success, err = pcall(function()
    local plrs = game:GetService("Players")
    local lplr = plrs.LocalPlayer
    local coreGui = game:GetService("CoreGui") or lplr:FindFirstChild("PlayerGui")
    local vim = game:GetService("VirtualInputManager")
    local ts = game:GetService("TweenService")
    local uis = game:GetService("UserInputService")
    
    local UI_NAME = "DqymonWord"
    local unloaded = false
    
    if coreGui:FindFirstChild(UI_NAME) then coreGui[UI_NAME]:Destroy() end

    -- ==========================================
    -- 1. LOAD CLOUD DATABASE
    -- ==========================================
    local DATABASE_URL = "https://raw.githubusercontent.com/afs-rake/dqymon/refs/heads/main/dqymon_database.lua" 
    
    if type(_G.DqymonDatabase) ~= "table" then
        print("Mengunduh Dqymon Database dari GitHub...")
        local successLoad, loadErr = pcall(function()
            local code = game:HttpGet(DATABASE_URL)
            local loadedFunc, syntaxErr = loadstring(code)
            if not loadedFunc then
                error("\n[!] ADA TYPO DI DATABASE GITHUB KAMU [!]\nDetail Error: " .. tostring(syntaxErr))
            end
            loadedFunc()
        end)
        
        if not successLoad then
            warn("Gagal Load Database! " .. tostring(loadErr))
            return 
        end
    end

    local kbbi = _G.DqymonDatabase

    -- RUNTIME DEDUPLICATOR
    for key, list in pairs(kbbi) do
        local seen = {}
        local uniqueList = {}
        for _, word in ipairs(list) do
            local lowerWord = word:lower()
            if not seen[lowerWord] then
                seen[lowerWord] = true
                table.insert(uniqueList, lowerWord)
            end
        end
        kbbi[key] = uniqueList
    end

    local usedWords = {} 
    local settings = {
        autoEnter = true,
        typeDelay = 0.04, 
        autoFocus = true,
        autoScan = false,
        autoClear = true
    }

    local connections = {}
    local currentWordLength = 10
    local forceRetypeNextTick = false
    local isTyping = false

    -- ==========================================
    -- 2. SMART LOGIC ENGINE (V28)
    -- ==========================================
    
    local function cleanRichText(text)
        return text:gsub("<[^>]+>", ""):gsub("%s+", "")
    end

    local function simKeyPress(keyEnum)
        if unloaded then return end
        vim:SendKeyEvent(true, keyEnum, false, game)
        task.wait(0.015) 
        vim:SendKeyEvent(false, keyEnum, false, game)
        task.wait(0.015) 
    end

    -- Hapus manual via Text property jika memungkinkan, lalu fallback ke VIM Backspace
    local function forceClearTextBoxes()
        for _, g in ipairs(lplr.PlayerGui:GetDescendants()) do
            if g:IsA("TextBox") and g.Visible then
                pcall(function() g.Text = "" end)
            end
        end
    end

    -- SMART CLEAR
    local function clearGameInput(charsToDelete)
        if not settings.autoClear then return end
        forceClearTextBoxes()
        
        local toDelete = (charsToDelete or 10) + 3
        for i = 1, toDelete do
            if unloaded then break end
            simKeyPress(Enum.KeyCode.Backspace)
        end
        task.wait(0.2) -- Jeda aman agar tidak bertabrakan dengan ketikan baru
    end

    local function TypeText(text)
        if unloaded then return end
        isTyping = true
        
        task.wait(0.1) 
        for i = 1, #text do
            local char = text:sub(i, i):upper()
            local keyEnum = nil
            pcall(function()
                if char == "-" then keyEnum = Enum.KeyCode.Minus
                elseif char == " " then keyEnum = Enum.KeyCode.Space
                else keyEnum = Enum.KeyCode[char] end
            end)
            if keyEnum then 
                simKeyPress(keyEnum) 
                task.wait(settings.typeDelay) 
            end
        end
        if settings.autoEnter then 
            task.wait(0.1) 
            simKeyPress(Enum.KeyCode.Return) 
        end
        
        isTyping = false 
    end

    local function GetSuggestions(pattern)
        pattern = pattern:lower()
        local results = {}
        local wordList = kbbi[pattern]
        
        if not wordList or #wordList == 0 then
            local firstChar = pattern:sub(1, 1)
            local baseList = kbbi[firstChar]
            if baseList then
                wordList = {}
                for _, w in ipairs(baseList) do
                    if w:lower():sub(1, #pattern) == pattern then
                        table.insert(wordList, w)
                    end
                end
            end
        end

        if wordList then
            for _, word in ipairs(wordList) do
                if not usedWords[word] then table.insert(results, word) end
                if #results >= 5 then break end
            end
        end
        return results
    end

    -- DEEP PROMPT DETECTOR V28
    local function getPromptInfo()
        local detected = ""
        local maxLen = 0
        local isMyTurn = false
        local candidates = {}
        
        -- 1. Deteksi via BillboardGui di atas kepala (Paling Akurat)
        if lplr.Character then
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("BillboardGui") and desc.Adornee and (desc.Adornee == lplr.Character or desc.Adornee:IsDescendantOf(lplr.Character)) then
                    for _, lbl in ipairs(desc:GetDescendants()) do
                        if (lbl:IsA("TextLabel") or lbl:IsA("TextBox")) and lbl.Visible and lbl.Text ~= "" then
                            local cleanTxt = cleanRichText(lbl.Text)
                            if cleanTxt:match("^%a+$") and #cleanTxt >= 1 and #cleanTxt <= 4 then
                                isMyTurn = true
                                table.insert(candidates, {txt = cleanTxt:lower(), len = #cleanTxt})
                            end
                        end
                    end
                end
            end
        end

        -- 2. Deteksi via Layar Utama (Deep Hierarchy Scan)
        for _, g in ipairs(lplr.PlayerGui:GetDescendants()) do
            if g:IsDescendantOf(sg) then continue end
            if (g:IsA("TextLabel") or g:IsA("TextBox")) and g.Visible and g.Text ~= "" then
                local rawText = g.Text:lower()
                if rawText:find("hurufnya") or rawText:find("mulai dari") or rawText:find("awalnya") then
                    -- Telusuri dari Parent untuk mencari huruf tantangan yang disembunyikan di label terpisah
                    if g.Parent then
                        for _, nearby in ipairs(g.Parent:GetDescendants()) do
                            if (nearby:IsA("TextLabel") or nearby:IsA("TextBox")) and nearby ~= g and nearby.Visible then
                                local cleanTxt = cleanRichText(nearby.Text)
                                if cleanTxt:match("^%a+$") and #cleanTxt >= 1 and #cleanTxt <= 4 then
                                    table.insert(candidates, {txt = cleanTxt:lower(), len = #cleanTxt})
                                end
                            end
                        end
                    end
                end
            end
        end

        if #candidates > 0 and not isMyTurn then
            isMyTurn = true -- Asumsikan giliran kita jika ada prompt di layar
        end

        for _, cand in ipairs(candidates) do
            if cand.len > maxLen then
                detected = cand.txt
                maxLen = cand.len
            end
        end
        return detected, isMyTurn
    end

    -- ==========================================
    -- 3. GUI SYSTEM
    -- ==========================================
    local sg = Instance.new("ScreenGui", coreGui)
    sg.Name = UI_NAME
    sg.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame", sg)
    mainFrame.Size = UDim2.new(0, 280, 0, 420) 
    mainFrame.Position = UDim2.new(0.5, -140, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 18)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true -- [FIX] Mencegah UI meluber keluar frame
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Color3.fromRGB(150, 0, 255)
    mainStroke.Thickness = 1.8

    local dragging, dragInput, mousePos, framePos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; mousePos = input.Position; framePos = mainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    mainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    table.insert(connections, uis.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            mainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end))

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "DQYMON AUTO-WORD V28"
    title.TextColor3 = Color3.fromRGB(200, 100, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 13 -- [FIX] Ukuran statis agar tidak meluber
    title.TextXAlignment = Enum.TextXAlignment.Center

    local inputBox = Instance.new("TextBox", mainFrame)
    inputBox.Size = UDim2.new(0.9, 0, 0, 35)
    inputBox.Position = UDim2.new(0.05, 0, 0, 40) 
    inputBox.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextSize = 14
    inputBox.PlaceholderText = "Input manual di sini..."
    inputBox.Text = ""
    Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)

    local suggestionFrame = Instance.new("Frame", mainFrame)
    suggestionFrame.Size = UDim2.new(0, 252, 0, 100) 
    suggestionFrame.Position = UDim2.new(0.05, 0, 0, 85)
    suggestionFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 25)
    suggestionFrame.ClipsDescendants = true -- [FIX] Mencegah teks overlap bocor
    Instance.new("UICorner", suggestionFrame).CornerRadius = UDim.new(0, 6)
    
    local sugLayout = Instance.new("UIListLayout", suggestionFrame)
    sugLayout.Padding = UDim.new(0, 2)
    sugLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    -- [FIX] Membersihkan UI dengan aman
    local function clearSug()
        for _, c in ipairs(suggestionFrame:GetChildren()) do 
            if not c:IsA("UIListLayout") then 
                c:Destroy() 
            end 
        end
    end

    local function updateSug(pattern)
        clearSug()
        local sugs = GetSuggestions(pattern)
        if #sugs == 0 then
            local lbl = Instance.new("TextLabel", suggestionFrame)
            lbl.Size = UDim2.new(1, 0, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "Habis: "..pattern:upper()
            lbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 10
            return
        end
        for _, s in ipairs(sugs) do
            local btn = Instance.new("TextButton", suggestionFrame)
            btn.Size = UDim2.new(0.95, 0, 0, 18)
            btn.BackgroundColor3 = Color3.fromRGB(35, 30, 45)
            btn.Text = " " .. s:upper()
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 10
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                if not isTyping then
                    usedWords[s] = true
                    currentWordLength = #s
                    task.spawn(function() TypeText(s:sub(#pattern + 1)) end)
                    updateSug(pattern)
                end
            end)
        end
    end

    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
        if inputBox.Text ~= "" then updateSug(inputBox.Text) else clearSug() end
    end)

    local infoText = Instance.new("TextLabel", mainFrame)
    infoText.Size = UDim2.new(1, 0, 0, 20)
    infoText.Position = UDim2.new(0, 0, 0, 190)
    infoText.BackgroundTransparency = 1
    infoText.Text = "Scanner Idle..."
    infoText.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoText.Font = Enum.Font.GothamSemibold
    infoText.TextSize = 11

    local function createToggle(text, pos, configKey)
        local frame = Instance.new("Frame", mainFrame)
        frame.Size = UDim2.new(0.9, 0, 0, 25)
        frame.Position = UDim2.new(0.05, 0, 0, pos)
        frame.BackgroundTransparency = 1
        
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 18, 0, 18)
        btn.BackgroundColor3 = settings[configKey] and Color3.fromRGB(150, 0, 255) or Color3.fromRGB(50, 50, 50)
        btn.Text = settings[configKey] and "✓" or ""
        btn.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, -30, 1, 0)
        lbl.Position = UDim2.new(0, 25, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        
        btn.MouseButton1Click:Connect(function()
            settings[configKey] = not settings[configKey]
            btn.BackgroundColor3 = settings[configKey] and Color3.fromRGB(150, 0, 255) or Color3.fromRGB(50, 50, 50)
            btn.Text = settings[configKey] and "✓" or ""
        end)
    end

    createToggle("Auto Submit (Enter)", 215, "autoEnter")
    createToggle("Smart Auto-Clear", 240, "autoClear")
    createToggle("Deep Auto-Scan (V28)", 265, "autoScan")

    local function forceRetype()
        if not isTyping then
            forceRetypeNextTick = true
            infoText.Text = "Force Retrying..."
            infoText.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    end

    local retypeBtn = Instance.new("TextButton", mainFrame)
    retypeBtn.Size = UDim2.new(0.9, 0, 0, 30)
    retypeBtn.Position = UDim2.new(0.05, 0, 0, 300)
    retypeBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 20)
    retypeBtn.Text = "Force Retype [Hotkey: Q]"
    retypeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    retypeBtn.Font = Enum.Font.GothamBold
    retypeBtn.TextSize = 11
    Instance.new("UICorner", retypeBtn).CornerRadius = UDim.new(0, 6)
    retypeBtn.MouseButton1Click:Connect(forceRetype)

    local resetBtn = Instance.new("TextButton", mainFrame)
    resetBtn.Size = UDim2.new(0.9, 0, 0, 30)
    resetBtn.Position = UDim2.new(0.05, 0, 0, 340)
    resetBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 60)
    resetBtn.Text = "Reset Word History"
    resetBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)
    resetBtn.MouseButton1Click:Connect(function()
        usedWords = {}
        infoText.Text = "History Cleared!"
    end)

    local unloadBtn = Instance.new("TextButton", mainFrame)
    unloadBtn.Size = UDim2.new(0.9, 0, 0, 30)
    unloadBtn.Position = UDim2.new(0.05, 0, 0, 380)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    unloadBtn.Text = "UNLOAD SCRIPT"
    unloadBtn.TextColor3 = Color3.new(1,1,1)
    unloadBtn.Font = Enum.Font.GothamBlack
    unloadBtn.TextSize = 11
    Instance.new("UICorner", unloadBtn).CornerRadius = UDim.new(0, 6)
    
    unloadBtn.MouseButton1Click:Connect(function()
        unloaded = true
        for _, conn in pairs(connections) do conn:Disconnect() end
        sg:Destroy()
    end)

    table.insert(connections, uis.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.Q then
            forceRetype()
        end
    end))

    -- ==========================================
    -- 4. MASTER SCANNER ENGINE (Time-State Based)
    -- ==========================================
    task.spawn(function()
        local lastPrompt = ""
        local lastTypeTime = 0
        
        while task.wait(0.2) do
            if unloaded then break end
            
            if settings.autoScan and not isTyping then
                local prompt, isMyTurn = getPromptInfo()
                
                if isMyTurn and prompt ~= "" then
                    if prompt ~= lastPrompt or forceRetypeNextTick then
                        if forceRetypeNextTick then
                            clearGameInput(currentWordLength)
                            forceRetypeNextTick = false
                        end
                        
                        lastPrompt = prompt
                        local sugs = GetSuggestions(prompt)
                        
                        if #sugs > 0 then
                            local word = sugs[1]
                            usedWords[word] = true
                            currentWordLength = #word
                            
                            infoText.Text = "AUTO: " .. word:upper()
                            infoText.TextColor3 = Color3.fromRGB(0, 255, 150)
                            
                            task.spawn(function()
                                TypeText(word:sub(#prompt + 1))
                            end)
                            
                            lastTypeTime = tick() -- Catat waktu kita ngetik
                            updateSug(prompt)
                        else
                            infoText.Text = "Habis: " .. prompt:upper()
                            infoText.TextColor3 = Color3.fromRGB(255, 100, 100)
                            updateSug(prompt)
                        end
                        
                    elseif prompt == lastPrompt then
                        -- Jika kita sudah ngetik, tapi 2.2 detik kemudian giliran belum ganti (prompt sama)
                        -- Artinya jawaban kita DITOLAK atau TYPO! Langsung Retype.
                        if tick() - lastTypeTime > 2.2 then
                            forceRetypeNextTick = true
                            infoText.Text = "Ditolak! Auto-Retrying..."
                            infoText.TextColor3 = Color3.fromRGB(255, 100, 100)
                            lastTypeTime = tick() -- Reset waktu agar tidak spam loop
                        end
                    end
                else
                    if not isMyTurn then
                        lastPrompt = "" 
                        infoText.Text = "Menunggu Giliran..."
                        infoText.TextColor3 = Color3.fromRGB(150, 150, 150)
                    end
                end
            end
        end
    end)

    -- Manual Input Focus Logic
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and inputBox.Text ~= "" and not isTyping then
            local pattern = inputBox.Text:lower()
            local sugs = GetSuggestions(pattern)
            if #sugs > 0 then
                local fullWord = sugs[1]
                usedWords[fullWord] = true
                currentWordLength = #fullWord
                infoText.Text = "Manual: " .. pattern:upper() .. " + " .. fullWord:sub(#pattern + 1):upper()
                inputBox:ReleaseFocus()
                task.spawn(function() TypeText(fullWord:sub(#pattern + 1)) end)
                if settings.autoFocus then task.wait(0.2); inputBox.Text = ""; inputBox:CaptureFocus() end
            else
                infoText.Text = "Pattern Tidak Ditemukan!"
                infoText.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end
    end)
end)

if not success then warn("Dqymon Auto-Word Error: " .. tostring(err)) end
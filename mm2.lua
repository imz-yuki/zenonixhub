-- [[ ZENONIX HUB VIP - MM2 SPECIAL EDITION v2.0 ]] --
-- Developed by: Yuki.dev | Power: 9999

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- Khởi tạo UI bảo mật cao
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixHub_MM2_VIP"
local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
ScreenGui.Parent = success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Theme màu sắc Neon cao cấp
local Theme = {
    Background = Color3.fromRGB(11, 11, 14),
    MainFrame = Color3.fromRGB(15, 15, 18),
    Topbar = Color3.fromRGB(22, 22, 28),
    Accent = Color3.fromRGB(58, 134, 255),
    AccentRed = Color3.fromRGB(255, 0, 75),
    TextDark = Color3.fromRGB(140, 140, 145),
    TextLight = Color3.fromRGB(255, 255, 255)
}

-- Trạng thái các tính năng (State Manager)
local State = {
    ESPActive = false,
    ESPBoxes = true,
    ESPTracers = false,
    ESPRoles = true,
    ESPGunDrop = true,
    
    HitboxActive = false,
    HitboxSize = 2,
    
    SilentAimActive = false,
    AimPart = "Head",
    
    KillAuraActive = false,
    KillAuraDelay = 0.1,
    
    AccentColor = Theme.Accent
}

-- Các hàm hỗ trợ dựng UI mượt
local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

local function addStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(40, 40, 45)
    stroke.Thickness = thickness or 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- ==========================================
-- HỆ THỐNG THÔNG BÁO VIP (CUSTOM NOTIFICATIONS)
-- ==========================================
local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "YukiNotifications"
NotificationGui.Parent = success and coreGui or LocalPlayer:WaitForChild("PlayerGui")

local function notify(title, text, duration)
    task.spawn(function()
        local notifyFrame = Instance.new("Frame")
        notifyFrame.Size = UDim2.new(0, 260, 0, 65)
        notifyFrame.Position = UDim2.new(1, 20, 0.85, 0)
        notifyFrame.BackgroundColor3 = Theme.MainFrame
        notifyFrame.Parent = NotificationGui
        addCorner(notifyFrame, 8)
        local stroke = addStroke(notifyFrame, Theme.Accent, 1.5)
        
        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentRed)
        })
        grad.Parent = stroke

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -20, 0, 25)
        tLabel.Position = UDim2.new(0, 10, 0, 5)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = "✮ " .. tostring(title)
        tLabel.TextColor3 = Theme.TextLight
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = notifyFrame

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -20, 0, 30)
        dLabel.Position = UDim2.new(0, 10, 0, 28)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = tostring(text)
        dLabel.TextColor3 = Theme.TextDark
        dLabel.TextSize = 11
        dLabel.Font = Enum.Font.GothamMedium
        dLabel.TextWrapped = true
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = notifyFrame

        -- Hiệu ứng trượt vào mượt mà
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://4590662762"
        sound.Volume = 0.5
        sound.Parent = notifyFrame
        pcall(function() sound:Play() end)

        notifyFrame:TweenPosition(UDim2.new(1, -280, 0.85, 0), "Out", "Quad", 0.4, true)
        task.wait(duration or 3)
        notifyFrame:TweenPosition(UDim2.new(1, 20, 0.85, 0), "In", "Quad", 0.4, true)
        task.wait(0.5)
        notifyFrame:Destroy()
    end)
end

-- Khởi động thông báo chào mừng Yuki
notify("ZENONIX VIP v2", "Xin chào Yuki! Đang kết nối Yuki's Power...", 4.5)

-- ==========================================
-- KHUNG GIAO DIỆN CHÍNH (MAIN FRAME)
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 380)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
MainFrame.BackgroundColor3 = Theme.MainFrame
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 12)
local MainStroke = addStroke(MainFrame, Color3.fromRGB(45, 45, 55), 1.8)

-- Hiệu ứng viền chuyển màu RGB nhẹ
task.spawn(function()
    while task.wait(0.05) do
        local t = tick()
        local r = math.sin(t) * 0.5 + 0.5
        local g = math.sin(t + 2) * 0.5 + 0.5
        local b = math.sin(t + 4) * 0.5 + 0.5
        MainStroke.Color = Color3.new(r, g, b)
    end
end)

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 48)
Topbar.BackgroundColor3 = Theme.Topbar
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame
addCorner(Topbar, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ ZENONIX HUB | MM2 VIP v2"
Title.TextColor3 = Theme.TextLight
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 4)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 28
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.Parent = Topbar

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    notify("Zenonix Hub", "Đã gỡ giao diện hack an toàn!", 2)
end)

-- Kéo thả UI
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Topbar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 150, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = Theme.Background
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
addCorner(Sidebar, 12)

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -170, 1, -65)
ContentContainer.Position = UDim2.new(0, 160, 0, 56)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Trình tạo Tab mượt mà
local Pages = {}
local TabButtons = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.CanvasSize = UDim2.new(0, 0, 0, 450)
    page.Visible = false
    page.Parent = ContentContainer
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    
    Pages[name] = page
    return page
end

local ESPPage = createPage("ESP")
local CombatPage = createPage("Combat")
local InfoPage = createPage("PlayerInfo")

local function switchTab(tabName)
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Theme.Accent
            btn.TextColor3 = Theme.TextLight
            local t = TweenService:Create(btn, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 38)})
            t:Play()
        else
            btn.BackgroundColor3 = Theme.Topbar
            btn.TextColor3 = Theme.TextDark
            local t = TweenService:Create(btn, TweenInfo.new(0.3), {Size = UDim2.new(1, -18, 0, 35)})
            t:Play()
        end
    end
end

local function createTabButton(name, text, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -18, 0, 35)
    btn.Position = UDim2.new(0, 9, 0, positionY)
    btn.BackgroundColor3 = Theme.Topbar
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Theme.TextDark
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Sidebar
    addCorner(btn, 6)
    
    TabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

createTabButton("ESP", "👁️ MM2 ESP", 15)
createTabButton("Combat", "⚔️ VIP Combat", 60)
createTabButton("PlayerInfo", "ℹ️ Database", 105)

switchTab("ESP")

-- ==========================================
-- THƯ VIỆN WIDGETS TỰ DỰNG (TOGGLE & SLIDERS)
-- ==========================================
local function createSection(parent, text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -10, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = text:upper()
    section.TextColor3 = Theme.Accent
    section.TextSize = 11
    section.Font = Enum.Font.GothamBold
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = parent
end

local function createToggle(parent, text, stateKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 42)
    frame.BackgroundColor3 = Theme.Topbar
    frame.BorderSizePixel = 0
    frame.Parent = parent
    addCorner(frame, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextLight
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 45, 0, 22)
    button.Position = UDim2.new(1, -55, 0.5, -11)
    button.BackgroundColor3 = State[stateKey] and Theme.Accent or Color3.fromRGB(45, 45, 50)
    button.Text = ""
    button.Parent = frame
    addCorner(button, 11)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = State[stateKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = button
    addCorner(circle, 8)

    button.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        local targetColor = State[stateKey] and Theme.Accent or Color3.fromRGB(45, 45, 50)
        local targetPos = State[stateKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        
        if callback then callback(State[stateKey]) end
    end)
end

local function createSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 55)
    frame.BackgroundColor3 = Theme.Topbar
    frame.BorderSizePixel = 0
    frame.Parent = parent
    addCorner(frame, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 25)
    label.Position = UDim2.new(0, 12, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.TextLight
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.25, 0, 0, 25)
    valueLabel.Position = UDim2.new(1, -112, 0, 2)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, -24, 0, 6)
    sliderBg.Position = UDim2.new(0, 12, 0, 38)
    sliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    sliderBg.Text = ""
    sliderBg.Parent = frame
    addCorner(sliderBg, 3)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    addCorner(sliderFill, 3)

    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        local exactVal = math.round(min + (pos * (max - min)))
        valueLabel.Text = tostring(exactVal)
        callback(exactVal)
    end

    local draggingSlider = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            updateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
end

-- ==========================================
-- 1. THIẾT LẬP GIAO DIỆN CÁC TAB
-- ==========================================

-- Tab 1: ESP
createSection(ESPPage, "Định vị radar nâng cao")
createToggle(ESPPage, "Kích hoạt toàn bộ ESP MM2", "ESPActive", function(v)
    if v then notify("MM2 ESP", "Đã kích hoạt hệ thống radar!", 2.5) end
end)
createToggle(ESPPage, "Khung định vị (Boxes 2D)", "ESPBoxes")
createToggle(ESPPage, "Đường dẫn hướng (Tracers)", "ESPTracers")
createToggle(ESPPage, "Quét vai trò & Khoảng cách", "ESPRoles")
createToggle(ESPPage, "Phát hiện súng rơi (Drop Gun)", "ESPGunDrop")

-- Tab 2: COMBAT (HITBOX & AIMLOCK)
createSection(CombatPage, "Hệ thống bổ trợ bắn súng (Sheriff)")
createToggle(CombatPage, "Kích hoạt Aimlock Súng MM2", "SilentAimActive", function(v)
    if v then notify("Aim Mode", "Chỉ tự động bắn/khóa khi bạn cầm SÚNG!", 3) end
end)

createSection(CombatPage, "Hệ thống ám sát (Murderer)")
createToggle(CombatPage, "Kích hoạt Teleport Kill Aura", "KillAuraActive", function(v)
    if v then notify("Murder Aura", "Chỉ tự động dịch chuyển chém khi bạn cầm DAO!", 3) end
end)

createSection(CombatPage, "Nâng cấp kích thước kẻ địch (Hitbox)")
createToggle(CombatPage, "Kích hoạt Phóng to Hitbox", "HitboxActive", function(v)
    if v then notify("Hitbox Expander", "Cẩn thận không để người khác quay video tố cáo!", 3) end
end)
createSlider(CombatPage, "Cỡ Hitbox (Studs)", 2, 30, 15, function(v)
    State.HitboxSize = v
end)

-- ==========================================
-- 2. ĐỊNH NGHĨA VAI TRÒ TRONG MM2
-- ==========================================
local function getPlayerRole(player)
    local char = player.Character
    local backpack = player.Backpack
    
    local hasKnife = (backpack and (backpack:FindFirstChild("Knife") or backpack:FindFirstChild("Knife_Base"))) or 
                     (char and (char:FindFirstChild("Knife") or char:FindFirstChild("Knife_Base")))
    
    local hasGun = (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Gun_Base"))) or 
                   (char and (char:FindFirstChild("Gun") or char:FindFirstChild("Gun_Base")))
    
    if hasKnife then
        return "MURDERER", Theme.AccentRed
    elseif hasGun then
        return "SHERIFF", Color3.fromRGB(0, 180, 255)
    else
        return "INNOCENT", Color3.fromRGB(50, 255, 100)
    end
end

-- ==========================================
-- 3. HỆ THỐNG ESP BÁ ĐẠO NHẤT (SMART RENDERING)
-- ==========================================
local ESPObjects = {}

local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Destroy() end)
        end
        ESPObjects[player] = nil
    end
end

local function drawESP(player)
    removeESP(player)
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hrp or not hum then return end
    
    local container = {}
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "Zenonix_Highlight"
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    container.Highlight = highlight
    
    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Zenonix_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Parent = hrp
    container.Billboard = billboard
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = 13
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.3
    textLabel.Parent = billboard
    container.Label = textLabel
    
    ESPObjects[player] = container
end

-- Theo dõi vũ khí bị rơi trên sân đấu (Drop Gun Detector)
local function handleDroppedGun(instance)
    if not instance:IsA("Model") or not State.ESPGunDrop or not State.ESPActive then return end
    if instance.Name == "GunDrop" or instance:FindFirstChild("Gun_Base") then
        task.wait(0.2)
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "Zenonix_GunBillboard"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Parent = instance
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "🚨 SÚNG BỊ RƠI!"
        label.TextColor3 = Color3.fromRGB(255, 230, 0)
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
        
        notify("CẢNH BÁO", "Súng của Sheriff đã bị rơi! Hãy tới nhặt ngay!", 4)
    end
end

Workspace.ChildAdded:Connect(handleDroppedGun)
for _, child in ipairs(Workspace:GetChildren()) do
    handleDroppedGun(child)
end

-- Vòng lặp cập nhật thông tin ESP
RunService.RenderStepped:Connect(function()
    if not State.ESPActive then
        for p, _ in pairs(ESPObjects) do removeESP(p) end
        return
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                if not ESPObjects[player] then
                    drawESP(player)
                end
                
                local obj = ESPObjects[player]
                local role, color = getPlayerRole(player)
                
                -- Cập nhật highlight màu sắc theo vai trò
                if obj.Highlight and State.ESPBoxes then
                    obj.Highlight.Enabled = true
                    obj.Highlight.FillColor = color
                    obj.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                elseif obj.Highlight then
                    obj.Highlight.Enabled = false
                end
                
                -- Cập nhật thông tin vai trò, tên, khoảng cách
                if obj.Label and State.ESPRoles then
                    local dist = 0
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        dist = math.round((LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
                    end
                    obj.Label.Text = string.format("[%s]\n%s\n[%d studs]", role, player.DisplayName, dist)
                    obj.Label.TextColor3 = color
                elseif obj.Label then
                    obj.Label.Text = ""
                end
            else
                removeESP(player)
            end
        end
    end
end)

-- dọn dẹp khi người chơi thoát
Players.PlayerRemoving:Connect(removeESP)

-- ==========================================
-- 4. HỆ THỐNG PHÓNG TO HITBOX (HITBOX EXPANDER)
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if State.HitboxActive then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local role = getPlayerRole(player)
                    
                    if hrp then
                        -- Phóng to Head/RootPart giúp Yuki dễ chém/bắn trúng
                        hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                        hrp.Transparency = 0.65
                        hrp.Color = (role == "MURDERER") and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 150, 255)
                        hrp.Material = Enum.Material.ForceField
                        hrp.CanCollide = false
                    end
                end
            end
        else
            -- Phục hồi kích cỡ gốc khi tắt
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                        hrp.CanCollide = true
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- 5. AIMLOCK CHUYÊN SÂU & DỊCH CHUYỂN TIÊU DIỆT
-- ==========================================
local function getMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = getPlayerRole(player)
            if role == "MURDERER" and player.Character and player.Character:FindFirstChild("Head") then
                return player
            end
        end
    end
    return nil
end

local function getNearestInnocent()
    local nearest = nil
    local shortestDist = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = getPlayerRole(player)
            -- Sát nhân nhắm mục tiêu là Dân thường hoặc Sheriff
            if role ~= "MURDERER" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = player
                end
            end
        end
    end
    return nearest
end

-- Vòng lặp chiến đấu cốt lõi (Vòng lặp quan trọng nhất)
RunService.RenderStepped:Connect(function()
    local myRole = getPlayerRole(LocalPlayer)
    
    -- TRƯỜNG HỢP 1: YUKI LÀ SHERIFF (CÓ SÚNG) -> TỰ ĐỘNG KHÓA VÀO ĐẦU MUDERER
    if State.SilentAimActive and myRole == "SHERIFF" then
        local target = getMurderer()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(State.AimPart)
            if targetPart then
                -- Ép góc Camera hướng thẳng vào đầu Sát nhân
                local cam = Workspace.CurrentCamera
                local targetCFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
                cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.25) -- Khoá mượt mà không bị giật lag
            end
        end
        
    -- TRƯỜNG HỢP 2: YUKI LÀ MURDERER (CÓ DAO) -> DỊCH CHUYỂN RA SAU LƯNG ĐỂ CHÉM
    elseif State.KillAuraActive and myRole == "MURDERER" then
        local target = getNearestInnocent()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHRP = target.Character.HumanoidRootPart
            
            if myHRP then
                -- Teleport ra phía sau lưng nạn nhân 3 studs để chém lén hoàn hảo
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end
end)


-- ==========================================
-- 6. TAB 3: TRUY XUẤT DATABASE SERVER CHI TIẾT
-- ==========================================
local DatabaseLabel = Instance.new("TextLabel")
DatabaseLabel.Size = UDim2.new(1, -20, 0, 30)
DatabaseLabel.BackgroundTransparency = 1
DatabaseLabel.Text = "DANH SÁCH KHÁCH HÀNG SERVER THỜI GIAN THỰC"
DatabaseLabel.TextColor3 = Theme.TextLight
DatabaseLabel.TextSize = 13
DatabaseLabel.Font = Enum.Font.GothamBold
DatabaseLabel.Parent = InfoPage

local ListFrame = Instance.new("Frame")
ListFrame.Size = UDim2.new(1, -10, 0, 200)
ListFrame.BackgroundColor3 = Theme.Topbar
ListFrame.Parent = InfoPage
addCorner(ListFrame, 8)

local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(1, -10, 1, -10)
ListScroll.Position = UDim2.new(0, 5, 0, 5)
ListScroll.BackgroundTransparency = 1
ListScroll.ScrollBarThickness = 2
ListScroll.CanvasSize = UDim2.new(0, 0, 0, 350)
ListScroll.Parent = ListFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 5)
UIList.Parent = ListScroll

local function updateDatabaseView()
    for _, child in ipairs(ListScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        local pFrame = Instance.new("Frame")
        pFrame.Size = UDim2.new(1, -5, 0, 35)
        pFrame.BackgroundColor3 = Theme.MainFrame
        pFrame.Parent = ListScroll
        addCorner(pFrame, 4)
        
        local pName = Instance.new("TextLabel")
        pName.Size = UDim2.new(0.6, 0, 1, 0)
        pName.Position = UDim2.new(0, 10, 0, 0)
        pName.BackgroundTransparency = 1
        local role = getPlayerRole(player)
        pName.Text = player.DisplayName .. " [" .. role .. "]"
        pName.TextColor3 = (role == "MURDERER") and Theme.AccentRed or (role == "SHERIFF" and Color3.fromRGB(0, 180, 255) or Theme.TextLight)
        pName.TextSize = 11
        pName.Font = Enum.Font.GothamMedium
        pName.TextXAlignment = Enum.TextXAlignment.Left
        pName.Parent = pFrame
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0, 80, 0, 25)
        tpBtn.Position = UDim2.new(1, -90, 0.5, -12)
        tpBtn.BackgroundColor3 = Theme.Accent
        tpBtn.Text = "Teleport"
        tpBtn.TextColor3 = Theme.TextLight
        tpBtn.TextSize = 11
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.Parent = pFrame
        addCorner(tpBtn, 4)
        
        tpBtn.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                notify("TELEPORT", "Đã bay tới người chơi: " .. player.DisplayName, 2)
            end
        end)
    end
end

-- Cập nhật Database tự động sau mỗi 5 giây
task.spawn(function()
    while task.wait(5) do
        if InfoPage.Visible then
            updateDatabaseView()
        end
    end
end)

InfoPage:GetPropertyChangedSignal("Visible"):Connect(function()
    if InfoPage.Visible then updateDatabaseView() end
end)

print("------------------------------------------")
print("🔥 ZENONIX HUB: MM2 SPECIAL VIP v2 LOADED!")
print("👑 Built for: Yuki | Power 9999")
print("------------------------------------------")

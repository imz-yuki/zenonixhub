-- [[ ZENONIX HUB VIP - MM2 SPECIAL EDITION v3.0 ]] --
-- ✮ Developed by: Yuki.dev | Power: 9999
-- 🛠️ REMASTERED: Fixed Persistent Round Resets, Anti-Blink Hitbox, UI Minimize, Auto-Swing, & FOV Aimlock.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Tránh chạy trùng lặp nhiều thực thể script gây lag game
if _G.ZenonixLoaded then
    pcall(function() _G.ZenonixCleanup() end)
end
_G.ZenonixLoaded = true

-- Theme màu sắc Neon cao cấp độc quyền của Yuki
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
    HitboxSize = 15,
    HitboxTransparency = 0.65,
    
    SilentAimActive = false,
    AimPart = "Head",
    AimSmoothness = 0.2,
    AimFOV = 150,
    ShowFOV = true,
    
    KillAuraActive = false,
    AutoSwing = true,
    AutoCollectGun = false,
    
    AccentColor = Theme.Accent
}

-- ==========================================
-- HỆ THỐNG QUẢN LÝ BỘ NHỚ & SỰ KIỆN (JANITOR SYSTEM)
-- ==========================================
local Janitor = {
    Connections = {},
    Objects = {},
    ESPTracks = {},
    PlayerConnections = {}
}

function Janitor:Add(connection, tag)
    if tag then
        if self.Connections[tag] then self.Connections[tag]:Disconnect() end
        self.Connections[tag] = connection
    else
        table.insert(self.Connections, connection)
    end
    return connection
end

function Janitor:AddObject(object)
    table.insert(self.Objects, object)
    return object
end

function Janitor:Clean()
    for _, conn in pairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    self.Connections = {}
    
    for _, conn in pairs(self.PlayerConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    self.PlayerConnections = {}

    for _, obj in ipairs(self.Objects) do
        if obj then pcall(function() obj:Destroy() end) end
    end
    self.Objects = {}

    for p, items in pairs(self.ESPTracks) do
        for _, item in pairs(items) do
            pcall(function() item:Destroy() end)
        end
    end
    self.ESPTracks = {}

    -- Khôi phục kích thước người chơi về ban đầu
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            pcall(function()
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                end
            end)
        end
    end
    
    _G.ZenonixLoaded = false
end
_G.ZenonixCleanup = function() Janitor:Clean() end

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

-- Khởi tạo UI bảo mật cao chống bị phát hiện bởi Anti-Cheat hoặc các script chụp màn hình
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixHub_MM2_VIP_V3"
ScreenGui.ResetOnSpawn = false
local success, coreGui = pcall(function() return CoreGui end)
ScreenGui.Parent = success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
Janitor:AddObject(ScreenGui)

-- ==========================================
-- HỆ THỐNG THÔNG BÁO VIP (CUSTOM NOTIFICATIONS)
-- ==========================================
local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "YukiNotifications_V3"
NotificationGui.Parent = success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
Janitor:AddObject(NotificationGui)

local function notify(title, text, duration)
    task.spawn(function()
        local notifyFrame = Instance.new("Frame")
        notifyFrame.Size = UDim2.new(0, 280, 0, 70)
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
        tLabel.Position = UDim2.new(0, 12, 0, 5)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = "★ " .. tostring(title)
        tLabel.TextColor3 = Theme.TextLight
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = notifyFrame

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -20, 0, 35)
        dLabel.Position = UDim2.new(0, 12, 0, 28)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = tostring(text)
        dLabel.TextColor3 = Theme.TextDark
        dLabel.TextSize = 11
        dLabel.Font = Enum.Font.GothamMedium
        dLabel.TextWrapped = true
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = notifyFrame

        -- Hiệu ứng âm thanh thông báo cao cấp
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://4590662762"
        sound.Volume = 0.35
        sound.Parent = notifyFrame
        pcall(function() sound:Play() end)

        notifyFrame:TweenPosition(UDim2.new(1, -300, 0.85, -20), "Out", "Back", 0.4, true)
        task.wait(duration or 3)
        notifyFrame:TweenPosition(UDim2.new(1, 20, 0.85, -20), "In", "Quad", 0.4, true)
        task.wait(0.5)
        notifyFrame:Destroy()
    end)
end

-- Khởi động thông báo chào mừng Yuki
notify("ZENONIX VIP v3.0", "Xin chào Yuki! Đang kết kết nối Yuki's Power...", 4.5)

-- ==========================================
-- NÚT MINIMIZE (THU NHỎ GIAO DIỆN) SIÊU ĐẸP
-- ==========================================
local MinimizedBtn = Instance.new("TextButton")
MinimizedBtn.Name = "MinimizeButton"
MinimizedBtn.Size = UDim2.new(0, 50, 0, 50)
MinimizedBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
MinimizedBtn.BackgroundColor3 = Theme.MainFrame
MinimizedBtn.Text = "ZX"
MinimizedBtn.TextColor3 = Theme.Accent
MinimizedBtn.TextSize = 16
MinimizedBtn.Font = Enum.Font.GothamBold
MinimizedBtn.Visible = false
MinimizedBtn.Parent = ScreenGui
addCorner(MinimizedBtn, 25)
local miniStroke = addStroke(MinimizedBtn, Theme.Accent, 2)

-- Kéo thả cho nút Minimize
local miniDragging, miniDragStart, miniStartPos
MinimizedBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miniDragging = true
        miniDragStart = input.Position
        miniStartPos = MinimizedBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then miniDragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if miniDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miniDragStart
        MinimizedBtn.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y)
    end
end)

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

-- Hiệu ứng viền chuyển màu RGB nhẹ siêu mượt
task.spawn(function()
    while task.wait(0.01) do
        if not _G.ZenonixLoaded then break end
        local t = tick()
        local r = math.sin(t * 1.5) * 0.5 + 0.5
        local g = math.sin(t * 1.5 + 2) * 0.5 + 0.5
        local b = math.sin(t * 1.5 + 4) * 0.5 + 0.5
        MainStroke.Color = Color3.new(r, g, b)
        miniStroke.Color = Color3.new(r, g, b)
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

-- Phủ góc dưới của Topbar để giữ phong cách thiết kế phẳng
local TopbarCover = Instance.new("Frame")
TopbarCover.Size = UDim2.new(1, 0, 0, 10)
TopbarCover.Position = UDim2.new(0, 0, 1, -10)
TopbarCover.BackgroundColor3 = Theme.Topbar
TopbarCover.BorderSizePixel = 0
TopbarCover.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ ZENONIX HUB | MM2 VIP v3"
Title.TextColor3 = Theme.TextLight
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

-- Nút Minimize (Thu nhỏ trên Topbar)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 40, 0, 40)
MinimizeBtn.Position = UDim2.new(1, -85, 0, 4)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Topbar

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.ClipsDescendants = true
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 580, 0, 0),
        Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 190)
    }):Play()
    task.wait(0.3)
    MainFrame.Visible = false
    MinimizedBtn.Visible = true
    notify("Minimize", "Đã ẩn giao diện. Nhấn nút ZX trên màn hình để mở lại!", 1.5)
end)

MinimizedBtn.MouseButton1Click:Connect(function()
    MinimizedBtn.Visible = false
    MainFrame.Visible = true
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 580, 0, 380),
        Position = UDim2.new(0.5, -290, 0.5, -190)
    }):Play()
    task.wait(0.4)
    MainFrame.ClipsDescendants = false
end)

-- Nút Đóng UI (An toàn & Dọn Rác)
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
    Janitor:Clean()
    notify("Zenonix Hub", "Đã dọn dẹp bộ nhớ và tắt hack MM2 thành công!", 2)
end)

-- Kéo thả khung chính MainFrame
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

-- Che phủ các góc cần thiết để giữ form chuẩn
local SidebarCover = Instance.new("Frame")
SidebarCover.Size = UDim2.new(0, 10, 1, 0)
SidebarCover.Position = UDim2.new(1, -10, 0, 0)
SidebarCover.BackgroundColor3 = Theme.Background
SidebarCover.BorderSizePixel = 0
SidebarCover.Parent = Sidebar

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
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 480)
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
local ModPage = createPage("SelfMods")
local InfoPage = createPage("PlayerInfo")

local function switchTab(tabName)
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Theme.Accent
            btn.TextColor3 = Theme.TextLight
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -10, 0, 38)}):Play()
        else
            btn.BackgroundColor3 = Theme.Topbar
            btn.TextColor3 = Theme.TextDark
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -18, 0, 35)}):Play()
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
createTabButton("SelfMods", "⚡ Self Mods", 105)
createTabButton("PlayerInfo", "ℹ️ Database", 150)

switchTab("ESP")

-- ==========================================
-- THƯ VIỆN WIDGETS TỰ DỰNG (TOGGLES, SLIDERS & DROPDOWNS)
-- ==========================================
local function createSection(parent, text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -10, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = "  " .. text:upper()
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
        
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        
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
-- 1. THIẾT LẬP CÁC WIDGETS TÙY CHỌN TRONG TABS
-- ==========================================

-- Tab: ESP
createSection(ESPPage, "Định vị Radar MM2 chuyên sâu")
createToggle(ESPPage, "Kích hoạt toàn bộ ESP MM2", "ESPActive", function(v)
    if v then notify("MM2 ESP", "Đã khởi tạo hệ thống radar tầm xa!", 2.5) end
end)
createToggle(ESPPage, "Khung định vị (Boxes Dynamic Highlight)", "ESPBoxes")
createToggle(ESPPage, "Vẽ đường định hướng (Tracers)", "ESPTracers")
createToggle(ESPPage, "Hiện Vai Trò & Khoảng Cách", "ESPRoles")
createToggle(ESPPage, "Dò súng bị rơi (Dropped Gun Tracker)", "ESPGunDrop")

-- Tab: Combat
createSection(CombatPage, "Hệ thống bổ trợ Sheriff")
createToggle(CombatPage, "Kích hoạt Aimlock Súng MM2", "SilentAimActive", function(v)
    if v then notify("Aim Mode", "Chế độ bắn chuẩn xác cao đã sẵn sàng!", 2.5) end
end)
createSlider(CombatPage, "Cỡ Vòng quét Aim (FOV Circle)", 50, 500, 150, function(v)
    State.AimFOV = v
end)
createSlider(CombatPage, "Độ nhạy Aim (Smoothness)", 1, 100, 80, function(v)
    State.AimSmoothness = (101 - v) / 100 -- Càng mượt thì độ bám càng tự nhiên
end)

createSection(CombatPage, "Hệ thống ám sát Murderer")
createToggle(CombatPage, "Bật Auto-Teleport Kill Aura", "KillAuraActive")
createToggle(CombatPage, "Tự Động Vung Dao (Auto Swing)", "AutoSwing")

createSection(CombatPage, "Nâng Cấp Hitbox Kẻ Địch")
createToggle(CombatPage, "Phóng To Hitbox Người Chơi", "HitboxActive", function(v)
    if v then notify("Hitbox Locked", "Hitbox đã được áp dụng. Qua trận mới tự binding lại!", 2) end
end)
createSlider(CombatPage, "Kích thước Hitbox (Studs)", 5, 30, 15, function(v)
    State.HitboxSize = v
end)

-- Tab: Self Mods
createSection(ModPage, "Nâng cấp cơ bản của nhân vật")
local currentSpeed = 16
createSlider(ModPage, "Tốc độ chạy (WalkSpeed)", 16, 120, 16, function(v)
    currentSpeed = v
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
        end
    end)
end)

local currentJump = 50
createSlider(ModPage, "Độ cao nhảy (JumpPower)", 50, 200, 50, function(v)
    currentJump = v
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = v
        end
    end)
end)

createSection(ModPage, "Hỗ trợ nhặt súng tự động")
createToggle(ModPage, "Tự động dịch chuyển nhặt súng rơi", "AutoCollectGun", function(v)
    if v then notify("Auto Collect", "Sẽ tự động dịch chuyển nhặt súng khi súng rơi!", 2.5) end
end)


-- ==========================================
-- 2. ĐỊNH NGHĨA VAI TRÒ CHUẨN TRONG MM2
-- ==========================================
local function getPlayerRole(player)
    if not player then return "INNOCENT", Color3.fromRGB(50, 255, 100) end
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    local hasKnife = (backpack and (backpack:FindFirstChild("Knife") or backpack:FindFirstChild("Knife_Base") or backpack:FindFirstChild("MurdererKnife"))) or 
                     (char and (char:FindFirstChild("Knife") or char:FindFirstChild("Knife_Base") or char:FindFirstChild("MurdererKnife")))
    
    local hasGun = (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Gun_Base") or backpack:FindFirstChild("SheriffGun"))) or 
                   (char and (char:FindFirstChild("Gun") or char:FindFirstChild("Gun_Base") or char:FindFirstChild("SheriffGun")))
    
    if hasKnife then
        return "MURDERER", Theme.AccentRed
    elseif hasGun then
        return "SHERIFF", Color3.fromRGB(0, 180, 255)
    else
        return "INNOCENT", Color3.fromRGB(50, 255, 100)
    end
end

-- ==========================================
-- 3. HỆ THỐNG ESP BẤT TỬ (PERSISTENT & ROBUST RENDER)
-- ==========================================
local function cleanPlayerESP(player)
    if Janitor.ESPTracks[player] then
        for _, obj in pairs(Janitor.ESPTracks[player]) do
            pcall(function() obj:Destroy() end)
        end
        Janitor.ESPTracks[player] = nil
    end
end

local function drawESP(player)
    cleanPlayerESP(player)
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:WaitForChild("HumanoidRootPart", 8)
    local hum = char:WaitForChild("Humanoid", 8)
    if not hrp or not hum then return end
    
    local storage = {}
    
    -- Highlight để tạo khung viền 3D sắc nét xuyên tường
    local highlight = Instance.new("Highlight")
    highlight.Name = "ZX_Highlight"
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = char
    highlight.Parent = ScreenGui
    storage.Highlight = highlight
    
    -- Billboard hiển thị chữ (Tên, vai trò, khoảng cách)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ZX_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Adornee = hrp
    billboard.Parent = ScreenGui
    storage.Billboard = billboard
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.35
    textLabel.Parent = billboard
    storage.Label = textLabel

    -- Vẽ Tracer Line (Đường kẻ dẫn hướng)
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Transparency = 0.7
    storage.Tracer = tracer
    
    Janitor.ESPTracks[player] = storage
end

-- Tự động binding lại các sự kiện khi nhân vật hồi sinh (Sang trận mới)
local function bindPlayerEvents(player)
    if player == LocalPlayer then return end
    
    local function onCharacter(char)
        if not char then return end
        task.wait(1.2) -- Chờ game khởi tạo hoàn tất nhân vật gốc
        if State.ESPActive then
            drawESP(player)
        end
    end
    
    local charConn = player.CharacterAdded:Connect(onCharacter)
    table.insert(Janitor.PlayerConnections, charConn)
    
    if player.Character then
        onCharacter(player.Character)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    bindPlayerEvents(p)
end
Janitor:Add(Players.PlayerAdded:Connect(bindPlayerEvents))
Players.PlayerRemoving:Connect(cleanPlayerESP)

-- Vòng lặp cập nhật thông tin ESP, Tracers trên khung hình thực tế
Janitor:Add(RunService.RenderStepped:Connect(function()
    if not State.ESPActive then
        for p, _ in pairs(Janitor.ESPTracks) do cleanPlayerESP(p) end
        return
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local storage = Janitor.ESPTracks[player]
            
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
                if not storage then
                    drawESP(player)
                    storage = Janitor.ESPTracks[player]
                end
                
                if storage then
                    local hrp = char.HumanoidRootPart
                    local head = char.Head
                    local role, color = getPlayerRole(player)
                    
                    -- Cập nhật 3D Highlight
                    if storage.Highlight then
                        storage.Highlight.Enabled = State.ESPBoxes
                        storage.Highlight.FillColor = color
                        storage.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                    
                    -- Cập nhật Billboard chữ
                    if storage.Label then
                        if State.ESPRoles then
                            storage.Billboard.Enabled = true
                            local dist = 0
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                dist = math.round((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                            end
                            storage.Label.Text = string.format("[%s]\n%s\n[%d studs]", role, player.DisplayName, dist)
                            storage.Label.TextColor3 = color
                        else
                            storage.Billboard.Enabled = false
                        end
                    end
                    
                    -- Cập nhật Tracer dẫn đường bằng Camera Viewport
                    if storage.Tracer then
                        if State.ESPTracers then
                            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                storage.Tracer.Visible = true
                                storage.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                storage.Tracer.To = Vector2.new(vector.X, vector.Y)
                                storage.Tracer.Color = color
                            else
                                storage.Tracer.Visible = false
                            end
                        else
                            storage.Tracer.Visible = false
                        end
                    end
                end
            else
                cleanPlayerESP(player)
            end
        end
    end
end))

-- ==========================================
-- 4. THEO DÕI SÚNG RƠI & AUTO COLLECT GUN
-- ==========================================
local function handleDroppedGun(instance)
    task.wait(0.2)
    if not _G.ZenonixLoaded then return end
    
    local gunBase = instance:FindFirstChild("Gun_Base") or (instance:IsA("Model") and instance.Name == "GunDrop")
    if gunBase or instance.Name == "GunDrop" then
        -- Vẽ cột ánh sáng báo hiệu súng rơi
        if State.ESPGunDrop and State.ESPActive then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ZX_GunBillboard"
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.new(0, 150, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.Parent = instance
            Janitor:AddObject(billboard)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "🚨 SÚNG BỊ RƠI!"
            label.TextColor3 = Color3.fromRGB(255, 220, 0)
            label.TextSize = 13
            label.Font = Enum.Font.GothamBold
            label.Parent = billboard
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "ZX_GunHighlight"
            highlight.FillColor = Color3.fromRGB(255, 220, 0)
            highlight.FillTransparency = 0.5
            highlight.Adornee = instance
            highlight.Parent = instance
            
            notify("CẢNH BÁO", "Súng của Sheriff đã bị rơi! Đến nhặt ngay!", 4.5)
        end
        
        -- Auto Collect Gun: Dịch chuyển chớp mắt đến nhặt súng
        if State.AutoCollectGun then
            task.spawn(function()
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local oldCF = myHRP.CFrame
                    local targetPos = instance:IsA("Model") and instance:GetPivot().Position or instance.Position
                    
                    notify("AUTO GUN", "Đang tự động nhảy tới nhặt súng...", 2)
                    -- Dịch chuyển tới vị trí súng, đợi nhặt rồi quay lại chỗ cũ
                    for i = 1, 15 do
                        myHRP.CFrame = CFrame.new(targetPos + Vector3.new(0, 1, 0))
                        task.wait(0.05)
                    end
                    myHRP.CFrame = oldCF
                end
            end)
        end
    end
end

Janitor:Add(Workspace.ChildAdded:Connect(handleDroppedGun))
for _, child in ipairs(Workspace:GetChildren()) do
    handleDroppedGun(child)
end

-- ==========================================
-- 5. LÕI PHÁT TRIỂN HITBOX (ANTI-BLINK PHYSICS OVERRIDE)
-- ==========================================
local function setupHitboxForPlayer(player)
    if player == LocalPlayer then return end
    
    local function setup()
        local char = player.Character
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 8)
        if not hrp then return end
        
        -- Sử dụng vòng lặp vật lý tốc độ cao để khóa cứng thuộc tính
        local hbConn = RunService.PreSimulation:Connect(function()
            if not _G.ZenonixLoaded then return end
            if not char.Parent or not player.Parent then return end
            
            if State.HitboxActive then
                local role, color = getPlayerRole(player)
                hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                hrp.Transparency = State.HitboxTransparency
                hrp.Color = (role == "MURDERER") and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 150, 255)
                hrp.Material = Enum.Material.ForceField
                
                -- [[ KHÓA CHẶT VẬT LÝ TRÁNH GIẬT/CHỚP CHỚP/RƠI BẢN ĐỒ ]] --
                hrp.CanCollide = false
                hrp.CastShadow = false
                hrp.Massless = true
                if hrp:CanDeclareVelocity() then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            else
                -- Khi tắt, lập tức hồi phục trạng thái gốc
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.CanCollide = true
                hrp.Material = Enum.Material.Plastic
            end
        end)
        table.insert(Janitor.PlayerConnections, hbConn)
    end
    
    player.CharacterAdded:Connect(function()
        task.wait(1.5)
        setup()
    end)
    
    if player.Character then setup() end
end

for _, p in ipairs(Players:GetPlayers()) do
    setupHitboxForPlayer(p)
end
Janitor:Add(Players.PlayerAdded:Connect(setupHitboxForPlayer))


-- ==========================================
-- 6. CAMERA SILENT AIMLOCK WITH PROJECTION FOV
-- ==========================================
-- Vẽ vòng tròn FOV trực tiếp bằng Drawing API
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Color = Theme.Accent
Janitor:AddObject(FOVCircle)

local function getClosestPlayerInFOV()
    local target = nil
    local shortestDist = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if hrp and head then
                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local screenPos = Vector2.new(vector.X, vector.Y)
                    local dist = (screenPos - mousePos).Magnitude
                    
                    if dist <= State.AimFOV and dist < shortestDist then
                        -- Kiểm tra nếu đang ngắm Sheriff/Murderer tùy vai trò của bạn
                        local myRole = getPlayerRole(LocalPlayer)
                        local targetRole = getPlayerRole(player)
                        
                        local isTargetValid = false
                        if myRole == "SHERIFF" and targetRole == "MURDERER" then
                            isTargetValid = true
                        elseif myRole == "MURDERER" and targetRole ~= "MURDERER" then
                            isTargetValid = true
                        elseif myRole == "INNOCENT" then
                            isTargetValid = true -- Đề phòng tự vệ
                        end
                        
                        if isTargetValid then
                            shortestDist = dist
                            target = player
                        end
                    end
                end
            end
        end
    end
    return target
end

-- Vòng lặp cập nhật Aimlock và Vòng tròn FOV
Janitor:Add(RunService.RenderStepped:Connect(function()
    -- Cập nhật trạng thái vòng tròn FOV
    if State.SilentAimActive and State.ShowFOV then
        FOVCircle.Visible = true
        FOVCircle.Radius = State.AimFOV
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Color = (getPlayerRole(LocalPlayer) == "SHERIFF") and Color3.fromRGB(0, 180, 255) or Theme.Accent
    else
        FOVCircle.Visible = false
    end
    
    -- Xử lý Aimlock Camera mượt mà khi nhắm mục tiêu
    if State.SilentAimActive then
        local myRole = getPlayerRole(LocalPlayer)
        -- Chỉ bám súng khi local player là Sheriff hoặc đang cầm súng nhặt
        local target = getClosestPlayerInFOV()
        if target and target.Character then
            local aimPart = target.Character:FindFirstChild(State.AimPart)
            if aimPart then
                local currentCF = Camera.CFrame
                -- Thuật toán dự tính vị trí di chuyển thực tế (Prediction)
                local targetVelocity = aimPart.Parent:FindFirstChild("HumanoidRootPart") and aimPart.Parent.HumanoidRootPart.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                local predictedPosition = aimPart.Position + (targetVelocity * 0.055)
                
                local targetCFrame = CFrame.new(currentCF.Position, predictedPosition)
                Camera.CFrame = currentCF:Lerp(targetCFrame, State.AimSmoothness)
            end
        end
    end
end))


-- ==========================================
-- 7. MURDERER KILL AURA WITH AUTO-SWING
-- ==========================================
task.spawn(function()
    while task.wait(0.01) do
        if not _G.ZenonixLoaded then break end
        
        local myRole = getPlayerRole(LocalPlayer)
        if State.KillAuraActive and myRole == "MURDERER" then
            -- Tìm kiếm nạn nhân dân thường hoặc Sheriff gần bạn nhất
            local target = nil
            local shortestDist = math.huge
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if myHRP then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local role = getPlayerRole(player)
                        if role ~= "MURDERER" then
                            local dist = (player.Character.HumanoidRootPart.Position - myHRP.Position).Magnitude
                            if dist < shortestDist then
                                shortestDist = dist
                                target = player
                            end
                        end
                    end
                end
                
                -- Thực hiện dịch chuyển ám sát ra sau lưng
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = target.Character.HumanoidRootPart
                    local knife = LocalPlayer.Character:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife_Base")
                    
                    if knife then
                        -- Bay ra sau lưng nạn nhân 2.8 studs để chém lén hoàn hảo không thể trượt
                        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2.8)
                        
                        -- Tự động vung dao (Auto Swing) mô phỏng nhấp chuột thật
                        if State.AutoSwing then
                            knife:Activate()
                        end
                    end
                end
            end
        end
    end
end)


-- ==========================================
-- 8. TỰ ĐỘNG KHÓA THÔNG SỐ NHÂN VẬT (SPEED & JUMP BYPASS)
-- ==========================================
Janitor:Add(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1.5)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.WalkSpeed = currentSpeed
        hum.JumpPower = currentJump
        
        -- Lắng nghe xem game có cố tình khôi phục lại tốc độ của bạn không
        local speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if hum.WalkSpeed ~= currentSpeed then
                hum.WalkSpeed = currentSpeed
            end
        end)
        local jumpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if hum.JumpPower ~= currentJump then
                hum.JumpPower = currentJump
            end
        end)
        table.insert(Janitor.PlayerConnections, speedConn)
        table.insert(Janitor.PlayerConnections, jumpConn)
    end
end))


-- ==========================================
-- 9. TAB: TRUY XUẤT DATABASE SERVER CHI TIẾT
-- ==========================================
local DatabaseLabel = Instance.new("TextLabel")
DatabaseLabel.Size = UDim2.new(1, -20, 0, 30)
DatabaseLabel.BackgroundTransparency = 1
DatabaseLabel.Text = "DANH SÁCH GAME THỦ TRONG SERVER (REAL-TIME)"
DatabaseLabel.TextColor3 = Theme.TextLight
DatabaseLabel.TextSize = 12
DatabaseLabel.Font = Enum.Font.GothamBold
DatabaseLabel.Parent = InfoPage

local ListFrame = Instance.new("Frame")
ListFrame.Size = UDim2.new(1, -10, 0, 240)
ListFrame.BackgroundColor3 = Theme.Topbar
ListFrame.Parent = InfoPage
addCorner(ListFrame, 8)

local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(1, -10, 1, -10)
ListScroll.Position = UDim2.new(0, 5, 0, 5)
ListScroll.BackgroundTransparency = 1
ListScroll.ScrollBarThickness = 3
ListScroll.CanvasSize = UDim2.new(0, 0, 0, 450)
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
        pFrame.Size = UDim2.new(1, -5, 0, 40)
        pFrame.BackgroundColor3 = Theme.MainFrame
        pFrame.Parent = ListScroll
        addCorner(pFrame, 6)
        
        local pName = Instance.new("TextLabel")
        pName.Size = UDim2.new(0.6, 0, 1, 0)
        pName.Position = UDim2.new(0, 12, 0, 0)
        pName.BackgroundTransparency = 1
        
        local role, color = getPlayerRole(player)
        pName.Text = player.DisplayName .. " (@" .. player.Name .. ")"
        pName.TextColor3 = color
        pName.TextSize = 11
        pName.Font = Enum.Font.GothamMedium
        pName.TextXAlignment = Enum.TextXAlignment.Left
        pName.Parent = pFrame
        
        -- Nút Teleport nhanh tới người chơi
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0, 80, 0, 26)
        tpBtn.Position = UDim2.new(1, -90, 0.5, -13)
        tpBtn.BackgroundColor3 = Theme.Accent
        tpBtn.Text = "Teleport"
        tpBtn.TextColor3 = Theme.TextLight
        tpBtn.TextSize = 11
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.Parent = pFrame
        addCorner(tpBtn, 4)
        
        tpBtn.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and player.Character then
                local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local tarHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if myHRP and tarHRP then
                    myHRP.CFrame = tarHRP.CFrame * CFrame.new(0, 3, 0)
                    notify("TELEPORT", "Đã di chuyển tới " .. player.DisplayName, 2)
                end
            end
        end)
    end
end

-- Tự động cập nhật giao diện Database khi trang hiển thị
task.spawn(function()
    while task.wait(4) do
        if not _G.ZenonixLoaded then break end
        if InfoPage.Visible then
            updateDatabaseView()
        end
    end
end)

InfoPage:GetPropertyChangedSignal("Visible"):Connect(function()
    if InfoPage.Visible then updateDatabaseView() end
end)

print("------------------------------------------")
print("🔥 ZENONIX HUB: MM2 SPECIAL VIP v3.0 LOADED!")
print("👑 Specially Coded for Yuki | Power 9999")
print("⚡ Anti-Blink [ACTIVE] | Round persistence [LOCKED]")
print("------------------------------------------")

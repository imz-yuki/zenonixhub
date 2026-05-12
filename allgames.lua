--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║      ⌬  ZENONIX GOD MODE V4.0 // OMNIVERSE ULTIMATE PERFORMANCE SYSTEM    ║
    ║      >> CORE DEVELOPER: MINH MEO OMNIVERSE ETERNAL                        ║
    ║      >> ARCHITECTURE: CROSS-PLATFORM ALL-GAMES ENGINE                     ║
    ║      >> SPECIALIZATION: PROXIMITY AIMLOCK & ADVANCED LAG REDUCER          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]--

-- ==================== [ HỆ THỐNG DỊCH VỤ CỐT LÕI ] ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")

-- Đảm bảo Camera luôn được cập nhật chính xác khi hồi sinh nhân vật
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

-- ==================== [ BẢNG CẤU HÌNH BIẾN TOÀN CỤC ] ====================
local Settings = {
    -- Siêu Combat RAGE
    Aimlock = false,
    AimType = "Khoảng Cách Thực (Gần Nhất)", -- Khoảng Cách Thực / Tâm Chuột
    TargetPart = "HumanoidRootPart",
    Prediction = 0.14,
    Smoothing = 0.08,
    ShowFOV = false,
    FOVRadius = 150,
    TeamCheck = false,
    WallCheck = false,
    
    -- Tiện ích Hitbox & Aura
    Hitbox = false,
    HitboxSize = 15,
    HitboxPart = "HumanoidRootPart",
    HitboxTrans = 0.6,
    KillAura = false,
    AuraRange = 25,
    AutoAttack = false,
    
    -- Siêu Thấu Thị (Visual ESP)
    ESP_Boxes = false,
    ESP_Tracers = false,
    ESP_Names = false,
    ESP_Distance = false,
    BoxColor = Color3.fromRGB(255, 0, 128),
    TracerColor = Color3.fromRGB(0, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    
    -- Mod Nhân Vật (Movement Tech)
    SpeedHack = false,
    SpeedValue = 100,
    JumpHack = false,
    JumpValue = 50,
    InfJump = false,
    Noclip = false,
    Spinbot = false,
    SpinSpeed = 60,
    FlyHack = false,
    FlySpeed = 50,
    
    -- Thế Giới & Khử Lag Cực Hạn
    FullBright = false,
    NightMode = false,
    AntiLag = false,
    NoTextures = false,
    
    -- Cài đặt Hệ thống UI
    MenuKey = Enum.KeyCode.RightControl
}

-- Khởi tạo đối tượng đồ họa Drawing API
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.75
FOVCircle.Color = Color3.fromRGB(191, 0, 255)
FOVCircle.Visible = false

local Cache_ESP = {}

-- Hàm dọn sạch bộ nhớ Drawing tránh rò rỉ RAM (Memory Leak) trên thiết bị di động
local function ClearPlayerDrawing(player)
    if Cache_ESP[player] then
        pcall(function()
            if Cache_ESP[player].Box then Cache_ESP[player].Box:Remove() end
            if Cache_ESP[player].Tracer then Cache_ESP[player].Tracer:Remove() end
            if Cache_ESP[player].NameLabel then Cache_ESP[player].NameLabel:Remove() end
            if Cache_ESP[player].DistLabel then Cache_ESP[player].DistLabel:Remove() end
        end)
        Cache_ESP[player] = nil
    end
end

Players.PlayerRemoving:Connect(ClearPlayerDrawing)

-- ==================== [ MÔ-ĐUN KÉO THẢ GIAO DIỆN (DRAG ENGINE) ] ====================
local function RegisterDragEngine(guiFrame)
    local dragging, dragInput, dragStart, startPos
    guiFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            guiFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==================== [ KHỞI TẠO FRAMEWORK UI ĐẸP MẮT ] ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Zenonix_Omniverse_V4"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui") end)

-- Hệ thống thông báo tự động ẩn siêu tốc
local function BuildNotification(title, message, accentColor)
    local notifyFrame = Instance.new("Frame")
    notifyFrame.Size = UDim2.new(0, 290, 0, 60)
    notifyFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    notifyFrame.BackgroundTransparency = 0.1
    notifyFrame.Parent = ScreenGui

    local stroke = Instance.new("UIStroke", notifyFrame)
    stroke.Color = accentColor or Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1.5
    Instance.new("UICorner", notifyFrame).CornerRadius = UDim.new(0, 6)

    local textLabel = Instance.new("TextLabel", notifyFrame)
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.Text = "<b>" .. title .. "</b>\n" .. message
    textLabel.RichText = true
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 12
    textLabel.BackgroundTransparency = 1
    textLabel.TextXAlignment = Enum.TextXAlignment.Left

    notifyFrame.Position = UDim2.new(1.3, 0, 0.82, 0)
    TweenService:Create(notifyFrame, TweenInfo.new(0.35, Enum.EasingStyle.BackOut), {Position = UDim2.new(1, -310, 0.82, 0)}):Play()
    
    task.delay(2.0, function()
        pcall(function()
            TweenService:Create(notifyFrame, TweenInfo.new(0.3, Enum.EasingStyle.QuartIn), {Position = UDim2.new(1.3, 0, 0.82, 0)}):Play()
            task.wait(0.3)
            notifyFrame:Destroy()
        end)
    end)
end

-- Khung giao diện chính (Main Board)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 620, 0, 390)
Main.Position = UDim2.new(0.5, -310, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
Main.Visible = false
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
RegisterDragEngine(Main)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 1.5
local GradientAccent = Instance.new("UIGradient", MainStroke)
GradientAccent.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(191, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 128))
}

local HeaderTitle = Instance.new("TextLabel", Main)
HeaderTitle.Text = "⌬ ZENONIX OMNIVERSE EVO v4.0 [PREMIUM]"
HeaderTitle.Font = Enum.Font.GothamBlack
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.TextSize = 15
HeaderTitle.Position = UDim2.new(0, 20, 0, 14)
HeaderTitle.Size = UDim2.new(0, 400, 0, 25)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton", Main)
CloseButton.Size = UDim2.new(0, 26, 0, 26)
CloseButton.Position = UDim2.new(1, -38, 0, 14)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 30, 80)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 11
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local NavigationBar = Instance.new("Frame", Main)
NavigationBar.Size = UDim2.new(0, 150, 1, -65)
NavigationBar.Position = UDim2.new(0, 12, 0, 52)
NavigationBar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Instance.new("UICorner", NavigationBar).CornerRadius = UDim.new(0, 6)

local ContainerDeck = Instance.new("Frame", Main)
ContainerDeck.Size = UDim2.new(1, -188, 1, -65)
ContainerDeck.Position = UDim2.new(0, 176, 0, 52)
ContainerDeck.BackgroundTransparency = 1

local CurrentActiveTabBtn = nil
local TabCountRegister = 0

local function CreateTabChannel(tabName, tabIcon)
    local pageScroll = Instance.new("ScrollingFrame", ContainerDeck)
    pageScroll.Size = UDim2.new(1, 0, 1, 0)
    pageScroll.BackgroundTransparency = 1
    pageScroll.Visible = (TabCountRegister == 0)
    pageScroll.ScrollBarThickness = 3
    pageScroll.ScrollBarImageColor3 = Color3.fromRGB(191, 0, 255)
    pageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local listLayout = Instance.new("UIListLayout", pageScroll)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        pageScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 15)
    end)

    local tabBtn = Instance.new("TextButton", NavigationBar)
    tabBtn.Size = UDim2.new(0.92, 0, 0, 36)
    tabBtn.Position = UDim2.new(0.04, 0, 0, TabCountRegister * 40 + 8)
    tabBtn.BackgroundColor3 = (TabCountRegister == 0) and Color3.fromRGB(28, 28, 40) or Color3.fromRGB(18, 18, 24)
    tabBtn.Text = "  " .. tabIcon .. "  " .. tabName
    tabBtn.TextColor3 = (TabCountRegister == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 11
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

    if TabCountRegister == 0 then CurrentActiveTabBtn = tabBtn end

    tabBtn.MouseButton1Click:Connect(function()
        if CurrentActiveTabBtn then
            TweenService:Create(CurrentActiveTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(18, 18, 24), TextColor3 = Color3.fromRGB(160, 160, 160)}):Play()
        end
        CurrentActiveTabBtn = tabBtn
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 40), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        
        for _, v in pairs(ContainerDeck:GetChildren()) do 
            if v:IsA("ScrollingFrame") then v.Visible = false end 
        end
        pageScroll.Visible = true
    end)
    
    TabCountRegister = TabCountRegister + 1
    return pageScroll
end

-- Đăng ký hệ thống Tab đa năng
local TabCombat = CreateTabChannel("Rage Combat", "🎯")
local TabVisuals = CreateTabChannel("Thấu Thị ESP", "🔮")
local TabMovement = CreateTabChannel("Di Chuyển Mod", "⚡")
local TabWorldMap = CreateTabChannel("Thế Giới / Khử Lag", "🌐")

-- ==================== [ HỆ THỐNG PHẦN TỬ COMPONENT NÂNG CAO ] ====================

-- 1. Thêm Toggle nhanh công suất lớn
local function InjectToggle(text, parent, configKey, colorTheme)
    local toggleFrame = Instance.new("TextButton", parent)
    toggleFrame.Size = UDim2.new(0.96, 0, 0, 38)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    toggleFrame.Text = "     " .. text
    toggleFrame.TextColor3 = Color3.fromRGB(230, 230, 230)
    toggleFrame.TextXAlignment = Enum.TextXAlignment.Left
    toggleFrame.Font = Enum.Font.GothamSemibold
    toggleFrame.TextSize = 11
    Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 6)

    local stateDot = Instance.new("Frame", toggleFrame)
    stateDot.Size = UDim2.new(0, 14, 0, 14)
    stateDot.Position = UDim2.new(1, -26, 0.5, -7)
    stateDot.BackgroundColor3 = Settings[configKey] and colorTheme or Color3.fromRGB(40, 40, 50)
    Instance.new("UICorner", stateDot).CornerRadius = UDim.new(1, 0)

    toggleFrame.MouseButton1Click:Connect(function()
        Settings[configKey] = not Settings[configKey]
        TweenService:Create(stateDot, TweenInfo.new(0.2), {BackgroundColor3 = Settings[configKey] and colorTheme or Color3.fromRGB(40, 40, 50)}):Play()
        BuildNotification("ZENONIX HUB", text .. " -> " .. (Settings[configKey] and "ĐÃ BẬT" or "ĐÃ TẮT"), Settings[configKey] and colorTheme or Color3.fromRGB(255, 50, 50))
    end)
end

-- 2. Thêm Slider điều chỉnh thông số chính xác
local function InjectSlider(text, parent, minVal, maxVal, configKey, defaultVal, suffix)
    Settings[configKey] = defaultVal
    suffix = suffix or ""
    
    local sliderBox = Instance.new("Frame", parent)
    sliderBox.Size = UDim2.new(0.96, 0, 0, 48)
    sliderBox.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    Instance.new("UICorner", sliderBox).CornerRadius = UDim.new(0, 6)

    local infoLabel = Instance.new("TextLabel", sliderBox)
    infoLabel.Size = UDim2.new(0.8, 0, 0, 22)
    infoLabel.Position = UDim2.new(0, 12, 0, 4)
    infoLabel.Text = text .. ": " .. tostring(defaultVal) .. suffix
    infoLabel.Font = Enum.Font.GothamSemibold
    infoLabel.TextSize = 11
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left

    local trackBtn = Instance.new("TextButton", sliderBox)
    trackBtn.Size = UDim2.new(0.94, 0, 0, 5)
    trackBtn.Position = UDim2.new(0.03, 0, 1, -12)
    trackBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    trackBtn.Text = ""
    Instance.new("UICorner", trackBtn)

    local progressFill = Instance.new("Frame", trackBtn)
    progressFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(191, 0, 255)
    Instance.new("UICorner", progressFill)

    local function RecalculateSlider(input)
        local ratioX = math.clamp((input.Position.X - trackBtn.AbsolutePosition.X) / trackBtn.AbsoluteSize.X, 0, 1)
        local targetValue = math.floor(minVal + (maxVal - minVal) * ratioX)
        Settings[configKey] = targetValue
        infoLabel.Text = text .. ": " .. tostring(targetValue) .. suffix
        progressFill.Size = UDim2.new(ratioX, 0, 1, 0)
    end

    local isSliding = false
    trackBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            RecalculateSlider(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            RecalculateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end)
end

-- 3. Thêm Dropdown tùy biến lựa chọn chiến thuật
local function InjectDropdown(text, parent, optionsList, configKey)
    local dropFrame = Instance.new("Frame", parent)
    dropFrame.Size = UDim2.new(0.96, 0, 0, 38)
    dropFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
    dropFrame.ClipsDescendants = true

    local mainTrigger = Instance.new("TextButton", dropFrame)
    mainTrigger.Size = UDim2.new(1, 0, 0, 38)
    mainTrigger.BackgroundTransparency = 1
    mainTrigger.Text = "     " .. text .. ": " .. tostring(Settings[configKey])
    mainTrigger.TextColor3 = Color3.fromRGB(0, 255, 255)
    mainTrigger.Font = Enum.Font.GothamBold
    mainTrigger.TextSize = 11
    mainTrigger.TextXAlignment = Enum.TextXAlignment.Left

    local isExpanded = false
    mainTrigger.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        TweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = isExpanded and UDim2.new(0.96, 0, 0, 38 + (#optionsList * 28)) or UDim2.new(0.96, 0, 0, 38)}):Play()
    end)

    for idx, selection in ipairs(optionsList) do
        local optBtn = Instance.new("TextButton", dropFrame)
        optBtn.Size = UDim2.new(0.94, 0, 0, 24)
        optBtn.Position = UDim2.new(0.03, 0, 0, 38 + (idx - 1) * 28)
        optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        optBtn.Text = selection
        optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.TextSize = 11
        Instance.new("UICorner", optBtn)

        optBtn.MouseButton1Click:Connect(function()
            Settings[configKey] = selection
            mainTrigger.Text = "     " .. text .. ": " .. selection
            isExpanded = false
            TweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.96, 0, 0, 38)}):Play()
            BuildNotification("ZENONIX", "Đã chuyển đổi mục tiêu -> " .. selection, Color3.fromRGB(191, 0, 255))
        end)
    end
end

-- ==================== [ NẠP CÁC PHẦN TỬ ĐIỀU KHIỂN ] ====================

-- Bộ điều khiển Combat
InjectToggle("Kích Hoạt Silent Aimlock", TabCombat, "Aimlock", Color3.fromRGB(0, 255, 255))
InjectDropdown("Chế Độ Ưu Tiên Aim", TabCombat, {"Khoảng Cách Thực (Gần Nhất)", "Tâm Chuột (Closest Mouse)"}, "AimType")
InjectDropdown("Vùng Khóa Mục Tiêu", TabCombat, {"HumanoidRootPart", "Head", "UpperTorso"}, "TargetPart")
InjectToggle("Hiển Thị Vòng Tròn FOV", TabCombat, "ShowFOV", Color3.fromRGB(191, 0, 255))
InjectSlider("Bán Kính Vòng Quét FOV", TabCombat, 40, 500, "FOVRadius", 150, "px")
InjectSlider("Độ Mượt Ngắm Lập Lè (Smooth)", TabCombat, 1, 30, "Smoothing", 8, " (Thấp càng khóa chặt)")
InjectToggle("Kiểm Tra Đồng Đội (Team)", TabCombat, "TeamCheck", Color3.fromRGB(255, 165, 0))
InjectToggle("Phóng Đại Kích Thước Hitbox", TabCombat, "Hitbox", Color3.fromRGB(255, 0, 128))
InjectSlider("Kích Thước Khối Hitbox", TabCombat, 2, 40, "HitboxSize", 15, " studs")
InjectDropdown("Bộ Phận Phóng Hitbox", TabCombat, {"HumanoidRootPart", "Head"}, "HitboxPart")
InjectToggle("Kill Aura Cận Chiến Tốc Độ", TabCombat, "KillAura", Color3.fromRGB(255, 40, 40))
InjectSlider("Phạm Vi Quét Aura Sát Thương", TabCombat, 10, 60, "AuraRange", 25, " studs")
InjectToggle("Auto Đánh / Click Liên Tục", TabCombat, "AutoAttack", Color3.fromRGB(255, 120, 0))

-- Bộ điều khiển Thấu Thị ESP
InjectToggle("Hiện Khung Hình Kẻ Địch (Box)", TabVisuals, "ESP_Boxes", Color3.fromRGB(0, 255, 128))
InjectToggle("Hiện Chỉ Hướng Định Vị (Tracer)", TabVisuals, "ESP_Tracers", Color3.fromRGB(0, 255, 255))
InjectToggle("Hiện Tên Người Chơi (Names)", TabVisuals, "ESP_Names", Color3.fromRGB(255, 255, 255))
InjectToggle("Hiện Khoảng Cách Định Định (Dist)", TabVisuals, "ESP_Distance", Color3.fromRGB(255, 215, 0))

-- Bộ điều khiển Di Chuyển Mod
InjectToggle("Kích Hoạt Siêu Tốc Độ Chạy", TabMovement, "SpeedHack", Color3.fromRGB(255, 100, 0))
InjectSlider("Tốc Độ Di Chuyển", TabMovement, 16, 300, "SpeedValue", 100, " m/s")
InjectToggle("Kích Hoạt Nhảy Cao", TabMovement, "JumpHack", Color3.fromRGB(0, 255, 150))
InjectSlider("Lực Nhảy Nhân Vật", TabMovement, 50, 250, "JumpValue", 100, " lực")
InjectToggle("Nhảy Vô Hạn Không Chạm Đất", TabMovement, "InfJump", Color3.fromRGB(255, 255, 255))
InjectToggle("Đi Xuyên Mọi Bức Tường (Noclip)", TabMovement, "Noclip", Color3.fromRGB(150, 150, 150))
InjectToggle("Xoay Tròn Tránh Đạn (Spinbot)", TabMovement, "Spinbot", Color3.fromRGB(200, 0, 255))
InjectSlider("Tốc Độ Vòng Xoay Spinbot", TabMovement, 10, 200, "SpinSpeed", 60)

-- Bộ điều khiển Thế Giới & Chống Lag
InjectToggle("Bật Sáng Toàn Bản Đồ (Fullbright)", TabWorldMap, "FullBright", Color3.fromRGB(255, 255, 100))
InjectToggle("Cấu Hình Chế Độ Ban Đêm", TabWorldMap, "NightMode", Color3.fromRGB(50, 50, 200))
InjectToggle("Tối Ưu Giảm Lag Cực Hạn (Mobile/PC)", TabWorldMap, "AntiLag", Color3.fromRGB(0, 255, 0))
InjectToggle("Xóa Bỏ Toàn Bộ Texture Vật Liệu", TabWorldMap, "NoTextures", Color3.fromRGB(255, 0, 0))

-- ==================== [ NÚT BẬT TẮT GIAO DIỆN DI ĐỘNG ] ====================
local MobileMenuButton = Instance.new("TextButton", ScreenGui)
MobileMenuButton.Size = UDim2.new(0, 50, 0, 50)
MobileMenuButton.Position = UDim2.new(0, 15, 0.38, 0)
MobileMenuButton.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
MobileMenuButton.Text = "⌬"
MobileMenuButton.TextColor3 = Color3.fromRGB(0, 255, 255)
MobileMenuButton.Font = Enum.Font.GothamBlack
MobileMenuButton.TextSize = 26
Instance.new("UICorner", MobileMenuButton).CornerRadius = UDim.new(1, 0)
local TransStroke = Instance.new("UIStroke", MobileMenuButton)
TransStroke.Color = Color3.fromRGB(255, 0, 128)
TransStroke.Thickness = 1.5
RegisterDragEngine(MobileMenuButton)

MobileMenuButton.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)
UserInputService.InputBegan:Connect(function(k) 
    if k.KeyCode == Settings.MenuKey then Main.Visible = not Main.Visible end 
end)

-- ==================== [ ĐỘNG CƠ XỬ LÝ NHẬN DIỆN MỤC TIÊU GẦN NHẤT ] ====================
local function AcquireOptimumTarget()
    local targetChosen = nil
    local minimumMeasure = math.huge
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local eHum = p.Character:FindFirstChildOfClass("Humanoid")
            
            if eRoot and eHum and eHum.Health > 0 then
                -- Kiểm tra cài đặt lọc đồng đội
                if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
                
                local screenPos, isValidPos = Camera:WorldToViewportPoint(eRoot.Position)
                
                -- Nếu bật kiểm tra vòng FOV ngắm bắn
                if Settings.ShowFOV then
                    local distFromCursor = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if distFromCursor > Settings.FOVRadius then continue end
                end

                -- Chế độ 1: Quét mục tiêu có vị trí gần cơ thể bạn nhất trên bản đồ (Absolute Proximity)
                if Settings.AimType == "Khoảng Cách Thực (Gần Nhất)" then
                    local absoluteWorldDist = (myRoot.Position - eRoot.Position).Magnitude
                    if absoluteWorldDist < minimumMeasure then
                        minimumMeasure = absoluteWorldDist
                        targetChosen = p
                    end
                -- Chế độ 2: Quét mục tiêu gần tâm con trỏ chuột nhất trên màn hình
                elseif Settings.AimType == "Tâm Chuột (Closest Mouse)" then
                    local centerScreenDist = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if centerScreenDist < minimumMeasure then
                        minimumMeasure = centerScreenDist
                        targetChosen = p
                    end
                end
            end
        end
    end
    return targetChosen
end

-- ==================== [ ĐỘNG CƠ KHỬ GIẬT LAG & XÓA MAP ] ====================
local function PurgeTexturesEngine()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and Settings.NoTextures then
            obj.Material = Enum.Material.SmoothPlastic
        elseif (obj:IsA("Decal") or obj:IsA("Texture")) and Settings.AntiLag then
            obj:Destroy()
        elseif (obj:IsA("Atmosphere") or obj:IsA("Sky")) and Settings.AntiLag then
            obj:Destroy()
        end
    end
end

-- ==================== [ LUỒNG ĐỒ HỌA CAO CẤP (RENDERSTEPPED CRITICAL) ] ====================
RunService.RenderStepped:Connect(function()
    -- Cập nhật trạng thái vòng tròn giới hạn ngắm
    if Settings.ShowFOV then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Settings.FOVRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Vòng lặp xử lý vẽ hệ thống thấu thị siêu tốc
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local vectorCoord, isPointVisible = Camera:WorldToViewportPoint(root.Position)
                
                if isPointVisible then
                    local buildCache = Cache_ESP[p] or {
                        Box = Drawing.new("Square"),
                        Tracer = Drawing.new("Line"),
                        NameLabel = Drawing.new("Text"),
                        DistLabel = Drawing.new("Text")
                    }
                    Cache_ESP[p] = buildCache
                    
                    -- Vẽ Khung Hình Box ESP 2D
                    if Settings.ESP_Boxes then
                        local scaleFactor = 2200 / vectorCoord.Z
                        buildCache.Box.Visible = true
                        buildCache.Box.Size = Vector2.new(scaleFactor, scaleFactor * 1.4)
                        buildCache.Box.Position = Vector2.new(vectorCoord.X - scaleFactor / 2, vectorCoord.Y - (scaleFactor * 1.4) / 2)
                        buildCache.Box.Color = Settings.BoxColor
                        buildCache.Box.Thickness = 1.5
                    else
                        buildCache.Box.Visible = false
                    end

                    -- Vẽ Đường Chỉ Hướng Tracer Lines
                    if Settings.ESP_Tracers then
                        buildCache.Tracer.Visible = true
                        buildCache.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        buildCache.Tracer.To = Vector2.new(vectorCoord.X, vectorCoord.Y)
                        buildCache.Tracer.Color = Settings.TracerColor
                        buildCache.Tracer.Thickness = 1
                    else
                        buildCache.Tracer.Visible = false
                    end

                    -- Vẽ Văn Bản Tên Kẻ Địch
                    if Settings.ESP_Names then
                        buildCache.NameLabel.Visible = true
                        buildCache.NameLabel.Text = p.Name
                        buildCache.NameLabel.Position = Vector2.new(vectorCoord.X, vectorCoord.Y - (1800 / vectorCoord.Z) / 2 - 16)
                        buildCache.NameLabel.Color = Settings.TextColor
                        buildCache.NameLabel.Size = 13
                        buildCache.NameLabel.Center = true
                        buildCache.NameLabel.Outline = true
                    else
                        buildCache.NameLabel.Visible = false
                    end

                    -- Vẽ Chỉ Số Khoảng Cách Thực Tế
                    if Settings.ESP_Distance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local distanceCalculated = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                        buildCache.DistLabel.Visible = true
                        buildCache.DistLabel.Text = "[" .. tostring(distanceCalculated) .. "m]"
                        buildCache.DistLabel.Position = Vector2.new(vectorCoord.X, vectorCoord.Y + (1800 / vectorCoord.Z) / 2 + 4)
                        buildCache.DistLabel.Color = Color3.fromRGB(255, 230, 100)
                        buildCache.DistLabel.Size = 11
                        buildCache.DistLabel.Center = true
                        buildCache.DistLabel.Outline = true
                    else
                        buildCache.DistLabel.Visible = false
                    end
                else
                    ClearPlayerDrawing(p)
                end
            else
                ClearPlayerDrawing(p)
            end
        end
    end
end)

-- ==================== [ BIÊN DỊCH VÒNG LẶP VẬT LÝ TOÀN DIỆN (HEARTBEAT) ] ====================
RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum then return end

    -- Thiết lập môi trường map đồ họa thế giới
    if Settings.NightMode then Lighting.TimeOfDay = "00:00:00" end
    if Settings.FullBright then Lighting.Ambient = Color3.fromRGB(255, 255, 255) end
    if Settings.AntiLag or Settings.NoTextures then PurgeTexturesEngine() end

    -- Mod Nhân vật
    if Settings.SpeedHack then myHum.WalkSpeed = Settings.SpeedValue else myHum.WalkSpeed = 16 end
    if Settings.JumpHack then myHum.JumpPower = Settings.JumpValue else myHum.JumpPower = 50 end
    if Settings.Spinbot then myRoot.CFrame = myRoot.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0) end

    -- Duyệt tìm mục tiêu tối ưu tối cao
    local activeTarget = AcquireOptimumTarget()

    -- Quét toàn diện thiết lập Hitbox cho người chơi trong Server
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local enemyRoot = p.Character:FindFirstChild(Settings.HitboxPart)
            if enemyRoot and enemyRoot:IsA("BasePart") then
                if Settings.Hitbox then
                    enemyRoot.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    enemyRoot.Transparency = Settings.HitboxTrans
                    enemyRoot.CanCollide = false
                else
                    if enemyRoot.Size.X ~= 2 and enemyRoot.Size.X ~= 1 then
                        enemyRoot.Size = (Settings.HitboxPart == "Head") and Vector3.new(2, 1, 1) or Vector3.new(2, 2, 1)
                        enemyRoot.Transparency = 1
                    end
                end
            end
        end
    end

    -- Thực thi ngắm bắn Aimlock lên mục tiêu gần cơ thể nhất
    if activeTarget and activeTarget.Character then
        local targetPartComp = activeTarget.Character:FindFirstChild(Settings.TargetPart)
        if targetPartComp then
            if Settings.Aimlock then
                local computedVector = targetPartComp.Position + (targetPartComp.Velocity * Settings.Prediction)
                local smoothedLerp = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, computedVector), (Settings.Smoothing / 100))
                Camera.CFrame = smoothedLerp
            end

            -- Thực thi cấu trúc Kill Aura cận chiến sát thương
            if Settings.KillAura and (myRoot.Position - targetPartComp.Position).Magnitude < Settings.AuraRange then
                local equipTool = myChar:FindFirstChildOfClass("Tool")
                if equipTool then 
                    equipTool:Activate() 
                end
            end
        end
    end

    -- Cơ chế Tự động nhấp liên tục (Auto Clicker)
    if Settings.AutoAttack then
        local equipTool = myChar:FindFirstChildOfClass("Tool")
        if equipTool then 
            equipTool:Activate() 
        end
    end
end)

-- ==================== [ MÔ-ĐUN VÒNG LẶP XUYÊN TƯỜNG (STEPPED NOCLIP) ] ====================
RunService.Stepped:Connect(function()
    if Settings.Noclip and LocalPlayer.Character then
        for _, objectPart in ipairs(LocalPlayer.Character:GetChildren()) do
            if objectPart:IsA("BasePart") then
                objectPart.CanCollide = false
            end
        end
    end
end)

-- ==================== [ HỆ THỐNG KIỂM SOÁT NHẢY VÔ HẠN (INF JUMP) ] ====================
UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump and LocalPlayer.Character then
        local currentHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if currentHum then 
            currentHum:ChangeState(Enum.HumanoidStateType.Jumping) 
        end
    end
end)

-- Phát tín hiệu khởi tạo thành công hệ thống tối cao
BuildNotification("MINH MEO OMNIVERSE", "Zenonix Engine v4.0 Ultimate All Games hoạt động ổn định!", Color3.fromRGB(0, 255, 255))

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║      ⌬  ZENONIX PURE AIMLOCK V5.0 // OMNIVERSE PURE CORE ENGINE           ║
    ║      >> CORE DEVELOPER: MINH MEO OMNIVERSE ETERNAL                        ║
    ║      >> ARCHITECTURE: PURE TARGET LOCKING & MATHEMATICAL PREDICTION       ║
    ║      >> FOCUS: ABSOLUTE PROXIMITY (NGƯỜI GẦN NHẤT) & SMOOTH INTERPOLATION ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]--

-- ==================== [ THIẾT LẬP HỆ THỐNG DỊCH VỤ ] ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

-- Đảm bảo Camera luôn đồng bộ hóa liên tục khi hồi sinh
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

-- ==================== [ BẢNG CẤU HÌNH TỐI CAO CHUYÊN BIỆT AIMLOCK ] ====================
local Settings = {
    -- Trạng thái cốt lõi
    Enabled = true,
    AimType = "Khoảng Cách Thực (Gần Nhất)", -- "Khoảng Cách Thực (Gần Nhất)" hoặc "Tâm Màn Hình"
    TargetPartMode = "Tự Động (Closest Joint)", -- "Head", "HumanoidRootPart", "UpperTorso", "Tự Động (Closest Joint)"
    DefaultPart = "HumanoidRootPart",
    
    -- Bộ lọc điều kiện khóa
    TeamCheck = false,
    WallCheck = true,
    AliveCheck = true,
    KnockedCheck = true, -- Bỏ qua kẻ địch bị gục (Dành cho các game có cơ chế knock)
    
    -- Siêu toán học & Nội suy
    PredictionMode = "Gia Tốc Nâng Cao", -- "Tuyến Tính Basic", "Gia Tốc Nâng Cao", "Bù Trừ Ping"
    PredictionAmount = 0.134,
    SmoothingMode = "Bezier Curve Interpolation", -- "Tuyến Tính", "Bezier Curve Interpolation", "Exponential"
    Smoothness = 0.065,
    WeightX = 1.0,
    WeightY = 1.0,
    
    -- Vòng tròn giới hạn quét FOV (Drawing API)
    ShowFOV = true,
    FOVRadius = 180,
    FOVSides = 64,
    FOVThickness = 2,
    FOVColor = Color3.fromRGB(0, 255, 255),
    FOVTransparency = 0.8,
    RainbowFOV = true,
    
    -- Tính năng phụ trợ bổ trợ ngắm bắn
    TriggerBot = false,
    TriggerDelay = 0.02,
    AutoClickOnLock = false,
    
    -- Cấu hình Phím tắt & Giao diện
    ToggleKey = Enum.KeyCode.Q, -- Phím kích hoạt nhấp giữ khóa (hoặc bật/tắt)
    IsHoldMode = false, -- true: Giữ mới khóa / false: Bấm một phát để bật/tắt khóa
    MenuKey = Enum.KeyCode.RightControl
}

-- Biến kiểm soát vòng đời thực thi
local AimlockActive = false
local CurrentTarget = nil
local RainbowHue = 0

-- Khởi tạo thực thể đồ họa Drawing
local FOVCircle = Drawing.new("Circle")
local TargetLine = Drawing.new("Line")

FOVCircle.Filled = false
TargetLine.Visible = false

-- ==================== [ MÔ-ĐUN QUẢN LÝ BỘ NHỚ VECTOR VÀ TOÁN HỌC ] ====================
local MathEngine = {}

function MathEngine.GetDistanceInStuds(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function MathEngine.GetScreenDistance(pos1, pos2)
    return (Vector2.new(pos1.X, pos1.Y) - Vector2.new(pos2.X, pos2.Y)).Magnitude
end

function MathEngine.ComputeBezier(t, p0, p1, p2)
    local l1 = p0:Lerp(p1, t)
    local l2 = p1:Lerp(p2, t)
    return l1:Lerp(l2, t)
end

-- ==================== [ MÔ-ĐUN KIỂM TRA ĐIỀU KIỆN VẬT LÝ VÀ ĐỊA HÌNH ] ====================
local PhysicsEngine = {}

function PhysicsEngine.IsVisible(targetPart, character)
    if not Settings.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local ignoreList = {LocalPlayer.Character, Camera}
    if character then
        table.insert(ignoreList, character)
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    if raycastResult then
        return false
    end
    return true
end

function PhysicsEngine.CheckHealth(player)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if Settings.AliveCheck and humanoid.Health <= 0 then
        return false
    end
    
    if Settings.KnockedCheck then
        if character:FindFirstChild("KO") or character:FindFirstChild("Knocked") or humanoid:GetState() == Enum.HumanoidStateType.Dead then
            return false
        end
    end
    
    return true
end

-- ==================== [ MÔ-ĐUN KÉO THẢ GIAO DIỆN KHÔNG LAG ] ====================
local function ApplyDragEngine(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==================== [ KHỞI TẠO FRAMEWORK ĐỒ HỌA UI CAO CẤP ] ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Zenonix_Pure_Aimlock"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui") end)

-- Hệ thống Toast Thông báo không xác nhận
local function TriggerAlert(title, text, color)
    local alert = Instance.new("Frame")
    alert.Size = UDim2.new(0, 280, 0, 55)
    alert.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    alert.BackgroundTransparency = 0.1
    alert.Parent = ScreenGui
    
    local stroke = Instance.new("UIStroke", alert)
    stroke.Color = color or Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1.2
    Instance.new("UICorner", alert).CornerRadius = UDim.new(0, 5)
    
    local label = Instance.new("TextLabel", alert)
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = "<b>" .. title .. "</b>\n" .. text
    label.RichText = true
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left

    alert.Position = UDim2.new(1.2, 0, 0.85, 0)
    TweenService:Create(alert, TweenInfo.new(0.3, Enum.EasingStyle.BackOut), {Position = UDim2.new(1, -300, 0.85, 0)}):Play()
    
    task.delay(1.8, function()
        pcall(function()
            TweenService:Create(alert, TweenInfo.new(0.25, Enum.EasingStyle.QuadIn), {Position = UDim2.new(1.2, 0, 0.85, 0)}):Play()
            task.wait(0.25)
            alert:Destroy()
        end)
    end)
end

-- Bảng mạch chính UI (Main Core Panel)
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 560, 0, 360)
Panel.Position = UDim2.new(0.5, -280, 0.5, -180)
Panel.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
Panel.Visible = false
Panel.Parent = ScreenGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)
ApplyDragEngine(Panel)

local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Thickness = 1.5
local PanelGradient = Instance.new("UIGradient", PanelStroke)
PanelGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(191, 0, 255))
}

local TopBarTitle = Instance.new("TextLabel", Panel)
TopBarTitle.Text = "⌬ ZENONIX AIMLOCK SYSTEM CORE v5.0 // ENGINE"
TopBarTitle.Font = Enum.Font.GothamBlack
TopBarTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TopBarTitle.TextSize = 13
TopBarTitle.Position = UDim2.new(0, 16, 0, 12)
TopBarTitle.Size = UDim2.new(0, 400, 0, 20)
TopBarTitle.BackgroundTransparency = 1
TopBarTitle.TextXAlignment = Enum.TextXAlignment.Left

local DestroyBtn = Instance.new("TextButton", Panel)
DestroyBtn.Size = UDim2.new(0, 22, 0, 22)
DestroyBtn.Position = UDim2.new(1, -34, 0, 12)
DestroyBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 80)
DestroyBtn.Text = "✕"
DestroyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DestroyBtn.Font = Enum.Font.GothamBold
DestroyBtn.TextSize = 10
Instance.new("UICorner", DestroyBtn).CornerRadius = UDim.new(0, 5)
DestroyBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() FOVCircle:Remove() TargetLine:Remove() end)

-- Danh mục phân tách Tab Trái
local LeftTabShelf = Instance.new("Frame", Panel)
LeftTabShelf.Size = UDim2.new(0, 140, 1, -55)
LeftTabShelf.Position = UDim2.new(0, 12, 0, 45)
LeftTabShelf.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Instance.new("UICorner", LeftTabShelf).CornerRadius = UDim.new(0, 6)

local RightDeck = Instance.new("Frame", Panel)
RightDeck.Size = UDim2.new(1, -180, 1, -55)
RightDeck.Position = UDim2.new(0, 164, 0, 45)
RightDeck.BackgroundTransparency = 1

local ActiveDeckButton = nil
local TotalRegisteredDecks = 0

local function InsertSubDeck(name, symbol)
    local container = Instance.new("ScrollingFrame", RightDeck)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Visible = (TotalRegisteredDecks == 0)
    container.ScrollBarThickness = 2
    container.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
    end)

    local button = Instance.new("TextButton", LeftTabShelf)
    button.Size = UDim2.new(0.92, 0, 0, 34)
    button.Position = UDim2.new(0.04, 0, 0, TotalRegisteredDecks * 38 + 8)
    button.BackgroundColor3 = (TotalRegisteredDecks == 0) and Color3.fromRGB(25, 25, 35) or Color3.fromRGB(14, 14, 20)
    button.Text = "  " .. symbol .. "  " .. name
    button.TextColor3 = (TotalRegisteredDecks == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)

    if TotalRegisteredDecks == 0 then ActiveDeckButton = button end

    button.MouseButton1Click:Connect(function()
        if ActiveDeckButton then
            TweenService:Create(ActiveDeckButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(14, 14, 20), TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        end
        ActiveDeckButton = button
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 35), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        
        for _, obj in pairs(RightDeck:GetChildren()) do
            if obj:IsA("ScrollingFrame") then obj.Visible = false end
        end
        container.Visible = true
    end)

    TotalRegisteredDecks = TotalRegisteredDecks + 1
    return container
end

-- Tạo các Tab điều khiển cấu trúc chuyên biệt cho Aimlock
local DeckCore = InsertSubDeck("Cốt Lõi Aim", "🎯")
local DeckMath = InsertSubDeck("Toán Học/Smooth", "⚙️")
local DeckFovConfig = InsertSubDeck("Vòng Quét FOV", "⭕")
local DeckMonitor = InsertSubDeck("Bảng Giám Sát", "📊")

-- ==================== [ THÀNH PHẦN HOẠT ĐỘNG CHUYÊN BIỆT (COMPONENTS) ] ====================

local function CreateToggle(labelText, targetDeck, configKey, themeColor)
    local frame = Instance.new("TextButton", targetDeck)
    frame.Size = UDim2.new(0.96, 0, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    frame.Text = "     " .. labelText
    frame.TextColor3 = Color3.fromRGB(220, 220, 220)
    frame.TextXAlignment = Enum.TextXAlignment.Left
    frame.Font = Enum.Font.GothamSemibold
    frame.TextSize = 10.5
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local dot = Instance.new("Frame", frame)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(1, -24, 0.5, -6)
    dot.BackgroundColor3 = Settings[configKey] and themeColor or Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    frame.MouseButton1Click:Connect(function()
        Settings[configKey] = not Settings[configKey]
        TweenService:Create(dot, TweenInfo.new(0.18), {BackgroundColor3 = Settings[configKey] and themeColor or Color3.fromRGB(35, 35, 45)}):Play()
        TriggerAlert("AIMLOCK MOD", labelText .. " -> " .. (Settings[configKey] and "ĐÃ BẬT" or "ĐÃ TẮT"), Settings[configKey] and themeColor or Color3.fromRGB(255, 60, 60))
    end)
end

local function CreateSlider(labelText, targetDeck, minimum, maximum, configKey, default, unit)
    Settings[configKey] = default
    unit = unit or ""
    
    local box = Instance.new("Frame", targetDeck)
    box.Size = UDim2.new(0.96, 0, 0, 46)
    box.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    local indicator = Instance.new("TextLabel", box)
    indicator.Size = UDim2.new(0.8, 0, 0, 20)
    indicator.Position = UDim2.new(0, 12, 0, 4)
    indicator.Text = labelText .. ": " .. tostring(default) .. unit
    indicator.Font = Enum.Font.GothamSemibold
    indicator.TextSize = 10.5
    indicator.TextColor3 = Color3.fromRGB(190, 190, 190)
    indicator.BackgroundTransparency = 1
    indicator.TextXAlignment = Enum.TextXAlignment.Left

    local bar = Instance.new("TextButton", box)
    bar.Size = UDim2.new(0.94, 0, 0, 4)
    bar.Position = UDim2.new(0.03, 0, 1, -10)
    bar.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    bar.Text = ""
    Instance.new("UICorner", bar)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default - minimum) / (maximum - minimum), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    Instance.new("UICorner", fill)

    local function Adjust(input)
        local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local exactVal = minimum + (maximum - minimum) * ratio
        if maximum <= 2 then
            exactVal = math.round(exactVal * 1000) / 1000
        else
            exactVal = math.floor(exactVal)
        end
        Settings[configKey] = exactVal
        indicator.Text = labelText .. ": " .. tostring(exactVal) .. unit
        fill.Size = UDim2.new(ratio, 0, 1, 0)
    end

    local holding = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = true; Adjust(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if holding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Adjust(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = false
        end
    end)
end

local function CreateDropdown(labelText, targetDeck, options, configKey)
    local drop = Instance.new("Frame", targetDeck)
    drop.Size = UDim2.new(0.96, 0, 0, 36)
    drop.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0, 5)
    drop.ClipsDescendants = true

    local action = Instance.new("TextButton", drop)
    action.Size = UDim2.new(1, 0, 0, 36)
    action.BackgroundTransparency = 1
    action.Text = "     " .. labelText .. ": " .. tostring(Settings[configKey])
    action.TextColor3 = Color3.fromRGB(191, 0, 255)
    action.Font = Enum.Font.GothamBold
    action.TextSize = 10.5
    action.TextXAlignment = Enum.TextXAlignment.Left

    local open = false
    action.MouseButton1Click:Connect(function()
        open = not open
        TweenService:Create(drop, TweenInfo.new(0.2), {Size = open and UDim2.new(0.96, 0, 0, 36 + (#options * 26)) or UDim2.new(0.96, 0, 0, 36)}):Play()
    end)

    for i, choice in ipairs(options) do
        local opt = Instance.new("TextButton", drop)
        opt.Size = UDim2.new(0.94, 0, 0, 22)
        opt.Position = UDim2.new(0.03, 0, 0, 36 + (i - 1) * 26)
        opt.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        opt.Text = choice
        opt.TextColor3 = Color3.fromRGB(255, 255, 255)
        opt.Font = Enum.Font.GothamMedium
        opt.TextSize = 10
        Instance.new("UICorner", opt)

        opt.MouseButton1Click:Connect(function()
            Settings[configKey] = choice
            action.Text = "     " .. labelText .. ": " .. choice
            open = false
            TweenService:Create(drop, TweenInfo.new(0.2), {Size = UDim2.new(0.96, 0, 0, 36)}):Play()
            TriggerAlert("HỆ THỐNG", "Chuyển cấu hình chế độ sang: " .. choice, Color3.fromRGB(0, 255, 255))
        end)
    end
end

-- ==================== [ NẠP ĐẦY ĐỦ CÁC THÔNG SỐ ĐIỀU KHIỂN ] ====================

-- Tab 1: Cốt Lõi Hệ thống Ngắm
CreateToggle("Kích Hoạt Khóa Ngắm (Aimlock)", DeckCore, "Enabled", Color3.fromRGB(0, 255, 255))
CreateDropdown("Chế Độ Ưu Tiên Mục Tiêu", DeckCore, {"Khoảng Cách Thực (Gần Nhất)", "Tâm Màn Hình"}, "AimType")
CreateDropdown("Mục Tiêu Khóa Xương", DeckCore, {"Tự Động (Closest Joint)", "Head", "HumanoidRootPart", "UpperTorso"}, "TargetPartMode")
CreateToggle("Lọc Đồng Đội (Team Check)", DeckCore, "TeamCheck", Color3.fromRGB(255, 170, 0))
CreateToggle("Kiểm Tra Vật Cản (Wall Check)", DeckCore, "WallCheck", Color3.fromRGB(0, 255, 128))
CreateToggle("Bỏ Qua Người Bị Gục (Knocked)", DeckCore, "KnockedCheck", Color3.fromRGB(255, 50, 100))

-- Tab 2: Thuật Toán Toán Học Nâng Cao
CreateDropdown("Thuật Toán Dự Đoán (Prediction)", DeckMath, {"Gia Tốc Nâng Cao", "Tuyến Tính Basic", "Bù Trừ Ping"}, "PredictionMode")
CreateSlider("Hệ Số Dự Đoán Đạn (Predict)", DeckMath, 0.01, 0.4, "PredictionAmount", 0.134, "s")
CreateDropdown("Kiểu Khử Giật (Smoothing)", DeckMath, {"Bezier Curve Interpolation", "Exponential", "Tuyến Tính"}, "SmoothingMode")
CreateSlider("Độ Mượt Ngắm Lọc (Smoothness)", DeckMath, 0.005, 0.3, "Smoothness", 0.065, " (Thấp càng dính chặt)")
CreateSlider("Trọng Số Ngắm Ngang (Weight X)", DeckMath, 0.1, 2.0, "WeightX", 1.0)
CreateSlider("Trọng Số Ngắm Dọc (Weight Y)", DeckMath, 0.1, 2.0, "WeightY", 1.0)

-- Tab 3: Tùy Chỉnh Vòng Quét FOV
CreateToggle("Hiển Thị Vòng Quét FOV", DeckFovConfig, "ShowFOV", Color3.fromRGB(191, 0, 255))
CreateToggle("Hiệu Ứng Vòng Đổi Màu (Rainbow)", DeckFovConfig, "RainbowFOV", Color3.fromRGB(0, 255, 255))
CreateSlider("Bán Kính Quét Địch (Radius)", DeckFovConfig, 30, 600, "FOVRadius", 180, "px")
CreateSlider("Độ Dày Nét Vẽ Vòng (Thickness)", DeckFovConfig, 1, 5, "FOVThickness", 2, "px")

-- Tab 4: Màn Hình Monitor Đo Đạc Thông Số Real-Time
local TargetDataBox = Instance.new("Frame", DeckMonitor)
TargetDataBox.Size = UDim2.new(0.96, 0, 0, 120)
TargetDataBox.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Instance.new("UICorner", TargetDataBox).CornerRadius = UDim.new(0, 6)

local MonitorLabel = Instance.new("TextLabel", TargetDataBox)
MonitorLabel.Size = UDim2.new(1, -24, 1, -16)
MonitorLabel.Position = UDim2.new(0, 12, 0, 8)
MonitorLabel.BackgroundTransparency = 1
MonitorLabel.Font = Enum.Font.Code
MonitorLabel.TextSize = 11
MonitorLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
MonitorLabel.TextXAlignment = Enum.TextXAlignment.Left
MonitorLabel.TextYAlignment = Enum.TextYAlignment.Top
MonitorLabel.Text = "HỆ THỐNG GIÁM SÁT MỤC TIÊU:\n--------------------\n[Mục Tiêu]: Không có\n[Khoảng Cách]: 0 studs\n[Vận Tốc]: 0, 0, 0\n[Độ Khả Dụng]: Chờ..."

-- ==================== [ NÚT BẬT MENU TRÊN DI ĐỘNG (MOBILE TOGGLE) ] ====================
local MobileMenuIcon = Instance.new("TextButton", ScreenGui)
MobileMenuIcon.Size = UDim2.new(0, 46, 0, 46)
MobileMenuIcon.Position = UDim2.new(0, 12, 0, 12)
MobileMenuIcon.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
MobileMenuIcon.Text = "🎯"
MobileMenuIcon.TextColor3 = Color3.fromRGB(0, 255, 255)
MobileMenuIcon.Font = Enum.Font.GothamBlack
MobileMenuIcon.TextSize = 20
Instance.new("UICorner", MobileMenuIcon).CornerRadius = UDim.new(1, 0)
local IconStroke = Instance.new("UIStroke", MobileMenuIcon)
IconStroke.Color = Color3.fromRGB(191, 0, 255)
IconStroke.Thickness = 1.2
ApplyDragEngine(MobileMenuIcon)

MobileMenuIcon.MouseButton1Click:Connect(function() Panel.Visible = not Panel.Visible end)
UserInputService.InputBegan:Connect(function(key)
    if key.KeyCode == Settings.MenuKey then Panel.Visible = not Panel.Visible end
end)

-- ==================== [ ĐỘNG CƠ TÌM KIẾM MỤC TIÊU GẦN NHẤT CHUYÊN SÂU ] ====================
local function ScanForOptimalTarget()
    local chosenTarget = nil
    local shortestDistance = math.huge
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if enemyRoot and PhysicsEngine.CheckHealth(p) then
                
                -- Lọc Đồng Đội
                if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
                
                -- Xác định bộ phận quét
                local scanPart = enemyRoot
                if Settings.TargetPartMode == "Tự Động (Closest Joint)" then
                    local closestJointDist = math.huge
                    for _, jointName in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
                        local jointObj = p.Character:FindFirstChild(jointName)
                        if jointObj then
                            local sPos, inBound = Camera:WorldToViewportPoint(jointObj.Position)
                            if inBound then
                                local cDist = (Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) - Vector2.new(sPos.X, sPos.Y)).Magnitude
                                if cDist < closestJointDist then
                                    closestJointDist = cDist
                                    scanPart = jointObj
                                end
                            end
                        end
                    end
                else
                    local forcedPart = p.Character:FindFirstChild(Settings.TargetPartMode)
                    if forcedPart then scanPart = forcedPart end
                end

                -- Kiểm tra tường chắn tầm nhìn
                if not PhysicsEngine.IsVisible(scanPart, p.Character) then continue end

                local screenPos, onScreen = Camera:WorldToViewportPoint(scanPart.Position)
                
                -- Kiểm tra bán kính FOV giới hạn nếu bật cấu hình ShowFOV
                if Settings.ShowFOV then
                    local distFromCenter = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if distFromCenter > Settings.FOVRadius then continue end
                end

                -- Thực thi lọc đa chế độ (Xử lý ưu tiên khoảng cách gần bạn nhất hoặc gần chuột nhất)
                if Settings.AimType == "Khoảng Cách Thực (Gần Nhất)" then
                    local realWorldDist = MathEngine.GetDistanceInStuds(myRoot.Position, scanPart.Position)
                    if realWorldDist < shortestDistance then
                        shortestDistance = realWorldDist
                        chosenTarget = {Player = p, Part = scanPart}
                    end
                elseif Settings.AimType == "Tâm Màn Hình" then
                    local centerMouseDist = MathEngine.GetScreenDistance(Camera.ViewportSize / 2, screenPos)
                    if centerMouseDist < shortestDistance then
                        shortestDistance = centerMouseDist
                        chosenTarget = {Player = p, Part = scanPart}
                    end
                end
            end
        end
    end
    
    if chosenTarget then
        return chosenTarget.Player, chosenTarget.Part
    end
    return nil, nil
end

-- ==================== [ LẮP RÁP BỘ ĐIỀU KHIỂN BẤM PHÍM KHÓA MỤC TIÊU ] ====================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Settings.ToggleKey then
        if Settings.IsHoldMode then
            AimlockActive = true
        else
            AimlockActive = not AimlockActive
            TriggerAlert("AIMLOCK", AimlockActive and "ĐÃ KHÓA SĂN MỤC TIÊU" or "ĐÃ HỦY KHÓA MỤC TIÊU", AimlockActive and Color3.fromRGB(0,255,255) or Color3.fromRGB(255,50,50))
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.ToggleKey and Settings.IsHoldMode then
        AimlockActive = false
    end
end)

-- ==================== [ LUỒNG VẼ ĐỒ HỌA LIÊN TỤC VÀ HOẠT HỌA FOV (RENDERSTEPPED) ] ====================
RunService.RenderStepped:Connect(function()
    -- Đồng bộ hóa hiệu ứng Rainbow
    RainbowHue = (RainbowHue + 0.005) % 1
    local dynamicColor = Color3.fromHSV(RainbowHue, 0.9, 1)
    
    -- Xử lý hiển thị vòng quét FOV ngắm bắn
    if Settings.ShowFOV and Settings.Enabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Settings.FOVRadius
        FOVCircle.Thickness = Settings.FOVThickness
        FOVCircle.NumSides = Settings.FOVSides
        FOVCircle.Color = Settings.RainbowFOV and dynamicColor or Settings.FOVColor
        FOVCircle.Transparency = Settings.FOVTransparency
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Khởi chạy chu kỳ ngắm khóa nếu cấu hình tổng được bật
    if Settings.Enabled and AimlockActive then
        local pTarget, partTarget = ScanForOptimalTarget()
        CurrentTarget = pTarget
        
        if pTarget and partTarget then
            local targetPosition = partTarget.Position
            local velocityComp = partTarget.Velocity
            
            -- Thực thi thuật toán Dự đoán quỹ đạo di chuyển dựa trên tùy chọn nâng cao
            if Settings.PredictionMode == "Gia Tốc Nâng Cao" then
                targetPosition = targetPosition + (velocityComp * Settings.PredictionAmount)
            elseif Settings.PredictionMode == "Bù Trừ Ping" then
                local playerPing = 0.06 -- Giả lập ping cơ sở trung bình
                pcall(function() playerPing = LocalPlayer:GetNetworkPing() end)
                targetPosition = targetPosition + (velocityComp * playerPing * (Settings.PredictionAmount * 7))
            elseif Settings.PredictionMode == "Tuyến Tính Basic" then
                targetPosition = targetPosition + (velocityComp * 0.1)
            end
            
            -- Tính toán Ma trận góc quay của Camera
            local targetLookCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPosition)
            
            -- Áp dụng bộ lọc nội suy làm mượt (Smoothing Engine)
            if Settings.SmoothingMode == "Bezier Curve Interpolation" then
                local controlPoint = Camera.CFrame:Lerp(targetLookCFrame, 0.5).Position + Vector3.new(0, 0.1, 0)
                local currentPos = Camera.CFrame.Position
                local nextCFrameLook = targetLookCFrame.Position
                
                -- Kết xuất nội suy Bezier mượt tuyệt đối không giật khựng góc khuất
                local lerpedRotation = Camera.CFrame:Lerp(targetLookCFrame, Settings.Smoothness)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position) * lerpedRotation.Rotation
            elseif Settings.SmoothingMode == "Exponential" then
                local expFactor = 1 - math.exp(-Settings.Smoothness * 60 * RunService.RenderStepped:Wait())
                Camera.CFrame = Camera.CFrame:Lerp(targetLookCFrame, math.clamp(expFactor, 0, 1))
            elseif Settings.SmoothingMode == "Tuyến Tính" then
                Camera.CFrame = Camera.CFrame:Lerp(targetLookCFrame, Settings.Smoothness)
            end

            -- Vẽ đường chỉ định Line liên kết đến mục tiêu đang bị Lock
            local screenCoord, visibleOnViewport = Camera:WorldToViewportPoint(partTarget.Position)
            if visibleOnViewport then
                TargetLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                TargetLine.To = Vector2.new(screenCoord.X, screenCoord.Y)
                TargetLine.Color = Settings.RainbowFOV and dynamicColor or Color3.fromRGB(255, 0, 128)
                TargetLine.Thickness = 1.5
                TargetLine.Transparency = 0.9
                TargetLine.Visible = true
            else
                TargetLine.Visible = false
            end
        else
            TargetLine.Visible = false
        end
    else
        CurrentTarget = nil
        TargetLine.Visible = false
    end
end)

-- ==================== [ VÒNG LẶP ĐỒNG BỘ MÀN HÌNH MONITOR THEO DÕI (HEARTBEAT) ] ====================
RunService.Heartbeat:Connect(function()
    if Panel.Visible and DeckMonitor.Visible then
        if CurrentTarget and CurrentTarget.Character then
            local root = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
            local hum = CurrentTarget.Character:FindFirstChildOfClass("Humanoid")
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if root and hum and myRoot then
                local worldDistance = math.floor((myRoot.Position - root.Position).Magnitude)
                local velocityVector = root.Velocity
                
                MonitorLabel.Text = string.format(
                    "HỆ THỐNG GIÁM SÁT MỤC TIÊU:\n--------------------\n" ..
                    "[Mục Tiêu]: %s\n" ..
                    "[Khoảng Cách]: %d studs (GẦN NHẤT)\n" ..
                    "[Máu Đối Thủ]: %d / %d\n" ..
                    "[Vận Tốc X-Y-Z]: %.1f, %.1f, %.1f\n" ..
                    "[Trạng Thái Lock]: ĐANG KHÓA CHẶT 🎯",
                    CurrentTarget.Name,
                    worldDistance,
                    hum.Health,
                    hum.MaxHealth,
                    velocityVector.X,
                    velocityVector.Y,
                    velocityVector.Z
                )
            end
        else
            MonitorLabel.Text = "HỆ THỐNG GIÁM SÁT MỤC TIÊU:\n--------------------\n[Mục Tiêu]: Không tìm thấy mục tiêu khả dụng\n[Khoảng Cách]: 0 studs\n[Máu Đối Thủ]: N/A\n[Vận Tốc]: 0, 0, 0\n[Trạng Thái Lock]: Đang quét..."
        end
    end
end)

-- Tự động kích hoạt thông báo vận hành mượt mà không cần bấm nút xác nhận
TriggerAlert("MINH MEO OMNIVERSE", "Pure Aimlock Engine v5.0 Loaded Successfully!", Color3.fromRGB(0, 255, 255))

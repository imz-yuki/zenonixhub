--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║      ⌬  ZENONIX PURE AIMLOCK V6.0 // OMNIVERSE FIXED CORE ENGINE          ║
    ║      >> ĐÃ FIX LỖI: CHỐNG RUNG CAMERA, CHỐNG XOAY XOẮN, FIX NaN VECTOR    ║
    ║      >> PHÁT TRIỂN BỞI: MINH MEO OMNIVERSE ETERNAL                        ║
    ║      >> TRỌNG TÂM: 100% PURE AIMLOCK - TỐI ƯU CHO NGƯỜI MỚI CHƠI          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]--

-- ==================== [ HỆ THỐNG DỊCH VỤ HỆ ĐIỀU HÀNH ROBLOX ] ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Đồng bộ hóa Camera liên tục khi nhân vật hồi sinh hoặc chuyển đổi góc nhìn
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

-- ==================== [ BẢNG CẤU HÌNH TỐI ƯU HÓA SIÊU NGẮM ] ====================
local Settings = {
    -- Cấu hình chính
    Enabled = true,
    AimType = "Khoảng Cách (Gần Nhất)", -- "Khoảng Cách (Gần Nhất)" hoặc "Tâm Màn Hình"
    TargetPartMode = "Tự Động Quét Xương", -- "Head", "HumanoidRootPart", "UpperTorso", "Tự Động Quét Xương"
    
    -- Bộ lọc điều kiện (Chống khóa nhầm)
    TeamCheck = false,
    WallCheck = true,
    AliveCheck = true,
    KnockedCheck = true,
    
    -- Lõi toán học nâng cao (Đã sửa lỗi v4/v5)
    PredictionMode = "Gia Tốc Cao Cấp", -- "Tắt Dự Đoán", "Tuyến Tính Cơ Bản", "Gia Tốc Cao Cấp", "Bù Trừ Ping"
    PredictionAmount = 0.128,
    SmoothingMode = "Bộ Lọc Bezier", -- "Tuyến Tính", "Bộ Lọc Bezier", "Exponential Mượt"
    Smoothness = 0.055, -- Càng thấp càng dính chặt vào mục tiêu
    WeightX = 1.0,
    WeightY = 1.0,
    
    -- Vòng tròn quét mục tiêu FOV (Drawing API)
    ShowFOV = true,
    FOVRadius = 150,
    FOVSides = 64,
    FOVThickness = 2,
    FOVColor = Color3.fromRGB(0, 255, 255),
    FOVTransparency = 0.85,
    RainbowFOV = true,
    
    -- Phím tắt điều khiển dễ dùng
    LockKey = Enum.KeyCode.Q, -- Phím kích hoạt nhắm bắn
    IsHoldMode = false, -- false: Bấm 1 phát để Bật/Tắt khóa / true: Giữ mới khóa
    MenuKey = Enum.KeyCode.RightControl -- Phím ẩn/hiện bảng menu điều khiển
}

-- Biến trạng thái vòng đời hệ thống
local AimlockActive = false
local CurrentTargetPlayer = nil
local CurrentTargetPart = nil
local RainbowHue = 0

-- Khởi tạo công cụ vẽ Drawing API cho vòng FOV và đường chỉ hướng
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
local ConnectionLine = Drawing.new("Line")
ConnectionLine.Visible = false

-- ==================== [ THƯ VIỆN TOÁN HỌC CHỐNG LỖI VECTOR ] ====================
local MathLibrary = {}

function MathLibrary.CalculateWorldDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function MathLibrary.CalculateScreenDistance(pos1, pos2)
    return (Vector2.new(pos1.X, pos1.Y) - Vector2.new(pos2.X, pos2.Y)).Magnitude
end

-- Bộ lọc bảo vệ camera khỏi lỗi NaN (Not a Number) khi vị trí trùng khớp
function MathLibrary.SafeLookAt(origin, target)
    local direction = target - origin
    if direction.Magnitude < 0.001 then
        return CFrame.new(origin)
    end
    return CFrame.lookAt(origin, target)
end

-- ==================== [ ĐỘNG CƠ KIỂM TRA ĐIỀU KIỆN MỤC TIÊU VẬT LÝ ] ====================
local TargetValidator = {}

function TargetValidator.IsPlayerVisible(targetPart, targetCharacter)
    if not Settings.WallCheck then return true end
    
    local cameraPosition = Camera.CFrame.Position
    local partPosition = targetPart.Position
    local rayDirection = partPosition - cameraPosition
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local exclusionList = {LocalPlayer.Character, Camera}
    if targetCharacter then
        table.insert(exclusionList, targetCharacter)
    end
    raycastParams.FilterDescendantsInstances = exclusionList
    
    local result = workspace:Raycast(cameraPosition, rayDirection, raycastParams)
    
    -- Nếu không vướng vật cản (kết quả trả về nil) tức là nhìn thấy mục tiêu
    return result == nil
end

function TargetValidator.IsCharacterAlive(player)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if Settings.AliveCheck and humanoid.Health <= 0 then
        return false
    end
    
    -- Bỏ qua trạng thái bị gục (Knocked) trong các game sinh tồn
    if Settings.KnockedCheck then
        if character:FindFirstChild("KO") or character:FindFirstChild("Knocked") or character:FindFirstChild("Downed") or humanoid:GetState() == Enum.HumanoidStateType.Dead then
            return false
        end
    end
    
    return true
end

-- ==================== [ CƠ CHẾ KÉO THẢ MENU KHÔNG GÂY GIẬT LAG ] ====================
local function AttachDragMechanic(frameInstance)
    local isDragging, dragInput, dragStart, startPosition
    
    frameInstance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPosition = frameInstance.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    frameInstance.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        if isDragging and dragInput then
            local delta = dragInput.Position - dragStart
            frameInstance.Position = UDim2.new(
                startPosition.X.Scale, 
                startPosition.X.Offset + delta.X, 
                startPosition.Y.Scale, 
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==================== [ HỆ THỐNG GIAO DIỆN CYBERPUNK DỄ DÙNG ] ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Zenonix_PureAimlock_V6"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui") end)

-- Thông báo nổi góc màn hình (Không cần bấm xác nhận)
local function PushNotification(titleText, descText, accentColor)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 275, 0, 55)
    toast.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    toast.BackgroundTransparency = 0.1
    toast.Parent = ScreenGui
    
    local toastStroke = Instance.new("UIStroke", toast)
    toastStroke.Color = accentColor or Color3.fromRGB(0, 255, 255)
    toastStroke.Thickness = 1.2
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 5)
    
    local contentText = Instance.new("TextLabel", toast)
    contentText.Size = UDim2.new(1, -20, 1, 0)
    contentText.Position = UDim2.new(0, 10, 0, 0)
    contentText.Text = "<b>" .. titleText .. "</b>\n" .. descText
    contentText.RichText = true
    contentText.TextColor3 = Color3.fromRGB(255, 255, 255)
    contentText.Font = Enum.Font.GothamMedium
    contentText.TextSize = 11.5
    contentText.BackgroundTransparency = 1
    contentText.TextXAlignment = Enum.TextXAlignment.Left

    toast.Position = UDim2.new(1.2, 0, 0.85, 0)
    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.BackOut), {Position = UDim2.new(1, -295, 0.85, 0)}):Play()
    
    task.delay(1.5, function()
        pcall(function()
            TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.QuadIn), {Position = UDim2.new(1.2, 0, 0.85, 0)}):Play()
            task.wait(0.25)
            toast:Destroy()
        end)
    end)
end

-- Khung Menu Chính
local MenuFrame = Instance.new("Frame")
MenuFrame.Size = UDim2.new(0, 550, 0, 360)
MenuFrame.Position = UDim2.new(0.5, -275, 0.5, -180)
MenuFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
MenuFrame.Visible = false
MenuFrame.Parent = ScreenGui
Instance.new("UICorner", MenuFrame).CornerRadius = UDim.new(0, 8)
AttachDragMechanic(MenuFrame)

local MenuStroke = Instance.new("UIStroke", MenuFrame)
MenuStroke.Thickness = 1.5
local MenuGradient = Instance.new("UIGradient", MenuStroke)
MenuGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255))
}

local TitleLabel = Instance.new("TextLabel", MenuFrame)
TitleLabel.Text = "⌬ ZENONIX PURE AIMLOCK v6.0 [FIXED OMNIVERSE]"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
TitleLabel.Position = UDim2.new(0, 16, 0, 12)
TitleLabel.Size = UDim2.new(0, 420, 0, 20)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local ExitBtn = Instance.new("TextButton", MenuFrame)
ExitBtn.Size = UDim2.new(0, 22, 0, 22)
ExitBtn.Position = UDim2.new(1, -34, 0, 12)
ExitBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
ExitBtn.Text = "✕"
ExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExitBtn.Font = Enum.Font.GothamBold
ExitBtn.TextSize = 10
Instance.new("UICorner", ExitBtn).CornerRadius = UDim.new(0, 5)
ExitBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() FOVCircle:Remove() ConnectionLine:Remove() end)

-- Thanh phân loại danh mục (Tabs bên trái)
local TabBar = Instance.new("Frame", MenuFrame)
TabBar.Size = UDim2.new(0, 145, 1, -55)
TabBar.Position = UDim2.new(0, 12, 0, 45)
TabBar.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 6)

local DisplayDeck = Instance.new("Frame", MenuFrame)
DisplayDeck.Size = UDim2.new(1, -185, 1, -55)
DisplayDeck.Position = UDim2.new(0, 169, 0, 45)
DisplayDeck.BackgroundTransparency = 1

local ActiveTabButton = nil
local TabCounter = 0

local function AddMenuTab(tabName, iconSymbol)
    local scrollPage = Instance.new("ScrollingFrame", DisplayDeck)
    scrollPage.Size = UDim2.new(1, 0, 1, 0)
    scrollPage.BackgroundTransparency = 1
    scrollPage.Visible = (TabCounter == 0)
    scrollPage.ScrollBarThickness = 2
    scrollPage.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
    scrollPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local layout = Instance.new("UIListLayout", scrollPage)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollPage.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
    end)

    local tabSelectBtn = Instance.new("TextButton", TabBar)
    tabSelectBtn.Size = UDim2.new(0.92, 0, 0, 34)
    tabSelectBtn.Position = UDim2.new(0.04, 0, 0, TabCounter * 38 + 8)
    tabSelectBtn.BackgroundColor3 = (TabCounter == 0) and Color3.fromRGB(24, 24, 34) or Color3.fromRGB(12, 12, 18)
    tabSelectBtn.Text = "  " .. iconSymbol .. "  " .. tabName
    tabSelectBtn.TextColor3 = (TabCounter == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
    tabSelectBtn.Font = Enum.Font.GothamBold
    tabSelectBtn.TextSize = 10.5
    tabSelectBtn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", tabSelectBtn).CornerRadius = UDim.new(0, 5)

    if TabCounter == 0 then ActiveTabButton = tabSelectBtn end

    tabSelectBtn.MouseButton1Click:Connect(function()
        if ActiveTabButton then
            TweenService:Create(ActiveTabButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(12, 12, 18), TextColor3 = Color3.fromRGB(140, 140, 140)}):Play()
        end
        ActiveTabButton = tabSelectBtn
        TweenService:Create(tabSelectBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 24, 34), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        
        for _, child in pairs(DisplayDeck:GetChildren()) do
            if child:IsA("ScrollingFrame") then child.Visible = false end
        end
        scrollPage.Visible = true
    end)

    TabCounter = TabCounter + 1
    return scrollPage
end

-- Tạo các Tab điều khiển trực quan cho người mới
local GeneralTab = AddMenuTab("Cơ Bản", "🎯")
local MathTab = AddMenuTab("Thuật Toán Mượt", "⚙️")
local FovTab = AddMenuTab("Vòng Quét FOV", "⭕")
local PanelTab = AddMenuTab("Theo Dõi (Radar)", "📊")

-- ==================== [ CÁC THÀNH PHẦN ĐIỀU KHIỂN COMPONENT UI ] ====================

local function BuildToggleComponent(titleText, parentTab, key, activeColor)
    local toggleBtn = Instance.new("TextButton", parentTab)
    toggleBtn.Size = UDim2.new(0.96, 0, 0, 36)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(11, 11, 15)
    toggleBtn.Text = "     " .. titleText
    toggleBtn.TextColor3 = Color3.fromRGB(215, 215, 215)
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    toggleBtn.Font = Enum.Font.GothamSemibold
    toggleBtn.TextSize = 10.5
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 5)

    local statusLight = Instance.new("Frame", toggleBtn)
    statusLight.Size = UDim2.new(0, 12, 0, 12)
    statusLight.Position = UDim2.new(1, -24, 0.5, -6)
    statusLight.BackgroundColor3 = Settings[key] and activeColor or Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", statusLight).CornerRadius = UDim.new(1, 0)

    toggleBtn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        TweenService:Create(statusLight, TweenInfo.new(0.15), {BackgroundColor3 = Settings[key] and activeColor or Color3.fromRGB(35, 35, 45)}):Play()
        PushNotification("CẬP NHẬT", titleText .. " -> " .. (Settings[key] and "ĐÃ BẬT" or "ĐÃ TẮT"), Settings[key] and activeColor or Color3.fromRGB(255, 50, 50))
    end)
end

local function BuildSliderComponent(titleText, parentTab, min, max, key, default, sign)
    Settings[key] = default
    sign = sign or ""
    
    local sliderFrame = Instance.new("Frame", parentTab)
    sliderFrame.Size = UDim2.new(0.96, 0, 0, 46)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 15)
    Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 5)

    local valueDisplay = Instance.new("TextLabel", sliderFrame)
    valueDisplay.Size = UDim2.new(0.8, 0, 0, 20)
    valueDisplay.Position = UDim2.new(0, 12, 0, 4)
    valueDisplay.Text = titleText .. ": " .. tostring(default) .. sign
    valueDisplay.Font = Enum.Font.GothamSemibold
    valueDisplay.TextSize = 10.5
    valueDisplay.TextColor3 = Color3.fromRGB(185, 185, 185)
    valueDisplay.BackgroundTransparency = 1
    valueDisplay.TextXAlignment = Enum.TextXAlignment.Left

    local mainTrack = Instance.new("TextButton", sliderFrame)
    mainTrack.Size = UDim2.new(0.94, 0, 0, 4)
    mainTrack.Position = UDim2.new(0.03, 0, 1, -10)
    mainTrack.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    mainTrack.Text = ""
    Instance.new("UICorner", mainTrack)

    local currentFill = Instance.new("Frame", mainTrack)
    currentFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    currentFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    Instance.new("UICorner", currentFill)

    local function UpdateSliderLogic(input)
        local dragRatio = math.clamp((input.Position.X - mainTrack.AbsolutePosition.X) / mainTrack.AbsoluteSize.X, 0, 1)
        local outputVal = min + (max - min) * dragRatio
        if max <= 2 then
            outputVal = math.round(outputVal * 1000) / 1000
        else
            outputVal = math.floor(outputVal)
        end
        Settings[key] = outputVal
        valueDisplay.Text = titleText .. ": " .. tostring(outputVal) .. sign
        currentFill.Size = UDim2.new(dragRatio, 0, 1, 0)
    end

    local activeDrag = false
    mainTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeDrag = true; UpdateSliderLogic(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSliderLogic(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeDrag = false
        end
    end)
end

local function BuildDropdownComponent(titleText, parentTab, selections, key)
    local dropFrame = Instance.new("Frame", parentTab)
    dropFrame.Size = UDim2.new(0.96, 0, 0, 36)
    dropFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 15)
    Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 5)
    dropFrame.ClipsDescendants = true

    local openTrigger = Instance.new("TextButton", dropFrame)
    openTrigger.Size = UDim2.new(1, 0, 0, 36)
    openTrigger.BackgroundTransparency = 1
    openTrigger.Text = "     " .. titleText .. ": " .. tostring(Settings[key])
    openTrigger.TextColor3 = Color3.fromRGB(170, 0, 255)
    openTrigger.Font = Enum.Font.GothamBold
    openTrigger.TextSize = 10.5
    openTrigger.TextXAlignment = Enum.TextXAlignment.Left

    local activeState = false
    openTrigger.MouseButton1Click:Connect(function()
        activeState = not activeState
        TweenService:Create(dropFrame, TweenInfo.new(0.18), {Size = activeState and UDim2.new(0.96, 0, 0, 36 + (#selections * 26)) or UDim2.new(0.96, 0, 0, 36)}):Play()
    end)

    for i, item in ipairs(selections) do
        local selectionBtn = Instance.new("TextButton", dropFrame)
        selectionBtn.Size = UDim2.new(0.94, 0, 0, 22)
        selectionBtn.Position = UDim2.new(0.03, 0, 0, 36 + (i - 1) * 26)
        selectionBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
        selectionBtn.Text = item
        selectionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectionBtn.Font = Enum.Font.GothamMedium
        selectionBtn.TextSize = 10
        Instance.new("UICorner", selectionBtn)

        selectionBtn.MouseButton1Click:Connect(function()
            Settings[key] = item
            openTrigger.Text = "     " .. titleText .. ": " .. item
            activeState = false
            TweenService:Create(dropFrame, TweenInfo.new(0.18), {Size = UDim2.new(0.96, 0, 0, 36)}):Play()
            PushNotification("CẤU HÌNH", "Chuyển sang chế độ: " .. item, Color3.fromRGB(0, 255, 255))
        end)
    end
end

-- ==================== [ ĐIỀU KHIỂN THIẾT LẬP CHI TIẾT ] ====================

-- Tab 1: Cài đặt Aimlock cơ bản
BuildToggleComponent("Kích Hoạt Tổng Hệ Thống Ngắm", GeneralTab, "Enabled", Color3.fromRGB(0, 255, 255))
BuildDropdownComponent("Ưu Tiên Khóa Mục Tiêu", GeneralTab, {"Khoảng Cách (Gần Nhất)", "Tâm Màn Hình"}, "AimType")
BuildDropdownComponent("Vị Trí Khóa Trên Người Địch", GeneralTab, {"Tự Động Quét Xương", "Head", "HumanoidRootPart", "UpperTorso"}, "TargetPartMode")
BuildToggleComponent("Lọc Đồng Đội (Team Check)", GeneralTab, "TeamCheck", Color3.fromRGB(255, 165, 0))
BuildToggleComponent("Kiểm Tra Tường Chắn (Wall Check)", GeneralTab, "WallCheck", Color3.fromRGB(0, 255, 128))
BuildToggleComponent("Bỏ Qua Người Đã Bị Gục", GeneralTab, "KnockedCheck", Color3.fromRGB(255, 65, 100))

-- Tab 2: Thuật Toán mượt chống giật lag
BuildDropdownComponent("Chế Độ Tính Quỹ Đạo Đạn", MathTab, {"Gia Tốc Cao Cấp", "Tuyến Tính Cơ Bản", "Bù Trừ Ping", "Tắt Dự Đoán"}, "PredictionMode")
BuildSliderComponent("Hệ Số Dự Đoán Quỹ Đạo (Predict)", MathTab, 0.01, 0.4, "PredictionAmount", 0.128, "s")
BuildDropdownComponent("Thuật Toán Làm Mượt Góc Xoay", MathTab, {"Bộ Lọc Bezier", "Exponential Mượt", "Tuyến Tính"}, "SmoothingMode")
BuildSliderComponent("Độ Mượt Ngắm (Chống Rung Khựng)", MathTab, 0.005, 0.3, "Smoothness", 0.055, " (Thấp = Khóa chặt)")
BuildSliderComponent("Trọng Số Quét Trục Ngang (X)", MathTab, 0.1, 2.0, "WeightX", 1.0)
BuildSliderComponent("Trọng Số Quét Trục Dọc (Y)", MathTab, 0.1, 2.0, "WeightY", 1.0)

-- Tab 3: Tùy chỉnh vòng quét FOV giới hạn
BuildToggleComponent("Hiển Thị Vòng Tròn Quét FOV", FovTab, "ShowFOV", Color3.fromRGB(170, 0, 255))
BuildToggleComponent("Hiệu Ứng Vòng Đổi Màu RGB", FovTab, "RainbowFOV", Color3.fromRGB(0, 255, 255))
BuildSliderComponent("Bán Kính Quét Phạm Vi (Radius)", FovTab, 30, 600, "FOVRadius", 150, "px")
BuildSliderComponent("Độ Dày Nét Vẽ Vòng Tròn", FovTab, 1, 5, "FOVThickness", 2, "px")

-- Tab 4: Màn hình Radar theo dõi thông tin mục tiêu
local RadarFrame = Instance.new("Frame", PanelTab)
RadarFrame.Size = UDim2.new(0.96, 0, 0, 125)
RadarFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(0, 6)

local RadarText = Instance.new("TextLabel", RadarFrame)
RadarText.Size = UDim2.new(1, -24, 1, -16)
RadarText.Position = UDim2.new(0, 12, 0, 8)
RadarText.BackgroundTransparency = 1
RadarText.Font = Enum.Font.Code
RadarText.TextSize = 11
RadarText.TextColor3 = Color3.fromRGB(0, 255, 128)
RadarText.TextXAlignment = Enum.TextXAlignment.Left
RadarText.TextYAlignment = Enum.TextYAlignment.Top
RadarText.Text = "HỆ THỐNG GIÁM SÁT MỤC TIÊU AN TOÀN:\n-------------------------------------\n[Mục Tiêu Hiện Tại]: Chưa Có\n[Khoảng Cách]: 0 Studs\n[Lõi Khóa Trạng Thái]: Đang Đợi Phím Q..."

-- ==================== [ NÚT BẬT MENU DÀNH CHO MOBILE (ĐIỆN THOẠI) ] ====================
local MobileFloatingBtn = Instance.new("TextButton", ScreenGui)
MobileFloatingBtn.Size = UDim2.new(0, 48, 0, 48)
MobileFloatingBtn.Position = UDim2.new(0, 15, 0, 15)
MobileFloatingBtn.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
MobileFloatingBtn.Text = "🎯"
MobileFloatingBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
MobileFloatingBtn.Font = Enum.Font.GothamBlack
MobileFloatingBtn.TextSize = 22
Instance.new("UICorner", MobileFloatingBtn).CornerRadius = UDim.new(1, 0)
local ButtonBorder = Instance.new("UIStroke", MobileFloatingBtn)
ButtonBorder.Color = Color3.fromRGB(170, 0, 255)
ButtonBorder.Thickness = 1.2
AttachDragMechanic(MobileFloatingBtn)

MobileFloatingBtn.MouseButton1Click:Connect(function() MenuFrame.Visible = not MenuFrame.Visible end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.MenuKey then MenuFrame.Visible = not MenuFrame.Visible end
end)

-- ==================== [ CƠ CHẾ SĂN TÌM MỤC TIÊU PHÙ HỢP NHẤT ] ====================
local function ExecuteTargetScanning()
    local bestCandidate = nil
    local minimumScore = math.huge
    
    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil, nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if enemyRoot and TargetValidator.IsCharacterAlive(player) then
                
                -- Loại bỏ đồng đội nếu bật tính năng Team Check
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
                
                -- Tìm kiếm khớp xương tối ưu để ngắm bắn
                local selectedPart = enemyRoot
                if Settings.TargetPartMode == "Tự Động Quét Xương" then
                    local lowestScreenDist = math.huge
                    for _, jointName in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
                        local jointInstance = player.Character:FindFirstChild(jointName)
                        if jointInstance then
                            local screenPosition, insideViewport = Camera:WorldToViewportPoint(jointInstance.Position)
                            if insideViewport then
                                local distanceToCenter = (Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) - Vector2.new(screenPosition.X, screenPosition.Y)).Magnitude
                                if distanceToCenter < lowestScreenDist then
                                    lowestScreenDist = distanceToCenter
                                    selectedPart = jointInstance
                                end
                            end
                        end
                    end
                else
                    local forcedPart = player.Character:FindFirstChild(Settings.TargetPartMode)
                    if forcedPart then selectedPart = forcedPart end
                end

                -- Kiểm tra tường chắn rào cản tầm nhìn
                if not TargetValidator.IsPlayerVisible(selectedPart, player.Character) then continue end

                local screenCoords, isVisibleOnScreen = Camera:WorldToViewportPoint(selectedPart.Position)
                
                -- Lọc mục tiêu nằm ngoài phạm vi vòng tròn FOV
                if Settings.ShowFOV then
                    local mouseDistance = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(screenCoords.X, screenCoords.Y)).Magnitude
                    if mouseDistance > Settings.FOVRadius then continue end
                end

                -- Chế độ ưu tiên quét ngắm
                if Settings.AimType == "Khoảng Cách (Gần Nhất)" then
                    local worldDist = MathLibrary.CalculateWorldDistance(localRoot.Position, selectedPart.Position)
                    if worldDist < minimumScore then
                        minimumScore = worldDist
                        bestCandidate = {Player = player, Part = selectedPart}
                    end
                elseif Settings.AimType == "Tâm Màn Hình" then
                    local screenDist = MathLibrary.CalculateScreenDistance(Camera.ViewportSize / 2, screenCoords)
                    if screenDist < minimumScore then
                        minimumScore = screenDist
                        bestCandidate = {Player = player, Part = selectedPart}
                    end
                end
            end
        end
    end
    
    if bestCandidate then
        return bestCandidate.Player, bestCandidate.Part
    end
    return nil, nil
end

-- ==================== [ BẮT SỰ KIỆN PHÍM BẤM KÍCH HOẠT KHÓA NGẮM ] ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.LockKey then
        if Settings.IsHoldMode then
            AimlockActive = true
        else
            AimlockActive = not AimlockActive
            PushNotification("AIMLOCK V6", AimlockActive and "ĐANG KHÓA CHẶT MỤC TIÊU 🎯" or "ĐÃ NGẮT KHÓA MỤC TIÊU ✕", AimlockActive and Color3.fromRGB(0,255,255) or Color3.fromRGB(255,60,60))
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.LockKey and Settings.IsHoldMode then
        AimlockActive = false
    end
end)

-- ==================== [ LUỒNG VẼ ĐỒ HỌA VÀ ĐIỀU CHỈNH GÓC QUY SẤY ĐẠN (RENDERSTEPPED) ] ====================
RunService.RenderStepped:Connect(function()
    RainbowHue = (RainbowHue + 0.004) % 1
    local chromaColor = Color3.fromHSV(RainbowHue, 0.85, 1)
    
    -- Cập nhật trạng thái vòng FOV
    if Settings.ShowFOV and Settings.Enabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Settings.FOVRadius
        FOVCircle.Thickness = Settings.FOVThickness
        FOVCircle.NumSides = Settings.FOVSides
        FOVCircle.Color = Settings.RainbowFOV and chromaColor or Settings.FOVColor
        FOVCircle.Transparency = Settings.FOVTransparency
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Khởi chạy chu kỳ tính toán bám đuổi mục tiêu
    if Settings.Enabled and AimlockActive then
        local foundPlayer, foundPart = ExecuteTargetScanning()
        CurrentTargetPlayer = foundPlayer
        CurrentTargetPart = foundPart
        
        if foundPlayer and foundPart then
            local finalPosition = foundPart.Position
            local targetVelocity = foundPart.Velocity
            
            -- Thuật toán dự đoán chống trượt đạn dựa theo gia tốc di chuyển
            if Settings.PredictionMode == "Gia Tốc Cao Cấp" then
                finalPosition = finalPosition + (targetVelocity * Settings.PredictionAmount)
            elseif Settings.PredictionMode == "Bù Trừ Ping" then
                local currentPing = 0.045
                pcall(function() currentPing = LocalPlayer:GetNetworkPing() end)
                finalPosition = finalPosition + (targetVelocity * currentPing * (Settings.PredictionAmount * 6.5))
            elseif Settings.PredictionMode == "Tuyến Tính Cơ Bản" then
                finalPosition = finalPosition + (targetVelocity * 0.1)
            end
            
            -- Sửa lỗi NaN: Chỉ tính toán khi khoảng cách hợp lệ
            local calculatedCFrame = MathLibrary.SafeLookAt(Camera.CFrame.Position, finalPosition)
            
            -- Các thuật toán nội suy làm mượt góc xoay Camera mượt mà
            if Settings.SmoothingMode == "Bộ Lọc Bezier" then
                local lerpRotation = Camera.CFrame:Lerp(calculatedCFrame, Settings.Smoothness)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position) * lerpRotation.Rotation
            elseif Settings.SmoothingMode == "Exponential Mượt" then
                local interpolationFactor = 1 - math.exp(-Settings.Smoothness * 55 * RunService.RenderStepped:Wait())
                Camera.CFrame = Camera.CFrame:Lerp(calculatedCFrame, math.clamp(interpolationFactor, 0, 1))
            elseif Settings.SmoothingMode == "Tuyến Tính" then
                Camera.CFrame = Camera.CFrame:Lerp(calculatedCFrame, Settings.Smoothness)
            end

            -- Vẽ sợi dây khóa mục tiêu cyberpunk kết nối từ tâm màn hình
            local screenLocation, onViewport = Camera:WorldToViewportPoint(foundPart.Position)
            if onViewport then
                ConnectionLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                ConnectionLine.To = Vector2.new(screenLocation.X, screenLocation.Y)
                ConnectionLine.Color = Settings.RainbowFOV and chromaColor or Color3.fromRGB(255, 0, 130)
                ConnectionLine.Thickness = 1.5
                ConnectionLine.Transparency = 0.8
                ConnectionLine.Visible = true
            else
                ConnectionLine.Visible = false
            end
        else
            ConnectionLine.Visible = false
        end
    else
        CurrentTargetPlayer = nil
        CurrentTargetPart = nil
        ConnectionLine.Visible = false
    end
end)

-- ==================== [ VÒNG LẶP ĐỒNG BỘ THÔNG TIN BẢNG THEO DÕI HỆ THỐNG ] ====================
RunService.Heartbeat:Connect(function()
    if MenuFrame.Visible and PanelTab.Visible then
        if CurrentTargetPlayer and CurrentTargetPart and CurrentTargetPlayer.Character then
            local enemyHumanoid = CurrentTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
            local localCharacter = LocalPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            
            if enemyHumanoid and localRoot then
                local actualDistance = math.floor(MathLibrary.CalculateWorldDistance(localRoot.Position, CurrentTargetPart.Position))
                
                RadarText.Text = string.format(
                    "HỆ THỐNG GIÁM SÁT MỤC TIÊU AN TOÀN:\n-------------------------------------\n" ..
                    "[Mục Tiêu Hiện Tại]: %s\n" ..
                    "[Bộ Phận Đang Khóa]: %s\n" ..
                    "[Khoảng Cách Thực]: %d Studs\n" ..
                    "[Lượng Máu Kẻ Địch]: %d / %d\n" ..
                    "[Lõi Khóa Trạng Thái]: ĐANG BÁM CHẶT CHỐNG RUNG ĐẠN 🎯",
                    CurrentTargetPlayer.Name,
                    CurrentTargetPart.Name,
                    actualDistance,
                    enemyHumanoid.Health,
                    enemyHumanoid.MaxHealth
                )
            end
        else
            RadarText.Text = "HỆ THỐNG GIÁM SÁT MỤC TIÊU AN TOÀN:\n-------------------------------------\n[Mục Tiêu Hiện Tại]: Không tìm thấy mục tiêu khả dụng\n[Khoảng Cách]: 0 Studs\n[Lõi Khóa Trạng Thái]: Đang liên tục quét vùng FOV..."
        end
    end
end)

-- Phát tín hiệu khởi động bản Vá Lỗi thành công không rườm rà
PushNotification("MINH MEO OMNIVERSE", "Đã nạp Pure Aimlock Engine v6.0 thành công! Bấm Q để kích hoạt khóa.", Color3.fromRGB(0, 255, 255))

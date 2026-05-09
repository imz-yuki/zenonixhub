-- ====================================================================
-- ZENONIX HUB - PREMIUM KEY SYSTEM LOADER (KEY: teleprime)
-- ====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local CORRECT_KEY = "teleprime"
local DISCORD_LINK = "https://discord.gg/kaizenmc" -- Tự động copy link này khi nhấn Get Key

-- ==================== SCREEN GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixKeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

-- Main Frame (Bảng nhập Key)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -100) -- Căn giữa màn hình
MainFrame.Size = UDim2.new(0, 320, 0, 200)
MainFrame.BorderSizePixel = 0

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Viền Neon Xanh dương cực chất
local Stroke = Instance.new("UIStroke")
Stroke.Parent = MainFrame
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(0, 180, 255)
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Tiêu đề (Title)
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Text = "🔑 ZENONIX HUB - KEY SYSTEM"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Position = UDim2.new(0, 0, 0, 0)

-- Ô Nhập Key (TextBox)
local KeyInput = Instance.new("TextBox")
KeyInput.Parent = MainFrame
KeyInput.PlaceholderText = "Nhập Key tại đây..."
KeyInput.Text = ""
KeyInput.Font = Enum.Font.GothamSemibold
KeyInput.TextSize = 12
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
KeyInput.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
KeyInput.Position = UDim2.new(0.1, 0, 0.28, 0)
KeyInput.Size = UDim2.new(0.8, 0, 0, 35)
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 6)

local InputStroke = Instance.new("UIStroke")
InputStroke.Parent = KeyInput
InputStroke.Thickness = 1
InputStroke.Color = Color3.fromRGB(50, 50, 60)

-- Nút CHECK KEY
local CheckButton = Instance.new("TextButton")
CheckButton.Parent = MainFrame
CheckButton.Text = "XÁC NHẬN KEY"
CheckButton.Font = Enum.Font.GothamBold
CheckButton.TextSize = 11
CheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
CheckButton.Position = UDim2.new(0.1, 0, 0.52, 0)
CheckButton.Size = UDim2.new(0.38, 0, 0, 35)
Instance.new("UICorner", CheckButton).CornerRadius = UDim.new(0, 6)

-- Nút GET KEY
local GetKeyButton = Instance.new("TextButton")
GetKeyButton.Parent = MainFrame
GetKeyButton.Text = "LẤY KEY (DISCORD)"
GetKeyButton.Font = Enum.Font.GothamBold
GetKeyButton.TextSize = 11
GetKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
GetKeyButton.Position = UDim2.new(0.52, 0, 0.52, 0)
GetKeyButton.Size = UDim2.new(0.38, 0, 0, 35)
Instance.new("UICorner", GetKeyButton).CornerRadius = UDim.new(0, 6)

local GetKeyStroke = Instance.new("UIStroke")
GetKeyStroke.Parent = GetKeyButton
GetKeyStroke.Thickness = 1
GetKeyStroke.Color = Color3.fromRGB(80, 80, 90)

-- Trạng thái (Status)
local Status = Instance.new("TextLabel")
Status.Parent = MainFrame
Status.Text = "Vui lòng nhập key để mở khóa giao diện!"
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 10
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.Position = UDim2.new(0, 0, 0.78, 0)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.BackgroundTransparency = 1

-- ==================== CHỨC NĂNG HỖ TRỢ ====================

-- 1. Hàm thông báo nhanh bằng Roblox Core
local function Notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = duration or 5;
    })
end

-- 2. Hiệu ứng rung lắc UI khi nhập sai Key
local function shakeUI()
    local originalPos = MainFrame.Position
    for i = 1, 8 do
        local offsetX = math.random(-6, 6)
        local offsetY = math.random(-3, 3)
        MainFrame.Position = originalPos + UDim2.new(0, offsetX, 0, offsetY)
        task.wait(0.02)
    end
    MainFrame.Position = originalPos
end

-- 3. Hiệu ứng mờ dần (Fade Out) khi thành công
local function fadeOutAndDestroy()
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Cho mờ hết các phần tử con
    for _, child in ipairs(MainFrame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("TextButton") then
            TweenService:Create(child, tweenInfo, {TextTransparency = 1}):Play()
            if child:IsA("TextButton") or child:IsA("TextBox") then
                TweenService:Create(child, tweenInfo, {BackgroundTransparency = 1}):Play()
            end
        elseif child:IsA("UIStroke") then
            TweenService:Create(child, tweenInfo, {Transparency = 1}):Play()
        end
    end
    
    local mainTween = TweenService:Create(MainFrame, tweenInfo, {BackgroundTransparency = 1, Size = UDim2.new(0, 300, 0, 180)})
    mainTween:Play()
    mainTween.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end

-- ==================== LOGIC XỬ LÝ CHÍNH ====================

-- Sự kiện nhấn nút GET KEY (Tự copy link Discord)
GetKeyButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(DISCORD_LINK)
        Status.Text = "✅ Đã copy link Discord vào khay nhớ tạm!"
        Status.TextColor3 = Color3.fromRGB(0, 255, 120)
    else
        Status.Text = "❌ Executor không hỗ trợ setclipboard!"
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

-- Sự kiện nhấn nút XÁC NHẬN KEY
CheckButton.MouseButton1Click:Connect(function()
    local enteredKey = KeyInput.Text
    
    if enteredKey == CORRECT_KEY then
        Status.Text = "🔑 Key chính xác! Đang tải dữ liệu..."
        Status.TextColor3 = Color3.fromRGB(0, 255, 120)
        CheckButton.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
        
        -- Chờ tí cho mượt rồi tải Script chính
        task.wait(0.5)
        fadeOutAndDestroy()
        
        -- [TẢI SCRIPT CHÍNH TỪ GITHUB]
        local success, result = pcall(function()
            local url = "https://raw.githubusercontent.com/imz-yuki/zenonixhub/refs/heads/main/teleprime.lua?t=" .. os.time()
            local code = game:HttpGet(url)
            return loadstring(code)
        end)
        
        if success and type(result) == "function" then
            local run_success, run_err = pcall(result)
            if run_success then
                Notify("ZENONIX LOADED", "Script Teleprime khởi chạy thành công!", 5)
            else
                Notify("SCRIPT ERROR", "Lỗi thực thi code bên trong!", 10)
                warn("❌ [Zenonix Exec Error]: " .. tostring(run_err))
            end
        else
            Notify("DOWNLOAD ERROR", "Không thể tải file từ GitHub!", 10)
            warn("❌ [Zenonix Download Error]: " .. tostring(result))
        end
    else
        -- Xử lý khi sai Key
        Status.Text = "❌ Key không đúng! Vui lòng thử lại."
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)
        InputStroke.Color = Color3.fromRGB(255, 80, 80)
        
        task.spawn(shakeUI) -- Hiệu ứng rung màn hình
        
        task.delay(1.5, function()
            if KeyInput.Text ~= CORRECT_KEY then
                InputStroke.Color = Color3.fromRGB(50, 50, 60)
            end
        end)
    end
end)

-- ==================== HỆ THỐNG KÉO UI MƯỢT MÀ ====================
local dragging = false
local dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

print("🚀 [Zenonix Loader]: Key System Active! Created by Yuki.")

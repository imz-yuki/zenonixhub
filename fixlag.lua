-- [[ ZENONIX HUB - FIX LAG LOADER V2 ]] --
-- ✮-> Developed by: yuki.dev | Power: 9999

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 1. Tránh Double-Load (Anti-Double Load)
local successGui, coreGui = pcall(function() return game:GetService("CoreGui") end)
local targetParent = successGui and coreGui or LocalPlayer:WaitForChild("PlayerGui")

if targetParent:FindFirstChild("YukiFixLagLoader") then
    targetParent.YukiFixLagLoader:Destroy()
end

-- 2. Khởi tạo Giao diện Loader
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YukiFixLagLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetParent

-- Hàm tạo Corner chuẩn Local
local function applyCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

-- Khung chính của Loader (Bắt đầu nhỏ để làm hiệu ứng Elastic phóng to)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 180, 0, 80)
Main.Position = UDim2.new(0.5, -90, 0.5, -40)
Main.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
Main.BorderSizePixel = 0
Main.BackgroundTransparency = 1
Main.Parent = ScreenGui
applyCorner(Main, 12)

-- Viền Neon ảo diệu đổi màu liên tục
local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(58, 134, 255)
Stroke.Thickness = 1.8
Stroke.Transparency = 1
Stroke.Parent = Main

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 134, 255)), -- Neon Blue
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 120)), -- Hot Pink
    ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 134, 255))
})
UIGradient.Parent = Stroke

-- Tiêu đề Loader
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 12)
Title.BackgroundTransparency = 1
Title.Text = "ZENONIX HUB | FIX LAG"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextTransparency = 1
Title.Parent = Main

-- Trạng thái tải (Status)
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0, 42)
Status.BackgroundTransparency = 1
Status.Text = "Đang kết nối..."
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.TextSize = 11
Status.Font = Enum.Font.GothamMedium
Status.TextTransparency = 1
Status.Parent = Main

-- Bộ đếm phần trăm dạng số (%)
local PercentLabel = Instance.new("TextLabel")
PercentLabel.Size = UDim2.new(0, 50, 0, 20)
PercentLabel.Position = UDim2.new(0.5, -25, 0.65, 12)
PercentLabel.BackgroundTransparency = 1
PercentLabel.Text = "0%"
PercentLabel.TextColor3 = Color3.fromRGB(58, 134, 255)
PercentLabel.TextSize = 12
PercentLabel.Font = Enum.Font.GothamBold
PercentLabel.TextTransparency = 1
PercentLabel.Parent = Main

-- Thanh Progress Bar Background
local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(0, 250, 0, 6)
BarBg.Position = UDim2.new(0.5, -125, 0.65, 4)
BarBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
BarBg.BorderSizePixel = 0
BarBg.BackgroundTransparency = 1
BarBg.Parent = Main
applyCorner(BarBg, 4)

-- Thanh Progress Bar Chạy thực tế
local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(58, 134, 255)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBg
applyCorner(BarFill, 4)

local BarGradient = UIGradient:Clone()
BarGradient.Parent = BarFill

-- ==========================================
-- 3. HIỆU ỨNG XOAY VIỀN NEON TỰ ĐỘNG
-- ==========================================
task.spawn(function()
    local rot = 0
    while ScreenGui and ScreenGui.Parent do
        rot = (rot + 2) % 360
        UIGradient.Rotation = rot
        pcall(function() BarGradient.Rotation = rot end)
        task.wait(0.01)
    end
end)

-- ==========================================
-- 4. HIỆU ỨNG BOUNCE XUẤT HIỆN (0.5 GIÂY)
-- ==========================================
TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 320, 0, 150),
    Position = UDim2.new(0.5, -160, 0.5, -75),
    BackgroundTransparency = 0.05
}):Play()

TweenService:Create(Stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
TweenService:Create(Title, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
TweenService:Create(Status, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
TweenService:Create(PercentLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
TweenService:Create(BarBg, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
task.wait(0.6)

-- ==========================================
-- 5. LÕI CHẠY KHỚP TRẠNG THÁI (ĐÚNG 3 GIÂY)
-- ==========================================
task.spawn(function()
    local duration = 3.0 -- Khóa cứng thời gian chạy là 3 giây
    local elapsed = 0
    
    while elapsed < duration do
        local dt = task.wait()
        elapsed = elapsed + dt
        local ratio = math.min(elapsed / duration, 1)
        
        -- Cập nhật kích thước thanh tiến trình & phần trăm số
        BarFill.Size = UDim2.new(ratio, 0, 1, 0)
        local currentPercent = math.round(ratio * 100)
        PercentLabel.Text = tostring(currentPercent) .. "%"
        
        -- Hiệu ứng chuyển màu chữ phần trăm từ Neon Xanh -> Neon Xanh Lá khi hoàn thành
        PercentLabel.TextColor3 = Color3.fromRGB(58, 134, 255):Lerp(Color3.fromRGB(100, 255, 100), ratio)
        
        -- Cập nhật Trạng thái & Xác nhận danh tính theo tiến trình thời gian
        if ratio < 0.35 then
            Status.Text = "Đang xác nhận: yuki.dev..."
            Status.TextColor3 = Color3.fromRGB(180, 180, 180)
        elseif ratio >= 0.35 and ratio < 0.70 then
            Status.Text = "Xác nhận thành công! (Power: 9999)"
            Status.TextColor3 = Color3.fromRGB(100, 255, 100)
        elseif ratio >= 0.70 and ratio < 0.95 then
            Status.Text = "Đang dọn dẹp bộ nhớ đệm (VRAM)..."
            Status.TextColor3 = Color3.fromRGB(240, 240, 240)
        else
            Status.Text = "Khởi chạy Fix Lag..."
            Status.TextColor3 = Color3.fromRGB(58, 134, 255)
        end
    end
    
    -- Đảm bảo kết thúc hiển thị chính xác 100%
    BarFill.Size = UDim2.new(1, 0, 1, 0)
    PercentLabel.Text = "100%"
    PercentLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    Status.Text = "Hoàn tất!"
    Status.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    -- Âm thanh báo hiệu bíp nhẹ cực cuốn khi hoàn tất tải
    local successSound = Instance.new("Sound")
    successSound.SoundId = "rbxassetid://4590662762"
    successSound.Volume = 0.5
    successSound.Parent = Main
    pcall(function() successSound:Play() end)
    
    task.wait(0.6)
    
    -- ==========================================
    -- 6. HIỆU ỨNG THU NHỎ BIẾN MẤT (OUTRO)
    -- ==========================================
    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 150, 0, 60),
        Position = UDim2.new(0.5, -75, 0.5, -30),
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
    TweenService:Create(Title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(Status, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(PercentLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(BarBg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(BarFill, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    task.wait(0.4)
    
    -- Dọn dẹp giao diện hoàn tất
    ScreenGui:Destroy()
    
    -- ==========================================
    -- 7. KHỞI CHẠY SCRIPT CHÍNH (FIX LAG)
    -- ==========================================
    local successRun, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/imz-yuki/zenonixhub/refs/heads/main/loifixlag.lua"))()
    end)
    
    if not successRun then
        warn("Lỗi tải script: " .. tostring(err)) -- Đã loại bỏ hoàn toàn lỗi cú pháp dư "nil"
    end
end)

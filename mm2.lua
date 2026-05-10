-- [[ ZENONIX HUB VIP - MM2 SPECIAL EDITION ]] --
-- Developed for Yuki (Power 9999)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Tạo ScreenGui trong CoreGui để tránh bị phát hiện/chụp màn hình
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixHub_MM2"
local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
ScreenGui.Parent = success and coreGui or LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

-- ==========================================
-- 1. THIẾT KẾ GIAO DIỆN CHÍNH (MAIN FRAME)
-- ==========================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 12)

-- Viền Neon phát sáng nhẹ
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 80, 95)
UIStroke.Thickness = 1.8
UIStroke.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 45)
Topbar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame
addCorner(Topbar, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ ZENONIX HUB | MM2 SPECIAL EDITION"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.TextSize = 26
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.Parent = Topbar

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Hệ thống kéo thả UI
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

-- Sidebar điều hướng
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -155, 1, -60)
ContentContainer.Position = UDim2.new(0, 148, 0, 52)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Hệ thống tạo Tab
local Pages = {}
local TabButtons = {}

local function createPage(name)
    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentContainer
    Pages[name] = page
    return page
end

local ESPPage = createPage("ESP")
local CopySkinPage = createPage("CopySkin")
local InfoPage = createPage("PlayerInfo")

local function switchTab(tabName)
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(58, 134, 255)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

local function createTabButton(name, text, positionY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 38)
    btn.Position = UDim2.new(0, 6, 0, positionY)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Sidebar
    addCorner(btn, 6)
    
    TabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

createTabButton("ESP", "👁️ MM2 ESP", 10)
createTabButton("CopySkin", "👥 Clone Skin", 53)
createTabButton("PlayerInfo", "ℹ️ Info Player", 96)

switchTab("ESP")

-- ==========================================
-- 2. LOGIC MM2 ESP (BÁ ĐẠO NHẤT)
-- ==========================================

local ESPActive = false
local ESPConnection = nil

-- Hàm check vũ khí MM2 để phân vai trò người chơi
local function getMM2Role(player)
    local character = player.Character
    local backpack = player.Backpack
    
    -- Kiểm tra Dao (Sát nhân)
    local hasKnife = (backpack and (backpack:FindFirstChild("Knife") or backpack:FindFirstChild("Knife_Base"))) or 
                     (character and (character:FindFirstChild("Knife") or character:FindFirstChild("Knife_Base")))
    
    -- Kiểm tra Súng (Cảnh sát trưởng hoặc người nhặt súng)
    local hasGun = (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Gun_Base"))) or 
                   (character and (character:FindFirstChild("Gun") or character:FindFirstChild("Gun_Base")))
    
    if hasKnife then
        return "MURDERER", Color3.fromRGB(255, 0, 50) -- Đỏ rực
    elseif hasGun then
        return "SHERIFF", Color3.fromRGB(0, 150, 255) -- Xanh súng
    else
        return "INNOCENT", Color3.fromRGB(50, 255, 100) -- Xanh lá mướt
    end
end

-- Dọn dẹp ESP của một người chơi
local function removePlayerESP(player)
    local char = player.Character
    if char then
        local highlight = char:FindFirstChild("MM2_Highlight")
        if highlight then highlight:Destroy() end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local billboard = hrp:FindFirstChild("MM2_Billboard")
            if billboard then billboard:Destroy() end
        end
    end
end

-- Cập nhật ESP liên tục theo thời gian thực (Real-time Tracker)
local function startESPTracker()
    ESPConnection = RunService.RenderStepped:Connect(function()
        if not ESPActive then return end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
                    local hrp = char.HumanoidRootPart
                    local roleName, roleColor = getMM2Role(player)
                    
                    -- 1. Vẽ Viền xuyên tường (Highlight)
                    local highlight = char:FindFirstChild("MM2_Highlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "MM2_Highlight"
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = char
                    end
                    highlight.FillColor = roleColor
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.55
                    highlight.OutlineTransparency = 0.1
                    
                    -- 2. Vẽ bảng thông tin (Billboard) trên đầu
                    local billboard = hrp:FindFirstChild("MM2_Billboard")
                    if not billboard then
                        billboard = Instance.new("BillboardGui")
                        billboard.Name = "MM2_Billboard"
                        billboard.AlwaysOnTop = true
                        billboard.Size = UDim2.new(0, 220, 0, 60)
                        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
                        
                        local textLabel = Instance.new("TextLabel")
                        textLabel.Name = "InfoLabel"
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.TextSize = 13
                        textLabel.Font = Enum.Font.GothamBold
                        textLabel.TextStrokeTransparency = 0.3
                        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        textLabel.Parent = billboard
                        
                        billboard.Parent = hrp
                    end
                    
                    -- Tính toán khoảng cách
                    local distance = 0
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        distance = math.round((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                    end
                    
                    local infoLabel = billboard:FindFirstChild("InfoLabel")
                    if infoLabel then
                        infoLabel.Text = string.format("[%s]\n%s\n[%d studs]", roleName, player.DisplayName, distance)
                        infoLabel.TextColor3 = roleColor
                    end
                end
            end
        end
    end)
end

local function stopESPTracker()
    if ESPConnection then
        ESPConnection:Disconnect()
        ESPConnection = nil
    end
    for _, p in ipairs(Players:GetPlayers()) do
        removePlayerESP(p)
    end
end

-- Giao diện điều khiển ESP
local ESPDesc = Instance.new("TextLabel")
ESPDesc.Text = "HỆ THỐNG ĐỊNH VỊ VAI TRÒ MM2\n\n🔴 Đỏ: Sát Nhân | 🔵 Xanh Dương: Cảnh Sát | 🟢 Xanh Lá: Dân"
ESPDesc.Size = UDim2.new(1, 0, 0, 60)
ESPDesc.BackgroundTransparency = 1
ESPDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
ESPDesc.TextSize = 13
ESPDesc.Font = Enum.Font.GothamMedium
ESPDesc.Parent = ESPPage

local ESPToggle = Instance.new("TextButton")
ESPToggle.Size = UDim2.new(0, 190, 0, 48)
ESPToggle.Position = UDim2.new(0.5, -95, 0.45, 0)
ESPToggle.BackgroundColor3 = Color3.fromRGB(242, 76, 76)
ESPToggle.Text = "MM2 ESP: TẮT"
ESPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPToggle.TextSize = 15
ESPToggle.Font = Enum.Font.GothamBold
ESPToggle.Parent = ESPPage
addCorner(ESPToggle, 8)

ESPToggle.MouseButton1Click:Connect(function()
    if ESPActive then
        ESPActive = false
        stopESPTracker()
        ESPToggle.Text = "MM2 ESP: TẮT"
        ESPToggle.BackgroundColor3 = Color3.fromRGB(242, 76, 76)
    else
        ESPActive = true
        startESPTracker()
        ESPToggle.Text = "MM2 ESP: BẬT"
        ESPToggle.BackgroundColor3 = Color3.fromRGB(76, 201, 240)
    end
end)


-- ==========================================
-- 3. LOGIC TAB 2: COPY SKIN TRONG SERVER
-- ==========================================

local SkinDesc = Instance.new("TextLabel")
SkinDesc.Text = "SAO CHÉP NGOẠI HÌNH NGƯỜI CHƠI TRONG SERVER"
SkinDesc.Size = UDim2.new(1, 0, 0, 30)
SkinDesc.BackgroundTransparency = 1
SkinDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
SkinDesc.TextSize = 12
SkinDesc.Font = Enum.Font.GothamBold
SkinDesc.Parent = CopySkinPage

local SkinTextBox = Instance.new("TextBox")
SkinTextBox.Size = UDim2.new(1, -30, 0, 40)
SkinTextBox.Position = UDim2.new(0, 15, 0.28, 0)
SkinTextBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
SkinTextBox.PlaceholderText = "Nhập tên hoặc chữ cái đầu..."
SkinTextBox.Text = ""
SkinTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SkinTextBox.TextSize = 14
SkinTextBox.Font = Enum.Font.Gotham
SkinTextBox.Parent = CopySkinPage
addCorner(SkinTextBox, 8)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 160, 0, 42)
CopyBtn.Position = UDim2.new(0.5, -80, 0.6, 10)
CopyBtn.BackgroundColor3 = Color3.fromRGB(58, 134, 255)
CopyBtn.Text = "Clone Skin"
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.TextSize = 14
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.Parent = CopySkinPage
addCorner(CopyBtn, 8)

CopyBtn.MouseButton1Click:Connect(function()
    local targetName = SkinTextBox.Text
    local targetPlayer = nil
    
    -- Thuật toán tìm kiếm tên tương đối cực mạnh
    for _, p in ipairs(Players:GetPlayers()) do
        if string.sub(string.lower(p.Name), 1, string.len(targetName)) == string.lower(targetName) or
           string.sub(string.lower(p.DisplayName), 1, string.len(targetName)) == string.lower(targetName) then
            targetPlayer = p
            break
        end
    end
    
    if targetPlayer then
        local myChar = LocalPlayer.Character
        local targetChar = targetPlayer.Character
        if myChar and targetChar then
            local myHum = myChar:FindFirstChildOfClass("Humanoid")
            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
            if myHum and targetHum then
                local s, desc = pcall(function() return targetHum:GetAppliedDescription() end)
                if s and desc then
                    myHum:ApplyDescription(desc)
                    SkinDesc.Text = "✔️ Đã sao chép thành công của: " .. targetPlayer.DisplayName
                    SkinDesc.TextColor3 = Color3.fromRGB(50, 255, 100)
                    task.delay(3, function()
                        SkinDesc.Text = "SAO CHÉP NGOẠI HÌNH NGƯỜI CHƠI TRONG SERVER"
                        SkinDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
                    end)
                end
            end
        end
    else
        SkinDesc.Text = "❌ Không tìm thấy người chơi!"
        SkinDesc.TextColor3 = Color3.fromRGB(242, 76, 76)
        task.delay(3, function()
            SkinDesc.Text = "SAO CHÉP NGOẠI HÌNH NGƯỜI CHƠI TRONG SERVER"
            SkinDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
        end)
    end
end)


-- ==========================================
-- 4. LOGIC TAB 3: PLAYER INFO (CHI TIẾT)
-- ==========================================

local InfoDesc = Instance.new("TextLabel")
InfoDesc.Text = "TRA CỨU THÔNG TIN CHI TIẾT NGƯỜI CHƠI"
InfoDesc.Size = UDim2.new(1, 0, 0, 25)
InfoDesc.BackgroundTransparency = 1
InfoDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
InfoDesc.TextSize = 12
InfoDesc.Font = Enum.Font.GothamBold
InfoDesc.Parent = InfoPage

local InfoTextBox = Instance.new("TextBox")
InfoTextBox.Size = UDim2.new(1, -30, 0, 36)
InfoTextBox.Position = UDim2.new(0, 15, 0.15, 0)
InfoTextBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
InfoTextBox.PlaceholderText = "Nhập tên người chơi..."
InfoTextBox.Text = ""
InfoTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoTextBox.TextSize = 13
InfoTextBox.Font = Enum.Font.Gotham
InfoTextBox.Parent = InfoPage
addCorner(InfoTextBox, 8)

-- Khung hiển thị thông số đẹp mắt
local DetailFrame = Instance.new("Frame")
DetailFrame.Size = UDim2.new(1, -30, 0, 100)
DetailFrame.Position = UDim2.new(0, 15, 0.35, 10)
DetailFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
DetailFrame.BorderSizePixel = 0
DetailFrame.Parent = InfoPage
addCorner(DetailFrame, 8)

local DisplayLabel = Instance.new("TextLabel")
DisplayLabel.Size = UDim2.new(1, -20, 0, 25)
DisplayLabel.Position = UDim2.new(0, 10, 0, 5)
DisplayLabel.BackgroundTransparency = 1
DisplayLabel.Text = "Display Name: ---"
DisplayLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
DisplayLabel.TextSize = 13
DisplayLabel.Font = Enum.Font.Gotham
DisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
DisplayLabel.Parent = DetailFrame

local IDLabel = DisplayLabel:Clone()
IDLabel.Position = UDim2.new(0, 10, 0, 35)
IDLabel.Text = "User ID: ---"
IDLabel.Parent = DetailFrame

local AgeLabel = DisplayLabel:Clone()
AgeLabel.Position = UDim2.new(0, 10, 0, 65)
AgeLabel.Text = "Tuổi tài khoản: ---"
AgeLabel.Parent = DetailFrame

local FetchBtn = Instance.new("TextButton")
FetchBtn.Size = UDim2.new(0, 150, 0, 36)
FetchBtn.Position = UDim2.new(0.5, -75, 0.78, 15)
FetchBtn.BackgroundColor3 = Color3.fromRGB(76, 201, 240)
FetchBtn.Text = "Xem thông tin"
FetchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FetchBtn.TextSize = 13
FetchBtn.Font = Enum.Font.GothamBold
FetchBtn.Parent = InfoPage
addCorner(FetchBtn, 8)

FetchBtn.MouseButton1Click:Connect(function()
    local targetName = InfoTextBox.Text
    local targetPlayer = nil
    
    for _, p in ipairs(Players:GetPlayers()) do
        if string.sub(string.lower(p.Name), 1, string.len(targetName)) == string.lower(targetName) or
           string.sub(string.lower(p.DisplayName), 1, string.len(targetName)) == string.lower(targetName) then
            targetPlayer = p
            break
        end
    end
    
    if targetPlayer then
        DisplayLabel.Text = "Display Name: " .. targetPlayer.DisplayName
        IDLabel.Text = "User ID: " .. tostring(targetPlayer.UserId)
        AgeLabel.Text = "Tuổi tài khoản: " .. tostring(targetPlayer.AccountAge) .. " ngày"
    else
        DisplayLabel.Text = "Display Name: Không tìm thấy!"
        IDLabel.Text = "User ID: ---"
        AgeLabel.Text = "Tuổi tài khoản: ---"
    end
end)

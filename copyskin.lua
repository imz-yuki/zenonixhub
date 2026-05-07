--[[
    ZENONIX HUB | SKIN COPIER V3.0
    Strongest Version - Clean & Powerful
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Accent1 = Color3.fromRGB(255, 85, 165)   -- Hot Pink
local Accent2 = Color3.fromRGB(120, 30, 230)   -- Deep Purple

-- ==================== UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixSkinCopierV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 340, 0, 320)
Main.Position = UDim2.new(0.5, -170, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 23)
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 3.5
local Grad = Instance.new("UIGradient", Stroke)
Grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Accent1),
    ColorSequenceKeypoint.new(1, Accent2)
}

-- Title
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 18)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "⌬ ZENONIX SKIN COPIER"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 17

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -17.5)
CloseBtn.Text = "✕"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1,0)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Player Selector
local PlayerButton = Instance.new("TextButton", Main)
PlayerButton.Size = UDim2.new(0.9, 0, 0, 50)
PlayerButton.Position = UDim2.new(0.05, 0, 0.22, 0)
PlayerButton.Text = "Select Player ▼"
PlayerButton.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
PlayerButton.TextColor3 = Color3.new(1,1,1)
PlayerButton.Font = Enum.Font.GothamSemibold
PlayerButton.TextSize = 15
Instance.new("UICorner", PlayerButton).CornerRadius = UDim.new(0, 12)

local Dropdown = Instance.new("ScrollingFrame", Main)
Dropdown.Size = UDim2.new(0.9, 0, 0, 160)
Dropdown.Position = UDim2.new(0.05, 0, 0.42, 0)
Dropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Dropdown.Visible = false
Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 12)
local DropLayout = Instance.new("UIListLayout", Dropdown)
DropLayout.Padding = UDim.new(0, 6)

-- Copy Button
local CopyButton = Instance.new("TextButton", Main)
CopyButton.Size = UDim2.new(0.9, 0, 0, 55)
CopyButton.Position = UDim2.new(0.05, 0, 0.75, 0)
CopyButton.Text = "COPY FULL SKIN"
CopyButton.BackgroundColor3 = Accent1
CopyButton.TextColor3 = Color3.new(1,1,1)
CopyButton.Font = Enum.Font.GothamBold
CopyButton.TextSize = 16
Instance.new("UICorner", CopyButton).CornerRadius = UDim.new(0, 14)

-- ==================== LOGIC COPY SIÊU MẠNH ====================
local SelectedPlayer = nil

local function DeepClean(char)
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("Accessory") or v:IsA("Clothing") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
            v:Destroy()
        end
    end
    if char:FindFirstChild("Head") then
        for _, f in pairs(char.Head:GetChildren()) do
            if f:IsA("Decal") and f.Name == "face" then
                f:Destroy()
            end
        end
    end
end

local function CopyFullSkin(target)
    if not target or not target.Character then
        warn("Target character not found!")
        return
    end

    local myChar = LocalPlayer.Character
    if not myChar then
        warn("Your character not loaded!")
        return
    end

    DeepClean(myChar)

    -- BodyColors
    local bodyColors = target.Character:FindFirstChildOfClass("BodyColors")
    if bodyColors then
        bodyColors:Clone().Parent = myChar
    end

    -- Face
    pcall(function()
        local face = target.Character.Head:FindFirstChild("face")
        if face then
            face:Clone().Parent = myChar.Head
        end
    end)

    -- All Clothing & Accessories
    for _, item in pairs(target.Character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("ShirtGraphic") then
            pcall(function()
                item:Clone().Parent = myChar
            end)
        end
    end

    print("✅ Copied full skin from: " .. target.DisplayName)
end

-- Refresh Player List
local function RefreshList()
    for _, v in pairs(Dropdown:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -12, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            btn.Text = "   " .. plr.DisplayName
            btn.TextColor3 = Color3.new(1,1,1)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            btn.Parent = Dropdown

            btn.MouseButton1Click:Connect(function()
                SelectedPlayer = plr
                PlayerButton.Text = plr.DisplayName
                Dropdown.Visible = false
            end)
        end
    end
end

-- Events
PlayerButton.MouseButton1Click:Connect(function()
    Dropdown.Visible = not Dropdown.Visible
    if Dropdown.Visible then RefreshList() end
end)

CopyButton.MouseButton1Click:Connect(function()
    if SelectedPlayer then
        CopyFullSkin(SelectedPlayer)
    end
end)

-- Draggable
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

print("Zenonix Skin Copier V3.0 Loaded - Strongest Version")

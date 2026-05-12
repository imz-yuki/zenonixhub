--[[
    PROJECT : KAIZEN - EXPERIMENTAL MODULE (BẢN TẠM THỜI)
    DEVELOPER: MINH MEO OMNIVERSE
--]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Trạng thái bật/tắt
local _G.AimlockEnabled = false
local _G.ESPEnabled = false

-- TẠO UI TẠM THỜI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local AimlockBtn = Instance.new("TextButton")
local ESPBtn = Instance.new("TextButton")

ScreenGui.Parent = game.CoreGui
MainFrame.Name = "KaizenPanel"
MainFrame.Size = UDim2.new(0, 180, 0, 140)
MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Title.Text = "KAIZEN - TEMP"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.Code
Title.Parent = MainFrame

-- Nút Aimlock
AimlockBtn.Text = "AIMLOCK: OFF"
AimlockBtn.Size = UDim2.new(0.8, 0, 0, 35)
AimlockBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
AimlockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AimlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimlockBtn.Parent = MainFrame

-- Nút ESP
ESPBtn.Text = "ESP: OFF"
ESPBtn.Size = UDim2.new(0.8, 0, 0, 35)
ESPBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
ESPBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPBtn.Parent = MainFrame

--- LOGIC HỆ THỐNG ---

local function getClosest()
    local target = nil
    local dist = math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            local pos, vis = Camera:WorldToViewportPoint(v.Character.Head.Position)
            if vis then
                local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if mag < dist then
                    dist = mag
                    target = v
                end
            end
        end
    end
    return target
end

-- Bật/Tắt Aimlock
AimlockBtn.MouseButton1Click:Connect(function()
    _G.AimlockEnabled = not _G.AimlockEnabled
    AimlockBtn.Text = _G.AimlockEnabled and "AIMLOCK: ON" or "AIMLOCK: OFF"
    AimlockBtn.TextColor3 = _G.AimlockEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- Bật/Tắt ESP
ESPBtn.MouseButton1Click:Connect(function()
    _G.ESPEnabled = not _G.ESPEnabled
    ESPBtn.Text = _G.ESPEnabled and "ESP: ON" or "ESP: OFF"
    ESPBtn.TextColor3 = _G.ESPEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- Vòng lặp xử lý
RunService.RenderStepped:Connect(function()
    -- Xử lý Aimlock
    if _G.AimlockEnabled then
        local target = getClosest()
        if target and target.Character then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end

    -- Xử lý ESP (Sử dụng Highlight để "đẹp và mạnh")
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local highlight = v.Character:FindFirstChild("KaizenESP")
            if _G.ESPEnabled then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "KaizenESP"
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.Parent = v.Character
                end
            else
                if highlight then highlight:Destroy() end
            end
        end
    end
end)

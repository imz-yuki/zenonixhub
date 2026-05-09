-- ====================================================================
-- ZENONIX SAVE & TELEPORT V5 - MODERN / CLEAN / DETAILS
-- Session-based save list
-- Loading screen: 2 seconds
-- Features:
-- - Save / Teleport / Delete positions
-- - Search filter
-- - Favorite pin
-- - Selected details panel
-- - Smooth loading animation
-- - Minimize / Close
-- ====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local savedPositions = {}
local selectedId = nil
local pendingDeleteId = nil
local saveDebounce = false
local minimized = false

-- ==================== HELPERS ====================
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function makeStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function round(n)
	return math.floor(n * 10 + 0.5) / 10
end

local function formatPos(cf)
	local p = cf.Position
	return string.format("X: %.1f   Y: %.1f   Z: %.1f", round(p.X), round(p.Y), round(p.Z))
end

local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	return char, hrp
end

local function makeGuid()
	return HttpService:GenerateGUID(false)
end

-- ==================== GUI ROOT ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixSaveTPV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ==================== LOADING SCREEN ====================
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Parent = ScreenGui
LoadingFrame.BackgroundColor3 = Color3.fromRGB(10, 11, 15)
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BorderSizePixel = 0

local LoadingCard = Instance.new("Frame")
LoadingCard.Parent = LoadingFrame
LoadingCard.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
LoadingCard.Size = UDim2.new(0, 360, 0, 140)
LoadingCard.Position = UDim2.new(0.5, -180, 0.5, -70)
LoadingCard.BorderSizePixel = 0
makeCorner(LoadingCard, 14)
makeStroke(LoadingCard, Color3.fromRGB(0, 170, 255), 2, 0.15)

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Parent = LoadingCard
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Position = UDim2.new(0.05, 0, 0.12, 0)
LoadingTitle.Size = UDim2.new(0.9, 0, 0, 24)
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.Text = "ZENONIX | SAVING SYSTEM"
LoadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingTitle.TextSize = 16

local LoadingSub = Instance.new("TextLabel")
LoadingSub.Parent = LoadingCard
LoadingSub.BackgroundTransparency = 1
LoadingSub.Position = UDim2.new(0.05, 0, 0.36, 0)
LoadingSub.Size = UDim2.new(0.9, 0, 0, 20)
LoadingSub.Font = Enum.Font.Gotham
LoadingSub.Text = "Đang khởi tạo giao diện..."
LoadingSub.TextColor3 = Color3.fromRGB(170, 175, 190)
LoadingSub.TextSize = 11

local ProgressBack = Instance.new("Frame")
ProgressBack.Parent = LoadingCard
ProgressBack.BackgroundColor3 = Color3.fromRGB(30, 33, 43)
ProgressBack.Position = UDim2.new(0.05, 0, 0.68, 0)
ProgressBack.Size = UDim2.new(0.9, 0, 0, 12)
ProgressBack.BorderSizePixel = 0
makeCorner(ProgressBack, 8)

local ProgressFill = Instance.new("Frame")
ProgressFill.Parent = ProgressBack
ProgressFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BorderSizePixel = 0
makeCorner(ProgressFill, 8)

local ProgressText = Instance.new("TextLabel")
ProgressText.Parent = LoadingCard
ProgressText.BackgroundTransparency = 1
ProgressText.Position = UDim2.new(0.05, 0, 0.81, 0)
ProgressText.Size = UDim2.new(0.9, 0, 0, 18)
ProgressText.Font = Enum.Font.GothamSemibold
ProgressText.Text = "0%"
ProgressText.TextColor3 = Color3.fromRGB(220, 225, 235)
ProgressText.TextSize = 11

do
	local steps = 40
	for i = 1, steps do
		local alpha = i / steps
		ProgressFill.Size = UDim2.new(alpha, 0, 1, 0)

		if alpha < 0.3 then
			LoadingSub.Text = "Đang nạp thành phần giao diện..."
		elseif alpha < 0.6 then
			LoadingSub.Text = "Đang chuẩn bị danh sách vị trí..."
		elseif alpha < 0.9 then
			LoadingSub.Text = "Đang tối ưu khung điều khiển..."
		else
			LoadingSub.Text = "Sẵn sàng..."
		end

		ProgressText.Text = tostring(math.floor(alpha * 100)) .. "%"
		task.wait(0.05)
	end
end

tween(LoadingCard, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 1
})
tween(LoadingTitle, TweenInfo.new(0.2), {TextTransparency = 1})
tween(LoadingSub, TweenInfo.new(0.2), {TextTransparency = 1})
tween(ProgressText, TweenInfo.new(0.2), {TextTransparency = 1})
tween(ProgressBack, TweenInfo.new(0.2), {BackgroundTransparency = 1})
tween(ProgressFill, TweenInfo.new(0.2), {BackgroundTransparency = 1})

task.wait(0.22)
LoadingFrame:Destroy()

-- ==================== MAIN UI ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
MainFrame.Position = UDim2.new(0.35, 0, 0.18, 0)
MainFrame.Size = UDim2.new(0, 420, 0, 520)
MainFrame.BorderSizePixel = 0
makeCorner(MainFrame, 14)
makeStroke(MainFrame, Color3.fromRGB(0, 170, 255), 2, 0.1)

local Topbar = Instance.new("Frame")
Topbar.Parent = MainFrame
Topbar.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Topbar.Size = UDim2.new(1, 0, 0, 54)
Topbar.BorderSizePixel = 0
makeCorner(Topbar, 14)

local TopbarFix = Instance.new("Frame")
TopbarFix.Parent = Topbar
TopbarFix.BackgroundColor3 = Topbar.BackgroundColor3
TopbarFix.BorderSizePixel = 0
TopbarFix.Position = UDim2.new(0, 0, 0.5, 0)
TopbarFix.Size = UDim2.new(1, 0, 0.5, 0)

local Title = Instance.new("TextLabel")
Title.Parent = Topbar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.Size = UDim2.new(0.75, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "ZENONIX | SAVE & TELEPORT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 120, 255))
})
TitleGradient.Parent = Title

local CountLabel = Instance.new("TextLabel")
CountLabel.Parent = Topbar
CountLabel.BackgroundTransparency = 1
CountLabel.Position = UDim2.new(0.04, 0, 0.5, -2)
CountLabel.Size = UDim2.new(0.55, 0, 0, 18)
CountLabel.Font = Enum.Font.Gotham
CountLabel.Text = "0 vị trí đã lưu"
CountLabel.TextColor3 = Color3.fromRGB(170, 175, 190)
CountLabel.TextSize = 10
CountLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinButton = Instance.new("TextButton")
MinButton.Parent = Topbar
MinButton.BackgroundColor3 = Color3.fromRGB(34, 37, 48)
MinButton.Text = "—"
MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinButton.Font = Enum.Font.GothamBold
MinButton.TextSize = 18
MinButton.Size = UDim2.new(0, 28, 0, 24)
MinButton.Position = UDim2.new(1, -66, 0.5, -12)
makeCorner(MinButton, 6)

local CloseButton = Instance.new("TextButton")
CloseButton.Parent = Topbar
CloseButton.BackgroundColor3 = Color3.fromRGB(55, 28, 34)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.Size = UDim2.new(0, 28, 0, 24)
CloseButton.Position = UDim2.new(1, -34, 0.5, -12)
makeCorner(CloseButton, 6)

local SearchBox = Instance.new("TextBox")
SearchBox.Parent = MainFrame
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.PlaceholderColor3 = Color3.fromRGB(125, 130, 145)
SearchBox.PlaceholderText = "Tìm vị trí..."
SearchBox.Text = ""
SearchBox.Font = Enum.Font.GothamSemibold
SearchBox.TextSize = 12
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(0.58, 0, 0, 36)
SearchBox.Position = UDim2.new(0.04, 0, 0, 66)
makeCorner(SearchBox, 8)
makeStroke(SearchBox, Color3.fromRGB(70, 75, 90), 1, 0.35)

local SaveButton = Instance.new("TextButton")
SaveButton.Parent = MainFrame
SaveButton.BackgroundColor3 = Color3.fromRGB(0, 160, 110)
SaveButton.Text = "LƯU VỊ TRÍ"
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.Font = Enum.Font.GothamBold
SaveButton.TextSize = 11
SaveButton.Size = UDim2.new(0.28, 0, 0, 36)
SaveButton.Position = UDim2.new(0.66, 0, 0, 66)
makeCorner(SaveButton, 8)

local RefreshButton = Instance.new("TextButton")
RefreshButton.Parent = MainFrame
RefreshButton.BackgroundColor3 = Color3.fromRGB(34, 37, 48)
RefreshButton.Text = "↻"
RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshButton.Font = Enum.Font.GothamBold
RefreshButton.TextSize = 16
RefreshButton.Size = UDim2.new(0, 34, 0, 36)
RefreshButton.Position = UDim2.new(0.96, -34, 0, 66)
makeCorner(RefreshButton, 8)

local DetailsFrame = Instance.new("Frame")
DetailsFrame.Parent = MainFrame
DetailsFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
DetailsFrame.Position = UDim2.new(0.04, 0, 0, 112)
DetailsFrame.Size = UDim2.new(0.92, 0, 0, 92)
DetailsFrame.BorderSizePixel = 0
makeCorner(DetailsFrame, 10)
makeStroke(DetailsFrame, Color3.fromRGB(65, 70, 85), 1, 0.5)

local DetailsTitle = Instance.new("TextLabel")
DetailsTitle.Parent = DetailsFrame
DetailsTitle.BackgroundTransparency = 1
DetailsTitle.Position = UDim2.new(0.04, 0, 0.06, 0)
DetailsTitle.Size = UDim2.new(0.6, 0, 0, 18)
DetailsTitle.Font = Enum.Font.GothamBold
DetailsTitle.Text = "CHI TIẾT"
DetailsTitle.TextColor3 = Color3.fromRGB(235, 238, 245)
DetailsTitle.TextSize = 12
DetailsTitle.TextXAlignment = Enum.TextXAlignment.Left

local DetailsName = Instance.new("TextLabel")
DetailsName.Parent = DetailsFrame
DetailsName.BackgroundTransparency = 1
DetailsName.Position = UDim2.new(0.04, 0, 0.30, 0)
DetailsName.Size = UDim2.new(0.92, 0, 0, 18)
DetailsName.Font = Enum.Font.GothamSemibold
DetailsName.Text = "Chưa chọn vị trí nào."
DetailsName.TextColor3 = Color3.fromRGB(190, 195, 208)
DetailsName.TextSize = 11
DetailsName.TextXAlignment = Enum.TextXAlignment.Left

local DetailsPos = Instance.new("TextLabel")
DetailsPos.Parent = DetailsFrame
DetailsPos.BackgroundTransparency = 1
DetailsPos.Position = UDim2.new(0.04, 0, 0.55, 0)
DetailsPos.Size = UDim2.new(0.92, 0, 0, 18)
DetailsPos.Font = Enum.Font.Gotham
DetailsPos.Text = "X: 0.0   Y: 0.0   Z: 0.0"
DetailsPos.TextColor3 = Color3.fromRGB(170, 175, 190)
DetailsPos.TextSize = 10
DetailsPos.TextXAlignment = Enum.TextXAlignment.Left

local DetailsMeta = Instance.new("TextLabel")
DetailsMeta.Parent = DetailsFrame
DetailsMeta.BackgroundTransparency = 1
DetailsMeta.Position = UDim2.new(0.04, 0, 0.78, 0)
DetailsMeta.Size = UDim2.new(0.92, 0, 0, 16)
DetailsMeta.Font = Enum.Font.Gotham
DetailsMeta.Text = "Favorited: No"
DetailsMeta.TextColor3 = Color3.fromRGB(170, 175, 190)
DetailsMeta.TextSize = 10
DetailsMeta.TextXAlignment = Enum.TextXAlignment.Left

local Scroll = Instance.new("ScrollingFrame")
Scroll.Parent = MainFrame
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.Position = UDim2.new(0.04, 0, 0, 214)
Scroll.Size = UDim2.new(0.92, 0, 0, 250)
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 255)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIList = Instance.new("UIListLayout")
UIList.Parent = Scroll
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
end)

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Parent = Scroll
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Size = UDim2.new(1, 0, 0, 50)
EmptyLabel.Position = UDim2.new(0, 0, 0, 90)
EmptyLabel.Font = Enum.Font.Gotham
EmptyLabel.Text = "Không có vị trí nào."
EmptyLabel.TextColor3 = Color3.fromRGB(145, 150, 165)
EmptyLabel.TextSize = 12

local Status = Instance.new("TextLabel")
Status.Parent = MainFrame
Status.BackgroundTransparency = 1
Status.Position = UDim2.new(0.04, 0, 0.94, 0)
Status.Size = UDim2.new(0.92, 0, 0, 18)
Status.Font = Enum.Font.Gotham
Status.Text = "Sẵn sàng."
Status.TextColor3 = Color3.fromRGB(160, 165, 180)
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left

local GlowBar = Instance.new("Frame")
GlowBar.Parent = MainFrame
GlowBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
GlowBar.BorderSizePixel = 0
GlowBar.Position = UDim2.new(0.04, 0, 0.11, 0)
GlowBar.Size = UDim2.new(0.18, 0, 0, 2)
makeCorner(GlowBar, 4)

tween(GlowBar, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	BackgroundColor3 = Color3.fromRGB(180, 120, 255)
})

-- ==================== LOGIC ====================
local function updateCount()
	CountLabel.Text = tostring(#savedPositions) .. " vị trí đã lưu"
end

local function getSelectedEntry()
	for _, v in ipairs(savedPositions) do
		if v.Id == selectedId then
			return v
		end
	end
	return nil
end

local function updateDetails(entry)
	if not entry then
		DetailsName.Text = "Chưa chọn vị trí nào."
		DetailsPos.Text = "X: 0.0   Y: 0.0   Z: 0.0"
		DetailsMeta.Text = "Favorited: No"
		return
	end

	DetailsName.Text = entry.Name
	DetailsPos.Text = formatPos(entry.CFrame)
	DetailsMeta.Text = "Favorited: " .. (entry.Favorited and "Yes" or "No") .. "   |   Saved: " .. os.date("%H:%M:%S - %d/%m/%Y", entry.CreatedAt or os.time())
end

local function passesFilter(entry)
	local q = string.lower(SearchBox.Text or "")
	if q == "" then
		return true
	end
	return string.find(string.lower(entry.Name or ""), q, 1, true) ~= nil
end

local function sortEntries()
	table.sort(savedPositions, function(a, b)
		if a.Favorited ~= b.Favorited then
			return a.Favorited and not b.Favorited
		end
		return (a.CreatedAt or 0) > (b.CreatedAt or 0)
	end)
end

local function refreshScroll()
	sortEntries()

	for _, child in ipairs(Scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local anyVisible = false

	for _, data in ipairs(savedPositions) do
		if passesFilter(data) then
			anyVisible = true

			local Card = Instance.new("Frame")
			Card.Parent = Scroll
			Card.BackgroundColor3 = (data.Id == selectedId) and Color3.fromRGB(28, 31, 42) or Color3.fromRGB(21, 23, 31)
			Card.Size = UDim2.new(1, 0, 0, 62)
			Card.BorderSizePixel = 0
			makeCorner(Card, 10)
			makeStroke(Card, (data.Id == selectedId) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(65, 70, 85), 1, 0.45)

			local NameLabel = Instance.new("TextLabel")
			NameLabel.Parent = Card
			NameLabel.BackgroundTransparency = 1
			NameLabel.Position = UDim2.new(0.04, 0, 0.05, 0)
			NameLabel.Size = UDim2.new(0.62, 0, 0.42, 0)
			NameLabel.Font = Enum.Font.GothamSemibold
			NameLabel.Text = (data.Favorited and "★ " or "") .. data.Name
			NameLabel.TextColor3 = Color3.fromRGB(240, 242, 245)
			NameLabel.TextSize = 12
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left

			local PosLabel = Instance.new("TextLabel")
			PosLabel.Parent = Card
			PosLabel.BackgroundTransparency = 1
			PosLabel.Position = UDim2.new(0.04, 0, 0.5, 0)
			PosLabel.Size = UDim2.new(0.64, 0, 0.28, 0)
			PosLabel.Font = Enum.Font.Gotham
			PosLabel.Text = formatPos(data.CFrame)
			PosLabel.TextColor3 = Color3.fromRGB(145, 150, 165)
			PosLabel.TextSize = 10
			PosLabel.TextXAlignment = Enum.TextXAlignment.Left

			local SelectBtn = Instance.new("TextButton")
			SelectBtn.Parent = Card
			SelectBtn.BackgroundTransparency = 1
			SelectBtn.Text = ""
			SelectBtn.Size = UDim2.new(1, 0, 1, 0)

			local TpBtn = Instance.new("TextButton")
			TpBtn.Parent = Card
			TpBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
			TpBtn.Text = "TELE"
			TpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			TpBtn.Font = Enum.Font.GothamBold
			TpBtn.TextSize = 10
			TpBtn.Size = UDim2.new(0, 52, 0, 30)
			TpBtn.Position = UDim2.new(1, -118, 0.5, -15)
			makeCorner(TpBtn, 8)

			local FavBtn = Instance.new("TextButton")
			FavBtn.Parent = Card
			FavBtn.BackgroundColor3 = data.Favorited and Color3.fromRGB(120, 95, 0) or Color3.fromRGB(38, 42, 54)
			FavBtn.Text = data.Favorited and "★" or "☆"
			FavBtn.TextColor3 = data.Favorited and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(255, 255, 255)
			FavBtn.Font = Enum.Font.GothamBold
			FavBtn.TextSize = 14
			FavBtn.Size = UDim2.new(0, 30, 0, 30)
			FavBtn.Position = UDim2.new(1, -62, 0.5, -15)
			makeCorner(FavBtn, 8)

			local DelBtn = Instance.new("TextButton")
			DelBtn.Parent = Card
			DelBtn.BackgroundColor3 = (pendingDeleteId == data.Id) and Color3.fromRGB(90, 28, 34) or Color3.fromRGB(46, 28, 34)
			DelBtn.Text = (pendingDeleteId == data.Id) and "OK" or "X"
			DelBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
			DelBtn.Font = Enum.Font.GothamBold
			DelBtn.TextSize = 10
			DelBtn.Size = UDim2.new(0, 28, 0, 30)
			DelBtn.Position = UDim2.new(1, -28, 0.5, -15)
			makeCorner(DelBtn, 8)

			SelectBtn.MouseButton1Click:Connect(function()
				selectedId = data.Id
				updateDetails(data)
				refreshScroll()
			end)

			TpBtn.MouseButton1Click:Connect(function()
				selectedId = data.Id
				updateDetails(data)

				local _, hrp = getCharacter()
				if not hrp then
					Status.Text = "Không tìm thấy HumanoidRootPart."
					Status.TextColor3 = Color3.fromRGB(255, 80, 80)
					return
				end

				tween(hrp, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = data.CFrame
				})

				Status.Text = "Teleport đến: " .. data.Name
				Status.TextColor3 = Color3.fromRGB(0, 255, 140)
			end)

			FavBtn.MouseButton1Click:Connect(function()
				data.Favorited = not data.Favorited
				selectedId = data.Id
				updateDetails(data)
				refreshScroll()
				Status.Text = data.Favorited and "Đã ghim: " .. data.Name or "Đã bỏ ghim: " .. data.Name
				Status.TextColor3 = Color3.fromRGB(255, 220, 80)
			end)

			DelBtn.MouseButton1Click:Connect(function()
				if pendingDeleteId ~= data.Id then
					pendingDeleteId = data.Id
					Status.Text = "Bấm lại để xác nhận xóa: " .. data.Name
					Status.TextColor3 = Color3.fromRGB(255, 200, 80)
					refreshScroll()

					task.delay(2, function()
						if pendingDeleteId == data.Id then
							pendingDeleteId = nil
							refreshScroll()
						end
					end)
					return
				end

				for i, v in ipairs(savedPositions) do
					if v.Id == data.Id then
						table.remove(savedPositions, i)
						break
					end
				end

				if selectedId == data.Id then
					selectedId = nil
					updateDetails(nil)
				end

				pendingDeleteId = nil
				updateCount()
				refreshScroll()
				Status.Text = "Đã xóa: " .. data.Name
				Status.TextColor3 = Color3.fromRGB(255, 100, 100)
			end)
		end
	end

	EmptyLabel.Visible = not anyVisible
	updateCount()
	updateDetails(getSelectedEntry())
end

local function saveCurrentPosition()
	if saveDebounce then return end
	saveDebounce = true

	local _, hrp = getCharacter()
	if not hrp then
		Status.Text = "Lỗi: chưa tìm thấy nhân vật."
		Status.TextColor3 = Color3.fromRGB(255, 80, 80)
		saveDebounce = false
		return
	end

	local name = string.gsub(SearchBox.Text or "", "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	if name == "" then
		name = "Vị trí " .. tostring(#savedPositions + 1)
	end

	for _, v in ipairs(savedPositions) do
		if v.Name == name then
			Status.Text = "Tên đã tồn tại."
			Status.TextColor3 = Color3.fromRGB(255, 200, 80)
			saveDebounce = false
			return
		end
	end

	local entry = {
		Id = makeGuid(),
		Name = name,
		CFrame = hrp.CFrame,
		Favorited = false,
		CreatedAt = os.time()
	}

	table.insert(savedPositions, entry)
	selectedId = entry.Id

	SearchBox.Text = ""
	updateCount()
	updateDetails(entry)
	refreshScroll()

	Status.Text = "Đã lưu: " .. name
	Status.TextColor3 = Color3.fromRGB(0, 255, 140)

	task.delay(0.2, function()
		saveDebounce = false
	end)
end

SaveButton.MouseButton1Click:Connect(saveCurrentPosition)

RefreshButton.MouseButton1Click:Connect(function()
	pendingDeleteId = nil
	refreshScroll()
	Status.Text = "Đã làm mới danh sách."
	Status.TextColor3 = Color3.fromRGB(160, 165, 180)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	refreshScroll()
end)

MinButton.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		tween(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 420, 0, 54)
		})
		SearchBox.Visible = false
		SaveButton.Visible = false
		RefreshButton.Visible = false
		DetailsFrame.Visible = false
		Scroll.Visible = false
		Status.Visible = false
		CountLabel.Visible = false
	else
		SearchBox.Visible = true
		SaveButton.Visible = true
		RefreshButton.Visible = true
		DetailsFrame.Visible = true
		Scroll.Visible = true
		Status.Visible = true
		CountLabel.Visible = true

		tween(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 420, 0, 520)
		})
	end
end)

CloseButton.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

-- ==================== DRAG ====================
local dragging = false
local dragStart
local startPos

Topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- ==================== OPEN ANIMATION ====================
MainFrame.Size = UDim2.new(0, 380, 0, 500)
MainFrame.BackgroundTransparency = 0.08
tween(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 420, 0, 520),
	BackgroundTransparency = 0
})

updateCount()
updateDetails(nil)
refreshScroll()

print("Zenonix Save & Teleport V5 loaded.")

-- ====================================================================
-- ZENONIX SAVE & TELEPORT V6 — SAKURA EDITION
-- Theme: Hồng phấn & Trắng ngà — Luxury / Soft Glow
-- Tác giả: Zenonix Team
-- Tính năng:
--   ✦ Lưu / Teleport / Xóa vị trí
--   ✦ Tìm kiếm thông minh
--   ✦ Ghim yêu thích (Favorite)
--   ✦ Bảng chi tiết vị trí đang chọn
--   ✦ Tag / Nhãn màu cho từng vị trí
--   ✦ Hiệu ứng Ripple khi click nút
--   ✦ Thanh trạng thái động (toast)
--   ✦ Bộ đếm teleport
--   ✦ Loading screen sang trọng
--   ✦ Animation mở / thu gọn / đóng
--   ✦ Kéo thả (drag)
-- ====================================================================

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local RunService     = game:GetService("RunService")

local player = Players.LocalPlayer

-- ==================== STATE ====================
local savedPositions = {}  -- {Id, Name, CFrame, Favorited, CreatedAt, TpCount, Tag}
local selectedId     = nil
local pendingDeleteId = nil
local saveDebounce   = false
local minimized      = false
local totalTeleports = 0

local TAGS = {"🌸 Home", "⚔️ Combat", "🏆 Farm", "🗺️ Explore", "⭐ Special"}
local TAG_COLORS = {
	["🌸 Home"]    = Color3.fromRGB(255, 160, 200),
	["⚔️ Combat"]  = Color3.fromRGB(255, 110, 130),
	["🏆 Farm"]    = Color3.fromRGB(255, 200, 80),
	["🗺️ Explore"] = Color3.fromRGB(100, 210, 255),
	["⭐ Special"] = Color3.fromRGB(200, 160, 255),
}
local selectedTagFilter = nil  -- nil = all
local currentTagIndex   = 1   -- for cycling when saving

-- ==================== COLORS ====================
local C = {
	bg          = Color3.fromRGB(252, 245, 250),
	bgCard      = Color3.fromRGB(255, 250, 254),
	bgDeep      = Color3.fromRGB(248, 238, 246),
	topbar      = Color3.fromRGB(255, 240, 248),
	accent      = Color3.fromRGB(240, 100, 160),
	accentLight = Color3.fromRGB(255, 180, 215),
	accentDark  = Color3.fromRGB(200, 60, 120),
	pink2       = Color3.fromRGB(255, 210, 230),
	white       = Color3.fromRGB(255, 255, 255),
	textMain    = Color3.fromRGB(80, 50, 70),
	textSub     = Color3.fromRGB(160, 120, 145),
	textFaint   = Color3.fromRGB(200, 170, 190),
	stroke      = Color3.fromRGB(240, 195, 220),
	strokeSel   = Color3.fromRGB(240, 100, 160),
	green       = Color3.fromRGB(80, 200, 140),
	red         = Color3.fromRGB(255, 100, 130),
	gold        = Color3.fromRGB(255, 200, 80),
	scrollBar   = Color3.fromRGB(240, 140, 190),
	delBg       = Color3.fromRGB(255, 235, 240),
	delConfirm  = Color3.fromRGB(255, 200, 210),
}

-- ==================== HELPERS ====================
local function makeCorner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = p
	return c
end

local function makeStroke(p, color, thick, transp)
	local s = Instance.new("UIStroke")
	s.Color = color or C.stroke
	s.Thickness = thick or 1
	s.Transparency = transp or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function makePadding(p, top, bottom, left, right)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, top    or 0)
	pad.PaddingBottom = UDim.new(0, bottom or 0)
	pad.PaddingLeft   = UDim.new(0, left   or 0)
	pad.PaddingRight  = UDim.new(0, right  or 0)
	pad.Parent = p
	return pad
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local TQ  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TQS = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TSine = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local function round(n) return math.floor(n * 10 + 0.5) / 10 end

local function formatPos(cf)
	local p = cf.Position
	return string.format("X: %.1f  Y: %.1f  Z: %.1f", round(p.X), round(p.Y), round(p.Z))
end

local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp  = char:WaitForChild("HumanoidRootPart", 5)
	return char, hrp
end

local function makeGuid()
	return HttpService:GenerateGUID(false)
end

local function fmtTime(t)
	return os.date("%H:%M — %d/%m/%Y", t or os.time())
end

-- ==================== ROOT ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixV6_Sakura"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ==================== LOADING SCREEN ====================
local LoadBG = Instance.new("Frame")
LoadBG.Parent = ScreenGui
LoadBG.BackgroundColor3 = Color3.fromRGB(255, 242, 250)
LoadBG.Size = UDim2.new(1, 0, 1, 0)
LoadBG.BorderSizePixel = 0

-- Decorative petals
for i = 1, 8 do
	local petal = Instance.new("Frame")
	petal.Parent = LoadBG
	petal.BackgroundColor3 = Color3.fromRGB(255, 210, 230)
	petal.BackgroundTransparency = 0.55
	local sz = math.random(30, 80)
	petal.Size = UDim2.new(0, sz, 0, sz)
	petal.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
	petal.BorderSizePixel = 0
	petal.Rotation = math.random(0, 360)
	makeCorner(petal, math.random(20, 50))
end

local LoadCard = Instance.new("Frame")
LoadCard.Parent = LoadBG
LoadCard.BackgroundColor3 = C.white
LoadCard.Size = UDim2.new(0, 380, 0, 170)
LoadCard.Position = UDim2.new(0.5, -190, 0.5, -85)
LoadCard.BorderSizePixel = 0
makeCorner(LoadCard, 20)
makeStroke(LoadCard, C.accentLight, 2, 0)

local LcGrad = Instance.new("UIGradient")
LcGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 250)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})
LcGrad.Rotation = 135
LcGrad.Parent = LoadCard

local LoadIcon = Instance.new("TextLabel")
LoadIcon.Parent = LoadCard
LoadIcon.BackgroundTransparency = 1
LoadIcon.Position = UDim2.new(0, 0, 0, 14)
LoadIcon.Size = UDim2.new(1, 0, 0, 32)
LoadIcon.Font = Enum.Font.GothamBold
LoadIcon.Text = "🌸  ZENONIX SYSTEM"
LoadIcon.TextColor3 = C.accent
LoadIcon.TextSize = 18

local LoadSub = Instance.new("TextLabel")
LoadSub.Parent = LoadCard
LoadSub.BackgroundTransparency = 1
LoadSub.Position = UDim2.new(0.05, 0, 0, 52)
LoadSub.Size = UDim2.new(0.9, 0, 0, 18)
LoadSub.Font = Enum.Font.Gotham
LoadSub.Text = "Đang khởi động Sakura Edition..."
LoadSub.TextColor3 = C.textSub
LoadSub.TextSize = 11

local PBG = Instance.new("Frame")
PBG.Parent = LoadCard
PBG.BackgroundColor3 = C.bgDeep
PBG.Position = UDim2.new(0.05, 0, 0, 82)
PBG.Size = UDim2.new(0.9, 0, 0, 10)
PBG.BorderSizePixel = 0
makeCorner(PBG, 8)

local PFill = Instance.new("Frame")
PFill.Parent = PBG
PFill.BackgroundColor3 = C.accent
PFill.Size = UDim2.new(0, 0, 1, 0)
PFill.BorderSizePixel = 0
makeCorner(PFill, 8)

local PGrad = Instance.new("UIGradient")
PGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accentLight),
	ColorSequenceKeypoint.new(1, C.accent),
})
PGrad.Parent = PFill

local PPct = Instance.new("TextLabel")
PPct.Parent = LoadCard
PPct.BackgroundTransparency = 1
PPct.Position = UDim2.new(0.05, 0, 0, 100)
PPct.Size = UDim2.new(0.9, 0, 0, 16)
PPct.Font = Enum.Font.GothamSemibold
PPct.Text = "0%"
PPct.TextColor3 = C.textSub
PPct.TextSize = 10

local LoadDots = Instance.new("TextLabel")
LoadDots.Parent = LoadCard
LoadDots.BackgroundTransparency = 1
LoadDots.Position = UDim2.new(0.05, 0, 0, 120)
LoadDots.Size = UDim2.new(0.9, 0, 0, 30)
LoadDots.Font = Enum.Font.GothamBold
LoadDots.Text = "✦ ✦ ✦"
LoadDots.TextColor3 = C.accentLight
LoadDots.TextSize = 20

-- Animate dots
local dotConn
local dotState = 0
dotConn = RunService.Heartbeat:Connect(function()
	dotState = dotState + 1
	if dotState % 18 == 0 then
		local patterns = {"✦ · ·", "· ✦ ·", "· · ✦", "✦ ✦ ✦"}
		LoadDots.Text = patterns[math.ceil(dotState / 18) % #patterns + 1]
	end
end)

local steps = 40
local msgs = {
	"Đang tải giao diện hoa anh đào...",
	"Chuẩn bị danh sách vị trí...",
	"Tối ưu animation...",
	"Sẵn sàng! 🌸"
}

for i = 1, steps do
	local a = i / steps
	PFill.Size = UDim2.new(a, 0, 1, 0)
	PPct.Text = tostring(math.floor(a * 100)) .. "%"
	local mi = math.ceil(a * #msgs)
	if mi < 1 then mi = 1 end
	if mi > #msgs then mi = #msgs end
	LoadSub.Text = msgs[mi]
	task.wait(0.05)
end

dotConn:Disconnect()

tween(LoadCard, TQ, {BackgroundTransparency = 1})
tween(LoadIcon, TQ, {TextTransparency = 1})
tween(LoadSub, TQ, {TextTransparency = 1})
tween(PPct, TQ, {TextTransparency = 1})
tween(LoadDots, TQ, {TextTransparency = 1})
tween(PBG, TQ, {BackgroundTransparency = 1})
tween(PFill, TQ, {BackgroundTransparency = 1})
task.wait(0.25)
LoadBG:Destroy()

-- ==================== MAIN FRAME ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "ZenonixMain"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = C.bg
MainFrame.Position = UDim2.new(0.33, 0, 0.12, 0)
MainFrame.Size = UDim2.new(0, 460, 0, 580)
MainFrame.BorderSizePixel = 0
makeCorner(MainFrame, 18)
makeStroke(MainFrame, C.accentLight, 2, 0)

-- Subtle gradient background
local MainGrad = Instance.new("UIGradient")
MainGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 253)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(252, 238, 248)),
})
MainGrad.Rotation = 145
MainGrad.Parent = MainFrame

-- Top decorative bar
local TopAccentBar = Instance.new("Frame")
TopAccentBar.Parent = MainFrame
TopAccentBar.BackgroundColor3 = C.accent
TopAccentBar.BorderSizePixel = 0
TopAccentBar.Size = UDim2.new(1, 0, 0, 3)
TopAccentBar.Position = UDim2.new(0, 0, 0, 0)
makeCorner(TopAccentBar, 18)

local TopAccentBarBot = Instance.new("Frame")
TopAccentBarBot.Parent = TopAccentBar
TopAccentBarBot.BackgroundColor3 = C.accent
TopAccentBarBot.BorderSizePixel = 0
TopAccentBarBot.Size = UDim2.new(1, 0, 0.5, 0)
TopAccentBarBot.Position = UDim2.new(0, 0, 0.5, 0)

local TBarGrad = Instance.new("UIGradient")
TBarGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accentLight),
	ColorSequenceKeypoint.new(0.5, C.accent),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 160)),
})
TBarGrad.Parent = TopAccentBar

-- ==================== TOPBAR ====================
local Topbar = Instance.new("Frame")
Topbar.Parent = MainFrame
Topbar.BackgroundColor3 = C.topbar
Topbar.Size = UDim2.new(1, 0, 0, 60)
Topbar.Position = UDim2.new(0, 0, 0, 3)
Topbar.BorderSizePixel = 0

local TbGrad = Instance.new("UIGradient")
TbGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 238, 248)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 248, 252)),
})
TbGrad.Rotation = 90
TbGrad.Parent = Topbar

-- Fix corners overlap
local TbFix = Instance.new("Frame")
TbFix.Parent = Topbar
TbFix.BackgroundColor3 = C.topbar
TbFix.BorderSizePixel = 0
TbFix.Position = UDim2.new(0, 0, 0.55, 0)
TbFix.Size = UDim2.new(1, 0, 0.5, 0)

-- Logo icon flower
local LogoIcon = Instance.new("TextLabel")
LogoIcon.Parent = Topbar
LogoIcon.BackgroundTransparency = 1
LogoIcon.Position = UDim2.new(0, 14, 0.5, -14)
LogoIcon.Size = UDim2.new(0, 28, 0, 28)
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Text = "🌸"
LogoIcon.TextSize = 22

-- Animate logo spin slowly
spawn(function()
	while MainFrame and MainFrame.Parent do
		for r = 0, 10, 1 do
			if not LogoIcon or not LogoIcon.Parent then break end
			LogoIcon.Rotation = r
			task.wait(0.05)
		end
		for r = 10, -10, -1 do
			if not LogoIcon or not LogoIcon.Parent then break end
			LogoIcon.Rotation = r
			task.wait(0.05)
		end
		for r = -10, 0, 1 do
			if not LogoIcon or not LogoIcon.Parent then break end
			LogoIcon.Rotation = r
			task.wait(0.05)
		end
		task.wait(2)
	end
end)

local Title = Instance.new("TextLabel")
Title.Parent = Topbar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 50, 0, 6)
Title.Size = UDim2.new(0.65, 0, 0, 26)
Title.Font = Enum.Font.GothamBold
Title.Text = "ZENONIX  SAKURA"
Title.TextColor3 = C.accent
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accent),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 180)),
})
TitleGrad.Parent = Title

local SubTitle = Instance.new("TextLabel")
SubTitle.Parent = Topbar
SubTitle.BackgroundTransparency = 1
SubTitle.Position = UDim2.new(0, 50, 0, 32)
SubTitle.Size = UDim2.new(0.65, 0, 0, 16)
SubTitle.Font = Enum.Font.Gotham
SubTitle.Text = "Save & Teleport  V6"
SubTitle.TextColor3 = C.textFaint
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Stats pill
local StatPill = Instance.new("Frame")
StatPill.Parent = Topbar
StatPill.BackgroundColor3 = C.pink2
StatPill.Position = UDim2.new(0, 50, 0.5, 0)
StatPill.Size = UDim2.new(0, 120, 0, 16)
makeCorner(StatPill, 8)

local StatLabel = Instance.new("TextLabel")
StatLabel.Parent = StatPill
StatLabel.BackgroundTransparency = 1
StatLabel.Size = UDim2.new(1, 0, 1, 0)
StatLabel.Font = Enum.Font.GothamSemibold
StatLabel.Text = "0 lưu  •  0 teleport"
StatLabel.TextColor3 = C.accentDark
StatLabel.TextSize = 9

local MinButton = Instance.new("TextButton")
MinButton.Parent = Topbar
MinButton.BackgroundColor3 = C.pink2
MinButton.Text = "—"
MinButton.TextColor3 = C.accent
MinButton.Font = Enum.Font.GothamBold
MinButton.TextSize = 16
MinButton.Size = UDim2.new(0, 30, 0, 26)
MinButton.Position = UDim2.new(1, -70, 0.5, -13)
makeCorner(MinButton, 8)

local CloseButton = Instance.new("TextButton")
CloseButton.Parent = Topbar
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 225, 232)
CloseButton.Text = "✕"
CloseButton.TextColor3 = C.red
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 12
CloseButton.Size = UDim2.new(0, 30, 0, 26)
CloseButton.Position = UDim2.new(1, -36, 0.5, -13)
makeCorner(CloseButton, 8)

-- Topbar separator
local TbLine = Instance.new("Frame")
TbLine.Parent = MainFrame
TbLine.BackgroundColor3 = C.stroke
TbLine.BorderSizePixel = 0
TbLine.Position = UDim2.new(0.04, 0, 0, 63)
TbLine.Size = UDim2.new(0.92, 0, 0, 1)

-- ==================== TAG FILTER ROW ====================
local TagRow = Instance.new("ScrollingFrame")
TagRow.Parent = MainFrame
TagRow.BackgroundTransparency = 1
TagRow.BorderSizePixel = 0
TagRow.Position = UDim2.new(0.04, 0, 0, 72)
TagRow.Size = UDim2.new(0.92, 0, 0, 28)
TagRow.ScrollBarThickness = 0
TagRow.CanvasSize = UDim2.new(0, 0, 0, 0)

local TagRowList = Instance.new("UIListLayout")
TagRowList.Parent = TagRow
TagRowList.FillDirection = Enum.FillDirection.Horizontal
TagRowList.Padding = UDim.new(0, 6)
TagRowList.SortOrder = Enum.SortOrder.LayoutOrder
TagRowList.VerticalAlignment = Enum.VerticalAlignment.Center

local function buildTagRow()
	for _, c in ipairs(TagRow:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	-- "Tất cả" button
	local allBtn = Instance.new("TextButton")
	allBtn.Parent = TagRow
	allBtn.Font = Enum.Font.GothamSemibold
	allBtn.TextSize = 10
	allBtn.Text = "All"
	allBtn.Size = UDim2.new(0, 40, 0, 22)
	allBtn.BackgroundColor3 = selectedTagFilter == nil and C.accent or C.pink2
	allBtn.TextColor3 = selectedTagFilter == nil and C.white or C.accentDark
	allBtn.BorderSizePixel = 0
	makeCorner(allBtn, 11)

	allBtn.MouseButton1Click:Connect(function()
		selectedTagFilter = nil
		buildTagRow()
	end)

	for _, tag in ipairs(TAGS) do
		local col = TAG_COLORS[tag] or C.accentLight
		local btn = Instance.new("TextButton")
		btn.Parent = TagRow
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 10
		btn.Text = tag
		btn.AutomaticSize = Enum.AutomaticSize.X
		btn.Size = UDim2.new(0, 0, 0, 22)
		btn.BackgroundColor3 = selectedTagFilter == tag and col or C.white
		btn.TextColor3 = selectedTagFilter == tag and C.white or C.textSub
		btn.BorderSizePixel = 0
		makeCorner(btn, 11)
		makeStroke(btn, col, 1, selectedTagFilter == tag and 1 or 0.3)
		makePadding(btn, 0, 0, 8, 8)

		btn.MouseButton1Click:Connect(function()
			selectedTagFilter = (selectedTagFilter == tag) and nil or tag
			buildTagRow()
			-- refresh is called in refreshScroll via buildTagRow->nothing; call explicitly:
		end)
	end

	TagRow.CanvasSize = UDim2.new(0, TagRowList.AbsoluteContentSize.X + 10, 0, 0)
	-- Trigger refresh after rebuild
	task.defer(function() refreshScroll() end)
end

-- ==================== SEARCH + SAVE ROW ====================
local SearchBox = Instance.new("TextBox")
SearchBox.Parent = MainFrame
SearchBox.BackgroundColor3 = C.white
SearchBox.TextColor3 = C.textMain
SearchBox.PlaceholderColor3 = C.textFaint
SearchBox.PlaceholderText = "🔍  Tên vị trí / tìm kiếm..."
SearchBox.Text = ""
SearchBox.Font = Enum.Font.GothamSemibold
SearchBox.TextSize = 11
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(0.55, 0, 0, 36)
SearchBox.Position = UDim2.new(0.04, 0, 0, 108)
makeCorner(SearchBox, 10)
makeStroke(SearchBox, C.stroke, 1.5, 0)
makePadding(SearchBox, 0, 0, 10, 0)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	refreshScroll()
end)

local TagCycleBtn = Instance.new("TextButton")
TagCycleBtn.Parent = MainFrame
TagCycleBtn.BackgroundColor3 = C.pink2
TagCycleBtn.Font = Enum.Font.GothamSemibold
TagCycleBtn.TextSize = 9
TagCycleBtn.Text = TAGS[currentTagIndex]
TagCycleBtn.TextColor3 = C.accentDark
TagCycleBtn.Size = UDim2.new(0, 80, 0, 36)
TagCycleBtn.Position = UDim2.new(0.04 + 0.55 + 0.015, 0, 0, 108)
makeCorner(TagCycleBtn, 10)
makeStroke(TagCycleBtn, C.accentLight, 1, 0)

TagCycleBtn.MouseButton1Click:Connect(function()
	currentTagIndex = currentTagIndex % #TAGS + 1
	TagCycleBtn.Text = TAGS[currentTagIndex]
end)

local SaveButton = Instance.new("TextButton")
SaveButton.Parent = MainFrame
SaveButton.BackgroundColor3 = C.accent
SaveButton.Text = "✦ LƯU"
SaveButton.TextColor3 = C.white
SaveButton.Font = Enum.Font.GothamBold
SaveButton.TextSize = 11
SaveButton.Size = UDim2.new(0.19, 0, 0, 36)
SaveButton.Position = UDim2.new(0.77, 0, 0, 108)
makeCorner(SaveButton, 10)

local SaveGrad = Instance.new("UIGradient")
SaveGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accentLight),
	ColorSequenceKeypoint.new(1, C.accentDark),
})
SaveGrad.Rotation = 90
SaveGrad.Parent = SaveButton

-- ==================== DETAILS PANEL ====================
local DetailsFrame = Instance.new("Frame")
DetailsFrame.Parent = MainFrame
DetailsFrame.BackgroundColor3 = C.white
DetailsFrame.Position = UDim2.new(0.04, 0, 0, 154)
DetailsFrame.Size = UDim2.new(0.92, 0, 0, 104)
DetailsFrame.BorderSizePixel = 0
makeCorner(DetailsFrame, 12)
makeStroke(DetailsFrame, C.stroke, 1.5, 0)

local DfGrad = Instance.new("UIGradient")
DfGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 253)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})
DfGrad.Rotation = 135
DfGrad.Parent = DetailsFrame

-- Left accent stripe
local DStripe = Instance.new("Frame")
DStripe.Parent = DetailsFrame
DStripe.BackgroundColor3 = C.accent
DStripe.BorderSizePixel = 0
DStripe.Position = UDim2.new(0, 0, 0, 12)
DStripe.Size = UDim2.new(0, 3, 0, 80)
makeCorner(DStripe, 4)

local DetailsTitle = Instance.new("TextLabel")
DetailsTitle.Parent = DetailsFrame
DetailsTitle.BackgroundTransparency = 1
DetailsTitle.Position = UDim2.new(0, 18, 0, 8)
DetailsTitle.Size = UDim2.new(0.5, 0, 0, 18)
DetailsTitle.Font = Enum.Font.GothamBold
DetailsTitle.Text = "CHI TIẾT VỊ TRÍ"
DetailsTitle.TextColor3 = C.accent
DetailsTitle.TextSize = 11
DetailsTitle.TextXAlignment = Enum.TextXAlignment.Left

local DetailsTagBadge = Instance.new("TextLabel")
DetailsTagBadge.Parent = DetailsFrame
DetailsTagBadge.BackgroundColor3 = C.pink2
DetailsTagBadge.Position = UDim2.new(1, -120, 0, 10)
DetailsTagBadge.Size = UDim2.new(0, 110, 0, 16)
DetailsTagBadge.Font = Enum.Font.GothamSemibold
DetailsTagBadge.Text = ""
DetailsTagBadge.TextColor3 = C.accentDark
DetailsTagBadge.TextSize = 9
makeCorner(DetailsTagBadge, 8)
makePadding(DetailsTagBadge, 0, 0, 6, 6)

local DetailsName = Instance.new("TextLabel")
DetailsName.Parent = DetailsFrame
DetailsName.BackgroundTransparency = 1
DetailsName.Position = UDim2.new(0, 18, 0, 30)
DetailsName.Size = UDim2.new(0.88, 0, 0, 20)
DetailsName.Font = Enum.Font.GothamSemibold
DetailsName.Text = "Chưa chọn vị trí nào."
DetailsName.TextColor3 = C.textMain
DetailsName.TextSize = 12
DetailsName.TextXAlignment = Enum.TextXAlignment.Left

local DetailsPos = Instance.new("TextLabel")
DetailsPos.Parent = DetailsFrame
DetailsPos.BackgroundTransparency = 1
DetailsPos.Position = UDim2.new(0, 18, 0, 52)
DetailsPos.Size = UDim2.new(0.88, 0, 0, 16)
DetailsPos.Font = Enum.Font.Code
DetailsPos.Text = "X: —   Y: —   Z: —"
DetailsPos.TextColor3 = C.textSub
DetailsPos.TextSize = 10
DetailsPos.TextXAlignment = Enum.TextXAlignment.Left

local DetailsMeta = Instance.new("TextLabel")
DetailsMeta.Parent = DetailsFrame
DetailsMeta.BackgroundTransparency = 1
DetailsMeta.Position = UDim2.new(0, 18, 0, 70)
DetailsMeta.Size = UDim2.new(0.88, 0, 0, 16)
DetailsMeta.Font = Enum.Font.Gotham
DetailsMeta.Text = "Yêu thích: Không  •  Teleport: 0 lần"
DetailsMeta.TextColor3 = C.textFaint
DetailsMeta.TextSize = 9
DetailsMeta.TextXAlignment = Enum.TextXAlignment.Left

local DetailsMeta2 = Instance.new("TextLabel")
DetailsMeta2.Parent = DetailsFrame
DetailsMeta2.BackgroundTransparency = 1
DetailsMeta2.Position = UDim2.new(0, 18, 0, 84)
DetailsMeta2.Size = UDim2.new(0.88, 0, 0, 14)
DetailsMeta2.Font = Enum.Font.Gotham
DetailsMeta2.Text = ""
DetailsMeta2.TextColor3 = C.textFaint
DetailsMeta2.TextSize = 9
DetailsMeta2.TextXAlignment = Enum.TextXAlignment.Left

-- ==================== SCROLL LIST ====================
local Scroll = Instance.new("ScrollingFrame")
Scroll.Parent = MainFrame
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.Position = UDim2.new(0.04, 0, 0, 268)
Scroll.Size = UDim2.new(0.92, 0, 0, 268)
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = C.scrollBar
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIList = Instance.new("UIListLayout")
UIList.Parent = Scroll
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 12)
end)

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Parent = Scroll
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Size = UDim2.new(1, 0, 0, 60)
EmptyLabel.Font = Enum.Font.GothamSemibold
EmptyLabel.Text = "🌸  Chưa có vị trí nào được lưu."
EmptyLabel.TextColor3 = C.textFaint
EmptyLabel.TextSize = 12
EmptyLabel.Visible = true

-- ==================== STATUS TOAST ====================
local ToastFrame = Instance.new("Frame")
ToastFrame.Parent = MainFrame
ToastFrame.BackgroundColor3 = C.white
ToastFrame.BorderSizePixel = 0
ToastFrame.Position = UDim2.new(0.04, 0, 0.92, 0)
ToastFrame.Size = UDim2.new(0.92, 0, 0, 28)
ToastFrame.BackgroundTransparency = 0.05
makeCorner(ToastFrame, 8)
makeStroke(ToastFrame, C.stroke, 1, 0.3)

local ToastDot = Instance.new("Frame")
ToastDot.Parent = ToastFrame
ToastDot.BackgroundColor3 = C.accent
ToastDot.BorderSizePixel = 0
ToastDot.Position = UDim2.new(0, 10, 0.5, -4)
ToastDot.Size = UDim2.new(0, 8, 0, 8)
makeCorner(ToastDot, 4)

local ToastLabel = Instance.new("TextLabel")
ToastLabel.Parent = ToastFrame
ToastLabel.BackgroundTransparency = 1
ToastLabel.Position = UDim2.new(0, 26, 0, 0)
ToastLabel.Size = UDim2.new(0.88, 0, 1, 0)
ToastLabel.Font = Enum.Font.GothamSemibold
ToastLabel.Text = "Sẵn sàng 🌸"
ToastLabel.TextColor3 = C.textSub
ToastLabel.TextSize = 10
ToastLabel.TextXAlignment = Enum.TextXAlignment.Left

local toastConn
local function showToast(msg, color, dotColor)
	if toastConn then toastConn:Disconnect() end
	ToastLabel.Text = msg
	ToastLabel.TextColor3 = color or C.textSub
	ToastDot.BackgroundColor3 = dotColor or C.accent
	tween(ToastFrame, TQ, {BackgroundTransparency = 0})

	toastConn = task.delay(3, function()
		tween(ToastFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.05})
		ToastLabel.TextColor3 = C.textSub
		ToastDot.BackgroundColor3 = C.accent
		ToastLabel.Text = "Sẵn sàng 🌸"
	end)
end

-- ==================== LOGIC ====================
local function updateStatPill()
	StatLabel.Text = tostring(#savedPositions) .. " lưu  •  " .. tostring(totalTeleports) .. " tp"
end

local function getEntry(id)
	for _, v in ipairs(savedPositions) do
		if v.Id == id then return v end
	end
	return nil
end

local function updateDetails(entry)
	if not entry then
		DetailsName.Text = "Chưa chọn vị trí nào."
		DetailsPos.Text = "X: —   Y: —   Z: —"
		DetailsMeta.Text = "Yêu thích: Không  •  Teleport: 0 lần"
		DetailsMeta2.Text = ""
		DetailsTagBadge.Text = ""
		DetailsTagBadge.BackgroundTransparency = 1
		DStripe.BackgroundColor3 = C.accentLight
		return
	end
	DetailsName.Text = (entry.Favorited and "★  " or "") .. entry.Name
	DetailsPos.Text = formatPos(entry.CFrame)
	DetailsMeta.Text = "Yêu thích: " .. (entry.Favorited and "Có ★" or "Không") .. "  •  Teleport: " .. tostring(entry.TpCount or 0) .. " lần"
	DetailsMeta2.Text = "Lưu lúc: " .. fmtTime(entry.CreatedAt)
	DetailsTagBadge.Text = entry.Tag or ""
	DetailsTagBadge.BackgroundTransparency = entry.Tag and 0 or 1

	if entry.Tag and TAG_COLORS[entry.Tag] then
		DetailsTagBadge.BackgroundColor3 = TAG_COLORS[entry.Tag]
		DStripe.BackgroundColor3 = TAG_COLORS[entry.Tag]
	else
		DStripe.BackgroundColor3 = C.accent
	end
end

local function passesFilter(entry)
	local q = string.lower(SearchBox.Text or "")
	local nameMatch = q == "" or string.find(string.lower(entry.Name or ""), q, 1, true) ~= nil
	local tagMatch  = selectedTagFilter == nil or entry.Tag == selectedTagFilter
	return nameMatch and tagMatch
end

local function sortEntries()
	table.sort(savedPositions, function(a, b)
		if a.Favorited ~= b.Favorited then return a.Favorited and not b.Favorited end
		return (a.CreatedAt or 0) > (b.CreatedAt or 0)
	end)
end

-- Ripple effect on button
local function ripple(btn, col)
	local r = Instance.new("Frame")
	r.Parent = btn
	r.BackgroundColor3 = col or C.white
	r.BackgroundTransparency = 0.5
	r.Size = UDim2.new(0, 0, 0, 0)
	r.Position = UDim2.new(0.5, 0, 0.5, 0)
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.BorderSizePixel = 0
	r.ZIndex = 10
	makeCorner(r, 100)
	tween(r, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1.5, 0, 4, 0),
		BackgroundTransparency = 1
	})
	task.delay(0.36, function() r:Destroy() end)
end

function refreshScroll()
	sortEntries()

	for _, c in ipairs(Scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local anyVisible = false

	for _, data in ipairs(savedPositions) do
		if passesFilter(data) then
			anyVisible = true
			local isSel = data.Id == selectedId
			local tagCol = data.Tag and TAG_COLORS[data.Tag] or C.accentLight

			local Card = Instance.new("Frame")
			Card.Parent = Scroll
			Card.BackgroundColor3 = isSel and Color3.fromRGB(255, 243, 250) or C.white
			Card.Size = UDim2.new(1, 0, 0, 68)
			Card.BorderSizePixel = 0
			makeCorner(Card, 12)
			makeStroke(Card, isSel and C.strokeSel or C.stroke, isSel and 2 or 1, isSel and 0 or 0.2)

			if isSel then
				local CardGrad = Instance.new("UIGradient")
				CardGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 250)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 248, 255)),
				})
				CardGrad.Rotation = 135
				CardGrad.Parent = Card
			end

			-- Tag stripe left
			local CardStripe = Instance.new("Frame")
			CardStripe.Parent = Card
			CardStripe.BackgroundColor3 = tagCol
			CardStripe.BorderSizePixel = 0
			CardStripe.Position = UDim2.new(0, 0, 0, 10)
			CardStripe.Size = UDim2.new(0, 3, 0, 48)
			makeCorner(CardStripe, 4)

			local NameLabel = Instance.new("TextLabel")
			NameLabel.Parent = Card
			NameLabel.BackgroundTransparency = 1
			NameLabel.Position = UDim2.new(0, 14, 0, 8)
			NameLabel.Size = UDim2.new(0.55, 0, 0, 20)
			NameLabel.Font = Enum.Font.GothamSemibold
			NameLabel.Text = (data.Favorited and "★ " or "") .. data.Name
			NameLabel.TextColor3 = isSel and C.accent or C.textMain
			NameLabel.TextSize = 12
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left

			-- Tag badge
			if data.Tag then
				local TagBadge = Instance.new("TextLabel")
				TagBadge.Parent = Card
				TagBadge.BackgroundColor3 = tagCol
				TagBadge.BackgroundTransparency = 0.65
				TagBadge.Position = UDim2.new(0, 14, 0, 30)
				TagBadge.Size = UDim2.new(0, 80, 0, 14)
				TagBadge.Font = Enum.Font.GothamSemibold
				TagBadge.Text = data.Tag
				TagBadge.TextColor3 = C.accentDark
				TagBadge.TextSize = 8
				makeCorner(TagBadge, 7)
				makePadding(TagBadge, 0, 0, 4, 4)
			end

			local PosLabel = Instance.new("TextLabel")
			PosLabel.Parent = Card
			PosLabel.BackgroundTransparency = 1
			PosLabel.Position = UDim2.new(0, 14, 0, 47)
			PosLabel.Size = UDim2.new(0.6, 0, 0, 14)
			PosLabel.Font = Enum.Font.Code
			PosLabel.Text = formatPos(data.CFrame)
			PosLabel.TextColor3 = C.textFaint
			PosLabel.TextSize = 9
			PosLabel.TextXAlignment = Enum.TextXAlignment.Left

			-- TP Count pill
			local TpPill = Instance.new("TextLabel")
			TpPill.Parent = Card
			TpPill.BackgroundColor3 = C.bgDeep
			TpPill.Position = UDim2.new(0.58, 0, 0, 8)
			TpPill.Size = UDim2.new(0, 48, 0, 14)
			TpPill.Font = Enum.Font.GothamSemibold
			TpPill.Text = "tp: " .. tostring(data.TpCount or 0)
			TpPill.TextColor3 = C.textSub
			TpPill.TextSize = 8
			makeCorner(TpPill, 7)

			local SelectBtn = Instance.new("TextButton")
			SelectBtn.Parent = Card
			SelectBtn.BackgroundTransparency = 1
			SelectBtn.Text = ""
			SelectBtn.Size = UDim2.new(1, 0, 1, 0)
			SelectBtn.ZIndex = 1

			local TpBtn = Instance.new("TextButton")
			TpBtn.Parent = Card
			TpBtn.BackgroundColor3 = isSel and C.accent or Color3.fromRGB(245, 210, 230)
			TpBtn.Text = "TELE"
			TpBtn.TextColor3 = isSel and C.white or C.accentDark
			TpBtn.Font = Enum.Font.GothamBold
			TpBtn.TextSize = 10
			TpBtn.Size = UDim2.new(0, 52, 0, 28)
			TpBtn.Position = UDim2.new(1, -128, 0.5, -14)
			TpBtn.ZIndex = 2
			makeCorner(TpBtn, 9)

			local FavBtn = Instance.new("TextButton")
			FavBtn.Parent = Card
			FavBtn.BackgroundColor3 = data.Favorited and Color3.fromRGB(255, 240, 180) or C.bgDeep
			FavBtn.Text = data.Favorited and "★" or "☆"
			FavBtn.TextColor3 = data.Favorited and Color3.fromRGB(200, 140, 0) or C.textFaint
			FavBtn.Font = Enum.Font.GothamBold
			FavBtn.TextSize = 16
			FavBtn.Size = UDim2.new(0, 30, 0, 28)
			FavBtn.Position = UDim2.new(1, -72, 0.5, -14)
			FavBtn.ZIndex = 2
			makeCorner(FavBtn, 9)

			local DelBtn = Instance.new("TextButton")
			DelBtn.Parent = Card
			DelBtn.BackgroundColor3 = (pendingDeleteId == data.Id) and C.delConfirm or C.delBg
			DelBtn.Text = (pendingDeleteId == data.Id) and "✓" or "✕"
			DelBtn.TextColor3 = C.red
			DelBtn.Font = Enum.Font.GothamBold
			DelBtn.TextSize = 12
			DelBtn.Size = UDim2.new(0, 30, 0, 28)
			DelBtn.Position = UDim2.new(1, -36, 0.5, -14)
			DelBtn.ZIndex = 2
			makeCorner(DelBtn, 9)

			SelectBtn.MouseButton1Click:Connect(function()
				ripple(Card, C.accentLight)
				selectedId = data.Id
				updateDetails(data)
				refreshScroll()
			end)

			TpBtn.MouseButton1Click:Connect(function()
				ripple(TpBtn, C.white)
				selectedId = data.Id
				updateDetails(data)

				local _, hrp = getCharacter()
				if not hrp then
					showToast("❌  Không tìm thấy nhân vật!", C.red, C.red)
					return
				end

				tween(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = data.CFrame})

				data.TpCount = (data.TpCount or 0) + 1
				totalTeleports = totalTeleports + 1
				updateDetails(data)
				updateStatPill()
				refreshScroll()
				showToast("🌸  Đã teleport: " .. data.Name, C.accent, C.accent)
			end)

			FavBtn.MouseButton1Click:Connect(function()
				ripple(FavBtn, C.gold)
				data.Favorited = not data.Favorited
				selectedId = data.Id
				updateDetails(data)
				refreshScroll()
				if data.Favorited then
					showToast("★  Đã ghim yêu thích: " .. data.Name, Color3.fromRGB(200, 140, 0), C.gold)
				else
					showToast("☆  Đã bỏ ghim: " .. data.Name, C.textSub, C.textFaint)
				end
			end)

			DelBtn.MouseButton1Click:Connect(function()
				ripple(DelBtn, C.red)
				if pendingDeleteId ~= data.Id then
					pendingDeleteId = data.Id
					showToast("⚠️  Bấm lại để xác nhận xóa: " .. data.Name, Color3.fromRGB(200, 100, 0), Color3.fromRGB(255, 180, 80))
					refreshScroll()

					task.delay(2.5, function()
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
				updateStatPill()
				refreshScroll()
				showToast("🗑️  Đã xóa: " .. data.Name, C.red, C.red)
			end)
		end
	end

	EmptyLabel.Visible = not anyVisible
	updateStatPill()
	updateDetails(getEntry(selectedId))
end

local function saveCurrentPosition()
	if saveDebounce then return end
	saveDebounce = true
	ripple(SaveButton, C.white)

	local _, hrp = getCharacter()
	if not hrp then
		showToast("❌  Lỗi: không tìm thấy nhân vật.", C.red, C.red)
		saveDebounce = false
		return
	end

	local name = (SearchBox.Text or ""):match("^%s*(.-)%s*$")
	if name == "" then
		name = "Vị trí " .. tostring(#savedPositions + 1)
	end

	for _, v in ipairs(savedPositions) do
		if v.Name == name then
			showToast("⚠️  Tên đã tồn tại: " .. name, Color3.fromRGB(200, 120, 0), C.gold)
			saveDebounce = false
			return
		end
	end

	local tag = TAGS[currentTagIndex]
	local entry = {
		Id        = makeGuid(),
		Name      = name,
		CFrame    = hrp.CFrame,
		Favorited = false,
		CreatedAt = os.time(),
		TpCount   = 0,
		Tag       = tag,
	}

	table.insert(savedPositions, entry)
	selectedId = entry.Id
	SearchBox.Text = ""

	updateStatPill()
	updateDetails(entry)
	refreshScroll()
	showToast("✦  Đã lưu: " .. name .. "  [" .. tag .. "]", C.accent, C.accent)

	-- Flash save button
	tween(SaveButton, TQ, {BackgroundColor3 = C.green})
	task.delay(0.4, function()
		tween(SaveButton, TQS, {BackgroundColor3 = C.accent})
	end)

	task.delay(0.25, function()
		saveDebounce = false
	end)
end

SaveButton.MouseButton1Click:Connect(saveCurrentPosition)

MinButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	ripple(MinButton, C.accent)

	if minimized then
		tween(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 460, 0, 63)
		})
		for _, v in ipairs({SearchBox, TagCycleBtn, SaveButton, TagRow, DetailsFrame, Scroll, ToastFrame, TbLine}) do
			v.Visible = false
		end
	else
		for _, v in ipairs({SearchBox, TagCycleBtn, SaveButton, TagRow, DetailsFrame, Scroll, ToastFrame, TbLine}) do
			v.Visible = true
		end
		tween(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 460, 0, 580)
		})
	end
end)

CloseButton.MouseButton1Click:Connect(function()
	ripple(CloseButton, C.red)
	tween(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 460, 0, 0),
		BackgroundTransparency = 1
	})
	task.delay(0.22, function()
		ScreenGui:Destroy()
	end)
end)

-- ==================== DRAG ====================
local dragging = false
local dragStart, startPos

Topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- ==================== HOVER EFFECTS ====================
local function addHover(btn, normalColor, hoverColor)
	btn.MouseEnter:Connect(function()
		tween(btn, TQ, {BackgroundColor3 = hoverColor})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, TQ, {BackgroundColor3 = normalColor})
	end)
end

addHover(MinButton,   C.pink2,   C.accentLight)
addHover(CloseButton, Color3.fromRGB(255, 225, 232), Color3.fromRGB(255, 190, 210))

-- ==================== GLOW ANIMATION ====================
tween(TopAccentBar, TSine, {BackgroundColor3 = Color3.fromRGB(200, 80, 180)})

-- ==================== OPEN ANIMATION ====================
MainFrame.Size = UDim2.new(0, 440, 0, 560)
MainFrame.BackgroundTransparency = 0.1
tween(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 460, 0, 580),
	BackgroundTransparency = 0
})

-- ==================== INIT ====================
buildTagRow()
updateStatPill()
updateDetails(nil)
refreshScroll()

print("✦ Zenonix Save & Teleport V6 — Sakura Edition loaded! ✦")

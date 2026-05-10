-- ====================================================================
-- ZENONIX SAVE & TELEPORT V6 — SAKURA EDITION (CLEAN REWRITE)
-- Theme: Hồng phấn & Trắng ngà
-- ====================================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer

-- ==================== STATE ====================
local savedPositions  = {}
local selectedId      = nil
local pendingDeleteId = nil
local saveDebounce    = false
local minimized       = false
local totalTeleports  = 0
local currentTagIndex = 1
local selectedTagFilter = nil

local TAGS = {"🌸 Home", "⚔️ Combat", "🏆 Farm", "🗺️ Explore", "⭐ Special"}
local TAG_COLORS = {
	["🌸 Home"]    = Color3.fromRGB(255, 160, 200),
	["⚔️ Combat"]  = Color3.fromRGB(255, 110, 130),
	["🏆 Farm"]    = Color3.fromRGB(255, 200, 80),
	["🗺️ Explore"] = Color3.fromRGB(100, 210, 255),
	["⭐ Special"] = Color3.fromRGB(200, 160, 255),
}

-- ==================== COLORS ====================
local C = {
	bg          = Color3.fromRGB(252, 245, 250),
	topbar      = Color3.fromRGB(255, 240, 248),
	bgDeep      = Color3.fromRGB(248, 238, 246),
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
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = p
	return c
end

local function makeStroke(p, color, thick, transp)
	local s = Instance.new("UIStroke")
	s.Color = color or C.stroke
	s.Thickness = thick or 1.5
	s.Transparency = transp or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function makePadding(p, top, bot, left, right)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, top   or 0)
	pad.PaddingBottom = UDim.new(0, bot   or 0)
	pad.PaddingLeft   = UDim.new(0, left  or 0)
	pad.PaddingRight  = UDim.new(0, right or 0)
	pad.Parent = p
	return pad
end

local function tw(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local TQ   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TQS  = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TBk  = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TSin = TweenInfo.new(2,    Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local function round(n) return math.floor(n * 10 + 0.5) / 10 end

local function formatPos(cf)
	local p = cf.Position
	return string.format("X:%.1f  Y:%.1f  Z:%.1f", round(p.X), round(p.Y), round(p.Z))
end

local function fmtTime(t)
	return os.date("%H:%M — %d/%m/%Y", t or os.time())
end

local function getHRP()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart", 5)
end

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
	tw(r, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(2, 0, 4, 0),
		BackgroundTransparency = 1,
	})
	task.delay(0.37, function() r:Destroy() end)
end

-- ==================== ROOT ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZenonixV6"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ==================== LOADING SCREEN ====================
local LoadBG = Instance.new("Frame")
LoadBG.Parent = ScreenGui
LoadBG.BackgroundColor3 = Color3.fromRGB(255, 242, 250)
LoadBG.Size = UDim2.new(1, 0, 1, 0)
LoadBG.BorderSizePixel = 0

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
LoadIcon.Size = UDim2.new(1, 0, 0, 30)
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
LoadSub.Text = "Đang khởi động..."
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
LoadDots.Position = UDim2.new(0.05, 0, 0, 122)
LoadDots.Size = UDim2.new(0.9, 0, 0, 28)
LoadDots.Font = Enum.Font.GothamBold
LoadDots.Text = "✦ ✦ ✦"
LoadDots.TextColor3 = C.accentLight
LoadDots.TextSize = 20

local dotConn
local dotTick = 0
dotConn = RunService.Heartbeat:Connect(function()
	dotTick += 1
	local patterns = {"✦ · ·", "· ✦ ·", "· · ✦", "✦ ✦ ✦"}
	if dotTick % 18 == 0 then
		LoadDots.Text = patterns[math.ceil(dotTick / 18) % #patterns + 1]
	end
end)

local loadMsgs = {
	"Đang tải giao diện hoa anh đào...",
	"Chuẩn bị danh sách vị trí...",
	"Tối ưu animation...",
	"Sẵn sàng! 🌸",
}
for i = 1, 40 do
	local a = i / 40
	PFill.Size = UDim2.new(a, 0, 1, 0)
	PPct.Text = tostring(math.floor(a * 100)) .. "%"
	local mi = math.max(1, math.min(#loadMsgs, math.ceil(a * #loadMsgs)))
	LoadSub.Text = loadMsgs[mi]
	task.wait(0.05)
end

dotConn:Disconnect()

local fti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
tw(LoadCard,  fti, {BackgroundTransparency = 1})
tw(LoadIcon,  fti, {TextTransparency = 1})
tw(LoadSub,   fti, {TextTransparency = 1})
tw(PPct,      fti, {TextTransparency = 1})
tw(LoadDots,  fti, {TextTransparency = 1})
tw(PBG,       fti, {BackgroundTransparency = 1})
tw(PFill,     fti, {BackgroundTransparency = 1})
task.wait(0.25)
LoadBG:Destroy()

-- ==================== MAIN FRAME ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "ZenonixMain"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = C.bg
MainFrame.Position = UDim2.new(0.33, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 460, 0, 590)
MainFrame.BorderSizePixel = 0
makeCorner(MainFrame, 18)
makeStroke(MainFrame, C.accentLight, 2, 0)

local MFGrad = Instance.new("UIGradient")
MFGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 253)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(252, 238, 248)),
})
MFGrad.Rotation = 145
MFGrad.Parent = MainFrame

-- Top glow bar
local GlowBar = Instance.new("Frame")
GlowBar.Parent = MainFrame
GlowBar.BackgroundColor3 = C.accent
GlowBar.BorderSizePixel = 0
GlowBar.Size = UDim2.new(1, 0, 0, 3)
makeCorner(GlowBar, 18)

local GlowBarFix = Instance.new("Frame")
GlowBarFix.Parent = GlowBar
GlowBarFix.BackgroundColor3 = C.accent
GlowBarFix.BorderSizePixel = 0
GlowBarFix.Position = UDim2.new(0, 0, 0.5, 0)
GlowBarFix.Size = UDim2.new(1, 0, 0.5, 0)

local GBGrad = Instance.new("UIGradient")
GBGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accentLight),
	ColorSequenceKeypoint.new(0.5, C.accent),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 160)),
})
GBGrad.Parent = GlowBar

tw(GlowBar, TSin, {BackgroundColor3 = Color3.fromRGB(200, 80, 180)})

-- ==================== TOPBAR ====================
local Topbar = Instance.new("Frame")
Topbar.Parent = MainFrame
Topbar.BackgroundColor3 = C.topbar
Topbar.Size = UDim2.new(1, 0, 0, 58)
Topbar.Position = UDim2.new(0, 0, 0, 3)
Topbar.BorderSizePixel = 0

local TbFix = Instance.new("Frame")
TbFix.Parent = Topbar
TbFix.BackgroundColor3 = C.topbar
TbFix.BorderSizePixel = 0
TbFix.Position = UDim2.new(0, 0, 0.55, 0)
TbFix.Size = UDim2.new(1, 0, 0.5, 0)

local TbGrad = Instance.new("UIGradient")
TbGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 238, 248)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 248, 252)),
})
TbGrad.Rotation = 90
TbGrad.Parent = Topbar

local LogoIcon = Instance.new("TextLabel")
LogoIcon.Parent = Topbar
LogoIcon.BackgroundTransparency = 1
LogoIcon.Position = UDim2.new(0, 14, 0.5, -13)
LogoIcon.Size = UDim2.new(0, 26, 0, 26)
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Text = "🌸"
LogoIcon.TextSize = 22

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Parent = Topbar
TitleLbl.BackgroundTransparency = 1
TitleLbl.Position = UDim2.new(0, 48, 0, 7)
TitleLbl.Size = UDim2.new(0.65, 0, 0, 22)
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.Text = "ZENONIX  SAKURA"
TitleLbl.TextColor3 = C.accent
TitleLbl.TextSize = 14
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local TLGrad = Instance.new("UIGradient")
TLGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accent),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 180)),
})
TLGrad.Parent = TitleLbl

local SubLbl = Instance.new("TextLabel")
SubLbl.Parent = Topbar
SubLbl.BackgroundTransparency = 1
SubLbl.Position = UDim2.new(0, 48, 0, 31)
SubLbl.Size = UDim2.new(0.6, 0, 0, 14)
SubLbl.Font = Enum.Font.Gotham
SubLbl.Text = "Save & Teleport  V6"
SubLbl.TextColor3 = C.textFaint
SubLbl.TextSize = 9
SubLbl.TextXAlignment = Enum.TextXAlignment.Left

local StatPill = Instance.new("Frame")
StatPill.Parent = Topbar
StatPill.BackgroundColor3 = C.pink2
StatPill.Position = UDim2.new(0, 48, 0.5, 2)
StatPill.Size = UDim2.new(0, 128, 0, 16)
makeCorner(StatPill, 8)

local StatLbl = Instance.new("TextLabel")
StatLbl.Parent = StatPill
StatLbl.BackgroundTransparency = 1
StatLbl.Size = UDim2.new(1, 0, 1, 0)
StatLbl.Font = Enum.Font.GothamSemibold
StatLbl.Text = "0 lưu  •  0 teleport"
StatLbl.TextColor3 = C.accentDark
StatLbl.TextSize = 9

local MinBtn = Instance.new("TextButton")
MinBtn.Parent = Topbar
MinBtn.BackgroundColor3 = C.pink2
MinBtn.Text = "—"
MinBtn.TextColor3 = C.accent
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.Size = UDim2.new(0, 30, 0, 26)
MinBtn.Position = UDim2.new(1, -70, 0.5, -13)
makeCorner(MinBtn, 8)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Topbar
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 225, 232)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.red
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Size = UDim2.new(0, 30, 0, 26)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -13)
makeCorner(CloseBtn, 8)

-- Separator
local TbLine = Instance.new("Frame")
TbLine.Parent = MainFrame
TbLine.BackgroundColor3 = C.stroke
TbLine.BorderSizePixel = 0
TbLine.Position = UDim2.new(0.04, 0, 0, 61)
TbLine.Size = UDim2.new(0.92, 0, 0, 1)

-- ==================== TAG FILTER ROW ====================
local TagScroll = Instance.new("ScrollingFrame")
TagScroll.Parent = MainFrame
TagScroll.BackgroundTransparency = 1
TagScroll.BorderSizePixel = 0
TagScroll.Position = UDim2.new(0.04, 0, 0, 70)
TagScroll.Size = UDim2.new(0.92, 0, 0, 28)
TagScroll.ScrollBarThickness = 0
TagScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local TagRowList = Instance.new("UIListLayout")
TagRowList.Parent = TagScroll
TagRowList.FillDirection = Enum.FillDirection.Horizontal
TagRowList.Padding = UDim.new(0, 6)
TagRowList.SortOrder = Enum.SortOrder.LayoutOrder
TagRowList.VerticalAlignment = Enum.VerticalAlignment.Center

-- ==================== SEARCH + SAVE ====================
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
SearchBox.Size = UDim2.new(0.54, 0, 0, 36)
SearchBox.Position = UDim2.new(0.04, 0, 0, 106)
SearchBox.BorderSizePixel = 0
makeCorner(SearchBox, 10)
makeStroke(SearchBox, C.stroke, 1.5, 0)
makePadding(SearchBox, 0, 0, 10, 0)

local TagCycleBtn = Instance.new("TextButton")
TagCycleBtn.Parent = MainFrame
TagCycleBtn.BackgroundColor3 = C.pink2
TagCycleBtn.Font = Enum.Font.GothamSemibold
TagCycleBtn.TextSize = 9
TagCycleBtn.Text = TAGS[currentTagIndex]
TagCycleBtn.TextColor3 = C.accentDark
TagCycleBtn.Size = UDim2.new(0, 80, 0, 36)
TagCycleBtn.Position = UDim2.new(0.04 + 0.54 + 0.02, 0, 0, 106)
TagCycleBtn.BorderSizePixel = 0
makeCorner(TagCycleBtn, 10)
makeStroke(TagCycleBtn, C.accentLight, 1, 0)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = C.accent
SaveBtn.Text = "✦ LƯU"
SaveBtn.TextColor3 = C.white
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 11
SaveBtn.Size = UDim2.new(0.19, 0, 0, 36)
SaveBtn.Position = UDim2.new(0.77, 0, 0, 106)
SaveBtn.BorderSizePixel = 0
makeCorner(SaveBtn, 10)

local SaveGrad = Instance.new("UIGradient")
SaveGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.accentLight),
	ColorSequenceKeypoint.new(1, C.accentDark),
})
SaveGrad.Rotation = 90
SaveGrad.Parent = SaveBtn

-- ==================== DETAILS PANEL ====================
local DetFrame = Instance.new("Frame")
DetFrame.Parent = MainFrame
DetFrame.BackgroundColor3 = C.white
DetFrame.Position = UDim2.new(0.04, 0, 0, 152)
DetFrame.Size = UDim2.new(0.92, 0, 0, 100)
DetFrame.BorderSizePixel = 0
makeCorner(DetFrame, 12)
makeStroke(DetFrame, C.stroke, 1.5, 0)

local DfGrad = Instance.new("UIGradient")
DfGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 253)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})
DfGrad.Rotation = 135
DfGrad.Parent = DetFrame

local DStripe = Instance.new("Frame")
DStripe.Parent = DetFrame
DStripe.BackgroundColor3 = C.accent
DStripe.BorderSizePixel = 0
DStripe.Position = UDim2.new(0, 0, 0, 10)
DStripe.Size = UDim2.new(0, 3, 0, 80)
makeCorner(DStripe, 4)

local DetTitle = Instance.new("TextLabel")
DetTitle.Parent = DetFrame
DetTitle.BackgroundTransparency = 1
DetTitle.Position = UDim2.new(0, 16, 0, 7)
DetTitle.Size = UDim2.new(0.5, 0, 0, 16)
DetTitle.Font = Enum.Font.GothamBold
DetTitle.Text = "CHI TIẾT VỊ TRÍ"
DetTitle.TextColor3 = C.accent
DetTitle.TextSize = 10
DetTitle.TextXAlignment = Enum.TextXAlignment.Left

local DetTagBadge = Instance.new("TextLabel")
DetTagBadge.Parent = DetFrame
DetTagBadge.BackgroundColor3 = C.pink2
DetTagBadge.BackgroundTransparency = 1
DetTagBadge.Position = UDim2.new(1, -118, 0, 8)
DetTagBadge.Size = UDim2.new(0, 110, 0, 16)
DetTagBadge.Font = Enum.Font.GothamSemibold
DetTagBadge.Text = ""
DetTagBadge.TextColor3 = C.accentDark
DetTagBadge.TextSize = 9
makeCorner(DetTagBadge, 8)
makePadding(DetTagBadge, 0, 0, 6, 6)

local DetName = Instance.new("TextLabel")
DetName.Parent = DetFrame
DetName.BackgroundTransparency = 1
DetName.Position = UDim2.new(0, 16, 0, 27)
DetName.Size = UDim2.new(0.9, 0, 0, 20)
DetName.Font = Enum.Font.GothamSemibold
DetName.Text = "Chưa chọn vị trí nào."
DetName.TextColor3 = C.textMain
DetName.TextSize = 12
DetName.TextXAlignment = Enum.TextXAlignment.Left

local DetPos = Instance.new("TextLabel")
DetPos.Parent = DetFrame
DetPos.BackgroundTransparency = 1
DetPos.Position = UDim2.new(0, 16, 0, 50)
DetPos.Size = UDim2.new(0.9, 0, 0, 15)
DetPos.Font = Enum.Font.Code
DetPos.Text = "X: —   Y: —   Z: —"
DetPos.TextColor3 = C.textSub
DetPos.TextSize = 10
DetPos.TextXAlignment = Enum.TextXAlignment.Left

local DetMeta = Instance.new("TextLabel")
DetMeta.Parent = DetFrame
DetMeta.BackgroundTransparency = 1
DetMeta.Position = UDim2.new(0, 16, 0, 68)
DetMeta.Size = UDim2.new(0.9, 0, 0, 14)
DetMeta.Font = Enum.Font.Gotham
DetMeta.Text = "Yêu thích: Không  •  Teleport: 0 lần"
DetMeta.TextColor3 = C.textFaint
DetMeta.TextSize = 9
DetMeta.TextXAlignment = Enum.TextXAlignment.Left

local DetMeta2 = Instance.new("TextLabel")
DetMeta2.Parent = DetFrame
DetMeta2.BackgroundTransparency = 1
DetMeta2.Position = UDim2.new(0, 16, 0, 82)
DetMeta2.Size = UDim2.new(0.9, 0, 0, 14)
DetMeta2.Font = Enum.Font.Gotham
DetMeta2.Text = ""
DetMeta2.TextColor3 = C.textFaint
DetMeta2.TextSize = 9
DetMeta2.TextXAlignment = Enum.TextXAlignment.Left

-- ==================== SCROLL ====================
local Scroll = Instance.new("ScrollingFrame")
Scroll.Parent = MainFrame
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.Position = UDim2.new(0.04, 0, 0, 262)
Scroll.Size = UDim2.new(0.92, 0, 0, 284)
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

local EmptyLbl = Instance.new("TextLabel")
EmptyLbl.Parent = Scroll
EmptyLbl.BackgroundTransparency = 1
EmptyLbl.Size = UDim2.new(1, 0, 0, 60)
EmptyLbl.Font = Enum.Font.GothamSemibold
EmptyLbl.Text = "🌸  Chưa có vị trí nào được lưu."
EmptyLbl.TextColor3 = C.textFaint
EmptyLbl.TextSize = 12
EmptyLbl.Visible = true

-- ==================== TOAST ====================
local ToastFrame = Instance.new("Frame")
ToastFrame.Parent = MainFrame
ToastFrame.BackgroundColor3 = C.white
ToastFrame.BorderSizePixel = 0
ToastFrame.Position = UDim2.new(0.04, 0, 0, 556)
ToastFrame.Size = UDim2.new(0.92, 0, 0, 26)
ToastFrame.BackgroundTransparency = 0.05
makeCorner(ToastFrame, 8)
makeStroke(ToastFrame, C.stroke, 1, 0.4)

local ToastDot = Instance.new("Frame")
ToastDot.Parent = ToastFrame
ToastDot.BackgroundColor3 = C.accent
ToastDot.BorderSizePixel = 0
ToastDot.Position = UDim2.new(0, 10, 0.5, -4)
ToastDot.Size = UDim2.new(0, 8, 0, 8)
makeCorner(ToastDot, 4)

local ToastLbl = Instance.new("TextLabel")
ToastLbl.Parent = ToastFrame
ToastLbl.BackgroundTransparency = 1
ToastLbl.Position = UDim2.new(0, 26, 0, 0)
ToastLbl.Size = UDim2.new(0.88, 0, 1, 0)
ToastLbl.Font = Enum.Font.GothamSemibold
ToastLbl.Text = "Sẵn sàng 🌸"
ToastLbl.TextColor3 = C.textSub
ToastLbl.TextSize = 10
ToastLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ==================== LOGIC FUNCTIONS ====================

local toastThread
local function showToast(msg, color, dotColor)
	if toastThread then task.cancel(toastThread) end
	ToastLbl.Text = msg
	ToastLbl.TextColor3 = color or C.textSub
	ToastDot.BackgroundColor3 = dotColor or C.accent
	toastThread = task.delay(3, function()
		ToastLbl.Text = "Sẵn sàng 🌸"
		ToastLbl.TextColor3 = C.textSub
		ToastDot.BackgroundColor3 = C.accent
	end)
end

local function updateStat()
	StatLbl.Text = tostring(#savedPositions) .. " lưu  •  " .. tostring(totalTeleports) .. " tp"
end

local function getEntry(id)
	for _, v in ipairs(savedPositions) do
		if v.Id == id then return v end
	end
	return nil
end

local function updateDetails(entry)
	if not entry then
		DetName.Text = "Chưa chọn vị trí nào."
		DetPos.Text  = "X: —   Y: —   Z: —"
		DetMeta.Text = "Yêu thích: Không  •  Teleport: 0 lần"
		DetMeta2.Text = ""
		DetTagBadge.Text = ""
		DetTagBadge.BackgroundTransparency = 1
		DStripe.BackgroundColor3 = C.accentLight
		return
	end
	DetName.Text = (entry.Favorited and "★  " or "") .. entry.Name
	DetPos.Text  = formatPos(entry.CFrame)
	DetMeta.Text = "Yêu thích: " .. (entry.Favorited and "Có ★" or "Không") ..
	               "  •  Teleport: " .. tostring(entry.TpCount or 0) .. " lần"
	DetMeta2.Text = "Lưu lúc: " .. fmtTime(entry.CreatedAt)
	DetTagBadge.Text = entry.Tag or ""
	DetTagBadge.BackgroundTransparency = entry.Tag and 0 or 1

	local tc = entry.Tag and TAG_COLORS[entry.Tag]
	DStripe.BackgroundColor3 = tc or C.accent
	if tc then DetTagBadge.BackgroundColor3 = tc end
end

local function passesFilter(entry)
	local q = string.lower(SearchBox.Text or "")
	local nameOk = q == "" or string.find(string.lower(entry.Name or ""), q, 1, true)
	local tagOk  = selectedTagFilter == nil or entry.Tag == selectedTagFilter
	return nameOk and tagOk
end

local function sortEntries()
	table.sort(savedPositions, function(a, b)
		if a.Favorited ~= b.Favorited then return a.Favorited end
		return (a.CreatedAt or 0) > (b.CreatedAt or 0)
	end)
end

-- refreshScroll declared before buildTagRow so buildTagRow can call it
local refreshScroll

refreshScroll = function()
	sortEntries()

	for _, ch in ipairs(Scroll:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
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
				local cg = Instance.new("UIGradient")
				cg.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 250)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 248, 255)),
				})
				cg.Rotation = 135
				cg.Parent = Card
			end

			local Stripe = Instance.new("Frame")
			Stripe.Parent = Card
			Stripe.BackgroundColor3 = tagCol
			Stripe.BorderSizePixel = 0
			Stripe.Position = UDim2.new(0, 0, 0, 10)
			Stripe.Size = UDim2.new(0, 3, 0, 48)
			makeCorner(Stripe, 4)

			local NameLbl = Instance.new("TextLabel")
			NameLbl.Parent = Card
			NameLbl.BackgroundTransparency = 1
			NameLbl.Position = UDim2.new(0, 14, 0, 7)
			NameLbl.Size = UDim2.new(0.55, 0, 0, 20)
			NameLbl.Font = Enum.Font.GothamSemibold
			NameLbl.Text = (data.Favorited and "★ " or "") .. data.Name
			NameLbl.TextColor3 = isSel and C.accent or C.textMain
			NameLbl.TextSize = 12
			NameLbl.TextXAlignment = Enum.TextXAlignment.Left

			if data.Tag then
				local tb = Instance.new("TextLabel")
				tb.Parent = Card
				tb.BackgroundColor3 = tagCol
				tb.BackgroundTransparency = 0.65
				tb.Position = UDim2.new(0, 14, 0, 29)
				tb.Size = UDim2.new(0, 80, 0, 14)
				tb.Font = Enum.Font.GothamSemibold
				tb.Text = data.Tag
				tb.TextColor3 = C.accentDark
				tb.TextSize = 8
				makeCorner(tb, 7)
				makePadding(tb, 0, 0, 4, 4)
			end

			local PosLbl = Instance.new("TextLabel")
			PosLbl.Parent = Card
			PosLbl.BackgroundTransparency = 1
			PosLbl.Position = UDim2.new(0, 14, 0, 47)
			PosLbl.Size = UDim2.new(0.58, 0, 0, 14)
			PosLbl.Font = Enum.Font.Code
			PosLbl.Text = formatPos(data.CFrame)
			PosLbl.TextColor3 = C.textFaint
			PosLbl.TextSize = 9
			PosLbl.TextXAlignment = Enum.TextXAlignment.Left

			local TpPill = Instance.new("TextLabel")
			TpPill.Parent = Card
			TpPill.BackgroundColor3 = C.bgDeep
			TpPill.Position = UDim2.new(0.58, 0, 0, 7)
			TpPill.Size = UDim2.new(0, 48, 0, 14)
			TpPill.Font = Enum.Font.GothamSemibold
			TpPill.Text = "tp: " .. tostring(data.TpCount or 0)
			TpPill.TextColor3 = C.textSub
			TpPill.TextSize = 8
			makeCorner(TpPill, 7)

			-- invisible select button
			local SelBtn = Instance.new("TextButton")
			SelBtn.Parent = Card
			SelBtn.BackgroundTransparency = 1
			SelBtn.Text = ""
			SelBtn.Size = UDim2.new(1, 0, 1, 0)
			SelBtn.ZIndex = 1

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

			-- Events
			SelBtn.MouseButton1Click:Connect(function()
				ripple(Card, C.accentLight)
				selectedId = data.Id
				updateDetails(data)
				refreshScroll()
			end)

			TpBtn.MouseButton1Click:Connect(function()
				ripple(TpBtn, C.white)
				selectedId = data.Id
				local hrp = getHRP()
				if not hrp then
					showToast("❌  Không tìm thấy nhân vật!", C.red, C.red)
					return
				end
				tw(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = data.CFrame})
				data.TpCount = (data.TpCount or 0) + 1
				totalTeleports = totalTeleports + 1
				updateDetails(data)
				updateStat()
				refreshScroll()
				showToast("🌸  Đã teleport: " .. data.Name, C.accent, C.accent)
			end)

			FavBtn.MouseButton1Click:Connect(function()
				ripple(FavBtn, C.gold)
				data.Favorited = not data.Favorited
				selectedId = data.Id
				updateDetails(data)
				refreshScroll()
				showToast(
					data.Favorited and "★  Đã ghim: " .. data.Name or "☆  Đã bỏ ghim: " .. data.Name,
					data.Favorited and Color3.fromRGB(200, 140, 0) or C.textSub,
					data.Favorited and C.gold or C.textFaint
				)
			end)

			DelBtn.MouseButton1Click:Connect(function()
				ripple(DelBtn, C.red)
				if pendingDeleteId ~= data.Id then
					pendingDeleteId = data.Id
					showToast("⚠️  Bấm lại để xác nhận xóa: " .. data.Name, Color3.fromRGB(200, 100, 0), C.gold)
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
				updateStat()
				refreshScroll()
				showToast("🗑️  Đã xóa: " .. data.Name, C.red, C.red)
			end)
		end
	end

	EmptyLbl.Visible = not anyVisible
	updateStat()
	updateDetails(getEntry(selectedId))
end

-- ==================== BUILD TAG ROW ====================
local function buildTagRow()
	for _, ch in ipairs(TagScroll:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end

	local allBtn = Instance.new("TextButton")
	allBtn.Parent = TagScroll
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
		btn.Parent = TagScroll
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
		end)
	end

	TagScroll.CanvasSize = UDim2.new(0, TagRowList.AbsoluteContentSize.X + 10, 0, 0)
	task.defer(refreshScroll)
end

-- ==================== SAVE LOGIC ====================
local function saveCurrentPosition()
	if saveDebounce then return end
	saveDebounce = true
	ripple(SaveBtn, C.white)

	local hrp = getHRP()
	if not hrp then
		showToast("❌  Không tìm thấy nhân vật.", C.red, C.red)
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
		Id        = HttpService:GenerateGUID(false),
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

	updateStat()
	updateDetails(entry)
	refreshScroll()
	showToast("✦  Đã lưu: " .. name .. "  [" .. tag .. "]", C.accent, C.accent)

	tw(SaveBtn, TQ, {BackgroundColor3 = C.green})
	task.delay(0.45, function()
		tw(SaveBtn, TQS, {BackgroundColor3 = C.accent})
	end)

	task.delay(0.25, function() saveDebounce = false end)
end

-- ==================== BUTTON EVENTS ====================
SaveBtn.MouseButton1Click:Connect(saveCurrentPosition)

TagCycleBtn.MouseButton1Click:Connect(function()
	ripple(TagCycleBtn, C.white)
	currentTagIndex = currentTagIndex % #TAGS + 1
	TagCycleBtn.Text = TAGS[currentTagIndex]
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(refreshScroll)

MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	ripple(MinBtn, C.accent)
	local elems = {SearchBox, TagCycleBtn, SaveBtn, TagScroll, DetFrame, Scroll, ToastFrame, TbLine}
	if minimized then
		tw(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 460, 0, 61)})
		for _, v in ipairs(elems) do v.Visible = false end
	else
		for _, v in ipairs(elems) do v.Visible = true end
		tw(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 460, 0, 590)})
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	ripple(CloseBtn, C.red)
	tw(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 460, 0, 0),
		BackgroundTransparency = 1,
	})
	task.delay(0.24, function() ScreenGui:Destroy() end)
end)

-- Hover effects
MinBtn.MouseEnter:Connect(function() tw(MinBtn, TQ, {BackgroundColor3 = C.accentLight}) end)
MinBtn.MouseLeave:Connect(function() tw(MinBtn, TQ, {BackgroundColor3 = C.pink2}) end)
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, TQ, {BackgroundColor3 = Color3.fromRGB(255, 190, 210)}) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, TQ, {BackgroundColor3 = Color3.fromRGB(255, 225, 232)}) end)

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

-- ==================== OPEN ANIMATION ====================
MainFrame.Size = UDim2.new(0, 440, 0, 570)
MainFrame.BackgroundTransparency = 0.12
tw(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 460, 0, 590),
	BackgroundTransparency = 0,
})

-- ==================== INIT ====================
buildTagRow()
updateStat()
updateDetails(nil)
refreshScroll()

print("✦ Zenonix V6 Sakura — loaded successfully!")

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║      ⌬  ZENONIX REBORN V3.0 // SUPERIOR OMNIVERSE COMPLETION EDITION      ║
    ║      >> PHÁT TRIỂN BỞI: MINH MEO OMNIVERSE ETERNAL                        ║
    ║      >> PHONG CÁCH V3: SIÊU NHẸ, KHÔNG XÁC NHẬN, XOÁ LAG, COMBAT BÁ ĐẠO   ║
    ║      >> TỐI ƯU HÓA: 100% TIẾNG VIỆT, SỬA TOÀN BỘ LỖI GIẬT KHỰNG CAMERA     ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]--

-- ==================== [ HỆ THỐNG QUẢN LÝ DỊCH VỤ ROBLOX CORE ] ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")

-- Đảm bảo Camera luôn được đồng bộ chính xác khi người chơi hồi sinh
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

-- ==================== [ BẢNG CẤU HÌNH TỔNG HOÀN CHỈNH V3 ] ====================
local Settings = {
    -- CẤU HÌNH SIÊU AIMLOCK V3 (ĐÃ NÂNG CẤP THUẬT TOÁN)
    Aimlock_KichHoat = true,
    Aimlock_CheDoQuet = "Tâm Màn Hình", -- "Tâm Màn Hình" hoặc "Gần Nhất"
    Aimlock_ViTriKhoa = "Quét Thông Minh V3", -- "Quét Thông Minh V3", "Head", "HumanoidRootPart"
    Aimlock_DuDoanQuyDao = "Ma Trận V3", -- "Tắt", "Tuyến Tính", "Ma Trận V3", "Bù Ping"
    Aimlock_HeSoDuDoan = 0.135,
    Aimlock_LamMuotGoc = "Nội Suy Siêu Mượt", -- "Tuyến Tính", "Nội Suy Siêu Mượt", "Exponential"
    Aimlock_DoMuot = 0.042, -- Chỉ số càng thấp ngắm càng dính chặt
    Aimlock_GiuMucTieu = true, -- Sticky Lock: Giữ chặt mục tiêu cũ cho đến khi khuất/chết
    Aimlock_CoGianFOV = true, -- Tự co giãn vòng FOV theo khoảng cách thực tế
    
    -- BỘ LỌC ĐIỀU KIỆN (CHỐNG KHÓA NHẦM)
    Loc_DongDoi = false,
    Loc_TuongChan = true,
    Loc_ConSong = true,
    Loc_BiGuc = true,

    -- PHẠM VI QUÉT FOV (DRAWING API)
    FOV_HienThi = true,
    FOV_Rgb = true,
    FOV_BanKinh = 150,
    FOV_DoDay = 2,
    FOV_MauSac = Color3.fromRGB(0, 255, 128),
    FOV_TrongSuot = 0.8,
    
    -- TIỆN ÍCH CHIẾN ĐẤU & HITBOX V4.5/V3
    Combat_PhongHitbox = false,
    Combat_KichThuocHitbox = 12,
    Combat_BoPhanHitbox = "HumanoidRootPart",
    Combat_TrongSuotHitbox = 0.6,
    Combat_KillAura = false,
    Combat_PhamViAura = 20,
    Combat_TuDongChem = false,
    Combat_GiamDoGiutSung = false,
    
    -- HỆ THỐNG THẤU THỊ VISUAL ESP V3
    ESP_KichHoat = false,
    ESP_KhungHinh = false,
    ESP_DuongChi = false,
    ESP_HienTen = false,
    ESP_HienKhoangCach = false,
    ESP_ThanhMau = false,
    ESP_MauKhung = Color3.fromRGB(255, 0, 128),
    ESP_MauChi = Color3.fromRGB(0, 255, 255),
    ESP_MauChu = Color3.fromRGB(255, 255, 255),
    
    -- MOD DI CHUYỂN NHÂN VẬT MECHANICAL
    Mod_TocDo = false,
    Mod_GiaTriTocDo = 85,
    Mod_NhayCao = false,
    Mod_GiaTriNhay = 75,
    Mod_NhayVoHan = false,
    Mod_DiXuyenTuong = false,
    Mod_XoayThan = false,
    Mod_TocDoXoay = 50,
    
    -- CẢI THIỆN MÔI TRƯỜNG & KHỬ LAG ĐỒ HỌA
    Map_SangToanBanDo = false,
    Map_EpBanDem = false,
    Map_KhuLagRam = false,
    Map_XoaVatLieu = false,
    
    -- HỆ THỐNG PHÍM BẤM ĐIỀU KHIỂN DỄ DÙNG
    Phim_Aimlock = Enum.KeyCode.Q,
    CheDo_DeGiu = false, -- false = Bấm 1 phát để Bật/Tắt / true = Đè giữ phím
    Phim_Menu = Enum.KeyCode.RightControl
}

-- Biến Quản Lý Trạng Thái Toàn Cục
local LinhHonAimlockActive = false
local MucTieuHienTai_Player = nil
local MucTieuHienTai_Part = nil
local TanSoQuet_RGB = 0
local BoNho_ESP_Goc = {}

-- Khởi tạo các đối tượng đồ họa siêu tốc Drawing API
local VongTronFOV = Drawing.new("Circle")
VongTronFOV.Filled = false
local DuongChiLaserV3 = Drawing.new("Line")
DuongChiLaserV3.Visible = false

-- Hàm dọn dẹp bộ nhớ đồ họa ESP tránh rò rỉ RAM (Memory Leak)
local function GiaiPhongEspNguoiChoi(player)
    if BoNho_ESP_Goc[player] then
        pcall(function()
            if BoNho_ESP_Goc[player].Box then BoNho_ESP_Goc[player].Box:Remove() end
            if BoNho_ESP_Goc[player].Tracer then BoNho_ESP_Goc[player].Tracer:Remove() end
            if BoNho_ESP_Goc[player].Name then BoNho_ESP_Goc[player].Name:Remove() end
            if BoNho_ESP_Goc[player].Dist then BoNho_ESP_Goc[player].Dist:Remove() end
            if BoNho_ESP_Goc[player].HealthBar then BoNho_ESP_Goc[player].HealthBar:Remove() end
        end)
        BoNho_ESP_Goc[player] = nil
    end
end

Players.PlayerRemoving:Connect(GiaiPhongEspNguoiChoi)

-- ==================== [ THƯ VIỆN TOÁN HỌC & KIỂM TRA ĐIỀU KIỆN VẬT LÝ ] ====================
local LogicV3Core = {}

function LogicV3Core.KiemTraTuongChan(targetPart, character)
    if not Settings.Loc_TuongChan then return true end
    local cameraPos = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local huongQuet = targetPos - cameraPos
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local danhSachLoaiTru = {LocalPlayer.Character, Camera}
    if character then table.insert(danhSachLoaiTru, character) end
    params.FilterDescendantsInstances = danhSachLoaiTru
    
    local ketQuaRaycast = workspace:Raycast(cameraPos, huongQuet, params)
    return ketQuaRaycast == nil
end

function LogicV3Core.HopLeDeBan(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    if Settings.Loc_ConSong and hum.Health <= 0 then return false end
    if Settings.Loc_BiGuc then
        if char:FindFirstChild("KO") or char:FindFirstChild("Knocked") or char:FindFirstChild("Downed") or hum:GetState() == Enum.HumanoidStateType.Dead then
            return false
        end
    end
    return true
end

-- ==================== [ MÔ-ĐUN KÉO THẢ UI KHÔNG LAG TẦN SỐ ] ====================
local function DangKyKeoThaGiaoDien(guiInstance)
    local dangKeo, duLieuKeo, viTriBatDauInput, viTriBatDauFrame
    guiInstance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dangKeo = true
            viTriBatDauInput = input.Position
            viTriBatDauFrame = guiInstance.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dangKeo = false end
            end)
        end
    end)
    guiInstance.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            duLieuKeo = input
        end
    end)
    RunService.Heartbeat:Connect(function()
        if dangKeo and duLieuKeo then
            local doLech = duLieuKeo.Position - viTriBatDauInput
            guiInstance.Position = UDim2.new(viTriBatDauFrame.X.Scale, viTriBatDauFrame.X.Offset + doLech.X, viTriBatDauFrame.Y.Scale, viTriBatDauFrame.Y.Offset + doLech.Y)
        end
    end)
end

-- ==================== [ KHỞI TẠO FRAMEWORK UI V3 RETRO CYBER ] ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Zenonix_Superior_V3"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui") end)

-- Thông báo nổi một chạm không rườm rà
local function DayThongBaoHeThong(tieuDe, noiDung, mauChuDao)
    local oThongBao = Instance.new("Frame")
    oThongBao.Size = UDim2.new(0, 280, 0, 56)
    oThongBao.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
    oThongBao.BackgroundTransparency = 0.15
    oThongBao.Parent = ScreenGui

    local stroke = Instance.new("UIStroke", oThongBao)
    stroke.Color = mauChuDao or Color3.fromRGB(0, 255, 128)
    stroke.Thickness = 1.2
    Instance.new("UICorner", oThongBao).CornerRadius = UDim.new(0, 5)

    local chuThongBao = Instance.new("TextLabel", oThongBao)
    chuThongBao.Size = UDim2.new(1, -20, 1, 0)
    chuThongBao.Position = UDim2.new(0, 10, 0, 0)
    chuThongBao.Text = "<b>" .. tieuDe .. "</b>\n" .. noiDung
    chuThongBao.RichText = true
    chuThongBao.TextColor3 = Color3.fromRGB(255, 255, 255)
    chuThongBao.Font = Enum.Font.GothamMedium
    chuThongBao.TextSize = 11
    chuThongBao.BackgroundTransparency = 1
    chuThongBao.TextXAlignment = Enum.TextXAlignment.Left

    oThongBao.Position = UDim2.new(1.3, 0, 0.8, 0)
    TweenService:Create(oThongBao, TweenInfo.new(0.35, Enum.EasingStyle.BackOut), {Position = UDim2.new(1, -300, 0.8, 0)}):Play()
    
    task.delay(1.5, function()
        pcall(function()
            TweenService:Create(oThongBao, TweenInfo.new(0.25, Enum.EasingStyle.QuadIn), {Position = UDim2.new(1.3, 0, 0.8, 0)}):Play()
            task.wait(0.25)
            oThongBao:Destroy()
        end)
    end)
end

-- Khung Menu V3 Cổ Điển Mạnh Mẽ
local KhungChinhV3 = Instance.new("Frame")
KhungChinhV3.Size = UDim2.new(0, 580, 0, 370)
KhungChinhV3.Position = UDim2.new(0.5, -290, 0.5, -185)
KhungChinhV3.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
KhungChinhV3.Visible = false
KhungChinhV3.Parent = ScreenGui
Instance.new("UICorner", KhungChinhV3).CornerRadius = UDim.new(0, 6)
DangKyKeoThaGiaoDien(KhungChinhV3)

local VienKhungChinh = Instance.new("UIStroke", KhungChinhV3)
VienKhungChinh.Thickness = 1.5
local GradientMauVien = Instance.new("UIGradient", VienKhungChinh)
GradientMauVien.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 128)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 128))
}

local TieuDeGiaoDien = Instance.new("TextLabel", KhungChinhV3)
TieuDeGiaoDien.Text = "⌬ ZENONIX REBORN v3.0 // SUPERIOR CORE ENGINE"
TieuDeGiaoDien.Font = Enum.Font.GothamBlack
TieuDeGiaoDien.TextColor3 = Color3.fromRGB(255, 255, 255)
TieuDeGiaoDien.TextSize = 12.5
TieuDeGiaoDien.Position = UDim2.new(0, 16, 0, 12)
TieuDeGiaoDien.Size = UDim2.new(0, 400, 0, 22)
TieuDeGiaoDien.BackgroundTransparency = 1
TieuDeGiaoDien.TextXAlignment = Enum.TextXAlignment.Left

local NutDongGiaoDien = Instance.new("TextButton", KhungChinhV3)
NutDongGiaoDien.Size = UDim2.new(0, 22, 0, 22)
NutDongGiaoDien.Position = UDim2.new(1, -34, 0, 12)
NutDongGiaoDien.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
NutDongGiaoDien.Text = "✕"
NutDongGiaoDien.TextColor3 = Color3.fromRGB(255, 255, 255)
NutDongGiaoDien.Font = Enum.Font.GothamBold
NutDongGiaoDien.TextSize = 9
Instance.new("UICorner", NutDongGiaoDien).CornerRadius = UDim.new(0, 4)
NutDongGiaoDien.MouseButton1Click:Connect(function() ScreenGui:Destroy() VongTronFOV:Remove() DuongChiLaserV3:Remove() end)

local ThanhDanhMucTabs = Instance.new("Frame", KhungChinhV3)
ThanhDanhMucTabs.Size = UDim2.new(0, 140, 1, -55)
ThanhDanhMucTabs.Position = UDim2.new(0, 12, 0, 44)
ThanhDanhMucTabs.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Instance.new("UICorner", ThanhDanhMucTabs).CornerRadius = UDim.new(0, 5)

local BoChuaTrangNoidung = Instance.new("Frame", KhungChinhV3)
BoChuaTrangNoidung.Size = UDim2.new(1, -176, 1, -55)
BoChuaTrangNoidung.Position = UDim2.new(0, 164, 0, 44)
BoChuaTrangNoidung.BackgroundTransparency = 1

local TabNutDangKichHoat = nil
local DemSoLuongTab = 0

local function TaoTrangDanhMuc(tenTab, bieuTuong)
    local cuonTrang = Instance.new("ScrollingFrame", BoChuaTrangNoidung)
    cuonTrang.Size = UDim2.new(1, 0, 1, 0)
    cuonTrang.BackgroundTransparency = 1
    cuonTrang.Visible = (DemSoLuongTab == 0)
    cuonTrang.ScrollBarThickness = 1.5
    cuonTrang.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 128)
    cuonTrang.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local boBoTri = Instance.new("UIListLayout", cuonTrang)
    boBoTri.Padding = UDim.new(0, 6)
    boBoTri.HorizontalAlignment = Enum.HorizontalAlignment.Center
    boBoTri.SortOrder = Enum.SortOrder.LayoutOrder

    boBoTri:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cuonTrang.CanvasSize = UDim2.new(0, 0, 0, boBoTri.AbsoluteContentSize.Y + 12)
    end)

    local nutChuyenTab = Instance.new("TextButton", ThanhDanhMucTabs)
    nutChuyenTab.Size = UDim2.new(0.92, 0, 0, 34)
    nutChuyenTab.Position = UDim2.new(0.04, 0, 0, DemSoLuongTab * 38 + 6)
    nutChuyenTab.BackgroundColor3 = (DemSoLuongTab == 0) and Color3.fromRGB(24, 24, 34) or Color3.fromRGB(16, 16, 24)
    nutChuyenTab.Text = "  " .. bieuTuong .. "  " .. tenTab
    nutChuyenTab.TextColor3 = (DemSoLuongTab == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
    nutChuyenTab.Font = Enum.Font.GothamBold
    nutChuyenTab.TextSize = 10.5
    nutChuyenTab.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", nutChuyenTab).CornerRadius = UDim.new(0, 4)

    if DemSoLuongTab == 0 then TabNutDangKichHoat = nutChuyenTab end

    nutChuyenTab.MouseButton1Click:Connect(function()
        if TabNutDangKichHoat then
            TweenService:Create(TabNutDangKichHoat, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(16, 16, 24), TextColor3 = Color3.fromRGB(140, 140, 140)}):Play()
        end
        TabNutDangKichHoat = nutChuyenTab
        TweenService:Create(nutChuyenTab, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 24, 34), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        
        for _, v in pairs(BoChuaTrangNoidung:GetChildren()) do 
            if v:IsA("ScrollingFrame") then v.Visible = false end 
        end
        cuonTrang.Visible = true
    end)
    
    DemSoLuongTab = DemSoLuongTab + 1
    return cuonTrang
end

-- Khởi tạo 4 phân mục chính chuẩn V3
local TrangAimlock = TaoTrangDanhMuc("Lõi Ngắm V3", "🎯")
local TrangVisuals = TaoTrangDanhMuc("Thấu Thị ESP", "👁️")
local TrangMovement = TaoTrangDanhMuc("Di Chuyển", "⚡")
local TrangWorldMap = TaoTrangDanhMuc("Hệ Thống Lag", "⚙️")

-- ==================== [ THIẾT KẾ CÁC THÀNH PHẦN COMPONENT ĐIỀU KHIỂN ] ====================

local function TaoNutCongTac(tenHienThi, trangChua, keyCauHinh, mauKichHoat)
    local khungNut = Instance.new("TextButton", trangChua)
    khungNut.Size = UDim2.new(0.96, 0, 0, 36)
    khungNut.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    khungNut.Text = "     " .. tenHienThi
    khungNut.TextColor3 = Color3.fromRGB(220, 220, 220)
    khungNut.TextXAlignment = Enum.TextXAlignment.Left
    khungNut.Font = Enum.Font.GothamSemibold
    khungNut.TextSize = 10.5
    Instance.new("UICorner", khungNut).CornerRadius = UDim.new(0, 4)

    local chamDenLed = Instance.new("Frame", khungNut)
    chamDenLed.Size = UDim2.new(0, 10, 0, 10)
    chamDenLed.Position = UDim2.new(1, -22, 0.5, -5)
    chamDenLed.BackgroundColor3 = Settings[keyCauHinh] and mauKichHoat or Color3.fromRGB(40, 40, 50)
    Instance.new("UICorner", chamDenLed).CornerRadius = UDim.new(1, 0)

    khungNut.MouseButton1Click:Connect(function()
        Settings[keyCauHinh] = not Settings[keyCauHinh]
        TweenService:Create(chamDenLed, TweenInfo.new(0.12), {BackgroundColor3 = Settings[keyCauHinh] and mauKichHoat or Color3.fromRGB(40, 40, 50)}):Play()
        DayThongBaoHeThong("CẬP NHẬT V3", tenHienThi .. " -> " .. (Settings[keyCauHinh] and "ĐÃ BẬT" or "ĐÃ TẮT"), Settings[keyCauHinh] and mauKichHoat or Color3.fromRGB(255, 50, 50))
    end)
end

local function TaoThanhTruot(tenHienThi, trangChua, min, max, keyCauHinh, macDinh, donVi)
    Settings[keyCauHinh] = macDinh
    donVi = donVi or ""
    
    local oTruot = Instance.new("Frame", trangChua)
    oTruot.Size = UDim2.new(0.96, 0, 0, 46)
    oTruot.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    Instance.new("UICorner", oTruot).CornerRadius = UDim.new(0, 4)

    local nhanGiaTri = Instance.new("TextLabel", oTruot)
    nhanGiaTri.Size = UDim2.new(0.8, 0, 0, 20)
    nhanGiaTri.Position = UDim2.new(0, 12, 0, 4)
    nhanGiaTri.Text = tenHienThi .. ": " .. tostring(macDinh) .. donVi
    nhanGiaTri.Font = Enum.Font.GothamSemibold
    nhanGiaTri.TextSize = 10.5
    nhanGiaTri.TextColor3 = Color3.fromRGB(180, 180, 180)
    nhanGiaTri.BackgroundTransparency = 1
    nhanGiaTri.TextXAlignment = Enum.TextXAlignment.Left

    local ranhTruot = Instance.new("TextButton", oTruot)
    ranhTruot.Size = UDim2.new(0.94, 0, 0, 4)
    ranhTruot.Position = UDim2.new(0.03, 0, 1, -10)
    ranhTruot.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    ranhTruot.Text = ""
    Instance.new("UICorner", ranhTruot)

    local vungLapDay = Instance.new("Frame", ranhTruot)
    vungLapDay.Size = UDim2.new((macDinh - min) / (max - min), 0, 1, 0)
    vungLapDay.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
    Instance.new("UICorner", vungLapDay)

    local function CapNhatLogicTruot(input)
        local tiLe = math.clamp((input.Position.X - ranhTruot.AbsolutePosition.X) / ranhTruot.AbsoluteSize.X, 0, 1)
        local giaTriTinhToan = min + (max - min) * tiLe
        if max <= 2 then
            giaTriTinhToan = math.round(giaTriTinhToan * 1000) / 1000
        else
            giaTriTinhToan = math.floor(giaTriTinhToan)
        end
        Settings[keyCauHinh] = giaTriTinhToan
        nhanGiaTri.Text = tenHienThi .. ": " .. tostring(giaTriTinhToan) .. donVi
        vungLapDay.Size = UDim2.new(tiLe, 0, 1, 0)
    end

    local dangReChuot = false
    ranhTruot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dangReChuot = true; CapNhatLogicTruot(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dangReChuot and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            CapNhatLogicTruot(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dangReChuot = false
        end
    end)
end

local function TaoMenuLuaChon(tenHienThi, trangChua, danhSachOpt, keyCauHinh)
    local oMenu = Instance.new("Frame", trangChua)
    oMenu.Size = UDim2.new(0.96, 0, 0, 36)
    oMenu.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    Instance.new("UICorner", oMenu).CornerRadius = UDim.new(0, 4)
    oMenu.ClipsDescendants = true

    local nutBamMo = Instance.new("TextButton", oMenu)
    nutBamMo.Size = UDim2.new(1, 0, 0, 36)
    nutBamMo.BackgroundTransparency = 1
    nutBamMo.Text = "     " .. tenHienThi .. ": " .. tostring(Settings[keyCauHinh])
    nutBamMo.TextColor3 = Color3.fromRGB(0, 170, 255)
    nutBamMo.Font = Enum.Font.GothamBold
    nutBamMo.TextSize = 10.5
    nutBamMo.TextXAlignment = Enum.TextXAlignment.Left

    local moRong = false
    nutBamMo.MouseButton1Click:Connect(function()
        moRong = not moRong
        TweenService:Create(oMenu, TweenInfo.new(0.16), {Size = moRong and UDim2.new(0.96, 0, 0, 36 + (#danhSachOpt * 25)) or UDim2.new(0.96, 0, 0, 36)}):Play()
    end)

    for i, luaChon in ipairs(danhSachOpt) do
        local nutNho = Instance.new("TextButton", oMenu)
        nutNho.Size = UDim2.new(0.94, 0, 0, 22)
        nutNho.Position = UDim2.new(0.03, 0, 0, 36 + (i - 1) * 25)
        nutNho.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        nutNho.Text = luaChon
        nutNho.TextColor3 = Color3.fromRGB(255, 255, 255)
        nutNho.Font = Enum.Font.GothamMedium
        nutNho.TextSize = 10
        Instance.new("UICorner", nutNho)

        nutNho.MouseButton1Click:Connect(function()
            Settings[keyCauHinh] = luaChon
            nutBamMo.Text = "     " .. tenHienThi .. ": " .. luaChon
            moRong = false
            TweenService:Create(oMenu, TweenInfo.new(0.16), {Size = UDim2.new(0.96, 0, 0, 36)}):Play()
            DayThongBaoHeThong("CẤU HÌNH V3", "Chuyển chế độ: " .. luaChon, Color3.fromRGB(0, 255, 128))
        end)
    end
end

-- ==================== [ ĐỔ ĐỮ LIỆU ĐIỀU KHIỂN VÀO CÁC DANH MỤC ] ====================

-- DANH MỤC 1: BỘ LÕI SIÊU AIMLOCK V3 ĐỘC QUYỀN
TaoNutCongTac("Kích Hoạt Hệ Thống Aimlock", TrangAimlock, "Aimlock_KichHoat", Color3.fromRGB(0, 255, 128))
TaoMenuLuaChon("Ưu Tiên Quét Khóa", TrangAimlock, {"Tâm Màn Hình", "Gần Nhất"}, "Aimlock_CheDoQuet")
TaoMenuLuaChon("Bộ Phận Khóa Tâm", TrangAimlock, {"Quét Thông Minh V3", "Head", "HumanoidRootPart"}, "Aimlock_ViTriKhoa")
TaoMenuLuaChon("Thuật Toán Tính Đường Đạn", TrangAimlock, {"Ma Trận V3", "Tuyến Tính", "Bù Ping", "Tắt"}, "Aimlock_DuDoanQuyDao")
TaoThanhTruot("Hệ Số Dự Đoán Tốc Độ", TrangAimlock, 0.01, 0.4, "Aimlock_HeSoDuDoan", 0.135, "s")
TaoMenuLuaChon("Nội Suy Góc Quay Camera", TrangAimlock, {"Nội Suy Siêu Mượt", "Exponential", "Tuyến Tính"}, "Aimlock_LamMuotGoc")
TaoThanhTruot("Độ Mượt Khóa Tâm (Smoothness)", TrangAimlock, 0.005, 0.3, "Aimlock_DoMuot", 0.042)
TaoNutCongTac("Khóa Chặt Mục Tiêu Cũ (Sticky)", TrangAimlock, "Aimlock_GiuMucTieu", Color3.fromRGB(0, 170, 255))
TaoNutCongTac("Tự Co Giãn FOV Theo Tầm Xa", TrangAimlock, "Aimlock_CoGianFOV", Color3.fromRGB(255, 0, 128))
TaoNutCongTac("Kiểm Tra Đội (Team Check)", TrangAimlock, "Loc_DongDoi", Color3.fromRGB(255, 165, 0))
TaoNutCongTac("Kiểm Tra Vật Cản (Wall Check)", TrangAimlock, "Loc_TuongChan", Color3.fromRGB(0, 255, 255))
TaoNutCongTac("Bỏ Qua Người Đã Bị Gục", TrangAimlock, "Loc_BiGuc", Color3.fromRGB(255, 50, 50))
TaoNutCongTac("Hiển Thị Vòng Tròn Vùng FOV", TrangAimlock, "FOV_HienThi", Color3.fromRGB(170, 0, 255))
TaoNutCongTac("Vòng Quét Đổi Màu Cầu Vồng RGB", TrangAimlock, "FOV_Rgb", Color3.fromRGB(0, 255, 128))
TaoThanhTruot("Bán Kính Vòng Quét FOV", TrangAimlock, 30, 600, "FOV_BanKinh", 150, "px")

-- DANH MỤC 2: TIỆN ÍCH KHUNG THẤU THỊ ESP & GIAN LẬN HITBOX 
TaoNutCongTac("Kích Hoạt Thấu Thị Tổng (ESP)", TrangVisuals, "ESP_KichHoat", Color3.fromRGB(0, 255, 255))
TaoNutCongTac("Hiện Khung Hình Kẻ Địch (Box)", TrangVisuals, "ESP_KhungHinh", Color3.fromRGB(255, 0, 128))
TaoNutCongTac("Hiện Sợi Dây Chỉ Hướng (Tracer)", TrangVisuals, "ESP_DuongChi", Color3.fromRGB(0, 255, 128))
TaoNutCongTac("Hiện Tên Người Chơi", TrangVisuals, "ESP_HienTen", Color3.fromRGB(255, 255, 255))
TaoNutCongTac("Hiện Khoảng Cách Thâm Nhập", TrangVisuals, "ESP_HienKhoangCach", Color3.fromRGB(255, 215, 0))
TaoNutCongTac("Hiện Thanh Máu Linh Hoạt", TrangVisuals, "ESP_ThanhMau", Color3.fromRGB(0, 255, 0))
TaoNutCongTac("Phóng Đại Kích Thước Hitbox Địch", TrangVisuals, "Combat_PhongHitbox", Color3.fromRGB(255, 0, 128))
TaoThanhTruot("Phạm Vi Phóng Đại Khối Cầu", TrangVisuals, 2, 40, "Combat_KichThuocHitbox", 12, " studs")
TaoMenuLuaChon("Bộ Phận Ép Kích Thước", TrangVisuals, {"HumanoidRootPart", "Head"}, "Combat_BoPhanHitbox")
TaoNutCongTac("Kill Aura Tự Động Sát Thương", TrangVisuals, "Combat_KillAura", Color3.fromRGB(255, 50, 50))
TaoThanhTruot("Phạm Vi Quét Vòng Cận Chiến Aura", TrangVisuals, 10, 50, "Combat_PhamViAura", 20, " studs")
TaoNutCongTac("Auto Clicker / Tự Động Vung Vũ Khí", TrangVisuals, "Combat_TuDongChem", Color3.fromRGB(255, 140, 0))

-- DANH MỤC 3: CƠ CHẾ SỬA ĐỔI DI CHUYỂN VẬT LÝ NHÂN VẬT 
TaoNutCongTac("Kích Hoạt Siêu Tốc Độ Chạy", TrangMovement, "Mod_TocDo", Color3.fromRGB(255, 100, 0))
TaoThanhTruot("Chỉ Số WalkSpeed Tùy Chỉnh", TrangMovement, 16, 250, "Mod_GiaTriTocDo", 85, " studs/s")
TaoNutCongTac("Kích Hoạt Siêu Lực Nhảy Cao", TrangMovement, "Mod_NhayCao", Color3.fromRGB(0, 255, 150))
TaoThanhTruot("Chỉ Số JumpPower Tùy Chỉnh", TrangMovement, 50, 250, "Mod_GiaTriNhay", 75, " lực")
TaoNutCongTac("Nhảy Vô Hạn Trên Không (InfJump)", TrangMovement, "Mod_NhayVoHan", Color3.fromRGB(255, 255, 255))
TaoNutCongTac("Đi Xuyên Mọi Bức Tường (Noclip)", TrangMovement, "Mod_DiXuyenTuong", Color3.fromRGB(130, 130, 130))
TaoNutCongTac("Xoay Thân Né Đạn Khóa Tâm (Spinbot)", TrangMovement, "Mod_XoayThan", Color3.fromRGB(180, 0, 255))
TaoThanhTruot("Tốc Độ Vòng Xoay Thân Spinbot", TrangMovement, 10, 200, "Mod_TocDoXoay", 50)

-- DANH MỤC 4: THAY ĐỔI ÁNH SÁNG MAP & GIẢM TẢI LAG ĐỒ HỌA RAM
TaoNutCongTac("Bật Ánh Sáng Toàn Bản Đồ (Fullbright)", TrangWorldMap, "Map_SangToanBanDo", Color3.fromRGB(255, 255, 100))
TaoNutCongTac("Ép Buộc Bầu Trời Ban Đêm", TrangWorldMap, "Map_EpBanDem", Color3.fromRGB(60, 60, 180))
TaoNutCongTac("Kích Hoạt Chống Rò Rỉ Lag RAM", TrangWorldMap, "Map_KhuLagRam", Color3.fromRGB(0, 255, 0))
TaoNutCongTac("Xóa Sạch Chất Liệu Bề Mặt Gây Lag", TrangWorldMap, "Map_XoaVatLieu", Color3.fromRGB(255, 0, 100))

-- ==================== [ NÚT FLOATING MENU DÀNH CHO THIẾT BỊ DI ĐỘNG MOBILE ] ====================
local NutMoMobile = Instance.new("TextButton", ScreenGui)
NutMoMobile.Size = UDim2.new(0, 44, 0, 44)
NutMoMobile.Position = UDim2.new(0, 15, 0.45, 0)
NutMoMobile.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
NutMoMobile.Text = "⌬"
NutMoMobile.TextColor3 = Color3.fromRGB(0, 255, 128)
NutMoMobile.Font = Enum.Font.GothamBlack
NutMoMobile.TextSize = 22
Instance.new("UICorner", NutMoMobile).CornerRadius = UDim.new(1, 0)
local VienNutMobile = Instance.new("UIStroke", NutMoMobile)
VienNutMobile.Color = Color3.fromRGB(0, 170, 255)
VienNutMobile.Thickness = 1
DangKyKeoThaGiaoDien(NutMoMobile)

NutMoMobile.MouseButton1Click:Connect(function() KhungChinhV3.Visible = not KhungChinhV3.Visible end)
UserInputService.InputBegan:Connect(function(k) 
    if k.KeyCode == Settings.Phim_Menu then KhungChinhV3.Visible = not KhungChinhV3.Visible end 
end)

-- ==================== [ LUỒNG THUẬT TOÁN SĂN ĐỊCH LÕI V3 ĐA ĐIỂM TỐI ƯU ] ====================
local function QuetTimMucTieuV3Optimal()
    -- Cơ chế Sticky Lock: Duy trì khóa mục tiêu cũ nếu thỏa mãn điều kiện hợp lệ
    if Settings.Aimlock_GiuMucTieu and MucTieuHienTai_Player and MucTieuHienTai_Part then
        if MucTieuHienTai_Player.Character and MucTieuHienTai_Part:IsDescendantOf(MucTieuHienTai_Player.Character) then
            if LogicV3Core.HopLeDeBan(MucTieuHienTai_Player) and LogicV3Core.KiemTraTuongChan(MucTieuHienTai_Part, MucTieuHienTai_Player.Character) then
                local toaDoManHinh, trenManHinh = Camera:WorldToViewportPoint(MucTieuHienTai_Part.Position)
                if trenManHinh then
                    local banKinhApDung = Settings.FOV_BanKinh
                    if Settings.Aimlock_CoGianFOV and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local tamXaThuc = (LocalPlayer.Character.HumanoidRootPart.Position - MucTieuHienTai_Part.Position).Magnitude
                        banKinhApDung = math.clamp((Settings.FOV_BanKinh * 125) / tamXaThuc, 30, Settings.FOV_BanKinh * 1.6)
                    end
                    if not Settings.FOV_HienThi or (Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) - Vector2.new(toaDoManHinh.X, toaDoManHinh.Y)).Magnitude <= banKinhApDung then
                        return MucTieuHienTai_Player, MucTieuHienTai_Part
                    end
                end
            end
        end
    end

    local mucTieuTotNhat = nil
    local diemSoNhoNhat = math.huge
    local tamNhanVatToi = LocalPlayer.Character
    local gocGocToi = tamNhanVatToi and tamNhanVatToi:FindFirstChild("HumanoidRootPart")
    if not gocGocToi then return nil, nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local gocDich = p.Character:FindFirstChild("HumanoidRootPart")
            if gocDich and LogicV3Core.HopLeDeBan(p) then
                if Settings.Loc_DongDoi and p.Team == LocalPlayer.Team then continue end
                
                local boPhanQuet = gocDich
                -- Thuật toán V3 Smart Scan quét tìm khớp xương có góc ngắm dễ nhất
                if Settings.Aimlock_ViTriKhoa == "Quét Thông Minh V3" then
                    local khoangCachTamMin = math.huge
                    for _, tenKhop in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
                        local doiTuongKhop = p.Character:FindFirstChild(tenKhop)
                        if doiTuongKhop then
                            local sPos, oView = Camera:WorldToViewportPoint(doiTuongKhop.Position)
                            if oView and LogicV3Core.KiemTraTuongChan(doiTuongKhop, p.Character) then
                                local cDist = (Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) - Vector2.new(sPos.X, sPos.Y)).Magnitude
                                if cDist < khoangCachTamMin then
                                    khoangCachTamMin = cDist
                                    boPhanQuet = doiTuongKhop
                                end
                            end
                        end
                    end
                else
                    local khopBatBuoc = p.Character:FindFirstChild(Settings.Aimlock_ViTriKhoa)
                    if khopBatBuoc then boPhanQuet = khopBatBuoc end
                end

                if not LogicV3Core.KiemTraTuongChan(boPhanQuet, p.Character) then continue end

                local toaDoVp, hopLeVp = Camera:WorldToViewportPoint(boPhanQuet.Position)
                if not hopLeVp then continue end

                local khoangCachConTro = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(toaDoVp.X, toaDoVp.Y)).Magnitude
                
                local banKinhXoay = Settings.FOV_BanKinh
                if Settings.Aimlock_CoGianFOV then
                    local rangeThuc = (gocGocToi.Position - boPhanQuet.Position).Magnitude
                    banKinhXoay = math.clamp((Settings.FOV_BanKinh * 125) / rangeThuc, 30, Settings.FOV_BanKinh * 1.6)
                end

                if Settings.FOV_HienThi and khoangCachConTro > banKinhXoay then continue end

                if Settings.Aimlock_CheDoQuet == "Gần Nhất" then
                    local khoangCachTheGioi = (gocGocToi.Position - boPhanQuet.Position).Magnitude
                    if khoangCachTheGioi < diemSoNhoNhat then
                        diemSoNhoNhat = khoangCachTheGioi; mucTieuTotNhat = {Player = p, Part = boPhanQuet}
                    end
                elseif Settings.Aimlock_CheDoQuet == "Tâm Màn Hình" then
                    if khoangCachConTro < diemSoNhoNhat then
                        diemSoNhoNhat = khoangCachConTro; mucTieuTotNhat = {Player = p, Part = boPhanQuet}
                    end
                end
            end
        end
    end
    if mucTieuTotNhat then return mucTieuTotNhat.Player, mucTieuTotNhat.Part end
    return nil, nil
end

-- ==================== [ MÔ-ĐUN GIẢM LAG ENGINE TỐI ƯU HÓA PHẦN CỨNG ] ====================
local function TienHanhDonDepTextureXoaLag()
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and Settings.Map_XoaVatLieu then
            item.Material = Enum.Material.SmoothPlastic
        elseif (item:IsA("Decal") or item:IsA("Texture")) and Settings.Map_KhuLagRam then
            item:Destroy()
        elseif (item:IsA("Atmosphere") or item:IsA("Sky")) and Settings.Map_KhuLagRam then
            item:Destroy()
        end
    end
end

-- ==================== [ BẮT PHÍM KÍCH HOẠT VÒNG ĐỜI NGẮM BẮN ] ====================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Settings.Phim_Aimlock then
        if Settings.CheDo_DeGiu then
            LinhHonAimlockActive = true
        else
            LinhHonAimlockActive = not LinhHonAimlockActive
            DayThongBaoHeThong("AIMLOCK V3", LinhHonAimlockActive and "ĐANG KHÓA CHẶT ĐỊCH 🎯" or "ĐÃ BỎ KHÓA TÂM ✕", LinhHonAimlockActive and Color3.fromRGB(0,255,128) or Color3.fromRGB(255,50,50))
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.Phim_Aimlock and Settings.CheDo_DeGiu then
        LinhHonAimlockActive = false
    end
end)

-- ==================== [ VÒNG LẶP LIÊN TỤC KẾT XUẤT ĐỒ HỌA (RENDERSTEPPED) ] ====================
RunService.RenderStepped:Connect(function()
    TanSoQuet_RGB = (TanSoQuet_RGB + 0.005) % 1
    local mauSacChroma = Color3.fromHSV(TanSoQuet_RGB, 0.85, 1)

    -- Đồng bộ vòng quét FOV màn hình
    if Settings.FOV_HienThi and Settings.Aimlock_KichHoat then
        VongTronFOV.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        local fovBanKinhDong = Settings.FOV_BanKinh
        if Settings.Aimlock_CoGianFOV and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and MucTieuHienTai_Part then
            local kcThuc = (LocalPlayer.Character.HumanoidRootPart.Position - MucTieuHienTai_Part.Position).Magnitude
            fovBanKinhDong = math.clamp((Settings.FOV_BanKinh * 125) / kcThuc, 30, Settings.FOV_BanKinh * 1.6)
        end

        VongTronFOV.Radius = fovBanKinhDong
        VongTronFOV.Thickness = Settings.FOV_DoDay
        VongTronFOV.Color = Settings.FOV_Rgb and mauSacChroma or Settings.FOV_MauSac
        VongTronFOV.Transparency = Settings.FOV_TrongSuot
        VongTronFOV.Visible = true
    else
        VongTronFOV.Visible = false
    end

    -- Động cơ hiển thị thấu thị vẽ khung hình ESP V3 cực mượt
    if Settings.ESP_KichHoat then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if root and hum and hum.Health > 0 then
                    local viTriKhuVuc, nhinThayKhuVuc = Camera:WorldToViewportPoint(root.Position)
                    
                    if nhinThayKhuVuc then
                        local boNhoLuu = BoNho_ESP_Goc[p] or {
                            Box = Drawing.new("Square"), Tracer = Drawing.new("Line"),
                            Name = Drawing.new("Text"), Dist = Drawing.new("Text"),
                            HealthBar = Drawing.new("Square")
                        }
                        BoNho_ESP_Goc[p] = boNhoLuu
                        
                        local coChieuCao = 2000 / viTriKhuVuc.Z
                        local coChieuRong = coChieuCao * 1.35
                        
                        if Settings.ESP_KhungHinh then
                            boNhoLuu.Box.Visible = true
                            boNhoLuu.Box.Size = Vector2.new(coChieuRong, coChieuCao)
                            boNhoLuu.Box.Position = Vector2.new(viTriKhuVuc.X - coChieuRong / 2, viTriKhuVuc.Y - coChieuCao / 2)
                            boNhoLuu.Box.Color = Settings.ESP_MauKhung
                            boNhoLuu.Box.Thickness = 1.5
                        else boNhoLuu.Box.Visible = false end

                        if Settings.ESP_ThanhMau then
                            local tiLeMau = hum.Health / hum.MaxHealth
                            boNhoLuu.HealthBar.Visible = true
                            boNhoLuu.HealthBar.Size = Vector2.new(3, coChieuCao * tiLeMau)
                            boNhoLuu.HealthBar.Position = Vector2.new(viTriKhuVuc.X - coChieuRong / 2 - 6, viTriKhuVuc.Y - coChieuCao / 2 + (coChieuCao * (1 - tiLeMau)))
                            boNhoLuu.HealthBar.Color = Color3.fromRGB(255 - (255 * tiLeMau), 255 * tiLeMau, 0)
                            boNhoLuu.HealthBar.Filled = true
                        else boNhoLuu.HealthBar.Visible = false end

                        if Settings.ESP_DuongChi then
                            boNhoLuu.Tracer.Visible = true
                            boNhoLuu.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            boNhoLuu.Tracer.To = Vector2.new(viTriKhuVuc.X, viTriKhuVuc.Y)
                            boNhoLuu.Tracer.Color = Settings.ESP_MauChi
                            boNhoLuu.Tracer.Thickness = 1
                        else boNhoLuu.Tracer.Visible = false end

                        if Settings.ESP_HienTen then
                            boNhoLuu.Name.Visible = true
                            boNhoLuu.Name.Text = p.Name
                            boNhoLuu.Name.Position = Vector2.new(viTriKhuVuc.X, viTriKhuVuc.Y - coChieuCao / 2 - 15)
                            boNhoLuu.Name.Color = Settings.ESP_MauChu
                            boNhoLuu.Name.Size = 12
                            boNhoLuu.Name.Center = true; boNhoLuu.Name.Outline = true
                        else boNhoLuu.Name.Visible = false end

                        if Settings.ESP_HienKhoangCach and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local kCachMeta = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                            boNhoLuu.Dist.Visible = true
                            boNhoLuu.Dist.Text = tostring(kCachMeta) .. "m"
                            boNhoLuu.Dist.Position = Vector2.new(viTriKhuVuc.X, viTriKhuVuc.Y + coChieuCao / 2 + 3)
                            boNhoLuu.Dist.Color = Color3.fromRGB(255, 230, 80)
                            boNhoLuu.Dist.Size = 11
                            boNhoLuu.Dist.Center = true; boNhoLuu.Dist.Outline = true
                        else boNhoLuu.Dist.Visible = false end
                    else GiaiPhongEspNguoiChoi(p) end
                else GiaiPhongEspNguoiChoi(p) end
            end
        end
    else
        for player, _ in pairs(BoNho_ESP_Goc) do GiaiPhongEspNguoiChoi(player) end
    end

    -- Xử lý thuật toán siêu khóa Aimlock bám dính triệt tiêu hoàn toàn độ giật lệch tâm
    if Settings.Aimlock_KichHoat and LinhHonAimlockActive then
        local pQuet, partQuet = QuetTimMucTieuV3Optimal()
        MucTieuHienTai_Player = pQuet
        MucTieuHienTai_Part = partQuet
        
        if pQuet and partQuet then
            local viTriXoayHienTai = partQuet.Position
            local giaTocHienTai = partQuet.Velocity
            
            -- Lớp lọc ma trận tính toán điểm chặn đầu đạn di chuyển v3
            if Settings.Aimlock_DuDoanQuyDao == "Ma Trận V3" then
                viTriXoayHienTai = viTriXoayHienTai + (giaTocHienTai * Settings.Aimlock_HeSoDuDoan) + (partQuet.AssemblyLinearVelocity * 0.012)
            elseif Settings.Aimlock_DuDoanQuyDao == "Bù Ping" then
                local pingThongSo = 0.04
                pcall(function() pingThongSo = LocalPlayer:GetNetworkPing() end)
                viTriXoayHienTai = viTriXoayHienTai + (giaTocHienTai * pingThongSo * (Settings.Aimlock_HeSoDuDoan * 6.8))
            elseif Settings.Aimlock_DuDoanQuyDao == "Tuyến Tính" then
                viTriXoayHienTai = viTriXoayHienTai + (giaTocHienTai * 0.1)
            end
            
            -- Bảo vệ CFrame khỏi lỗi sập NaN Vector toán học trùng lặp vị trí
            local maTranHuongLook = CFrame.lookAt(Camera.CFrame.Position, viTriXoayHienTai)
            if (viTriXoayHienTai - Camera.CFrame.Position).Magnitude > 0.01 then
                -- Hệ thống nội suy góc quay làm mượt chống giật lag lắc màn hình
                if Settings.Aimlock_LamMuotGoc == "Nội Suy Siêu Mượt" then
                    local lerpXoay = Camera.CFrame:Lerp(maTranHuongLook, Settings.Aimlock_DoMuot)
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position) * lerpXoay.Rotation
                elseif Settings.Aimlock_LamMuotGoc == "Exponential" then
                    local expFactor = 1 - math.exp(-Settings.Aimlock_DoMuot * 60 * RunService.RenderStepped:Wait())
                    Camera.CFrame = Camera.CFrame:Lerp(maTranHuongLook, math.clamp(expFactor, 0, 1))
                elseif Settings.Aimlock_LamMuotGoc == "Tuyến Tính" then
                    Camera.CFrame = Camera.CFrame:Lerp(maTranHuongLook, Settings.Aimlock_DoMuot)
                end
            end

            -- Hiển thị sợi dây ngắm laser neon phong cách cyberpunk
            local vTManHinh, vTOn = Camera:WorldToViewportPoint(partQuet.Position)
            if vTOn then
                DuongChiLaserV3.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                DuongChiLaserV3.To = Vector2.new(vTManHinh.X, vTManHinh.Y)
                DuongChiLaserV3.Color = Settings.FOV_Rgb and mauSacChroma or Color3.fromRGB(0, 255, 128)
                DuongChiLaserV3.Thickness = 1.6
                DuongChiLaserV3.Transparency = 0.85
                DuongChiLaserV3.Visible = true
            else DuongChiLaserV3.Visible = false end
        else DuongChiLaserV3.Visible = false end
    else
        MucTieuHienTai_Player = nil; MucTieuHienTai_Part = nil
        DuongChiLaserV3.Visible = false
    end
end)

-- ==================== [ VÒNG LẶP ĐỒNG BỘ VẬT LÝ TOÀN ĐIỀU KIỆN (HEARTBEAT) ] ====================
RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum then return end

    -- Thực thi quản lý môi trường thế giới map và tối ưu RAM
    if Settings.Map_EpBanDem then Lighting.TimeOfDay = "00:00:00" end
    if Settings.Map_SangToanBanDo then Lighting.Ambient = Color3.fromRGB(255, 255, 255) end
    if Settings.Map_KhuLagRam or Settings.Map_XoaVatLieu then TienHanhDonDepTextureXoaLag() end

    -- Đồng bộ sửa đổi gian lận chỉ số tốc độ nhảy cao walkspeed của v3
    if Settings.Mod_TocDo then myHum.WalkSpeed = Settings.Mod_GiaTriTocDo else myHum.WalkSpeed = 16 end
    if Settings.Mod_NhayCao then myHum.JumpPower = Settings.Mod_GiaTriNhay else myHum.JumpPower = 50 end
    if Settings.Mod_XoayThan then myRoot.CFrame = myRoot.CFrame * CFrame.Angles(0, math.rad(Settings.Mod_TocDoXoay), 0) end

    -- Vòng lặp liên tục quét mở rộng hộp trúng đạn phóng đại Hitbox của địch
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local ePart = p.Character:FindFirstChild(Settings.Combat_BoPhanHitbox)
            if ePart and ePart:IsA("BasePart") then
                if Settings.Combat_PhongHitbox then
                    ePart.Size = Vector3.new(Settings.Combat_KichThuocHitbox, Settings.Combat_KichThuocHitbox, Settings.Combat_KichThuocHitbox)
                    ePart.Transparency = Settings.Combat_TrongSuotHitbox
                    ePart.CanCollide = false
                else
                    if ePart.Size.X ~= 2 and ePart.Size.X ~= 1 then
                        ePart.Size = (Settings.Combat_BoPhanHitbox == "Head") and Vector3.new(2, 1, 1) or Vector3.new(2, 2, 1)
                        ePart.Transparency = 1
                    end
                end
            end
        end
    end

    -- Kích hoạt hệ thống tự sấy tự vung kiếm (Kill Aura / Auto Clicker)
    if Settings.Combat_TuDongChem or (Settings.Combat_KillAura and MucTieuHienTai_Player) then
        local congCuTool = myChar:FindFirstChildOfClass("Tool")
        if congCuTool then congCuTool:Activate() end
    end
end)

-- Luồng thực thi đi xuyên tường rào cản địa hình (Stepped Noclip)
RunService.Stepped:Connect(function()
    if Settings.Mod_DiXuyenTuong and LocalPlayer.Character then
        for _, khopThan in ipairs(LocalPlayer.Character:GetChildren()) do
            if khopThan:IsA("BasePart") then khopThan.CanCollide = false end
        end
    end
end)

-- Luồng thực thi nhảy liên hoàn không chạm đất (JumpRequest InfJump)
UserInputService.JumpRequest:Connect(function()
    if Settings.Mod_NhayVoHan and LocalPlayer.Character then
        local doHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if doHum then doHum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Đẩy thông báo nạp thành công hệ thống lên góc HUD màn hình người dùng
DayThongBaoHeThong("MINH MEO OMNIVERSE", "Zenonix Reborn V3.0 Đã Sẵn Sàng! Bấm nút hoặc Right Control để mở bảng điều khiển.", Color3.fromRGB(0, 255, 128))

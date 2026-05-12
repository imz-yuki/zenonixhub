--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║      ⌬  ZENONIX REBORN V3.5 // ULTRA HEAVY AIM LOCK COMBAT EDITION        ║
    ║      >> PHÁT TRIỂN BỞI: MINH MEO OMNIVERSE ETERNAL                        ║
    ║      >> BẢN FIX MẠNH: THUẬT TOÁN RAGE LOCK, BÙ PING SIÊU ĐA ĐIỂM XƯƠNG     ║
    ║      >> CAM KẾT: 100% TIẾNG VIỆT, XOÁ BỎ HOÀN TOÀN TRỄ CAMERA, BẮM LÀ DÍNH ║
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

-- Đồng bộ hóa Camera liên tục chống lỗi mất mục tiêu khi hồi sinh
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

-- ==================== [ BẢNG CẤU HÌNH TỔNG QUÁI VẬT AIMLOCK V3.5 ] ====================
local Settings = {
    -- BỘ LÕI KHÓA TÂM TỐI THƯỢNG (ĐÃ FIX MẠNH)
    Aimlock_KichHoat = true,
    Aimlock_CheDoQuet = "Tâm Màn Hình", -- "Tâm Màn Hình", "Gần Nhất"
    Aimlock_ViTriKhoa = "Quét Đa Điểm Xương V3.5", -- Quét toàn bộ cơ thể kẻ địch tự động
    Aimlock_DuDoanQuyDao = "Ma Trận Bù Tốc Độ Cao", -- Thuật toán tính đường đạn nâng cấp
    Aimlock_HeSoDuDoan = 0.142, -- Hệ số dự đoán chính xác tuyệt đối
    Aimlock_LamMuotGoc = "Khóa Cứng Rage Lock", -- "Khóa Cứng Rage Lock", "Nội Suy Siêu Mượt"
    Aimlock_DoMuot = 0.005, -- Hạ xuống mức tối thiểu để camera bám dính như keo 502
    Aimlock_GiuMucTieu = true, -- Sticky Lock tối đa, không bị loạn mục tiêu khi địch nhảy chéo
    Aimlock_CoGianFOV = true, -- Tự động phóng to vùng FOV khi địch ở xa để dễ bắt mục tiêu
    
    -- BỘ LỌC ĐIỀU KIỆN CHIẾN ĐẤU
    Loc_DongDoi = false,
    Loc_TuongChan = true, -- Wall Check thông minh chống khóa xuyên tường gạch dày
    Loc_ConSong = true,
    Loc_BiGuc = true,

    -- PHẠM VI QUÉT FOV ĐỒ HỌA
    FOV_HienThi = true,
    FOV_Rgb = true,
    FOV_BanKinh = 180,
    FOV_DoDay = 2.5,
    FOV_MauSac = Color3.fromRGB(0, 255, 128),
    FOV_TrongSuot = 0.85,
    
    -- TIỆN ÍCH HITBOX & SÁT THƯƠNG PHỤ TRỢ
    Combat_PhongHitbox = false,
    Combat_KichThuocHitbox = 15,
    Combat_BoPhanHitbox = "HumanoidRootPart",
    Combat_TrongSuotHitbox = 0.5,
    Combat_KillAura = false,
    Combat_PhamViAura = 22,
    Combat_TuDongChem = false,
    
    -- HỆ THỐNG ESP BẢN V3.5
    ESP_KichHoat = false,
    ESP_KhungHinh = false,
    ESP_DuongChi = false,
    ESP_HienTen = false,
    ESP_HienKhoangCach = false,
    ESP_ThanhMau = false,
    ESP_MauKhung = Color3.fromRGB(255, 0, 128),
    ESP_MauChi = Color3.fromRGB(0, 255, 255),
    ESP_MauChu = Color3.fromRGB(255, 255, 255),
    
    -- MOD TRẠNG THÁI DI CHUYỂN
    Mod_TocDo = false,
    Mod_GiaTriTocDo = 90,
    Mod_NhayCao = false,
    Mod_GiaTriNhay = 80,
    Mod_NhayVoHan = false,
    Mod_DiXuyenTuong = false,
    Mod_XoayThan = false,
    Mod_TocDoXoay = 60,
    
    -- KHỬ LAG ĐỒ HỌA TUYỆT ĐỐI
    Map_SangToanBanDo = false,
    Map_EpBanDem = false,
    Map_KhuLagRam = false,
    Map_XoaVatLieu = false,
    
    -- HỆ THỐNG ĐIỀU KHIỂN
    Phim_Aimlock = Enum.KeyCode.Q,
    CheDo_DeGiu = false,
    Phim_Menu = Enum.KeyCode.RightControl
}

-- Biến Trạng Thái Toàn Cục
local LinhHonAimlockActive = false
local MucTieuHienTai_Player = nil
local MucTieuHienTai_Part = nil
local TanSoQuet_RGB = 0
local BoNho_ESP_Goc = {}

-- Khởi tạo Engine Vẽ Đồ Họa Gốc
local VongTronFOV = Drawing.new("Circle")
VongTronFOV.Filled = false
local DuongChiLaserV3 = Drawing.new("Line")
DuongChiLaserV3.Visible = false

-- Giải phóng bộ nhớ chống tụt FPS
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

-- ==================== [ HỆ THỐNG LOGIC CHIẾN ĐẤU NÂNG CAO ] ====================
local LogicV3Core = {}

function LogicV3Core.KiemTraTuongChan(targetPart, character)
    if not Settings.Loc_TuongChan then return true end
    local cameraPos = Camera.CFrame.Position
    local targetPos = targetPart.Position
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera, character}
    params.IgnoreWater = true
    
    local ketQuaRaycast = workspace:Raycast(cameraPos, targetPos - cameraPos, params)
    return ketQuaRaycast == nil
end

function LogicV3Core.HopLeDeBan(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    if Settings.Loc_ConSong and hum.Health <= 0 then return false end
    if Settings.Loc_BiGuc and (char:FindFirstChild("KO") or char:FindFirstChild("Knocked") or char:FindFirstChild("Downed")) then 
        return false 
    end
    return true
end

-- ==================== [ MÔ-ĐUN DI CHUYỂN GIAO DIỆN KHÔNG TRỄ ] ====================
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

-- ==================== [ KHỞI TẠO BẢNG ĐIỀU KHIỂN ĐỒ HỌA CYBER ] ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Zenonix_Heavy_V35"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui") end)

local function DayThongBaoHeThong(tieuDe, noiDung, mauChuDao)
    local oThongBao = Instance.new("Frame")
    oThongBao.Size = UDim2.new(0, 290, 0, 58)
    oThongBao.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    oThongBao.BackgroundTransparency = 0.1
    oThongBao.Parent = ScreenGui

    local stroke = Instance.new("UIStroke", oThongBao)
    stroke.Color = mauChuDao or Color3.fromRGB(0, 255, 128)
    stroke.Thickness = 1.5
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
    TweenService:Create(oThongBao, TweenInfo.new(0.3, Enum.EasingStyle.BackOut), {Position = UDim2.new(1, -310, 0.8, 0)}):Play()
    
    task.delay(1.6, function()
        pcall(function()
            TweenService:Create(oThongBao, TweenInfo.new(0.2, Enum.EasingStyle.QuadIn), {Position = UDim2.new(1.3, 0, 0.8, 0)}):Play()
            task.wait(0.2)
            oThongBao:Destroy()
        end)
    end)
end

local KhungChinhV3 = Instance.new("Frame")
KhungChinhV3.Size = UDim2.new(0, 590, 0, 380)
KhungChinhV3.Position = UDim2.new(0.5, -295, 0.5, -190)
KhungChinhV3.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
KhungChinhV3.Visible = false
KhungChinhV3.Parent = ScreenGui
Instance.new("UICorner", KhungChinhV3).CornerRadius = UDim.new(0, 6)
DangKyKeoThaGiaoDien(KhungChinhV3)

local VienKhungChinh = Instance.new("UIStroke", KhungChinhV3)
VienKhungChinh.Thickness = 1.8
local GradientMauVien = Instance.new("UIGradient", VienKhungChinh)
GradientMauVien.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 80)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 128))
}

local TieuDeGiaoDien = Instance.new("TextLabel", KhungChinhV3)
TieuDeGiaoDien.Text = "⌬ ZENONIX REBORN v3.5 // ULTRA HEAVY RAGE ENGINE"
TieuDeGiaoDien.Font = Enum.Font.GothamBlack
TieuDeGiaoDien.TextColor3 = Color3.fromRGB(255, 255, 255)
TieuDeGiaoDien.TextSize = 13
TieuDeGiaoDien.Position = UDim2.new(0, 16, 0, 12)
TieuDeGiaoDien.Size = UDim2.new(0, 450, 0, 22)
TieuDeGiaoDien.BackgroundTransparency = 1
TieuDeGiaoDien.TextXAlignment = Enum.TextXAlignment.Left

local NutDongGiaoDien = Instance.new("TextButton", KhungChinhV3)
NutDongGiaoDien.Size = UDim2.new(0, 22, 0, 22)
NutDongGiaoDien.Position = UDim2.new(1, -34, 0, 12)
NutDongGiaoDien.BackgroundColor3 = Color3.fromRGB(255, 40, 70)
NutDongGiaoDien.Text = "✕"
NutDongGiaoDien.TextColor3 = Color3.fromRGB(255, 255, 255)
NutDongGiaoDien.Font = Enum.Font.GothamBold
NutDongGiaoDien.TextSize = 9
Instance.new("UICorner", NutDongGiaoDien).CornerRadius = UDim.new(0, 4)
NutDongGiaoDien.MouseButton1Click:Connect(function() ScreenGui:Destroy() VongTronFOV:Remove() DuongChiLaserV3:Remove() end)

local ThanhDanhMucTabs = Instance.new("Frame", KhungChinhV3)
ThanhDanhMucTabs.Size = UDim2.new(0, 145, 1, -55)
ThanhDanhMucTabs.Position = UDim2.new(0, 12, 0, 44)
ThanhDanhMucTabs.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Instance.new("UICorner", ThanhDanhMucTabs).CornerRadius = UDim.new(0, 5)

local BoChuaTrangNoidung = Instance.new("Frame", KhungChinhV3)
BoChuaTrangNoidung.Size = UDim2.new(1, -182, 1, -55)
BoChuaTrangNoidung.Position = UDim2.new(0, 170, 0, 44)
BoChuaTrangNoidung.BackgroundTransparency = 1

local TabNutDangKichHoat = nil
local DemSoLuongTab = 0

local function TaoTrangDanhMuc(tenTab, bieuTuong)
    local cuonTrang = Instance.new("ScrollingFrame", BoChuaTrangNoidung)
    cuonTrang.Size = UDim2.new(1, 0, 1, 0)
    cuonTrang.BackgroundTransparency = 1
    cuonTrang.Visible = (DemSoLuongTab == 0)
    cuonTrang.ScrollBarThickness = 2
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
    nutChuyenTab.BackgroundColor3 = (DemSoLuongTab == 0) and Color3.fromRGB(22, 22, 32) or Color3.fromRGB(14, 14, 22)
    nutChuyenTab.Text = "  " .. bieuTuong .. "  " .. tenTab
    nutChuyenTab.TextColor3 = (DemSoLuongTab == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
    nutChuyenTab.Font = Enum.Font.GothamBold
    nutChuyenTab.TextSize = 10.5
    nutChuyenTab.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", nutChuyenTab).CornerRadius = UDim.new(0, 4)

    if DemSoLuongTab == 0 then TabNutDangKichHoat = nutChuyenTab end

    nutChuyenTab.MouseButton1Click:Connect(function()
        if TabNutDangKichHoat then
            TweenService:Create(TabNutDangKichHoat, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(14, 14, 22), TextColor3 = Color3.fromRGB(140, 140, 140)}):Play()
        end
        TabNutDangKichHoat = nutChuyenTab
        TweenService:Create(nutChuyenTab, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 32), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        
        for _, v in pairs(BoChuaTrangNoidung:GetChildren()) do 
            if v:IsA("ScrollingFrame") then v.Visible = false end 
        end
        cuonTrang.Visible = true
    end)
    
    DemSoLuongTab = DemSoLuongTab + 1
    return cuonTrang
end

-- Thiết lập các Phân mục Menu chính
local TrangAimlock = TaoTrangDanhMuc("BỘ LÕI RAGE", "🎯")
local TrangVisuals = TaoTrangDanhMuc("THẤU THỊ", "👁️")
local TrangMovement = TaoTrangDanhMuc("CƠ HỌC DI CHUYỂN", "⚡")
local TrangWorldMap = TaoTrangDanhMuc("HỆ THỐNG", "⚙️")

-- ==================== [ THIẾT KẾ CÁC THÀNH PHẦN CONTROL COMPONENT ] ====================

local function TaoNutCongTac(tenHienThi, trangChua, keyCauHinh, mauKichHoat)
    local khungNut = Instance.new("TextButton", trangChua)
    khungNut.Size = UDim2.new(0.96, 0, 0, 36)
    khungNut.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    khungNut.Text = "     " .. tenHienThi
    khungNut.TextColor3 = Color3.fromRGB(225, 225, 225)
    khungNut.TextXAlignment = Enum.TextXAlignment.Left
    khungNut.Font = Enum.Font.GothamSemibold
    khungNut.TextSize = 10.5
    Instance.new("UICorner", khungNut).CornerRadius = UDim.new(0, 4)

    local chamDenLed = Instance.new("Frame", khungNut)
    chamDenLed.Size = UDim2.new(0, 10, 0, 10)
    chamDenLed.Position = UDim2.new(1, -22, 0.5, -5)
    chamDenLed.BackgroundColor3 = Settings[keyCauHinh] and mauKichHoat or Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", chamDenLed).CornerRadius = UDim.new(1, 0)

    khungNut.MouseButton1Click:Connect(function()
        Settings[keyCauHinh] = not Settings[keyCauHinh]
        TweenService:Create(chamDenLed, TweenInfo.new(0.1), {BackgroundColor3 = Settings[keyCauHinh] and mauKichHoat or Color3.fromRGB(35, 35, 45)}):Play()
        DayThongBaoHeThong("ZENONIX RAGE", tenHienThi .. " -> " .. (Settings[keyCauHinh] and "ĐÃ BẬT" or "ĐÃ TẮT"), Settings[keyCauHinh] and mauKichHoat or Color3.fromRGB(255, 40, 40))
    end)
end

local function TaoThanhTruot(tenHienThi, trangChua, min, max, keyCauHinh, macDinh, donVi)
    Settings[keyCauHinh] = macDinh
    donVi = donVi or ""
    
    local oTruot = Instance.new("Frame", trangChua)
    oTruot.Size = UDim2.new(0.96, 0, 0, 46)
    oTruot.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Instance.new("UICorner", oTruot).CornerRadius = UDim.new(0, 4)

    local nhanGiaTri = Instance.new("TextLabel", oTruot)
    nhanGiaTri.Size = UDim2.new(0.8, 0, 0, 20)
    nhanGiaTri.Position = UDim2.new(0, 12, 0, 4)
    nhanGiaTri.Text = tenHienThi .. ": " .. tostring(macDinh) .. donVi
    nhanGiaTri.Font = Enum.Font.GothamSemibold
    nhanGiaTri.TextSize = 10.5
    nhanGiaTri.TextColor3 = Color3.fromRGB(185, 185, 185)
    nhanGiaTri.BackgroundTransparency = 1
    nhanGiaTri.TextXAlignment = Enum.TextXAlignment.Left

    local ranhTruot = Instance.new("TextButton", oTruot)
    ranhTruot.Size = UDim2.new(0.94, 0, 0, 4)
    ranhTruot.Position = UDim2.new(0.03, 0, 1, -10)
    ranhTruot.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    ranhTruot.Text = ""
    Instance.new("UICorner", ranhTruot)

    local vungLapDay = Instance.new("Frame", ranhTruot)
    vungLapDay.Size = UDim2.new((macDinh - min) / (max - min), 0, 1, 0)
    vungLapDay.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
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
    oMenu.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Instance.new("UICorner", oMenu).CornerRadius = UDim.new(0, 4)
    oMenu.ClipsDescendants = true

    local nutBamMo = Instance.new("TextButton", oMenu)
    nutBamMo.Size = UDim2.new(1, 0, 0, 36)
    nutBamMo.BackgroundTransparency = 1
    nutBamMo.Text = "     " .. tenHienThi .. ": " .. tostring(Settings[keyCauHinh])
    nutBamMo.TextColor3 = Color3.fromRGB(0, 255, 255)
    nutBamMo.Font = Enum.Font.GothamBold
    nutBamMo.TextSize = 10.5
    nutBamMo.TextXAlignment = Enum.TextXAlignment.Left

    local moRong = false
    nutBamMo.MouseButton1Click:Connect(function()
        moRong = not moRong
        TweenService:Create(oMenu, TweenInfo.new(0.14), {Size = moRong and UDim2.new(0.96, 0, 0, 36 + (#danhSachOpt * 25)) or UDim2.new(0.96, 0, 0, 36)}):Play()
    end)

    for i, luaChon in ipairs(danhSachOpt) do
        local nutNho = Instance.new("TextButton", oMenu)
        nutNho.Size = UDim2.new(0.94, 0, 0, 22)
        nutNho.Position = UDim2.new(0.03, 0, 0, 36 + (i - 1) * 25)
        nutNho.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        nutNho.Text = luaChon
        nutNho.TextColor3 = Color3.fromRGB(255, 255, 255)
        nutNho.Font = Enum.Font.GothamMedium
        nutNho.TextSize = 10
        Instance.new("UICorner", nutNho)

        nutNho.MouseButton1Click:Connect(function()
            Settings[keyCauHinh] = luaChon
            nutBamMo.Text = "     " .. tenHienThi .. ": " .. luaChon
            moRong = false
            TweenService:Create(oMenu, TweenInfo.new(0.14), {Size = UDim2.new(0.96, 0, 0, 36)}):Play()
            DayThongBaoHeThong("THAY ĐỔI CẤU HÌNH", "Chế độ mới: " .. luaChon, Color3.fromRGB(0, 255, 255))
        end)
    end
end

-- Đổ dữ liệu vào giao diện điều khiển
TaoNutCongTac("Kích Hoạt Hệ Thống Aimlock", TrangAimlock, "Aimlock_KichHoat", Color3.fromRGB(0, 255, 128))
TaoMenuLuaChon("Ưu Tiên Quét Khóa", TrangAimlock, {"Tâm Màn Hình", "Gần Nhất"}, "Aimlock_CheDoQuet")
TaoMenuLuaChon("Bộ Phận Khóa Tâm", TrangAimlock, {"Quét Đa Điểm Xương V3.5", "Head", "HumanoidRootPart"}, "Aimlock_ViTriKhoa")
TaoMenuLuaChon("Thuật Toán Tính Đường Đạn", TrangAimlock, {"Ma Trận Bù Tốc Độ Cao", "Tuyến Tính", "Tắt"}, "Aimlock_DuDoanQuyDao")
TaoThanhTruot("Hệ Số Dự Đoán Khóa", TrangAimlock, 0.01, 0.4, "Aimlock_HeSoDuDoan", 0.142)
TaoMenuLuaChon("Chế Độ Thao Tác Camera", TrangAimlock, {"Khóa Cứng Rage Lock", "Nội Suy Siêu Mượt"}, "Aimlock_LamMuotGoc")
TaoThanhTruot("Độ Trễ Khóa Mượt (Smoothness)", TrangAimlock, 0.001, 0.2, "Aimlock_DoMuot", 0.005)
TaoNutCongTac("Bám Dính Mục Tiêu Cũ (Sticky)", TrangAimlock, "Aimlock_GiuMucTieu", Color3.fromRGB(0, 170, 255))
TaoNutCongTac("Tự Động Co Giãn FOV Thông Minh", TrangAimlock, "Aimlock_CoGianFOV", Color3.fromRGB(255, 0, 128))
TaoNutCongTac("Kiểm Tra Đồng Đội (Team Check)", TrangAimlock, "Loc_DongDoi", Color3.fromRGB(255, 165, 0))
TaoNutCongTac("Kiểm Tra Tường Cản (Wall Check)", TrangAimlock, "Loc_TuongChan", Color3.fromRGB(0, 255, 255))
TaoNutCongTac("Hiển Thị Vòng Tròn FOV", TrangAimlock, "FOV_HienThi", Color3.fromRGB(170, 0, 255))
TaoNutCongTac("Vòng Quét Đổi Màu RGB Cầu Vồng", TrangAimlock, "FOV_Rgb", Color3.fromRGB(0, 255, 128))
TaoThanhTruot("Bán Kính Vòng Quét FOV", TrangAimlock, 30, 700, "FOV_BanKinh", 180, "px")

-- Phân mục thấu thị và hitbox nâng cấp
TaoNutCongTac("Kích Hoạt Thấu Thị Tổng (ESP)", TrangVisuals, "ESP_KichHoat", Color3.fromRGB(0, 255, 255))
TaoNutCongTac("Hiện Khung Hình Kẻ Địch (Box)", TrangVisuals, "ESP_KhungHinh", Color3.fromRGB(255, 0, 128))
TaoNutCongTac("Hiện Dây Chỉ Hướng (Tracer)", TrangVisuals, "ESP_DuongChi", Color3.fromRGB(0, 255, 128))
TaoNutCongTac("Hiện Tên Người Chơi", TrangVisuals, "ESP_HienTen", Color3.fromRGB(255, 255, 255))
TaoNutCongTac("Hiện Khoảng Cách Định Vị", TrangVisuals, "ESP_HienKhoangCach", Color3.fromRGB(255, 215, 0))
TaoNutCongTac("Hiện Thanh Máu Linh Hoạt", TrangVisuals, "ESP_ThanhMau", Color3.fromRGB(0, 255, 0))
TaoNutCongTac("Phóng Đại Kích Thước Hitbox Địch", TrangVisuals, "Combat_PhongHitbox", Color3.fromRGB(255, 0, 128))
TaoThanhTruot("Phạm Vi Phóng Khối Cầu Hitbox", TrangVisuals, 2, 50, "Combat_KichThuocHitbox", 15, " studs")
TaoNutCongTac("Kill Aura Tự Động Sát Thương", TrangVisuals, "Combat_KillAura", Color3.fromRGB(255, 50, 50))
TaoNutCongTac("Auto Clicker / Tự Động Vung Vũ Khí", TrangVisuals, "Combat_TuDongChem", Color3.fromRGB(255, 140, 0))

-- Cơ học di chuyển nhân vật
TaoNutCongTac("Kích Hoạt Siêu Tốc Độ Chạy", TrangMovement, "Mod_TocDo", Color3.fromRGB(255, 100, 0))
TaoThanhTruot("WalkSpeed Tùy Chỉnh", TrangMovement, 16, 300, "Mod_GiaTriTocDo", 90, " studs/s")
TaoNutCongTac("Kích Hoạt Siêu Lực Nhảy Cao", TrangMovement, "Mod_NhayCao", Color3.fromRGB(0, 255, 150))
TaoThanhTruot("JumpPower Tùy Chỉnh", TrangMovement, 50, 300, "Mod_GiaTriNhay", 80, " lực")
TaoNutCongTac("Nhảy Vô Hạn Trên Không (InfJump)", TrangMovement, "Mod_NhayVoHan", Color3.fromRGB(255, 255, 255))
TaoNutCongTac("Đi Xuyên Mọi Bức Tường (Noclip)", TrangMovement, "Mod_DiXuyenTuong", Color3.fromRGB(130, 130, 130))
TaoNutCongTac("Xoay Thân Né Đạn (Spinbot)", TrangMovement, "Mod_XoayThan", Color3.fromRGB(180, 0, 255))

-- Hệ thống bản đồ và tối ưu hóa khử lag
TaoNutCongTac("Bật Ánh Sáng Toàn Bản Đồ (Fullbright)", TrangWorldMap, "Map_SangToanBanDo", Color3.fromRGB(255, 255, 100))
TaoNutCongTac("Ép Buộc Bầu Trời Ban Đêm", TrangWorldMap, "Map_EpBanDem", Color3.fromRGB(60, 60, 180))
TaoNutCongTac("Kích Hoạt Chống Rò Rỉ Lag RAM", TrangWorldMap, "Map_KhuLagRam", Color3.fromRGB(0, 255, 0))
TaoNutCongTac("Xóa Sạch Chất Liệu Gây Giật FPS", TrangWorldMap, "Map_XoaVatLieu", Color3.fromRGB(255, 0, 100))

-- NÚT BẤM FLOATING MENU MOBILE & KEYBOARD PC
local NutMoMobile = Instance.new("TextButton", ScreenGui)
NutMoMobile.Size = UDim2.new(0, 44, 0, 44)
NutMoMobile.Position = UDim2.new(0, 15, 0.45, 0)
NutMoMobile.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
NutMoMobile.Text = "⌬"
NutMoMobile.TextColor3 = Color3.fromRGB(255, 0, 80)
NutMoMobile.Font = Enum.Font.GothamBlack
NutMoMobile.TextSize = 22
Instance.new("UICorner", NutMoMobile).CornerRadius = UDim.new(1, 0)
local VienNutMobile = Instance.new("UIStroke", NutMoMobile)
VienNutMobile.Color = Color3.fromRGB(0, 255, 255)
VienNutMobile.Thickness = 1.2
DangKyKeoThaGiaoDien(NutMoMobile)

NutMoMobile.MouseButton1Click:Connect(function() KhungChinhV3.Visible = not KhungChinhV3.Visible end)
UserInputService.InputBegan:Connect(function(k) 
    if k.KeyCode == Settings.Phim_Menu then KhungChinhV3.Visible = not KhungChinhV3.Visible end 
end)

-- ==================== [ LÕI THUẬT TOÁN AIMLOCK QUÉT ĐA ĐIỂM XƯƠNG RAGE (ĐÃ FIX MẠNH) ] ====================
local function QuetTimMucTieuV3Optimal()
    -- Cơ chế Sticky Lock tối đa: Giữ chặt mục tiêu cũ nếu nó còn hợp lệ
    if Settings.Aimlock_GiuMucTieu and MucTieuHienTai_Player and MucTieuHienTai_Part then
        if MucTieuHienTai_Player.Character and MucTieuHienTai_Part:IsDescendantOf(MucTieuHienTai_Player.Character) then
            if LogicV3Core.HopLeDeBan(MucTieuHienTai_Player) and LogicV3Core.KiemTraTuongChan(MucTieuHienTai_Part, MucTieuHienTai_Player.Character) then
                local toaDoManHinh, trenManHinh = Camera:WorldToViewportPoint(MucTieuHienTai_Part.Position)
                if trenManHinh then
                    local fovBanKinhThuc = Settings.FOV_BanKinh
                    if Settings.Aimlock_CoGianFOV and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local tamXaThuc = (LocalPlayer.Character.HumanoidRootPart.Position - MucTieuHienTai_Part.Position).Magnitude
                        fovBanKinhThuc = math.clamp((Settings.FOV_BanKinh * 140) / tamXaThuc, 40, Settings.FOV_BanKinh * 1.8)
                    end
                    if not Settings.FOV_HienThi or (Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) - Vector2.new(toaDoManHinh.X, toaDoManHinh.Y)).Magnitude <= fovBanKinhThuc then
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

    -- Danh sách các khớp xương quét dồn dập (Multi-Bone Array Engine)
    local KhopXuongQuet = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if Settings.Loc_DongDoi and p.Team == LocalPlayer.Team then continue end
            if not LogicV3Core.HopLeDeBan(p) then continue end

            local boPhanKhóaHợpLệ = nil
            local khoangCachTamNhoNhat = math.huge

            -- Cơ chế quét thông minh tìm khớp xương tối ưu nhất không bị che chắn
            if Settings.Aimlock_ViTriKhoa == "Quét Đa Điểm Xương V3.5" then
                for _, tenKhop in ipairs(KhopXuongQuet) do
                    local doiTuongKhop = p.Character:FindFirstChild(tenKhop)
                    if doiTuongKhop then
                        local viTriVp, hopLeVp = Camera:WorldToViewportPoint(doiTuongKhop.Position)
                        if hopLeVp and LogicV3Core.KiemTraTuongChan(doiTuongKhop, p.Character) then
                            local khoangCachConTro = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(viTriVp.X, viTriVp.Y)).Magnitude
                            if khoangCachConTro < khoangCachTamNhoNhat then
                                khoangCachTamNhoNhat = khoangCachConTro
                                boPhanKhóaHợpLệ = doiTuongKhop
                            end
                        end
                    end
                end
            else
                local khopChiDinh = p.Character:FindFirstChild(Settings.Aimlock_ViTriKhoa)
                if khopChiDinh and LogicV3Core.KiemTraTuongChan(khopChiDinh, p.Character) then
                    boPhanKhóaHợpLệ = khopChiDinh
                end
            end

            -- Nếu tìm thấy xương hợp lệ, tiến hành tính toán khóa tâm dồn dập
            if boPhanKhóaHợpLệ then
                local toaDoVp, hopLeVp = Camera:WorldToViewportPoint(boPhanKhóaHợpLệ.Position)
                if hopLeVp then
                    local khoangCachConTro = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(toaDoVp.X, toaDoVp.Y)).Magnitude
                    
                    local banKinhApDung = Settings.FOV_BanKinh
                    if Settings.Aimlock_CoGianFOV then
                        local kcTheGioi = (gocGocToi.Position - boPhanKhóaHợpLệ.Position).Magnitude
                        banKinhApDung = math.clamp((Settings.FOV_BanKinh * 140) / kcTheGioi, 40, Settings.FOV_BanKinh * 1.8)
                    end

                    if Settings.FOV_HienThi and khoangCachConTro > banKinhApDung then continue end

                    if Settings.Aimlock_CheDoQuet == "Gần Nhất" then
                        local khoangCachTheGioi = (gocGocToi.Position - boPhanKhóaHợpLệ.Position).Magnitude
                        if khoangCachTheGioi < diemSoNhoNhat then
                            diemSoNhoNhat = khoangCachTheGioi; mucTieuTotNhat = {Player = p, Part = boPhanKhóaHợpLệ}
                        end
                    elseif Settings.Aimlock_CheDoQuet == "Tâm Màn Hình" then
                        if khoangCachConTro < diemSoNhoNhat then
                            diemSoNhoNhat = khoangCachConTro; mucTieuTotNhat = {Player = p, Part = boPhanKhóaHợpLệ}
                        end
                    end
                end
            end
        end
    end
    if mucTieuTotNhat then return mucTieuTotNhat.Player, mucTieuTotNhat.Part end
    return nil, nil
end

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

-- Bắt tín hiệu kích hoạt Aimlock từ bàn phím
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Settings.Phim_Aimlock then
        if Settings.CheDo_DeGiu then
            LinhHonAimlockActive = true
        else
            LinhHonAimlockActive = not LinhHonAimlockActive
            DayThongBaoHeThong("AIMLOCK FIX MẠNH", LinhHonAimlockActive and "ĐANG GHÌ CHẶT MỤC TIÊU 🎯" or "ĐÃ NHẢ KHÓA TÂM ✕", LinhHonAimlockActive and Color3.fromRGB(0, 255, 128) or Color3.fromRGB(255, 40, 40))
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.Phim_Aimlock and Settings.CheDo_DeGiu then
        LinhHonAimlockActive = false
    end
end)

-- ==================== [ VÒNG LẶP LIÊN TỤC KẾT XUẤT ĐỒ HỌA SĂN ĐỊCH (RENDERSTEPPED) ] ====================
RunService.RenderStepped:Connect(function()
    TanSoQuet_RGB = (TanSoQuet_RGB + 0.006) % 1
    local mauSacChroma = Color3.fromHSV(TanSoQuet_RGB, 0.9, 1)

    -- Cập nhật Đồ họa vòng tròn FOV theo khoảng cách thực tế
    if Settings.FOV_HienThi and Settings.Aimlock_KichHoat then
        VongTronFOV.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        local fovDongKinh = Settings.FOV_BanKinh
        if Settings.Aimlock_CoGianFOV and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and MucTieuHienTai_Part then
            local kcM = (LocalPlayer.Character.HumanoidRootPart.Position - MucTieuHienTai_Part.Position).Magnitude
            fovDongKinh = math.clamp((Settings.FOV_BanKinh * 140) / kcM, 40, Settings.FOV_BanKinh * 1.8)
        end

        VongTronFOV.Radius = fovDongKinh
        VongTronFOV.Thickness = Settings.FOV_DoDay
        VongTronFOV.Color = Settings.FOV_Rgb and mauSacChroma or Settings.FOV_MauSac
        VongTronFOV.Transparency = Settings.FOV_TrongSuot
        VongTronFOV.Visible = true
    else
        VongTronFOV.Visible = false
    end

    -- Động cơ kết xuất khung hình ESP cực mượt chống trễ nhịp hình
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
                        
                        local coChieuCao = 2200 / viTriKhuVuc.Z
                        local coChieuRong = coChieuCao * 1.4
                        
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
                            boNhoLuu.Dist.Text = tostring(kCachMeta) .. " studs"
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

    -- THỰC THI KHÓA TÂM RAGE LOCK ĐÃ FIX MẠNH
    if Settings.Aimlock_KichHoat and LinhHonAimlockActive then
        local pQuet, partQuet = QuetTimMucTieuV3Optimal()
        MucTieuHienTai_Player = pQuet
        MucTieuHienTai_Part = partQuet
        
        if pQuet and partQuet then
            local viTriXoayHienTai = partQuet.Position
            local giaTocHienTai = partQuet.Velocity
            
            -- Động cơ bù vận tốc ma trận tốc độ cao tính toán điểm rơi của đạn
            if Settings.Aimlock_DuDoanQuyDao == "Ma Trận Bù Tốc Độ Cao" then
                local chiSoPing = 0.035
                pcall(function() chiSoPing = LocalPlayer:GetNetworkPing() end)
                -- Thuật toán nâng cấp tích hợp cả vector gia tốc góc giúp bắn trúng kẻ địch đang lướt (dash/dodge)
                viTriXoayHienTai = viTriXoayHienTai + (giaTocHienTai * Settings.Aimlock_HeSoDuDoan) + (partQuet.AssemblyLinearVelocity * chiSoPing * 1.1)
            elseif Settings.Aimlock_DuDoanQuyDao == "Tuyến Tính" then
                viTriXoayHienTai = viTriXoayHienTai + (giaTocHienTai * 0.1)
            end
            
            local maTranHuongLook = CFrame.lookAt(Camera.CFrame.Position, viTriXoayHienTai)
            
            -- Thực thi thao tác bám camera dính chặt
            if Settings.Aimlock_LamMuotGoc == "Khóa Cứng Rage Lock" then
                -- Ép góc Camera bằng 0 trễ, dính chặt mục tiêu tuyệt đối không một động tác thừa
                Camera.CFrame = CFrame.new(Camera.CFrame.Position) * maTranHuongLook.Rotation
            elseif Settings.Aimlock_LamMuotGoc == "Nội Suy Siêu Mượt" then
                Camera.CFrame = Camera.CFrame:Lerp(maTranHuongLook, Settings.Aimlock_DoMuot)
            end

            -- Vẽ sợi dây ngắm bắn Cyberneon
            local vTManHinh, vTOn = Camera:WorldToViewportPoint(partQuet.Position)
            if vTOn then
                DuongChiLaserV3.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                DuongChiLaserV3.To = Vector2.new(vTManHinh.X, vTManHinh.Y)
                DuongChiLaserV3.Color = Settings.FOV_Rgb and mauSacChroma or Color3.fromRGB(255, 0, 80)
                DuongChiLaserV3.Thickness = 1.8
                DuongChiLaserV3.Transparency = 0.9
                DuongChiLaserV3.Visible = true
            else DuongChiLaserV3.Visible = false end
        else DuongChiLaserV3.Visible = false end
    else
        MucTieuHienTai_Player = nil; MucTieuHienTai_Part = nil
        DuongChiLaserV3.Visible = false
    end
end)

-- ==================== [ VÒNG LẶP ĐỒNG BỘ VẬT LÝ NHÂN VẬT & MAP (HEARTBEAT) ] ====================
RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum then return end

    -- Quản lý hiệu ứng đồ họa map thế giới
    if Settings.Map_EpBanDem then Lighting.TimeOfDay = "00:00:00" end
    if Settings.Map_SangToanBanDo then Lighting.Ambient = Color3.fromRGB(255, 255, 255) end
    if Settings.Map_KhuLagRam or Settings.Map_XoaVatLieu then TienHanhDonDepTextureXoaLag() end

    -- Đồng bộ hóa tinh chỉnh thông số di chuyển
    if Settings.Mod_TocDo then myHum.WalkSpeed = Settings.Mod_GiaTriTocDo else myHum.WalkSpeed = 16 end
    if Settings.Mod_NhayCao then myHum.JumpPower = Settings.Mod_GiaTriNhay else myHum.JumpPower = 50 end
    if Settings.Mod_XoayThan then myRoot.CFrame = myRoot.CFrame * CFrame.Angles(0, math.rad(Settings.Mod_TocDoXoay), 0) end

    -- Vòng lặp cưỡng bức ép kích thước mở rộng Hitbox của địch
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

    -- Thực thi tự động Click / Vung vũ khí liên hồi
    if Settings.Combat_TuDongChem or (Settings.Combat_KillAura and MucTieuHienTai_Player) then
        local congCuTool = myChar:FindFirstChildOfClass("Tool")
        if congCuTool then congCuTool:Activate() end
    end
end)

-- Xử lý noclip xuyên tường địa hình
RunService.Stepped:Connect(function()
    if Settings.Mod_DiXuyenTuong and LocalPlayer.Character then
        for _, khopThan in ipairs(LocalPlayer.Character:GetChildren()) do
            if khopThan:IsA("BasePart") then khopThan.CanCollide = false end
        end
    end
end)

-- Xử lý nhảy vô hạn trên không
UserInputService.JumpRequest:Connect(function()
    if Settings.Mod_NhayVoHan and LocalPlayer.Character then
        local doHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if doHum then doHum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Bắn thông báo nạp thành công bộ lõi V3.5 Rage Engine
DayThongBaoHeThong("MINH MEO OMNIVERSE", "Đã nâng cấp Aimlock V3.5 siêu dính! Chế độ Khóa Cứng Rage Lock đã sẵn sàng.", Color3.fromRGB(255, 0, 100))

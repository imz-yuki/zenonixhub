-- [[ ZENONIX HUB - SUPER POTATO MODE (V3.0 FORESTO) ]] --
-- ✮-> Developed by: Yuki.dev | Power: 9999
-- 🔥 Status: Ultimate Lag Destroyer (All Games Compatible)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- ==========================================
-- 1. CAN THIỆP SÂU ENGINE LEVEL (FPS BOOST)
-- ==========================================
local settings = settings()
pcall(function()
    settings.Rendering.QualityLevel = Enum.QualityLevel.Level01
    settings.Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    settings.Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Heavy
end)

-- ==========================================
-- 2. THUẬT TOÁN NHẬN DIỆN NHÂN VẬT SIÊU TỐC
-- ==========================================
local function isPlayerAsset(instance)
    local current = instance
    while current and current ~= Workspace do
        if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
            return true
        end
        current = current.Parent
    end
    return false
end

-- ==========================================
-- 3. LÕI TỐI ƯU HÓA CỰC HẠN (SUPER POTATO ALGORITHM)
-- ==========================================
local function superOptimize(obj)
    if isPlayerAsset(obj) then return end -- Tuyệt đối giữ nguyên Skin/Anim/Clothing của người chơi

    -- Tối ưu hóa BasePart & MeshPart (Đưa về đất sét siêu tối giản)
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Color = Color3.fromRGB(110, 110, 112) -- Tone xám đất sét chuẩn Clay Mode
        obj.CastShadow = false
        obj.Reflectance = 0
        
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        end
        
    -- Triệt tiêu hoàn toàn SurfaceAppearance (Sát thủ ngốn VRAM đồ họa)
    elseif obj:IsA("SurfaceAppearance") then
        obj:Destroy()
        
    -- Xóa các file Texture dán, Decal vẽ trên tường/đất
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        obj:Destroy()
        
    -- Xóa lưới Mesh phụ của các Part thường
    elseif obj:IsA("SpecialMesh") then
        obj.TextureId = ""
        
    -- Xóa sạch nguồn sáng trong map (Giảm tải đổ bóng GPU)
    elseif obj:IsA("Light") then 
        obj:Destroy()
        
    -- Hủy diệt mọi loại hiệu ứng hạt, khói, lửa, tia sáng, vệt chuyển động
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or 
           obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
        obj:Destroy()
        
    -- Xóa bỏ Highlight (Hiệu ứng viền phát sáng siêu lag của game)
    elseif obj:IsA("Highlight") then
        obj:Destroy()
    end
end

-- ==========================================
-- 4. TRIỂN KHAI DỌN DẸP KHÔNG GÂY ĐƠ GAME (BUDGETED SWEEP)
-- ==========================================
task.spawn(function()
    local descendants = Workspace:GetDescendants()
    local startTime = os.clock()
    
    for _, desc in ipairs(descendants) do
        superOptimize(desc)
        
        -- Nếu quét map tốn quá 15 miligiây (ngưỡng giật khung hình), nhường luồng sang frame sau
        if os.clock() - startTime > 0.015 then
            task.wait()
            startTime = os.clock()
        end
    end
    
    -- Quét thời gian thực (Real-time sweep) cho các vật thể sinh ra sau này
    Workspace.DescendantAdded:Connect(function(newObj)
        task.wait(0.01) -- Tránh xung đột luồng khi game vừa instance mới
        superOptimize(newObj)
    end)
end)

-- ==========================================
-- 5. TRIỆT TIÊU ĐỒ HỌA NƯỚC & ĐỊA HÌNH SÂU
-- ==========================================
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
if Terrain then
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 1
    Terrain.Decoration = false -- Tắt cỏ 3D trên Terrain (Nếu có)
end

-- ==========================================
-- 6. KHÓA CỨNG ÁNH SÁNG MÔI TRƯỜNG (ANTI-GAME RECOVERY)
-- ==========================================
local function forceLockLighting()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 0
    Lighting.Brightness = 0
    Lighting.ShadowSoftness = 0
    Lighting.ClockTime = 12 -- Giữ trời sáng rõ như ban ngày để dễ nhìn map đất sét
    
    Lighting.Ambient = Color3.fromRGB(160, 160, 160)
    Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
    
    -- Tiêu diệt toàn bộ hiệu ứng hậu kỳ
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") or effect:IsA("Clouds") then
            effect:Destroy()
        end
    end
end

-- Kích hoạt lần đầu
forceLockLighting()

-- Khóa cứng vĩnh viễn (Chặn game tự động bật lại hiệu ứng)
Lighting.Changed:Connect(forceLockLighting)
Lighting.ChildAdded:Connect(function(child)
    task.wait()
    if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("Clouds") then
        child:Destroy()
    end
end)

print("------------------------------------------")
print("🔥 Zenonix Ultimate Lag Destroyer Active!")
print("👑 Built by: Yuki.dev")
print("⚡ Status: SmoothPlastic [LOCKED] | Fast Sweep [ON] | No-Lag Enabled")
print("------------------------------------------")

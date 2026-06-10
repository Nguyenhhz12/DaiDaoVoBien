-- ============================================================================
-- PROJECT: ĐẠI ĐẠO VÔ BIÊN - NHÀN RỖI TU TIÊN GIẢ LẬP
-- FRAMEWORK: LÖVE 2D (love2d.org)
-- AUDIO & FONT INTEGRATION: Roboto Font + Basic Sound Effects (Music & Click)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONSTANTS & GLOBAL CONFIGURATIONS
-- ----------------------------------------------------------------------------
local WINDOW_WIDTH = 400
local WINDOW_HEIGHT = 800

local DAI_CANH_GIOI = {
    "Phàm Nhân", "Luyện Khí", "Trúc Cơ", "Kim Đan", 
    "Nguyên Anh", "Hóa Thần", "Luyện Hư", "Hợp Thể", 
    "Độ Kiếp", "Chân Tiên", "Kim Tiên", "Đại La Kim Tiên", "Thánh Nhân"
}
local TIEU_CANH_GIOI = {"Nhất Kỳ", "Nhị Kỳ", "Tam Kỳ"}

local YEU_THU_LIST = {
    {name = "Cự Chuột Ngoại Vi", level = 1, exp = 10},
    {name = "Linh Miêu Hoang Dã", level = 1, exp = 15},
    {name = "Hắc Lang Độc Độc", level = 2, exp = 25},
    {name = "Bạo Hổ Rừng Sâu", level = 2, exp = 40},
    {name = "Mãng Xà Khổng Lồ", level = 3, exp = 60},
    {name = "Thiết Giáp Tê Ngưu", level = 3, exp = 90},
    {name = "Xích Nhãn Kim Hầu", level = 4, exp = 130},
    {name = "Băng Sương Ma Quạ", level = 4, exp = 180},
    {name = "U Minh Quỷ Trảo", level = 5, exp = 240},
    {name = "Địa Ngục Ma Khuyển", level = 5, exp = 310},
    {name = "Cửu Vĩ Linh Hồ", level = 6, exp = 400},
    {name = "Thôn Thiên Khuyển", level = 6, exp = 500},
    {name = "Thái Cổ Thần Điêu", level = 7, exp = 650},
    {name = "Kim Ngang Độc Long", level = 7, exp = 800},
    {name = "Thanh Long Ấu Thể", level = 8, exp = 1000},
    {name = "Huyền Vũ Trấn Điện", level = 8, exp = 1300},
    {name = "Phượng Hoàng Lửa", level = 9, exp = 1700},
    {name = "Kỳ Lân Biến Dị", level = 9, exp = 2200},
    {name = "Thôn Phệ Ma Long", level = 10, exp = 3000},
    {name = "Thái Sơ Thần Ma", level = 11, exp = 5000}
}

-- ----------------------------------------------------------------------------
-- GAME STATES & VARIABLES
-- ----------------------------------------------------------------------------
local player = {}
local currentScreen = "tuluyen"
local gameLog = {}
local maxLogs = 8
local saveTimer = 0
local globalTimer = 0
local eventTimer = 0
local eventCooldown = 15

local fontTieuDe = nil
local fontNoiDung = nil

-- QUẢN LÝ THẦN ÂM TINH GIẢN
local bgmMusic = nil
local sfxClick = nil

local shopItems = {}
local itemsPerPage = 5
local shopPage = 1
local bagPage = 1

local currentLodan = 1
local lodanList = {
    {name = "Lò Đất Ngoại Môn", cost = 0, rate = 0.5, multiplier = 1},
    {name = "Đồng Lô Nội Môn", cost = 200, rate = 0.65, multiplier = 1.5},
    {name = "Huyền Thiết Thần Đỉnh", cost = 1500, rate = 0.8, multiplier = 2.2},
    {name = "Cửu Long Hỗn Độn Đỉnh", cost = 10000, rate = 0.95, multiplier = 4.0}
}

local jobNames = {
    "Khai thác Linh Khoáng ở hậu sơn",
    "Chăm sóc Dược Viên cho Trưởng lão",
    "Tuần tra trận pháp biên giới",
    "Lên Tháp canh săn bắn Yêu thú",
    "Luyện chế Phàm khí cho Ngoại môn",
    "Sao chép cổ tịch tại Tàng Thư Các",
    "Hộ tống linh xa của Thương hội",
    "Quét dọn quảng trường Tông Môn",
    "Hái Nấm Linh Chi đỉnh Tuyết Sơn",
    "Tróc nã nội gián Ma giáo thâm nhập"
}

local achievements = {
    {id = "first_step", text = "Sơ Nhập Tiên Đồ", desc = "Đột phá đạt tới Luyện Khí Kỳ", unlocked = false},
    {id = "rich_man", text = "Tích Lũy Phú Gia", desc = "Sở hữu 1,000 Linh Thạch", unlocked = false},
    {id = "alchemist", text = "Đan Sư Khởi Nghiệp", desc = "Luyện thành công 5 viên đan dược", unlocked = false},
    {id = "collector", text = "Thần Binh Đầy Kho", desc = "Mua được 10 món bảo vật trở lên", unlocked = false},
    {id = "workaholic", text = "Tông Môn Lao Thần", desc = "Cống hiến hết lượt làm việc hôm nay", unlocked = false}
}

local mainButtons = {}
local shopButtons = {}
local bagButtons = {}
local jobButtons = {}
local danButtons = {}
local achiButtons = {}

-- ----------------------------------------------------------------------------
-- HELPER FUNCTIONS (UTILITIES)
-- ----------------------------------------------------------------------------
local function addLog(text)
    table.insert(gameLog, 1, text)
    if #gameLog > maxLogs then
        table.remove(gameLog)
    end
end

-- Hàm an toàn để phát âm thanh hiệu ứng (SFX) tránh bị lỗi crash
local function playSFX(audioObj)
    if audioObj then
        audioObj:stop()
        audioObj:play()
    end
end

local function initShopItems()
    shopItems = {}
    local loaiDo = {"Vũ Khí", "Pháp Bảo", "Thần Đan", "Thú Cưỡi"}
    local phamCap = {"Phàm", "Linh", "Huyền", "Địa", "Thiên", "Tiên", "Thần"}
    
    local prefixes = {
        ["Vũ Khí"] = {"Kiếm", "Đao", "Thương", "Cung", "Chùy", "Phạt", "Trảo"},
        ["Pháp Bảo"] = {"Đỉnh", "Tháp", "Gương", "Ấn", "Chuông", "Khuyên", "Tràng Hạt"},
        ["Thần Đan"] = {"Tẩy Tủy", "Trúc Cơ", "Bổ Thiên", "Nguyên Anh", "Độ Kiếp", "Hóa Thần", "Trường Sinh"},
        ["Thú Cưỡi"] = {"Hạc", "Hổ", "Long", "Quy", "Kỳ Lân", "Phượng Hoàng", "Bằng"}
    }
    local suffixes = {"U Minh", "Thái Sơ", "Cửu Thiên", "Huyết Nguyệt", "Kim Cương", "Hỗn Độn", "Vạn Tộc", "Lôi Đình"}
    
    local idCounter = 1
    for _, l in ipairs(loaiDo) do
        for pIdx, p in ipairs(phamCap) do
            for _, pre in ipairs(prefixes[l]) do
                for _, suf in ipairs(suffixes) do
                    if idCounter <= 120 then
                        local name = "[" .. p .. " Cấp] " .. pre .. " " .. suf
                        local price = pIdx * 25 + idCounter * 3
                        local buff = pIdx * 0.15 + (idCounter * 0.015)
                        table.insert(shopItems, {
                            id = idCounter, 
                            name = name, 
                            type = l, 
                            price = price, 
                            buff = buff,
                            phamIndex = pIdx
                        })
                        idCounter = idCounter + 1
                    end
                end
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- CORE DATA MANAGEMENT (SAVE / LOAD)
-- ----------------------------------------------------------------------------
local function saveGame()
    local daMuaTxt = ""
    for id, val in pairs(player.daMua) do
        if val then daMuaTxt = daMuaTxt .. id .. "-" end
    end
    if daMuaTxt == "" then daMuaTxt = "none" end
    
    local lodanTxt = ""
    for id, val in pairs(player.lodanDaMua) do
        if val then lodanTxt = lodanTxt .. id .. "-" end
    end
    if lodanTxt == "" then lodanTxt = "1-" end

    local lines = {
        "linhKhi=" .. tostring(player.linhKhi),
        "linhThach=" .. tostring(player.linhThach),
        "thaoDuoc=" .. tostring(player.thaoDuoc),
        "danDuoc=" .. tostring(player.danDuoc),
        "daiIndex=" .. tostring(player.daiIndex),
        "tieuIndex=" .. tostring(player.tieuIndex),
        "linhKhiCanThiet=" .. tostring(player.linhKhiCanThiet),
        "luotLamViec=" .. tostring(player.luotLamViec),
        "lastResetTime=" .. tostring(player.lastResetTime),
        "currentJobIndex=" .. tostring(player.currentJobIndex),
        "daMua=" .. daMuaTxt,
        "lodanDaMua=" .. lodanTxt,
        "currentLodan=" .. tostring(currentLodan),
        "tongSoLanLuyenDan=" .. tostring(player.tongSoLanLuyenDan)
    }
    
    local content = table.concat(lines, "\n")
    love.filesystem.write("tutien_vokhuyen_save.txt", content)
end

local function loadGame()
    player = {
        linhKhi = 0, linhThach = 0, thaoDuoc = 0, danDuoc = 0,
        daiIndex = 1, tieuIndex = 1, linhKhiCanThiet = 50,
        tocDoCoBan = 0.5, hieuQuaDan = 0.2, daMua = {},
        lodanDaMua = {[1] = true}, luotLamViec = 5,
        lastResetTime = os.time(), currentJobIndex = 1,
        tongSoLanLuyenDan = 0
    }
    currentLodan = 1

    if not love.filesystem.getInfo("tutien_vokhuyen_save.txt") then
        player.currentJobIndex = math.random(1, #jobNames)
        return
    end

    local content, size = love.filesystem.read("tutien_vokhuyen_save.txt")
    if not content then return end

    for line in string.gmatch(content, "[^\r\n]+") do
        local key, val = string.match(line, "([^=]+)=(.*)")
        if key and val then
            if key == "linhKhi" then player.linhKhi = tonumber(val) or 0
            elseif key == "linhThach" then player.linhThach = tonumber(val) or 0
            elseif key == "thaoDuoc" then player.thaoDuoc = tonumber(val) or 0
            elseif key == "danDuoc" then player.danDuoc = tonumber(val) or 0
            elseif key == "daiIndex" then player.daiIndex = tonumber(val) or 1
            elseif key == "tieuIndex" then player.tieuIndex = tonumber(val) or 1
            elseif key == "linhKhiCanThiet" then player.linhKhiCanThiet = tonumber(val) or 50
            elseif key == "luotLamViec" then player.luotLamViec = tonumber(val) or 5
            elseif key == "lastResetTime" then player.lastResetTime = tonumber(val) or os.time()
            elseif key == "currentJobIndex" then player.currentJobIndex = tonumber(val) or 1
            elseif key == "currentLodan" then currentLodan = tonumber(val) or 1
            elseif key == "tongSoLanLuyenDan" then player.tongSoLanLuyenDan = tonumber(val) or 0
            elseif key == "daMua" then
                if val ~= "none" then
                    for idStr in string.gmatch(val, "[^-]+") do
                        local idNum = tonumber(idStr)
                        if idNum then player.daMua[idNum] = true end
                    end
                end
            elseif key == "lodanDaMua" then
                for idStr in string.gmatch(val, "[^-]+") do
                    local idNum = tonumber(idStr)
                    if idNum then player.lodanDaMua[idNum] = true end
                end
            end
        end
    end

    if player.daiIndex < 1 or player.daiIndex > #DAI_CANH_GIOI then player.daiIndex = 1 end
    if player.tieuIndex < 1 or player.tieuIndex > 3 then player.tieuIndex = 1 end
    if player.linhKhiCanThiet <= 0 then player.linhKhiCanThiet = 50 end
    if player.currentJobIndex < 1 or player.currentJobIndex > #jobNames then player.currentJobIndex = 1 end
end

local function checkTimeReset()
    local currentTime = os.time()
    local diff = os.difftime(currentTime, player.lastResetTime)
    if diff >= 86400 then
        player.luotLamViec = 5
        player.currentJobIndex = math.random(1, #jobNames)
        player.lastResetTime = currentTime
        addLog("✨ Khởi đầu ngày mới, Tông Môn ban cấp 5 lượt làm việc mới!")
        saveGame()
    end
end

local function checkAchievements()
    if player.daiIndex > 1 and not achievements[1].unlocked then
        achievements[1].unlocked = true
        addLog("🏆 THÀNH TỰU: Mở khóa [" .. achievements[1].text .. "]!")
    end
    if player.linhThach >= 1000 and not achievements[2].unlocked then
        achievements[2].unlocked = true
        addLog("🏆 THÀNH TỰU: Mở khóa [" .. achievements[2].text .. "]!")
    end
    if player.tongSoLanLuyenDan >= 5 and not achievements[3].unlocked then
        achievements[3].unlocked = true
        addLog("🏆 THÀNH TỰU: Mở khóa [" .. achievements[3].text .. "]!")
    end
    
    local countItem = 0
    for _, owned in pairs(player.daMua) do
        if owned then countItem = countItem + 1 end
    end
    if countItem >= 10 and not achievements[4].unlocked then
        achievements[4].unlocked = true
        addLog("🏆 THÀNH TỰU: Mở khóa [" .. achievements[4].text .. "]!")
    end
    if player.luotLamViec == 0 and not achievements[5].unlocked then
        achievements[5].unlocked = true
        addLog("🏆 THÀNH TỰU: Mở khóa [" .. achievements[5].text .. "]!")
    end
end

local function triggerRandomEvent()
    local roller = math.random(1, 100)
    if roller <= 40 then
        local subRoller = math.random(1, 4)
        if subRoller == 1 then
            local bonusThach = math.random(10, 50) * player.daiIndex
            player.linhThach = player.linhThach + bonusThach
            addLog("☘️ Cơ Duyên: Nhặt được một túi đá vụn ở sơn môn, nhận +" .. bonusThach .. " Linh Thạch.")
        elseif subRoller == 2 then
            local bonusDuoc = math.random(2, 6)
            player.thaoDuoc = player.thaoDuoc + bonusDuoc
            addLog("☘️ Cơ Duyên: Đi dạo bắt gặp linh khí nồng đậm, tiện tay hái +" .. bonusDuoc .. " Thảo Dược.")
        elseif subRoller == 3 then
            local bonusKhi = math.floor(player.linhKhiCanThiet * 0.15)
            player.linhKhi = player.linhKhi + bonusKhi
            addLog("☘️ Cơ Duyên: Đột nhiên đốn ngộ đạo trời, hấp thu đại lượng +" .. bonusKhi .. " Linh Khí.")
        else
            if player.luotLamViec < 5 then
                player.luotLamViec = player.luotLamViec + 1
                addLog("☘️ Cơ Duyên: Ngửi thấy mùi hương trà ngộ đạo, khôi phục +1 Lượt làm việc.")
            else
                player.linhThach = player.linhThach + 100
                addLog("☘️ Cơ Duyên: Trưởng lão đi ngang khen ngợi căn cốt tinh kỳ, ban tặng 100 Linh Thạch.")
            end
        end
    elseif roller >= 85 then
        local subRoller = math.random(1, 3)
        if subRoller == 1 then
            local lostKhi = math.floor(player.linhKhi * 0.2)
            player.linhKhi = player.linhKhi - lostKhi
            addLog("⚡ Biến cố: Tu luyện vội vã dẫn tới nghịch chuyển kinh mạch, mất -" .. lostKhi .. " Linh Khí.")
        elseif subRoller == 2 then
            if player.linhThach > 30 then
                local lostThach = math.random(10, 30)
                player.linhThach = player.linhThach - lostThach
                addLog("⚡ Biến cố: Làm rơi mất túi trữ vật rách, hao tổn -" .. lostThach .. " Linh Thạch.")
            end
        else
            addLog("⚡ Biến cố: Thiên lôi đánh chệch qua nóc nhà, một phen kinh hồn bạt việc nhưng không sao.")
        end
    end
    saveGame()
end

-- ----------------------------------------------------------------------------
-- INTERFACE CONTROLLER & CORE ENGINE LOAD
-- ----------------------------------------------------------------------------
function love.load()
    math.randomseed(os.time())
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.window.setTitle("Đại Đạo Vô Biên - Bản Âm Thanh Tinh Giản v2.3")

    -- 1. THIẾT LẬP FONT CHỮ ROBOTO VARIABLE
    local fontPath = "Roboto-VariableFont_wdth,wght.ttf"
    if love.filesystem.getInfo(fontPath) then
        fontTieuDe = love.graphics.newFont(fontPath, 17)
        fontNoiDung = love.graphics.newFont(fontPath, 13)
        love.graphics.setFont(fontNoiDung)
    else
        addLog("⚠️ Trận pháp cảnh báo: Thiếu file Roboto-VariableFont_wdth,wght.ttf!")
    end

    -- 2. KHỞI TẠO ÂM THANH TINH GIẢN (CHỈ GIỮ LẠI NHẠC NỀN & CLICK)
    if love.filesystem.getInfo("nhac_nen.mp3") then
        bgmMusic = love.audio.newSource("nhac_nen.mp3", "stream")
        bgmMusic:setLooping(true) 
        bgmMusic:setVolume(0.4)    
        bgmMusic:play()            
    end

    if love.filesystem.getInfo("tieng_click.wav") then
        sfxClick = love.audio.newSource("tieng_click.wav", "static")
        sfxClick:setVolume(0.7)
    end

    initShopItems()
    loadGame()
    checkTimeReset()

    -- Khởi tạo nút bấm
    mainButtons = {
        {id = "tuluyen", text = "Tự Tay Hấp Thu (+3 Khí)", x = 40, y = 290, w = 320, h = 45, color = {0.15, 0.55, 0.35}},
        {id = "haithuoc", text = "Thu Thập Thảo Dược (+1)", x = 40, y = 345, w = 320, h = 45, color = {0.25, 0.45, 0.75}},
        {id = "to_dan", text = "Vào Phòng Luyện Đan TH", x = 40, y = 400, w = 320, h = 45, color = {0.75, 0.35, 0.15}},
        {id = "to_job", text = "Nhiệm Vụ Tông Môn", x = 40, y = 455, w = 320, h = 42, color = {0.2, 0.55, 0.65}},
        {id = "to_shop", text = "Đa Bảo Các (Cửa Hàng)", x = 40, y = 507, w = 320, h = 42, color = {0.65, 0.15, 0.55}},
        {id = "to_bag", text = "Túi Trữ Vật Hành Trang", x = 40, y = 559, w = 320, h = 42, color = {0.55, 0.45, 0.15}},
        {id = "to_achi", text = "Bảng Thành Tựu Đại Đạo", x = 40, y = 611, w = 320, h = 42, color = {0.4, 0.4, 0.5}},
        {id = "reset", text = "Binh Giải Kiếp Trước (Xóa Dữ Liệu)", x = 90, y = 665, w = 220, h = 32, color = {0.35, 0.35, 0.35}}
    }
    shopButtons = {
        {id = "to_main", text = "Trở Về Tu Luyện", x = 40, y = 650, w = 320, h = 50, color = {0.2, 0.45, 0.45}},
        {id = "prev_page", text = "Trang Trước", x = 40, y = 590, w = 150, h = 42, color = {0.25, 0.25, 0.25}},
        {id = "next_page", text = "Trang Sau", x = 210, y = 590, w = 150, h = 42, color = {0.25, 0.25, 0.25}}
    }
    bagButtons = {
        {id = "to_main", text = "Trở Về Tu Luyện", x = 40, y = 650, w = 320, h = 50, color = {0.2, 0.45, 0.45}},
        {id = "prev_bag", text = "Trang Trước", x = 40, y = 590, w = 150, h = 42, color = {0.25, 0.25, 0.25}},
        {id = "next_bag", text = "Trang Sau", x = 210, y = 590, w = 150, h = 42, color = {0.25, 0.25, 0.25}}
    }
    jobButtons = {
        {id = "to_main", text = "Trở Về Tu Luyện", x = 40, y = 650, w = 320, h = 50, color = {0.2, 0.45, 0.45}},
        {id = "do_work", text = "Thực Thi Nhiệm Vụ (Tốn 1 Lượt)", x = 40, y = 330, w = 320, h = 70, color = {0.15, 0.55, 0.25}}
    }
    danButtons = {
        {id = "to_main", text = "Trở Về Tu Luyện", x = 40, y = 650, w = 320, h = 50, color = {0.2, 0.45, 0.45}},
        {id = "craft_dan", text = "Bắt Đầu Khởi Hỏa Luyện Đan (Hao 10 Dược)", x = 40, y = 260, w = 320, h = 55, color = {0.7, 0.3, 0.1}},
        {id = "buy_danlo_2", text = "Mua Đồng Lô Nội Môn (200 Linh Thạch)", x = 40, y = 430, w = 320, h = 38, color = {0.4, 0.4, 0.6}},
        {id = "buy_danlo_3", text = "Mua Huyền Thiết Thần Đỉnh (1500 Thạch)", x = 40, y = 475, w = 320, h = 38, color = {0.5, 0.3, 0.6}},
        {id = "buy_danlo_4", text = "Mua Cửu Long Đỉnh (10000 Linh Thạch)", x = 40, y = 520, w = 320, h = 38, color = {0.6, 0.2, 0.4}}
    }
    achiButtons = {
        {id = "to_main", text = "Trở Về Tu Luyện", x = 40, y = 650, w = 320, h = 50, color = {0.2, 0.45, 0.45}}
    }

    addLog("Linh hồn thức tỉnh! Thiên địa tấu nhạc đón mừng đạo hữu.")
end

-- ----------------------------------------------------------------------------
-- SYSTEM UPDATE LOGIC
-- ----------------------------------------------------------------------------
function love.update(dt)
    globalTimer = globalTimer + dt
    saveTimer = saveTimer + dt
    eventTimer = eventTimer + dt

    checkTimeReset()
    checkAchievements()

    local buffBaoVat = 0
    for itemId, owned in pairs(player.daMua) do
        if owned and shopItems[itemId] then buffBaoVat = buffBaoVat + shopItems[itemId].buff end
    end

    local buffDanDuoc = (player.danDuoc or 0) * (player.hieuQuaDan or 0.2)
    local tocDoThucTe = (player.tocDoCoBan or 0.5) + buffDanDuoc + buffBaoVat

    if not (player.daiIndex == #DAI_CANH_GIOI and player.tieuIndex == 3) then
        player.linhKhi = player.linhKhi + tocDoThucTe * dt
        
        if player.linhKhi >= player.linhKhiCanThiet then
            player.linhKhi = 0
            local tyLeThanhCong = math.max(100 - (player.daiIndex * 6) - (player.tieuIndex * 4), 8)
            
            if math.random(1, 100) <= tyLeThanhCong then
                if player.tieuIndex < 3 then player.tieuIndex = player.tieuIndex + 1
                else player.tieuIndex = 1 player.daiIndex = player.daiIndex + 1 end
                player.linhKhiCanThiet = math.floor(player.linhKhiCanThiet * 2.3)
                addLog("⚡ [ĐỘT PHÁ THÀNH CÔNG]: Lên " .. DAI_CANH_GIOI[player.daiIndex] .. " (" .. TIEU_CANH_GIOI[player.tieuIndex] .. ")!")
            else
                if player.daiIndex == 1 and player.tieuIndex == 1 then
                    addLog("❌ [ĐỘT PHÁ THẤT BẠI]: Kinh mạch chấn động, linh khí quay về 0!")
                else
                    if player.tieuIndex > 1 then player.tieuIndex = player.tieuIndex - 1
                    else player.tieuIndex = 3 player.daiIndex = player.daiIndex - 1 end
                    player.linhKhiCanThiet = math.max(50, math.floor(player.linhKhiCanThiet / 2.3))
                end
                addLog("❌ [TÂM MA XÂM NHẬP]: Thất bại hạ cảnh giới!")
            end
            saveGame()
        end
    else
        player.linhKhi = player.linhKhiCanThiet
    end

    if math.random() < 0.08 * dt then player.linhThach = (player.linhThach or 0) + 1 end
    if eventTimer >= eventCooldown then triggerRandomEvent() eventTimer = 0 end
    if saveTimer >= 8 then saveGame() saveTimer = 0 end
end

-- ----------------------------------------------------------------------------
-- GRAPHICS RENDERING INTERFACE
-- ----------------------------------------------------------------------------
function love.draw()
    love.graphics.clear(0.02, 0.02, 0.06)

    if fontTieuDe then love.graphics.setFont(fontTieuDe) end
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("=== ĐẠI ĐẠO VÔ BIÊN TU TIÊN ===", 0, 15, WINDOW_WIDTH, "center")
    
    local dIdx = (player.daiIndex and player.daiIndex >= 1 and player.daiIndex <= #DAI_CANH_GIOI) and player.daiIndex or 1
    local tIdx = (player.tieuIndex and player.tieuIndex >= 1 and player.tieuIndex <= 3) and player.tieuIndex or 1
    local nameCanhGioi = DAI_CANH_GIOI[dIdx] .. " — " .. TIEU_CANH_GIOI[tIdx]
    
    love.graphics.setColor(0.95, 0.8, 0.15)
    love.graphics.printf("Tu Vi: " .. nameCanhGioi, 0, 45, WINDOW_WIDTH, "center")

    if fontNoiDung then love.graphics.setFont(fontNoiDung) end

    local buffBaoVat = 0
    local totalItems = 0
    for id, owned in pairs(player.daMua) do
        if owned then
            totalItems = totalItems + 1
            if shopItems[id] then buffBaoVat = buffBaoVat + shopItems[id].buff end
        end
    end
    local tTocDo = (player.tocDoCoBan or 0.5) + ((player.danDuoc or 0) * (player.hieuQuaDan or 0.2)) + buffBaoVat

    love.graphics.setColor(0.2, 0.75, 0.95)
    love.graphics.print("Linh Thạch: " .. math.floor(player.linhThach), 40, 80)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Hấp thu khí vạn vật: +" .. string.format("%.2f", tTocDo) .. " /s", 40, 102)

    if currentScreen == "tuluyen" then
        local targetTyle = math.max(100 - (dIdx * 6) - (tIdx * 4), 8)
        love.graphics.setColor(0.9, 0.35, 0.35)
        if dIdx == #DAI_CANH_GIOI and tIdx == 3 then
            love.graphics.printf("Cảnh Giới Tối Cao: CHUNG CỰC THÁNH NHÂN", 40, 130, 320, "left")
        else
            love.graphics.printf("Tỷ lệ thành công khi Đột Phá: " .. targetTyle .. "%", 40, 130, 320, "left")
        end

        local curKhi = player.linhKhi or 0
        local maxKhi = player.linhKhiCanThiet or 50
        love.graphics.setColor(0.25, 0.85, 0.55)
        love.graphics.print("Linh Khí Tích Tụ: " .. math.floor(curKhi) .. " / " .. maxKhi, 40, 155)

        love.graphics.setColor(0.08, 0.08, 0.12)
        love.graphics.rectangle("fill", 40, 180, 320, 16, 4, 4)
        local ratio = curKhi / maxKhi
        love.graphics.setColor(0.25, 0.85, 0.55)
        love.graphics.rectangle("fill", 40, 180, 320 * math.min(math.max(ratio, 0), 1), 16, 4, 4)

        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.rectangle("fill", 40, 210, 320, 65, 6, 6)
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.print("Kho Lưu Trữ Nhân Vật (Pháp bảo: " .. totalItems .. "/120)", 50, 215)
        love.graphics.setColor(0.4, 0.8, 0.4)
        love.graphics.print("Thảo Dược: " .. player.thaoDuoc, 55, 242)
        love.graphics.setColor(0.9, 0.55, 0.2)
        love.graphics.print("Đan Dược: " .. player.danDuoc, 200, 242)

        for _, btn in ipairs(mainButtons) do
            love.graphics.setColor(btn.color)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + (btn.h / 2 - 7), btn.w, "center")
        end

    elseif currentScreen == "shop" then
        love.graphics.setColor(0.95, 0.75, 0.1)
        love.graphics.printf("--- ĐA BẢO CÁC PHÁP BẢO (Trang " .. shopPage .. "/24) ---", 0, 130, WINDOW_WIDTH, "center")

        local startIdx = (shopPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, #shopItems)
        local startY = 165
        for i = startIdx, endIdx do
            local item = shopItems[i]
            if item then
                love.graphics.setColor(0.08, 0.08, 0.15)
                love.graphics.rectangle("fill", 40, startY, 320, 75, 6, 6)
                if player.daMua[item.id] then
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.print(item.name .. " [ĐÃ MUA]", 50, startY + 8)
                else
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(item.name, 50, startY + 8)
                end
                love.graphics.setColor(0.65, 0.65, 0.65)
                love.graphics.print("Loại: " .. item.type .. " | Hiệu suất: +" .. string.format("%.3f", item.buff) .. "/s", 50, startY + 30)
                love.graphics.setColor(0.9, 0.8, 0.2)
                love.graphics.print("Giá bán: " .. item.price .. " Linh Thạch", 50, startY + 50)

                if not player.daMua[item.id] then
                    love.graphics.setColor(0.2, 0.6, 0.3)
                    love.graphics.rectangle("fill", 280, startY + 18, 70, 36, 4, 4)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf("MUA", 280, startY + 28, 70, "center")
                end
                startY = startY + 83
            end
        end
        for _, btn in ipairs(shopButtons) do
            love.graphics.setColor(btn.color)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + (btn.h / 2 - 7), btn.w, "center")
        end

    elseif currentScreen == "bag" then
        local myItems = {}
        for id, owned in pairs(player.daMua) do
            if owned and shopItems[id] then table.insert(myItems, shopItems[id]) end
        end
        table.sort(myItems, function(a, b) return a.id < b.id end)
        local totalOwned = #myItems
        local maxBagPage = math.max(1, math.ceil(totalOwned / itemsPerPage))

        love.graphics.setColor(0.2, 0.8, 0.6)
        love.graphics.printf("--- HÀNH TRANG PHÁP BẢO (Trang " .. bagPage .. "/" .. maxBagPage .. ") ---", 0, 130, WINDOW_WIDTH, "center")

        if totalOwned == 0 then
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.printf("Túi trữ vật trống rỗng.", 0, 300, WINDOW_WIDTH, "center")
        else
            local startIdx = (bagPage - 1) * itemsPerPage + 1
            local endIdx = math.min(startIdx + itemsPerPage - 1, totalOwned)
            local startY = 165
            for i = startIdx, endIdx do
                local item = myItems[i]
                if item then
                    love.graphics.setColor(0.06, 0.12, 0.14)
                    love.graphics.rectangle("fill", 40, startY, 320, 75, 6, 6)
                    love.graphics.setColor(0.3, 0.8, 0.95)
                    love.graphics.print(item.name, 50, startY + 12)
                    love.graphics.setColor(0.5, 0.9, 0.5)
                    love.graphics.print("Gia trì: +" .. string.format("%.3f", item.buff) .. "/s", 50, startY + 52)
                    startY = startY + 83
                end
            end
        end
        for _, btn in ipairs(bagButtons) do
            love.graphics.setColor(btn.color)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + (btn.h / 2 - 7), btn.w, "center")
        end

    elseif currentScreen == "job" then
        love.graphics.setColor(0.2, 0.65, 0.8)
        love.graphics.printf("--- ĐIỆN NHIỆM VỤ TÔNG MÔN ---", 0, 130, WINDOW_WIDTH, "center")
        local tenCongViec = jobNames[player.currentJobIndex] or "Hộ pháp sơn môn"
        love.graphics.setColor(0.95, 0.95, 0.4)
        love.graphics.printf("💥 " .. tenCongViec .. " 💥", 40, 170, 320, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Lượt hành sự còn lại: " .. player.luotLamViec .. " / 5", 40, 225, 320, "center")

        for _, btn in ipairs(jobButtons) do
            love.graphics.setColor(btn.color)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + (btn.h / 2 - 7), btn.w, "center")
        end

    elseif currentScreen == "dan" then
        love.graphics.setColor(0.85, 0.4, 0.1)
        love.graphics.printf("--- KHU THẦN ĐAN THÀNH DIỆU ---", 0, 130, WINDOW_WIDTH, "center")
        local loDanHienTai = lodanList[currentLodan]
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Pháp Bảo Đỉnh Lô: " .. loDanHienTai.name, 45, 170)
        love.graphics.setColor(0.4, 0.9, 0.4)
        love.graphics.print("Tỷ lệ đan thành: " .. (loDanHienTai.rate * 100) .. "%", 45, 192)

        for _, btn in ipairs(danButtons) do
            local showBtn = true
            if btn.id == "buy_danlo_2" and player.lodanDaMua[2] then showBtn = false end
            if btn.id == "buy_danlo_3" and player.lodanDaMua[3] then showBtn = false end
            if btn.id == "buy_danlo_4" and player.lodanDaMua[4] then showBtn = false end

            if showBtn then
                love.graphics.setColor(btn.color)
                love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 6, 6)
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(btn.text, btn.x, btn.y + (btn.h / 2 - 7), btn.w, "center")
            else
                if btn.id ~= "to_main" and btn.id ~= "craft_dan" then
                    love.graphics.setColor(0.2, 0.2, 0.2)
                    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 6, 6)
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.printf("[Đã Sở Hữu — Có thể bấm kích hoạt]", btn.x, btn.y + (btn.h / 2 - 7), btn.w, "center")
                end
            end
        end

    elseif currentScreen == "achi" then
        love.graphics.setColor(0.4, 0.7, 0.6)
        love.graphics.printf("--- THÀNH TỰU ĐẠI ĐẠO VĨ ĐẠI ---", 0, 130, WINDOW_WIDTH, "center")
        local startY = 170
        for _, achi in ipairs(achievements) do
            love.graphics.setColor(0.07, 0.07, 0.12)
            love.graphics.rectangle("fill", 40, startY, 320, 65, 6, 6)
            if achi.unlocked then
                love.graphics.setColor(0.25, 0.85, 0.35)
                love.graphics.print("🌟 " .. achi.text .. " [HOÀN THÀNH]", 50, startY + 10)
            else
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print("🔒 " .. achi.text .. " [CHƯA ĐẠT]", 50, startY + 10)
            end
            love.graphics.setColor(0.75, 0.75, 0.75)
            love.graphics.print(achi.desc, 50, startY + 34)
            startY = startY + 75
        end
        for _, btn in ipairs(achiButtons) do
            love.graphics.setColor(btn.color)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btn.x, btn.y + (btn.h / 2 - 7), btn.w, "center")
        end
    end

    -- BOTTOM BOX LOGS
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 25, 712, 350, 80, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", 25, 712, 350, 80, 4, 4)

    local logY = 716
    for idx = #gameLog, 1, -1 do
        local logText = gameLog[idx]
        if logText then
            local alpha = 1.0 - (idx - 1) * 0.12
            love.graphics.setColor(0.85, 0.85, 0.9, math.max(alpha, 0.2))
            love.graphics.print(logText, 32, logY)
            logY = logY + 14
        end
    end
end

-- ----------------------------------------------------------------------------
-- TOUCH CONTROL / INTERACTION LOGIC
-- ----------------------------------------------------------------------------
function love.touchpressed(id, x, y, dx, dy, pressure)
    local tX = x
    local tY = y

    if currentScreen == "tuluyen" then
        for _, btn in ipairs(mainButtons) do
            if tX >= btn.x and tX <= btn.x + btn.w and tY >= btn.y and tY <= btn.y + btn.h then
                playSFX(sfxClick) 
                
                if btn.id == "tuluyen" then
                    if not (player.daiIndex == #DAI_CANH_GIOI and player.tieuIndex == 3) then
                        player.linhKhi = player.linhKhi + 3
                        addLog("Ngài kết ấn điều khí, nhận +3 Linh Khí!")
                    end
                    saveGame()
                elseif btn.id == "haithuoc" then
                    player.thaoDuoc = player.thaoDuoc + 1
                    addLog("Thu hoạch thành công +1 Thảo Dược.")
                    saveGame()
                elseif btn.id == "to_dan" then currentScreen = "dan"
                elseif btn.id == "to_job" then currentScreen = "job"
                elseif btn.id == "to_shop" then currentScreen = "shop" shopPage = 1
                elseif btn.id == "to_bag" then currentScreen = "bag" bagPage = 1
                elseif btn.id == "to_achi" then currentScreen = "achi"
                elseif btn.id == "reset" then
                    player = {
                        linhKhi = 0, linhThach = 0, thaoDuoc = 0, danDuoc = 0, 
                        daiIndex = 1, tieuIndex = 1, linhKhiCanThiet = 50, 
                        tocDoCoBan = 0.5, hieuQuaDan = 0.2, daMua = {}, 
                        lodanDaMua = {[1] = true}, luotLamViec = 5, 
                        lastResetTime = os.time(), currentJobIndex = math.random(1, #jobNames),
                        tongSoLanLuyenDan = 0
                    }
                    currentLodan = 1
                    addLog("☠️ Ngài tự bạo đan điền, luân hồi chuyển sinh!")
                    saveGame()
                end
                return
            end
        end

    elseif currentScreen == "shop" then
        for _, btn in ipairs(shopButtons) do
            if tX >= btn.x and tX <= btn.x + btn.w and tY >= btn.y and tY <= btn.y + btn.h then
                playSFX(sfxClick)
                if btn.id == "to_main" then currentScreen = "tuluyen"
                elseif btn.id == "prev_page" then if shopPage > 1 then shopPage = shopPage - 1 end
                elseif btn.id == "next_page" then if shopPage < math.ceil(#shopItems / itemsPerPage) then shopPage = shopPage + 1 end
                end
                return
            end
        end

        local startIdx = (shopPage - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, #shopItems)
        local startY = 165
        for i = startIdx, endIdx do
            local item = shopItems[i]
            if item then
                if tX >= 280 and tX <= 350 and tY >= startY + 18 and tY <= startY + 54 then
                    if not player.daMua[item.id] then
                        if player.linhThach >= item.price then
                            player.linhThach = player.linhThach - item.price
                            player.daMua[item.id] = true
                            addLog("💰 Mua thành công bảo vật: " .. item.name)
                            playSFX(sfxClick)
                            saveGame()
                        else
                            addLog("❌ Không đủ Linh Thạch!")
                        end
                    end
                    return
                end
                startY = startY + 83
            end
        end

    elseif currentScreen == "bag" then
        for _, btn in ipairs(bagButtons) do
            if tX >= btn.x and tX <= btn.x + btn.w and tY >= btn.y and tY <= btn.y + btn.h then
                playSFX(sfxClick)
                if btn.id == "to_main" then currentScreen = "tuluyen"
                elseif btn.id == "prev_bag" then if bagPage > 1 then bagPage = bagPage - 1 end
                elseif btn.id == "next_bag" then bagPage = bagPage + 1
                end
                return
            end
        end

    elseif currentScreen == "job" then
        for _, btn in ipairs(jobButtons) do
            if tX >= btn.x and tX <= btn.x + btn.w and tY >= btn.y and tY <= btn.y + btn.h then
                playSFX(sfxClick)
                if btn.id == "to_main" then currentScreen = "tuluyen"
                elseif btn.id == "do_work" then
                    if player.luotLamViec > 0 then
                        player.luotLamViec = player.luotLamViec - 1
                        local baseReward = math.random(20, 35)
                        local finalReward = baseReward * player.daiIndex
                        player.linhThach = player.linhThach + finalReward
                        
                        if math.random(1, 100) <= 50 then
                            local monster = YEU_THU_LIST[math.random(1, #YEU_THU_LIST)]
                            addLog("⚔️ Trảm quái: Tiêu diệt [" .. monster.name .. "], nhận thưởng " .. finalReward .. " Linh thạch!")
                        else
                            addLog("✅ Hoàn thành công tác chỉ định tốt đẹp.")
                        end
                        saveGame()
                    else
                        addLog("❌ Lượt hành sự hôm nay đã cạn!")
                    end
                end
                return
            end
        end

    elseif currentScreen == "dan" then
        for _, btn in ipairs(danButtons) do
            if tX >= btn.x and tX <= btn.x + btn.w and tY >= btn.y and tY <= btn.y + btn.h then
                playSFX(sfxClick)
                if btn.id == "to_main" then
                    currentScreen = "tuluyen"
                elseif btn.id == "craft_dan" then
                    if player.thaoDuoc >= 10 then
                        player.thaoDuoc = player.thaoDuoc - 10
                        player.tongSoLanLuyenDan = player.tongSoLanLuyenDan + 1
                        
                        if math.random() <= lodanList[currentLodan].rate then
                            player.danDuoc = player.danDuoc + 1
                            addLog("🔥 [THÀNH ĐAN]: Luyện thành công Kim Đan!")
                        else
                            addLog("💥 [NỔ LÒ]: Lò đan bốc khói đen kịt, tiêu hao sạch thảo dược!")
                        end
                        saveGame()
                    else
                        addLog("❌ Cần tối thiểu 10 Thảo dược để khai hỏa.")
                    end
                elseif btn.id == "buy_danlo_2" or btn.id == "buy_danlo_3" or btn.id == "buy_danlo_4" then
                    local targetId = btn.id == "buy_danlo_2" and 2 or (btn.id == "buy_danlo_3" and 3 or 4)
                    local costTable = {200, 1500, 10000}
                    local cost = costTable[targetId - 1]

                    if not player.lodanDaMua[targetId] then
                        if player.linhThach >= cost then
                            player.linhThach = player.linhThach - cost
                            player.lodanDaMua[targetId] = true
                            currentLodan = targetId
                            addLog("🛠️ Chế tạo thành công lò đan cấp mới!")
                            saveGame()
                        else addLog("❌ Cần thêm Linh Thạch.") end
                    else
                        currentLodan = targetId
                        addLog("🛠️ Đã kích hoạt lò đan chọn.")
                    end
                end
                return
            end
        end

    elseif currentScreen == "achi" then
        for _, btn in ipairs(achiButtons) do
            if tX >= btn.x and tX <= btn.x + btn.w and tY >= btn.y and tY <= btn.y + btn.h then
                playSFX(sfxClick)
                if btn.id == "to_main" then currentScreen = "tuluyen" end
                return
            end
        end
    end
end

function love.quit()
    saveGame()
    return false
end

if globalTimer and globalTimer % 60 == 0 then collectgarbage("collect") end
-- ============================================================================
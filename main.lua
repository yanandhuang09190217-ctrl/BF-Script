-- [[ AhKai Hub 終極版主程式 - 搭載透視與密碼系統 (修復版) ]]
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer -- 👉 就是漏了這行，這行是救命關鍵！

-- 1. 防斷線系統 (Anti-AFK) 
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("AhKai Hub: 已攔截閒置踢出，持續掛機中...")
end)

-- 全域控制狀態
_G.AhKai_Controls = {
    AutoFarm = false,
    Weapon = "Melee",
    ESP_Players = false,
    ESP_Fruits = false,
    CurrentSeaData = nil,
    LoadedSuccess = false
}

-- 你的 GitHub 資訊
local GitHub_Base = "https://raw.githubusercontent.com/yanandhuang09190217-ctrl/BF-Script/main/"

-- 載入頂級 Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 2. 專業級 UI 渲染 (加入專屬密碼系統)
local Window = Rayfield:CreateWindow({
    Name = "👑 AhKai's Premium Hub | Blox Fruits 👑",
    LoadingTitle = "正在驗證 AhKai 專屬密碼...",
    LoadingSubtitle = "By AhKai God",
    ConfigurationSaving = { Enabled = false },
    Discord = {
        Enabled = false,
    },
    KeySystem = true,
    KeySettings = {
        Title = "AhKai Hub 登入驗證",
        Subtitle = "請輸入高級會員密碼",
        Note = "密碼是: AhKaiGod2026",
        FileName = "AhKaiKey",
        SaveKey = true,
        GrabKeyFromSite = false, 
        Key = {"AhKaiGod2026"}
    }
})

-- 動態加載資料庫與引擎
local PlaceIds = { [2753915549] = "sea1", [4442272183] = "sea2", [7449423635] = "sea3" }
local CurrentSeaKey = PlaceIds[game.PlaceId] or "sea1"

pcall(function()
    _G.AhKai_Controls.CurrentSeaData = loadstring(game:HttpGet(GitHub_Base .. "data/" .. CurrentSeaKey .. ".lua"))()
    _G.AhKai_Controls.LoadedSuccess = true
end)
pcall(function() loadstring(game:HttpGet(GitHub_Base .. "modules/farm_engine.lua"))() end)

-- ================== 標籤頁 1: 自動農場 ==================
local Tab_Farm = Window:CreateTab("🔥 自動練等", 4483362458)
Tab_Farm:CreateToggle({
    Name = "啟動全自動升級 (Auto Leveling)",
    CurrentValue = false,
    Flag = "Toggle_Farm",
    Callback = function(Value) _G.AhKai_Controls.AutoFarm = Value end,
})
Tab_Farm:CreateDropdown({
    Name = "選擇掛機武器",
    Options = {"Melee", "Sword", "Blox Fruit"},
    CurrentOption = {"Melee"},
    MultipleOptions = false,
    Flag = "Weapon",
    Callback = function(Option) _G.AhKai_Controls.Weapon = Option[1] end,
})

-- ================== 標籤頁 2: 上帝視角 (ESP) ==================
local Tab_Visuals = Window:CreateTab("👁️ 視覺透視", 4483362458)

Tab_Visuals:CreateToggle({
    Name = "玩家透視 (Player ESP)",
    CurrentValue = false,
    Flag = "Toggle_ESP_Player",
    Callback = function(Value)
        _G.AhKai_Controls.ESP_Players = Value
        for _, v in pairs(game.Players:GetChildren()) do
            if v ~= LocalPlayer and v.Character then
                if Value then
                    local hl = Instance.new("Highlight")
                    hl.Name = "AhKai_ESP"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.Parent = v.Character
                else
                    if v.Character:FindFirstChild("AhKai_ESP") then
                        v.Character.AhKai_ESP:Destroy()
                    end
                end
            end
        end
    end,
})

Rayfield:Notify({Title = "驗證成功", Content = "歡迎來到 AhKai Hub 終極版！", Duration = 5})

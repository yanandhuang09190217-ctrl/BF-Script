-- [[ AhKai Hub 核心主程式 - 分段加載端 ]]
if not game:IsLoaded() then game.Loaded:Wait() end

-- 全域控制狀態
_G.AhKai_Controls = {
    AutoFarm = false,
    Weapon = "Melee",
    CurrentSeaData = nil,
    LoadedSuccess = false
}

-- 🛠️ 唯一需要配置的地方：填入你的 GitHub 資訊
local Git_User = "你的GitHub帳號" 
local Git_Repo = "你的GitHub專案名稱"
local Git_Branch = "main" -- 預設通常是 main

-- 自動生成雲端路徑，後面你完全不用手動改網址
local GitHub_Base = string.format("https://raw.githubusercontent.com/%s/%s/%s/", Git_User, Git_Repo, Git_Branch)
_G.AhKai_Controls.BaseURL = GitHub_Base

-- 載入高品質 Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 海域識別系統
local PlaceIds = { [2753915549] = "sea1", [4442272183] = "sea2", [7449423635] = "sea3" }
local CurrentSeaKey = PlaceIds[game.PlaceId] or "sea1"

-- 動態加載數據庫
local dataSuccess, dataResult = pcall(function()
    return loadstring(game:HttpGet(GitHub_Base .. "data/" .. CurrentSeaKey .. ".lua"))()
end)

if dataSuccess and type(dataResult) == "table" then
    _G.AhKai_Controls.CurrentSeaData = dataResult
    _G.AhKai_Controls.LoadedSuccess = true
else
    warn("AhKai Hub Error: 雲端數據庫加載失敗。網址是否正確？")
end

-- 載入功能功能引擎
task.spawn(function()
    local engineSuccess = pcall(function()
        loadstring(game:HttpGet(GitHub_Base .. "modules/farm_engine.lua"))()
    end)
    if not engineSuccess then warn("AhKai Hub Error: 農場功能引擎載入失敗。") end
end)

-- 渲染玩家介面
local Window = Rayfield:CreateWindow({
    Name = "⚔️ AhKai Hub | 商業級全自動掛機 ⚔️",
    LoadingTitle = "正在從 GitHub 獲取雲端模組...",
    LoadingSubtitle = "當前海域: " .. CurrentSeaKey:upper(),
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local Tab_Main = Window:CreateTab("🔥 全自動練等", 4483362458)

Tab_Main:CreateToggle({
    Name = "啟動全自動升級 (Auto Leveling)",
    CurrentValue = false,
    Flag = "Toggle_MainFarm",
    Callback = function(Value)
        _G.AhKai_Controls.AutoFarm = Value
    end,
})

Tab_Main:CreateDropdown({
    Name = "選擇掛機武器",
    Options = {"Melee", "Sword", "Blox Fruit"},
    CurrentOption = {"Melee"},
    MultipleOptions = false,
    Flag = "Dropdown_WeaponSelect",
    Callback = function(Option)
        _G.AhKai_Controls.Weapon = Option[1]
    end,
})

Rayfield:Notify({
    Title = "注入完成",
    Content = "成功從 GitHub 載入模組，祝您掛機愉快！",
    Duration = 5
})

-- [[ AhKai Hub 終極參考版 - 暴力破解農場引擎 ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- 🌟 業界最強防卡死/防掉落系統 (直接閹割遊戲物理引擎) 🌟
RunService.Stepped:Connect(function()
    if _G.AhKai_Controls.AutoFarm then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            -- 1. 關閉所有物理碰撞 (極致穿牆，不會被山壁卡死)
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            -- 2. 徹底凍結重力與慣性 (保證絕對不會掉進海裡或沉入地底)
            char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            char.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
            char.Humanoid.PlatformStand = true -- 強制剝奪原生走路與掉落狀態
        end
    else
        -- 關閉外掛時恢復正常
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.PlatformStand = false
        end
    end
end)

local function MatchCurrentQuest()
    if not _G.AhKai_Controls.LoadedSuccess or not _G.AhKai_Controls.CurrentSeaData then return nil end
    local currentLevel = LocalPlayer.Data.Level.Value
    local matched = _G.AhKai_Controls.CurrentSeaData[1]
    for _, data in ipairs(_G.AhKai_Controls.CurrentSeaData) do
        if currentLevel >= data.LevelReq then matched = data end
    end
    return matched
end

-- ✈️ 高空折線 Bypass 飛行 (頂級腳本標配)
local function SmartTween(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    if _G.ActiveTween then _G.ActiveTween:Cancel() end
    
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    
    -- 【外掛圈核心機制】距離超過 300 格時，直接瞬移到 400 高空，平移後再降落
    if dist > 300 then
        hrp.CFrame = CFrame.new(hrp.Position.X, 400, hrp.Position.Z)
        task.wait(0.1)
        hrp.CFrame = CFrame.new(targetCFrame.Position.X, 400, targetCFrame.Position.Z)
        task.wait(0.1)
    end
    
    local finalDist = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 320
    local tweenInfo = TweenInfo.new(finalDist / speed, Enum.EasingStyle.Linear)
    _G.ActiveTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    _G.ActiveTween:Play()
    _G.ActiveTween.Completed:Wait()
end

-- ⚔️ 自動農場主迴圈
task.spawn(function()
    -- 拔掉延遲，採用極速運算迴圈
    while task.wait() do 
        if _G.AhKai_Controls.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart
                
                local targetConfig = MatchCurrentQuest()
                if not targetConfig then return end
                
                -- 自動拿武器
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.ToolTip == _G.AhKai_Controls.Weapon then
                        char.Humanoid:EquipTool(tool)
                    end
                end
                
                -- 檢查任務
                local questGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest")
                if not (questGui and questGui.Visible) then
                    SmartTween(targetConfig.NPC_Pos)
                    task.wait(0.1)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", targetConfig.Quest_Name, targetConfig.Quest_Level)
                else
                    -- 鎖定怪物並攻擊
                    local enemyFolder = workspace:FindFirstChild("Enemies") or workspace
                    local hasTarget = false
                    
                    for _, mob in ipairs(enemyFolder:GetChildren()) do
                        if mob.Name == targetConfig.Mob_Name and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            hasTarget = true
                            
                            -- 暴力鎖定：直接把玩家 CFrame 釘在怪物正上方 6 格 (打得到又不會受傷)
                            -- 強制視角朝下，確保普攻判定絕對命中
                            hrp.CFrame = CFrame.new(mob.HumanoidRootPart.Position + Vector3.new(0, 6, 0), mob.HumanoidRootPart.Position)
                            
                            -- 瘋狂點擊攻擊
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(0, 0))
                            break
                        end
                    end
                    
                    -- 若全場沒怪，在重生點上方 40 格高空安全滯留
                    if not hasTarget then
                        SmartTween(targetConfig.Mob_Pos * CFrame.new(0, 40, 0))
                    end
                end
            end)
        end
    end
end)

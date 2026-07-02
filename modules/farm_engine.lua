-- [[ AhKai Hub 核心自動化農場引擎 ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 等級匹配器
local function MatchCurrentQuest()
    if not _G.AhKai_Controls.LoadedSuccess or not _G.AhKai_Controls.CurrentSeaData then return nil end
    local currentLevel = LocalPlayer.Data.Level.Value
    local matched = _G.AhKai_Controls.CurrentSeaData[1]
    
    for _, data in ipairs(_G.AhKai_Controls.CurrentSeaData) do
        if currentLevel >= data.LevelReq then
            matched = data
        end
    end
    return matched
end

-- 平滑移動 (防拉回)
local function TweenTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    if _G.ActiveTween then _G.ActiveTween:Cancel() end
    
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 315 -- 最安全的飛天速度
    local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
    
    _G.ActiveTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    _G.ActiveTween:Play()
    _G.ActiveTween.Completed:Wait()
end

-- 獨立線程掛機迴圈
task.spawn(function()
    while task.wait(0.1) do
        if _G.AhKai_Controls.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                
                local targetConfig = MatchCurrentQuest()
                if not targetConfig then return end
                
                -- 自動拿武器
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.ToolTip == _G.AhKai_Controls.Weapon then
                        char.Humanoid:EquipTool(tool)
                    end
                end
                
                -- 檢查是否有任務
                local questGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest")
                local hasActiveQuest = questGui and questGui.Visible
                
                if not hasActiveQuest then
                    -- 沒任務，飛去接
                    TweenTo(targetConfig.NPC_Pos)
                    task.wait(0.2)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", targetConfig.Quest_Name, targetConfig.Quest_Level)
                    task.wait(0.3)
                else
                    -- 有任務，飛去打怪
                    local enemyFolder = workspace:FindFirstChild("Enemies") or workspace
                    local hasTargetAlive = false
                    
                    for _, mob in ipairs(enemyFolder:GetChildren()) do
                        if mob.Name == targetConfig.Mob_Name and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            hasTargetAlive = true
                            -- 頂級防傷站位：在怪頭頂 7.5 格攻擊
                            char.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 7.5, 0)
                            game:GetService("VirtualUser"):ClickButton1(Vector2.new(0, 0))
                            break
                        end
                    end
                    
                    -- 地面上沒怪，在空中安全區滯留等待重生
                    if not hasTargetAlive then
                        TweenTo(targetConfig.Mob_Pos * CFrame.new(0, 30, 0))
                    end
                end
            end)
        end
    end
end)

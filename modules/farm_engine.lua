-- [[ AhKai Hub 核心自動化農場引擎 (V3 完美高空防溺水版) ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 🛡️ 全域穿牆防卡死 (Noclip)
RunService.Stepped:Connect(function()
    if _G.AhKai_Controls.AutoFarm then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- 等級匹配器
local function MatchCurrentQuest()
    if not _G.AhKai_Controls.LoadedSuccess or not _G.AhKai_Controls.CurrentSeaData then return nil end
    local currentLevel = LocalPlayer.Data.Level.Value
    local matched = _G.AhKai_Controls.CurrentSeaData[1]
    for _, data in ipairs(_G.AhKai_Controls.CurrentSeaData) do
        if currentLevel >= data.LevelReq then matched = data end
    end
    return matched
end

-- ✈️ 高空安全航線 (防溺水、防撞山)
local function TweenTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    if _G.ActiveTween then _G.ActiveTween:Cancel() end
    
    local currentPos = hrp.Position
    local targetPos = targetCFrame.Position
    local distance = (currentPos - targetPos).Magnitude
    local speed = 315
    
    -- 如果距離超過 300 格，啟動「高空折線飛行」
    if distance > 300 then
        -- 1. 先垂直升空到 500 高度
        local upPos = CFrame.new(currentPos.X, 500, currentPos.Z)
        local t1 = TweenService:Create(hrp, TweenInfo.new((upPos.Position - currentPos).Magnitude / speed, Enum.EasingStyle.Linear), {CFrame = upPos})
        _G.ActiveTween = t1; t1:Play(); t1.Completed:Wait()
        
        -- 2. 在高空平移到目標上方
        local overPos = CFrame.new(targetPos.X, 500, targetPos.Z)
        local t2 = TweenService:Create(hrp, TweenInfo.new((overPos.Position - upPos.Position).Magnitude / speed, Enum.EasingStyle.Linear), {CFrame = overPos})
        _G.ActiveTween = t2; t2:Play(); t2.Completed:Wait()
    end
    
    -- 3. 直降到目標
    local finalDist = (hrp.Position - targetPos).Magnitude
    local t3 = TweenService:Create(hrp, TweenInfo.new(finalDist / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    _G.ActiveTween = t3; t3:Play(); t3.Completed:Wait()
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
                
                -- 自動裝備武器
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.ToolTip == _G.AhKai_Controls.Weapon then
                        char.Humanoid:EquipTool(tool)
                    end
                end
                
                -- 🎈 反重力浮空系統 (防止掉落地底)
                local hrp = char.HumanoidRootPart
                if not hrp:FindFirstChild("AhKaiFloat") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "AhKaiFloat"
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.Parent = hrp
                end
                
                -- 任務判斷
                local questGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest")
                local hasActiveQuest = questGui and questGui.Visible
                
                if not hasActiveQuest then
                    TweenTo(targetConfig.NPC_Pos)
                    task.wait(0.2)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", targetConfig.Quest_Name, targetConfig.Quest_Level)
                    task.wait(0.3)
                else
                    local enemyFolder = workspace:FindFirstChild("Enemies") or workspace
                    local hasTargetAlive = false
                    
                    for _, mob in ipairs(enemyFolder:GetChildren()) do
                        if mob.Name == targetConfig.Mob_Name and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            hasTargetAlive = true
                            
                            -- ⚔️ 完美攻擊站位：高度降為 5 格，並且「強制面向」怪物確保打得到
                            hrp.CFrame = CFrame.new(mob.HumanoidRootPart.Position + Vector3.new(0, 5, 0), mob.HumanoidRootPart.Position)
                            
                            game:GetService("VirtualUser"):ClickButton1(Vector2.new(0, 0))
                            break
                        end
                    end
                    
                    -- 若沒怪，飛到天上 50 格安全等待，防其他玩家殺
                    if not hasTargetAlive then
                        hrp.CFrame = targetConfig.Mob_Pos * CFrame.new(0, 50, 0)
                    end
                end
            end)
        else
            -- 關閉外掛時，拆除浮空與穿牆，讓你恢復正常走路
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local float = char.HumanoidRootPart:FindFirstChild("AhKaiFloat")
                if float then float:Destroy() end
            end
        end
    end
end)

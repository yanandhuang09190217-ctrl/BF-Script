-- [[ AhKai Hub 終極暴力傳送引擎 ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- 穿牆與防掉落機制
RunService.Stepped:Connect(function()
    if _G.AhKai_Controls.AutoFarm then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            -- 關閉碰撞
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
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

-- 🚀 暴力高空傳送 (Bypass Teleport)
local function BypassTeleport(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    -- 確保有浮空力場，防止摔死
    if not hrp:FindFirstChild("AhKaiFloat") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "AhKaiFloat"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp
    end
    
    if _G.ActiveTween then _G.ActiveTween:Cancel() end
    
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    
    -- 距離超過 200，強制瞬間拔高到 600 格高空避障
    if dist > 200 then
        hrp.CFrame = CFrame.new(hrp.Position.X, 600, hrp.Position.Z)
        task.wait(0.2) -- 等待伺服器反應，防踢
        hrp.CFrame = CFrame.new(targetCFrame.Position.X, 600, targetCFrame.Position.Z)
        task.wait(0.2)
    end
    
    -- 短距離使用安全速度降落
    local speed = 300
    local tweenInfo = TweenInfo.new((hrp.Position - targetCFrame.Position).Magnitude / speed, Enum.EasingStyle.Linear)
    _G.ActiveTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    _G.ActiveTween:Play()
    _G.ActiveTween.Completed:Wait()
end

-- 自動農場主迴圈
task.spawn(function()
    while task.wait(0.1) do 
        if _G.AhKai_Controls.AutoFarm then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart
                
                local targetConfig = MatchCurrentQuest()
                if not targetConfig then return end
                
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.ToolTip == _G.AhKai_Controls.Weapon then
                        char.Humanoid:EquipTool(tool)
                    end
                end
                
                local questGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Quest")
                if not (questGui and questGui.Visible) then
                    BypassTeleport(targetConfig.NPC_Pos)
                    task.wait(0.3)
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", targetConfig.Quest_Name, targetConfig.Quest_Level)
                else
                    local enemyFolder = workspace:FindFirstChild("Enemies") or workspace
                    local hasTarget = false
                    
                    for _, mob in ipairs(enemyFolder:GetChildren()) do
                        if mob.Name == targetConfig.Mob_Name and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            hasTarget = true
                            -- 鎖定怪物正上方 6 格
                            hrp.CFrame = CFrame.new(mob.HumanoidRootPart.Position + Vector3.new(0, 6, 0), mob.HumanoidRootPart.Position)
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(0, 0))
                            break
                        end
                    end
                    
                    if not hasTarget then
                        BypassTeleport(targetConfig.Mob_Pos * CFrame.new(0, 50, 0))
                    end
                end
            end)
        else
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local float = char.HumanoidRootPart:FindFirstChild("AhKaiFloat")
                if float then float:Destroy() end
            end
        end
    end
end)

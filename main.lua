--[[
    WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local MIN_TIME = 10000
local MAX_TIME = 300000000
local ENABLED = false
local BIG_HITBOX = Vector3.new(12, 12, 12)
local NORMAL_HITBOX = Vector3.new(2, 2, 2)
local SAFE_HEALTH = 30
local ATTACK_DELAY = 0.25 + math.random() * 0.15

local terrainSpawn = Workspace:WaitForChild("Terrain"):WaitForChild("Spawn")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

-- Xeno Executor compatibility
if getgenv().UltraHunterLoaded then
    print("Ultra Hunter already loaded on Xeno!")
    return
end
getgenv().UltraHunterLoaded = true

-- Xeno үшін auto rejoin (queue_on_teleport кейде істемейді)
if syn and syn.queue_on_teleport then
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Started then
            syn.queue_on_teleport([[ 
                loadstring(game:HttpGet("https://pastebin.com/raw/UCT2bJHK"))() 
            ]])
        end
    end)
    print("Xeno auto-rejoin enabled with syn.queue_on_teleport")
elseif queue_on_teleport then
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Started then
            queue_on_teleport([[ 
                loadstring(game:HttpGet("https://pastebin.com/raw/YOUR_PASTE_HERE"))() 
            ]])
        end
    end)
    print("Xeno auto-rejoin enabled")
else
    print("Xeno: Auto-rejoin қосу үшін scriptті autoexec қалтасына салыңыз немесе executor-дың auto execute опциясын қолданыңыз.")
end

print("Ultra Hunter loaded on Xeno Executor!")

-- GUI (қалғаны өзгермеді)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltraHunterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 190)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local function makeDraggable(frame)
    local dragging, dragInput, mousePos, framePos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            mainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(mainFrame)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleButton.Text = "ULTRA HUNTER: OFF"
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16
toggleButton.Parent = mainFrame
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

local minBox = Instance.new("TextBox")
minBox.Size = UDim2.new(0.45, -5, 0, 30)
minBox.Position = UDim2.new(0, 10, 0, 70)
minBox.PlaceholderText = "Min Time"
minBox.Text = tostring(MIN_TIME)
minBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
minBox.TextColor3 = Color3.new(1,1,1)
minBox.Parent = mainFrame
Instance.new("UICorner", minBox).CornerRadius = UDim.new(0, 4)

local maxBox = Instance.new("TextBox")
maxBox.Size = UDim2.new(0.45, -5, 0, 30)
maxBox.Position = UDim2.new(0.55, -5, 0, 70)
maxBox.PlaceholderText = "Max Time"
maxBox.Text = tostring(MAX_TIME)
maxBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
maxBox.TextColor3 = Color3.new(1,1,1)
maxBox.Parent = mainFrame
Instance.new("UICorner", maxBox).CornerRadius = UDim.new(0, 4)

toggleButton.MouseButton1Click:Connect(function()
    ENABLED = not ENABLED
    if ENABLED then
        toggleButton.Text = "ULTRA HUNTER: ACTIVE"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        toggleButton.Text = "ULTRA HUNTER: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

minBox.FocusLost:Connect(function() MIN_TIME = tonumber(minBox.Text) or 2000 end)
maxBox.FocusLost:Connect(function() MAX_TIME = tonumber(maxBox.Text) or 300000000 end)

local function returnToOriginal(CFramePos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not (root and hum and CFramePos) then return end
    
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(0.15 + math.random()*0.1)
    
    root.CFrame = CFramePos
    task.wait(0.1)
    root.AssemblyLinearVelocity = Vector3.zero
    hum:ChangeState(Enum.HumanoidStateType.Running)
    
    task.delay(0.4, function()
        if hum and root then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

local function setHitbox(targetChar, size)
    local root = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if root then
        root.Size = size
        root.Transparency = (size == NORMAL_HITBOX) and 0 or 0.6
        root.CanCollide = false
    end
end

local function isInPvpArea(targetChar)
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    overlapParams.FilterDescendantsInstances = {targetChar, LocalPlayer.Character}
    local parts = Workspace:GetPartBoundsInBox(root.CFrame, Vector3.new(1,10,1), overlapParams)
    for _, part in ipairs(parts) do
        if part:IsDescendantOf(terrainSpawn) then
            return false
        end
    end
    return true
end

task.spawn(function()
    while true do
        task.wait(0.05 + math.random()*0.03)
        if not ENABLED then continue end
        
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChild("Humanoid")
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not (myChar and myHum and myRoot and myHum.Health > SAFE_HEALTH) then continue end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local targetChar = player.Character
            local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            local leaderstats = player:FindFirstChild("leaderstats")
            local timeStat = leaderstats and leaderstats:FindFirstChild("Time")
            
            if targetRoot and targetHum and targetHum.Health > 0 and timeStat then
                if timeStat.Value >= MIN_TIME and timeStat.Value <= MAX_TIME and isInPvpArea(targetChar) then
                    local originalCFrame = myRoot.CFrame
                    
                    setHitbox(targetChar, BIG_HITBOX)
                    local lastAttack = 0
                    
                    repeat
                        task.wait(0.03 + math.random()*0.04)
                        if not (ENABLED and targetHum.Health > 0 and myHum.Health > SAFE_HEALTH) then break end
                        
                        local targetPos = targetRoot.Position + targetRoot.CFrame.LookVector * -3 + Vector3.new(0, 3.5, 0)
                        local lookCFrame = CFrame.lookAt(targetPos, targetRoot.Position)
                        myRoot.CFrame = myRoot.CFrame:Lerp(lookCFrame, 0.75 + math.random()*0.15)
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        myHum:ChangeState(Enum.HumanoidStateType.Physics)
                        
                        local tool = myChar:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                        if tool then
                            if tool.Parent ~= myChar then
                                tool.Parent = myChar
                                task.wait(0.1)
                            end
                            if tick() - lastAttack > ATTACK_DELAY then
                                tool:Activate()
                                lastAttack = tick()
                            end
                        end
                    until not targetHum or targetHum.Health <= 0 or not ENABLED
                    
                    setHitbox(targetChar, NORMAL_HITBOX)
                    task.wait(0.5 + math.random()*0.3)
                    returnToOriginal(originalCFrame)
                    task.wait(1.2 + math.random()*0.8)
                    break
                end
            end
        end
    end
end)

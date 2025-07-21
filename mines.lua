--[[
    Author: Buffer_0verflow
]]

-- Main table to encapsulate the entire script
local MinesCheats = {}
MinesCheats.Name = "Mines - 0verflow Hub"
MinesCheats.Version = "1.0.0"
MinesCheats.Author = "Buffer_0verflow"

--// SERVICES //--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// LOCAL PLAYER //--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// CONFIGURATION //--
MinesCheats.Config = {
    OreTeleportDistance = 5,
    FlySpeed = 50,
    NoClipBypassRange = 10, -- Range to temporarily disable noclip near ores
    AutoNoClipBypass = true, -- Automatically disable noclip near ores
}

--// STATE //--
MinesCheats.State = {
    FlyBodyVelocity = nil,
    FlyGyro = nil,
    FlyLoopConnection = nil,
    NoClipConnection = nil,
    NoClipBypassConnection = nil,
    EnabledFlags = {},
    IsNearOre = false,
    KeyBindConnection = nil,
    ESPTable = {},
    ESPUpdateConnection = nil,
    ESPChildAddedConnection = nil,
    ESPChildRemovedConnection = nil,
    AutoCollectConnection = nil,
}

--// CORE MODULES //--
MinesCheats.Modules = {}

--// NOTIFICATIONS MODULE //--
MinesCheats.Modules.Notifications = {}
MinesCheats.Modules.Notifications.NotificationHolder = nil
MinesCheats.Modules.Notifications.TemplateFrame = nil
MinesCheats.Modules.Notifications.NotificationTypes = {
    INFO = {Color = Color3.fromRGB(52, 152, 219), Icon = "ℹ️"},
    SUCCESS = {Color = Color3.fromRGB(46, 204, 113), Icon = "✅"},
    WARNING = {Color = Color3.fromRGB(241, 196, 15), Icon = "⚠️"},
    ERROR = {Color = Color3.fromRGB(231, 76, 60), Icon = "❌"},
}

function MinesCheats.Modules.Notifications:Initialize()
    local holder = Instance.new("ScreenGui")
    holder.Name = "MinesCheatNotificationHolder"
    holder.ZIndexBehavior = Enum.ZIndexBehavior.Global
    holder.DisplayOrder = 99999
    holder.ResetOnSpawn = false
    holder.Parent = PlayerGui

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = holder
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    
    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = holder

    -- Main notification frame
    local template = Instance.new("Frame")
    template.Name = "NotificationTemplate"
    template.Size = UDim2.new(0, 280, 0, 50)
    template.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    template.BackgroundTransparency = 0.1
    template.ClipsDescendants = true
    template.Parent = nil

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = template

    -- Accent bar
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 5, 1, 0)
    accent.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    accent.BorderSizePixel = 0
    accent.Parent = template

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 30, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.TextSize = 24
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Text = "ℹ️"
    iconLabel.Parent = template

    -- Message Text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Message"
    textLabel.Size = UDim2.new(1, -50, 1, -10)
    textLabel.Position = UDim2.new(0, 45, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 16
    textLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = template

    self.TemplateFrame = template
    self.NotificationHolder = holder
end

function MinesCheats.Modules.Notifications:Show(message, duration, notifType)
    duration = duration or 3
    notifType = self.NotificationTypes[notifType] or self.NotificationTypes.INFO

    local notification = self.TemplateFrame:Clone()
    notification.Message.Text = message
    notification.Icon.Text = notifType.Icon
    notification.Accent.BackgroundColor3 = notifType.Color
    notification.Parent = self.NotificationHolder
    notification.LayoutOrder = tick()

    local startPos = UDim2.new(1, 0, 1, 0)
    local endPos = UDim2.new(0, 0, 1, 0)
    notification.Position = startPos
    
    local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    
    local slideIn = TweenService:Create(notification, tweenInfo, {Position = endPos})
    slideIn:Play()

    task.delay(duration, function()
        local slideOut = TweenService:Create(notification, tweenInfo, {Position = startPos})
        slideOut:Play()
        slideOut.Completed:Wait()
        notification:Destroy()
    end)
end

--// UI Library //--
MinesCheats.Modules.UI = {}
function MinesCheats.Modules.UI:Initialize()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    self.Window = Rayfield:CreateWindow({
        Name = "Mines - 0verflow Hub",
        LoadingTitle = "Loading 0verflow Hub...",
        LoadingSubtitle = "by " .. MinesCheats.Author,
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = "MinesCheatConfig"
        },
        Discord = {
            Enabled = true,
            Invite = "wjpTXW6nAR",
            RememberJoins = true
        },
        KeySystem = false
    })
end

--// DATA MODULE //--
MinesCheats.Modules.Data = {}

--// ACTIONS MODULE //--
MinesCheats.Modules.Actions = {}
function MinesCheats.Modules.Actions.TeleportAllOresToPlayer()
    local player = LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local itemsFolder = Workspace:WaitForChild("Items")
    
    -- Set simulation radius to claim network ownership
    pcall(function()
        sethiddenproperty(player, "MaximumSimulationRadius", 1e9)
        sethiddenproperty(player, "SimulationRadius", 1e9)
    end)
    
    local oreCount = 0
    
    for _, item in ipairs(itemsFolder:GetChildren()) do
        local parts = {}
        
        if item:IsA("Model") then
            for _, desc in ipairs(item:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Anchored = false
                    table.insert(parts, desc)
                end
            end
        elseif item:IsA("BasePart") then
            item.Anchored = false
            table.insert(parts, item)
        end
        
        -- Use BodyPosition to physically move each part to in front of the player
        local targetPos = (hrp.CFrame * CFrame.new(0, 0, -MinesCheats.Config.OreTeleportDistance)).Position
        
        for _, part in ipairs(parts) do
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bp.Position = targetPos
            bp.Parent = part
            
            -- Optional: Add BodyGyro to maintain orientation
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.CFrame = part.CFrame
            bg.Parent = part
            
            oreCount = oreCount + 1
        end
    end
    
    MinesCheats.Modules.Notifications:Show("Teleported " .. oreCount .. " ore parts to player!", 3, "SUCCESS")
end

function MinesCheats.Modules.Actions.ClearTeleportedOres()
    local itemsFolder = Workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in ipairs(itemsFolder:GetChildren()) do
            local parts = {}
            
            if item:IsA("Model") then
                for _, desc in ipairs(item:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        table.insert(parts, desc)
                    end
                end
            elseif item:IsA("BasePart") then
                table.insert(parts, item)
            end
            
            for _, part in ipairs(parts) do
                -- Remove BodyPosition and BodyGyro
                local bp = part:FindFirstChild("BodyPosition")
                local bg = part:FindFirstChild("BodyGyro")
                if bp then bp:Destroy() end
                if bg then bg:Destroy() end
                part.Anchored = true
            end
        end
    end
    MinesCheats.Modules.Notifications:Show("Cleared all teleported ores!", 3, "INFO")
end

function MinesCheats.Modules.Actions.CollectAllItems()
    local success, CollectItem = pcall(function()
        return ReplicatedStorage["shared/network/MiningNetwork@GlobalMiningEvents"].CollectItem
    end)
    
    if not success or not CollectItem then
        MinesCheats.Modules.Notifications:Show("Could not find CollectItem remote", 3, "ERROR")
        return
    end
    
    local itemsFolder = Workspace:FindFirstChild("Items")
    if not itemsFolder then
        MinesCheats.Modules.Notifications:Show("Items folder not found", 3, "ERROR")
        return
    end
    
    local collectedCount = 0
    for _, item in ipairs(itemsFolder:GetChildren()) do
        local success = pcall(function()
            CollectItem:FireServer(item.Name)
            collectedCount = collectedCount + 1
        end)
        
        if not success then
            MinesCheats.Modules.Notifications:Show("Failed to collect: " .. item.Name, 3, "WARNING")
        end
        
        task.wait(0.1) -- Small delay to avoid rate limiting
    end
    
    MinesCheats.Modules.Notifications:Show("Collected " .. collectedCount .. " items!", 3, "SUCCESS")
end

function MinesCheats.Modules.Actions:SetAutoCollect(enabled)
    MinesCheats.State.EnabledFlags["AutoCollect"] = enabled
    
    if enabled then
        MinesCheats.State.AutoCollectConnection = RunService.Heartbeat:Connect(function()
            local success, CollectItem = pcall(function()
                return ReplicatedStorage["shared/network/MiningNetwork@GlobalMiningEvents"].CollectItem
            end)
            
            if success and CollectItem then
                local itemsFolder = Workspace:FindFirstChild("Items")
                if itemsFolder then
                    for _, item in ipairs(itemsFolder:GetChildren()) do
                        pcall(function()
                            CollectItem:FireServer(item.Name)
                        end)
                    end
                end
            end
        end)
        
        MinesCheats.Modules.Notifications:Show("Auto collect enabled", 3, "SUCCESS")
    else
        if MinesCheats.State.AutoCollectConnection then
            MinesCheats.State.AutoCollectConnection:Disconnect()
            MinesCheats.State.AutoCollectConnection = nil
        end
        
        MinesCheats.Modules.Notifications:Show("Auto collect disabled", 3, "INFO")
    end
end

--// MOVEMENT MODULE //--
MinesCheats.Modules.Movement = {}
function MinesCheats.Modules.Movement:EnableFly()
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    MinesCheats.State.FlyBodyVelocity = Instance.new("BodyVelocity")
    MinesCheats.State.FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    MinesCheats.State.FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    MinesCheats.State.FlyBodyVelocity.Parent = root

    MinesCheats.State.FlyGyro = Instance.new("BodyGyro")
    MinesCheats.State.FlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    MinesCheats.State.FlyGyro.P = 20000
    MinesCheats.State.FlyGyro.Parent = root

    MinesCheats.State.FlyLoopConnection = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        if MinesCheats.State.FlyGyro then
            MinesCheats.State.FlyGyro.CFrame = cam.CFrame
        end
        local velocity = Vector3.new(0, 0, 0)
        local flySpeed = MinesCheats.Config.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + (cam.CFrame.LookVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - (cam.CFrame.LookVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - (cam.CFrame.RightVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + (cam.CFrame.RightVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, flySpeed, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity = velocity - Vector3.new(0, flySpeed, 0) end
        if MinesCheats.State.FlyBodyVelocity then
            MinesCheats.State.FlyBodyVelocity.Velocity = velocity
        end
    end)
end

function MinesCheats.Modules.Movement:DisableFly()
    if MinesCheats.State.FlyLoopConnection then
        MinesCheats.State.FlyLoopConnection:Disconnect()
        MinesCheats.State.FlyLoopConnection = nil
    end
    if MinesCheats.State.FlyBodyVelocity then
        MinesCheats.State.FlyBodyVelocity:Destroy()
        MinesCheats.State.FlyBodyVelocity = nil
    end
    if MinesCheats.State.FlyGyro then
        MinesCheats.State.FlyGyro:Destroy()
        MinesCheats.State.FlyGyro = nil
    end
end

function MinesCheats.Modules.Movement:SetFly(enabled)
    MinesCheats.State.EnabledFlags["FlyHack"] = enabled
    if enabled then
        self:EnableFly()
        MinesCheats.Modules.Notifications:Show("Fly enabled! Use WASD + Space/Ctrl", 3, "SUCCESS")
    else
        self:DisableFly()
        MinesCheats.Modules.Notifications:Show("Fly disabled", 3, "INFO")
    end
end

function MinesCheats.Modules.Movement:SetNoClip(enabled)
    MinesCheats.State.EnabledFlags["NoClip"] = enabled
    if enabled then
        -- Set up noclip with bypass system
        MinesCheats.State.NoClipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                local shouldBypass = false
                
                -- Check if auto bypass is enabled and we're near ores
                if MinesCheats.Config.AutoNoClipBypass and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
                    local itemsFolder = Workspace:FindFirstChild("Items")
                    
                    if itemsFolder then
                        for _, item in ipairs(itemsFolder:GetChildren()) do
                            local orePos
                            if item:IsA("Model") and item:FindFirstChild("HumanoidRootPart") then
                                orePos = item.HumanoidRootPart.Position
                            elseif item:IsA("BasePart") then
                                orePos = item.Position
                            end
                            
                            if orePos and (playerPos - orePos).Magnitude <= MinesCheats.Config.NoClipBypassRange then
                                shouldBypass = true
                                if not MinesCheats.State.IsNearOre then
                                    MinesCheats.State.IsNearOre = true
                                    MinesCheats.Modules.Notifications:Show("Near ore - NoClip temporarily disabled", 2, "WARNING")
                                end
                                break
                            end
                        end
                    end
                    
                    if not shouldBypass and MinesCheats.State.IsNearOre then
                        MinesCheats.State.IsNearOre = false
                        MinesCheats.Modules.Notifications:Show("NoClip re-enabled", 2, "INFO")
                    end
                end
                
                -- Apply noclip unless bypassed
                if not shouldBypass then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
        
        -- Set up keybind to toggle noclip quickly (X key)
        MinesCheats.State.KeyBindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.X then
                local currentState = MinesCheats.State.EnabledFlags["NoClip"]
                MinesCheats.Modules.Movement:SetNoClip(not currentState)
            end
        end)
        
        MinesCheats.Modules.Notifications:Show("NoClip enabled (Press X to toggle quickly)", 3, "SUCCESS")
    else
        if MinesCheats.State.NoClipConnection then
            MinesCheats.State.NoClipConnection:Disconnect()
            MinesCheats.State.NoClipConnection = nil
        end
        if MinesCheats.State.KeyBindConnection then
            MinesCheats.State.KeyBindConnection:Disconnect()
            MinesCheats.State.KeyBindConnection = nil
        end
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        MinesCheats.State.IsNearOre = false
        MinesCheats.Modules.Notifications:Show("NoClip disabled", 3, "INFO")
    end
end

--// ESP MODULE //--
MinesCheats.Modules.ESP = {}

function MinesCheats.Modules.ESP.GetPrimaryPart(item)
    if item:IsA("BasePart") then
        return item
    elseif item:IsA("Model") and item.PrimaryPart then
        return item.PrimaryPart
    elseif item:IsA("Model") then
        -- Find any BasePart descendant as fallback
        return item:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

function MinesCheats.Modules.ESP.CreateESP(item)
    if MinesCheats.State.ESPTable[item] or not MinesCheats.Modules.ESP.GetPrimaryPart(item) then return end
    
    local bb = Instance.new("BillboardGui")
    bb.Name = "OreESP"
    bb.Adornee = MinesCheats.Modules.ESP.GetPrimaryPart(item)
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 5, 0)  -- Above the item
    bb.MaxDistance = 2000
    bb.Parent = item  -- Client-side parent, visible only to you
    
    local frame = Instance.new("Frame", bb)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    
    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0.5
    text.TextSize = 18
    text.Font = Enum.Font.SourceSansBold
    
    -- Extract ore name, e.g., "Coal Ore" from full name
    local oreName = item.Name:match("^(.-Ore)") or item.Name
    text.Text = oreName
    
    -- Optional: Add a box around the item using SelectionBox
    local box = Instance.new("SelectionBox")
    box.Name = "OreBox"
    box.Adornee = item
    box.LineThickness = 0.05
    box.Color = BrickColor.new("Bright green")
    box.Transparency = 0
    box.Parent = item  -- Client-side
    
    MinesCheats.State.ESPTable[item] = {gui = bb, box = box}
end

function MinesCheats.Modules.ESP.DestroyESP(item)
    local esp = MinesCheats.State.ESPTable[item]
    if esp then
        esp.gui:Destroy()
        esp.box:Destroy()
        MinesCheats.State.ESPTable[item] = nil
    end
end

function MinesCheats.Modules.ESP.UpdateESP()
    for item, esp in pairs(MinesCheats.State.ESPTable) do
        if not item.Parent then
            MinesCheats.Modules.ESP.DestroyESP(item)
        end
    end
end

function MinesCheats.Modules.ESP:SetOreESP(enabled)
    MinesCheats.State.EnabledFlags["OreESP"] = enabled
    
    if enabled then
        local itemsFolder = Workspace:FindFirstChild("Items")
        if itemsFolder then
            -- Initial scan
            for _, item in ipairs(itemsFolder:GetChildren()) do
                MinesCheats.Modules.ESP.CreateESP(item)
            end
            
            -- Continuous scanning
            MinesCheats.State.ESPChildAddedConnection = itemsFolder.ChildAdded:Connect(MinesCheats.Modules.ESP.CreateESP)
            MinesCheats.State.ESPChildRemovedConnection = itemsFolder.ChildRemoved:Connect(MinesCheats.Modules.ESP.DestroyESP)
            
            -- Update loop
            MinesCheats.State.ESPUpdateConnection = RunService.RenderStepped:Connect(MinesCheats.Modules.ESP.UpdateESP)
            
            MinesCheats.Modules.Notifications:Show("Ore ESP enabled", 3, "SUCCESS")
        else
            MinesCheats.Modules.Notifications:Show("Items folder not found", 3, "ERROR")
        end
    else
        -- Clean up all ESP
        for item, esp in pairs(MinesCheats.State.ESPTable) do
            esp.gui:Destroy()
            esp.box:Destroy()
        end
        MinesCheats.State.ESPTable = {}
        
        -- Disconnect connections
        if MinesCheats.State.ESPChildAddedConnection then
            MinesCheats.State.ESPChildAddedConnection:Disconnect()
            MinesCheats.State.ESPChildAddedConnection = nil
        end
        if MinesCheats.State.ESPChildRemovedConnection then
            MinesCheats.State.ESPChildRemovedConnection:Disconnect()
            MinesCheats.State.ESPChildRemovedConnection = nil
        end
        if MinesCheats.State.ESPUpdateConnection then
            MinesCheats.State.ESPUpdateConnection:Disconnect()
            MinesCheats.State.ESPUpdateConnection = nil
        end
        
        MinesCheats.Modules.Notifications:Show("Ore ESP disabled", 3, "INFO")
    end
end

--// MAIN SCRIPT LOGIC //--
function MinesCheats:Initialize()
    self.Modules.UI:Initialize()
    self.Modules.Notifications:Initialize()
    self:CreateTabs()
end

function MinesCheats:CreateTabs()
    local window = self.Modules.UI.Window
    self:CreateHomeTab(window)
    self:CreateMiningTab(window)
    self:CreateMovementTab(window)
    self:CreateVisualsTab(window)
end

function MinesCheats:CreateHomeTab(window)
    local homeTab = window:CreateTab("Home", nil)
    homeTab:CreateParagraph({Title = "Welcome to 0verflow Hub!", Content = "This hub provides various features to enhance your mining experience."})
    homeTab:CreateParagraph({Title = "Features", Content = "• Teleport ores to player\n• Collect all items\n• Auto collect items\n• Fly and NoClip movement hacks\n• Ore ESP for better visibility"})
    homeTab:CreateButton({
        Name = "Join our Discord!",
        Callback = function()
            local url = "https://discord.gg/wjpTXW6nAR"
            pcall(function()
                game:GetService("GuiService"):OpenBrowserWindow(url)
            end)
            MinesCheats.Modules.Notifications:Show("Opening Discord invite...", 3, "INFO")
        end,
    })
end

function MinesCheats:CreateMiningTab(window)
    local miningTab = window:CreateTab("Mining", nil)
    
    miningTab:CreateButton({
        Name = "🔥 Teleport All Ores to Player",
        Callback = function()
            MinesCheats.Modules.Actions.TeleportAllOresToPlayer()
        end,
    })
    
    miningTab:CreateButton({
        Name = "📦 Collect All Items",
        Callback = function()
            MinesCheats.Modules.Actions.CollectAllItems()
        end,
    })
    
    miningTab:CreateToggle({
        Name = "🔄 Auto Collect Items",
        CurrentValue = false,
        Flag = "AutoCollectToggle",
        Callback = function(value)
            MinesCheats.Modules.Actions:SetAutoCollect(value)
        end,
    })
    
    miningTab:CreateButton({
        Name = "🧹 Clear Teleported Ores",
        Callback = function()
            MinesCheats.Modules.Actions.ClearTeleportedOres()
        end,
    })
    
    miningTab:CreateSlider({
        Name = "Ore Teleport Distance",
        Range = {3, 20},
        Increment = 1,
        Suffix = " studs",
        CurrentValue = MinesCheats.Config.OreTeleportDistance,
        Flag = "OreTeleportDistance",
        Callback = function(value)
            MinesCheats.Config.OreTeleportDistance = value
        end,
    })
end

function MinesCheats:CreateMovementTab(window)
    local movementTab = window:CreateTab("Movement", nil)
    
    movementTab:CreateToggle({
        Name = "🚁 Fly",
        CurrentValue = false,
        Flag = "FlyToggle",
        Callback = function(value)
            MinesCheats.Modules.Movement:SetFly(value)
        end,
    })
    
    movementTab:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 150},
        Increment = 5,
        Suffix = " Speed",
        CurrentValue = MinesCheats.Config.FlySpeed,
        Flag = "FlySpeedSlider",
        Callback = function(value)
            MinesCheats.Config.FlySpeed = value
        end,
    })
    
    movementTab:CreateToggle({
        Name = "👻 NoClip",
        CurrentValue = false,
        Flag = "NoClipToggle",
        Callback = function(value)
            MinesCheats.Modules.Movement:SetNoClip(value)
        end,
    })
    
    movementTab:CreateToggle({
        Name = "🔧 Auto NoClip Bypass",
        CurrentValue = MinesCheats.Config.AutoNoClipBypass,
        Flag = "AutoBypassToggle",
        Callback = function(value)
            MinesCheats.Config.AutoNoClipBypass = value
            if value then
                MinesCheats.Modules.Notifications:Show("Auto bypass enabled - NoClip will disable near ores", 3, "SUCCESS")
            else
                MinesCheats.Modules.Notifications:Show("Auto bypass disabled", 3, "INFO")
            end
        end,
    })
    
    movementTab:CreateSlider({
        Name = "Bypass Range",
        Range = {5, 25},
        Increment = 1,
        Suffix = " studs",
        CurrentValue = MinesCheats.Config.NoClipBypassRange,
        Flag = "BypassRangeSlider",
        Callback = function(value)
            MinesCheats.Config.NoClipBypassRange = value
        end,
    })
    
    movementTab:CreateParagraph({Title = "Controls", Content = "Fly: WASD to move, Space to go up, Ctrl to go down\nNoClip: Walk through walls and terrain\nPress X to quickly toggle NoClip on/off"})
end

function MinesCheats:CreateVisualsTab(window)
    local visualsTab = window:CreateTab("Visuals", nil)
    
    visualsTab:CreateToggle({
        Name = "👁️ Ore ESP",
        CurrentValue = false,
        Flag = "OreESPToggle",
        Callback = function(value)
            MinesCheats.Modules.ESP:SetOreESP(value)
        end,
    })
    
    visualsTab:CreateParagraph({Title = "Ore ESP Features", Content = "• Shows ore names above each ore\n• Green selection boxes around ores\n• Visible through walls up to 2000 studs\n• Automatically updates when ores spawn/despawn"})
end

--// INITIALIZE SCRIPT //--
MinesCheats:Initialize()

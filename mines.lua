--[[
    Mines - 0verflow Hub
    Advanced mining script with ore teleportation, auto collection, and ESP
    
    Author: buffer_0verflow
    Date: 2025-08-10
    Version: 2.0.0
    Time: 15:10:01 UTC
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Core Variables
local MinesExploit = {
    Active = false,
    OreTeleportDistance = 5,
    FlySpeed = 50,
    NoClipBypassRange = 10,
    AutoNoClipBypass = true,
    Toggles = {}
}

-- State Management
local State = {
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

-- ========================================
-- ORE COLLECTION SYSTEM
-- ========================================

local function TeleportAllOresToPlayer()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local itemsFolder = Workspace:WaitForChild("Items")
    
    -- Set simulation radius
    pcall(function()
        sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", 1e9)
        sethiddenproperty(LocalPlayer, "SimulationRadius", 1e9)
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
        
        local targetPos = (hrp.CFrame * CFrame.new(0, 0, -MinesExploit.OreTeleportDistance)).Position
        
        for _, part in ipairs(parts) do
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bp.Position = targetPos
            bp.Parent = part
            
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.CFrame = part.CFrame
            bg.Parent = part
            
            oreCount = oreCount + 1
        end
    end
    
    return oreCount
end

local function ClearTeleportedOres()
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
                local bp = part:FindFirstChild("BodyPosition")
                local bg = part:FindFirstChild("BodyGyro")
                if bp then bp:Destroy() end
                if bg then bg:Destroy() end
                part.Anchored = true
            end
        end
    end
end

local function CollectAllItems()
    local success, CollectItem = pcall(function()
        return ReplicatedStorage["shared/network/MiningNetwork@GlobalMiningEvents"].CollectItem
    end)
    
    if not success or not CollectItem then
        return false, 0
    end
    
    local itemsFolder = Workspace:FindFirstChild("Items")
    if not itemsFolder then
        return false, 0
    end
    
    local collectedCount = 0
    for _, item in ipairs(itemsFolder:GetChildren()) do
        local success = pcall(function()
            CollectItem:FireServer(item.Name)
            collectedCount = collectedCount + 1
        end)
        
        task.wait(0.1)
    end
    
    return true, collectedCount
end

local function StartAutoCollect()
    State.AutoCollectConnection = RunService.Heartbeat:Connect(function()
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
end

local function StopAutoCollect()
    if State.AutoCollectConnection then
        State.AutoCollectConnection:Disconnect()
        State.AutoCollectConnection = nil
    end
end

-- ========================================
-- MOVEMENT SYSTEM
-- ========================================

local function EnableFly()
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    State.FlyBodyVelocity = Instance.new("BodyVelocity")
    State.FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    State.FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    State.FlyBodyVelocity.Parent = root

    State.FlyGyro = Instance.new("BodyGyro")
    State.FlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    State.FlyGyro.P = 20000
    State.FlyGyro.Parent = root

    State.FlyLoopConnection = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        if State.FlyGyro then
            State.FlyGyro.CFrame = cam.CFrame
        end
        local velocity = Vector3.new(0, 0, 0)
        local flySpeed = MinesExploit.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + (cam.CFrame.LookVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - (cam.CFrame.LookVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - (cam.CFrame.RightVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + (cam.CFrame.RightVector * flySpeed) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, flySpeed, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity = velocity - Vector3.new(0, flySpeed, 0) end
        if State.FlyBodyVelocity then
            State.FlyBodyVelocity.Velocity = velocity
        end
    end)
end

local function DisableFly()
    if State.FlyLoopConnection then
        State.FlyLoopConnection:Disconnect()
        State.FlyLoopConnection = nil
    end
    if State.FlyBodyVelocity then
        State.FlyBodyVelocity:Destroy()
        State.FlyBodyVelocity = nil
    end
    if State.FlyGyro then
        State.FlyGyro:Destroy()
        State.FlyGyro = nil
    end
end

local function EnableNoClip()
    State.NoClipConnection = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            local shouldBypass = false
            
            if MinesExploit.AutoNoClipBypass and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
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
                        
                        if orePos and (playerPos - orePos).Magnitude <= MinesExploit.NoClipBypassRange then
                            shouldBypass = true
                            State.IsNearOre = true
                            break
                        end
                    end
                end
                
                if not shouldBypass and State.IsNearOre then
                    State.IsNearOre = false
                end
            end
            
            if not shouldBypass then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
    
    State.KeyBindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.X then
            if MinesExploit.Toggles.NoClip then
                MinesExploit.Toggles.NoClip:Set(not State.EnabledFlags["NoClip"])
            end
        end
    end)
end

local function DisableNoClip()
    if State.NoClipConnection then
        State.NoClipConnection:Disconnect()
        State.NoClipConnection = nil
    end
    if State.KeyBindConnection then
        State.KeyBindConnection:Disconnect()
        State.KeyBindConnection = nil
    end
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    State.IsNearOre = false
end

-- ========================================
-- ESP SYSTEM
-- ========================================

local function GetPrimaryPart(item)
    if item:IsA("BasePart") then
        return item
    elseif item:IsA("Model") and item.PrimaryPart then
        return item.PrimaryPart
    elseif item:IsA("Model") then
        return item:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function CreateESP(item)
    if State.ESPTable[item] or not GetPrimaryPart(item) then return end
    
    local bb = Instance.new("BillboardGui")
    bb.Name = "OreESP"
    bb.Adornee = GetPrimaryPart(item)
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.MaxDistance = 2000
    bb.Parent = item
    
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
    
    local oreName = item.Name:match("^(.-Ore)") or item.Name
    text.Text = oreName
    
    local box = Instance.new("SelectionBox")
    box.Name = "OreBox"
    box.Adornee = item
    box.LineThickness = 0.05
    box.Color = BrickColor.new("Bright green")
    box.Transparency = 0
    box.Parent = item
    
    State.ESPTable[item] = {gui = bb, box = box}
end

local function DestroyESP(item)
    local esp = State.ESPTable[item]
    if esp then
        esp.gui:Destroy()
        esp.box:Destroy()
        State.ESPTable[item] = nil
    end
end

local function UpdateESP()
    for item, esp in pairs(State.ESPTable) do
        if not item.Parent then
            DestroyESP(item)
        end
    end
end

local function EnableESP()
    local itemsFolder = Workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in ipairs(itemsFolder:GetChildren()) do
            CreateESP(item)
        end
        
        State.ESPChildAddedConnection = itemsFolder.ChildAdded:Connect(CreateESP)
        State.ESPChildRemovedConnection = itemsFolder.ChildRemoved:Connect(DestroyESP)
        State.ESPUpdateConnection = RunService.RenderStepped:Connect(UpdateESP)
    end
end

local function DisableESP()
    for item, esp in pairs(State.ESPTable) do
        esp.gui:Destroy()
        esp.box:Destroy()
    end
    State.ESPTable = {}
    
    if State.ESPChildAddedConnection then
        State.ESPChildAddedConnection:Disconnect()
        State.ESPChildAddedConnection = nil
    end
    if State.ESPChildRemovedConnection then
        State.ESPChildRemovedConnection:Disconnect()
        State.ESPChildRemovedConnection = nil
    end
    if State.ESPUpdateConnection then
        State.ESPUpdateConnection:Disconnect()
        State.ESPUpdateConnection = nil
    end
end

-- ========================================
-- UI CREATION
-- ========================================

local function CreateUI()
    -- Load 0verflow Hub UI
    local UILib = loadstring(game:HttpGet('https://raw.githubusercontent.com/pwd0kernel/0verflow/refs/heads/main/ui2.lua'))()
    local Window = UILib:CreateWindow("   Mines - 0verflow Hub")

    -- Mining Tab
    local MiningTab = Window:Tab("Mining")
    
    local CollectionSection = MiningTab:Section("Ore Collection")
    
    CollectionSection:Button("Teleport All Ores to Player", function()
        local count = TeleportAllOresToPlayer()
        Window:Notify("Teleported " .. count .. " ore parts!", 3)
    end)
    
    CollectionSection:Button("Collect All Items", function()
        local success, count = CollectAllItems()
        if success then
            Window:Notify("Collected " .. count .. " items!", 3)
        else
            Window:Notify("Failed to collect items", 3)
        end
    end)
    
    MinesExploit.Toggles.AutoCollect = CollectionSection:Toggle("Auto Collect Items", function(value)
        State.EnabledFlags["AutoCollect"] = value
        if value then
            StartAutoCollect()
            Window:Notify("Auto collect enabled", 2)
        else
            StopAutoCollect()
            Window:Notify("Auto collect disabled", 2)
        end
    end, {
        default = false,
        keybind = Enum.KeyCode.F1,
        color = Color3.fromRGB(100, 255, 100)
    })
    
    CollectionSection:Button("Clear Teleported Ores", function()
        ClearTeleportedOres()
        Window:Notify("Cleared all teleported ores", 2)
    end)
    
    local SettingsSection = MiningTab:Section("Settings")
    
    SettingsSection:Slider("Ore Teleport Distance", 3, 20, MinesExploit.OreTeleportDistance, function(value)
        MinesExploit.OreTeleportDistance = value
    end)
    
    -- Movement Tab
    local MovementTab = Window:Tab("Movement")
    
    local FlySection = MovementTab:Section("Fly System")
    
    MinesExploit.Toggles.Fly = FlySection:Toggle("Fly", function(value)
        State.EnabledFlags["Fly"] = value
        if value then
            EnableFly()
            Window:Notify("Fly enabled! Use WASD + Space/Ctrl", 3)
        else
            DisableFly()
            Window:Notify("Fly disabled", 2)
        end
    end, {
        default = false,
        keybind = Enum.KeyCode.F2,
        color = Color3.fromRGB(100, 200, 255)
    })
    
    FlySection:Slider("Fly Speed", 10, 150, MinesExploit.FlySpeed, function(value)
        MinesExploit.FlySpeed = value
    end)
    
    local NoClipSection = MovementTab:Section("NoClip System")
    
    MinesExploit.Toggles.NoClip = NoClipSection:Toggle("NoClip", function(value)
        State.EnabledFlags["NoClip"] = value
        if value then
            EnableNoClip()
            Window:Notify("NoClip enabled (Press X to toggle)", 3)
        else
            DisableNoClip()
            Window:Notify("NoClip disabled", 2)
        end
    end, {
        default = false,
        keybind = Enum.KeyCode.F3,
        color = Color3.fromRGB(255, 150, 50)
    })
    
    MinesExploit.Toggles.AutoBypass = NoClipSection:Toggle("Auto NoClip Bypass", function(value)
        MinesExploit.AutoNoClipBypass = value
        if value then
            Window:Notify("Auto bypass enabled - NoClip disables near ores", 3)
        else
            Window:Notify("Auto bypass disabled", 2)
        end
    end, {
        default = true,
        color = Color3.fromRGB(255, 200, 100)
    })
    
    NoClipSection:Slider("Bypass Range", 5, 25, MinesExploit.NoClipBypassRange, function(value)
        MinesExploit.NoClipBypassRange = value
    end)
    
    NoClipSection:Label("Controls: WASD to move, Space to go up, Ctrl to go down")
    NoClipSection:Label("Press X to quickly toggle NoClip on/off")
    
    -- Visuals Tab
    local VisualsTab = Window:Tab("Visuals")
    
    local ESPSection = VisualsTab:Section("ESP Features")
    
    MinesExploit.Toggles.OreESP = ESPSection:Toggle("Ore ESP", function(value)
        State.EnabledFlags["OreESP"] = value
        if value then
            EnableESP()
            Window:Notify("Ore ESP enabled", 2)
        else
            DisableESP()
            Window:Notify("Ore ESP disabled", 2)
        end
    end, {
        default = false,
        keybind = Enum.KeyCode.F4,
        color = Color3.fromRGB(255, 215, 0)
    })
    
    ESPSection:Label("• Shows ore names above each ore")
    ESPSection:Label("• Green selection boxes around ores")
    ESPSection:Label("• Visible through walls up to 2000 studs")
    ESPSection:Label("• Automatically updates when ores spawn/despawn")
    
    -- Info Tab
    local InfoTab = Window:Tab("Info")
    
    local InfoSection = InfoTab:Section("Script Information")
    
    InfoSection:Label("0verflow Hub - Mines Edition v2.0.0")
    InfoSection:Label("Author: buffer_0verflow")
    InfoSection:Label("Updated: 2025-08-10 15:10:01")
    InfoSection:Label("Features: Ore Collection + Movement + ESP")
    
    local ControlsSection = InfoTab:Section("Keybinds")
    
    ControlsSection:Label("F1 - Toggle Auto Collect")
    ControlsSection:Label("F2 - Toggle Fly")
    ControlsSection:Label("F3 - Toggle NoClip")
    ControlsSection:Label("F4 - Toggle Ore ESP")
    ControlsSection:Label("X - Quick Toggle NoClip")
    
    -- Discord Section
    local DiscordSection = InfoTab:Section("Community")
    
    DiscordSection:Button("Join Our Discord", function()
        pcall(function()
            setclipboard("https://discord.gg/QmRXz3n9HQ")
            Window:Notify("Discord invite copied! Paste in browser to join.", 4)
        end)
    end)
    
    DiscordSection:Label("Discord: discord.gg/QmRXz3n9HQ")
    DiscordSection:Label("Get support, updates, and community!")
    
    return Window
end

-- Initialize
local UI = CreateUI()

-- Notify user
UI:Notify("0verflow Hub - Mines Edition v2.0.0 Loaded", 3)

-- Auto-start if configured
if _G.AutoStartMining then
    if MinesExploit.Toggles.AutoCollect then
        MinesExploit.Toggles.AutoCollect:Set(true)
    end
end

-- Return API for external use
return {
    -- Collection Functions
    TeleportOres = TeleportAllOresToPlayer,
    CollectAll = CollectAllItems,
    StartAutoCollect = function()
        State.EnabledFlags["AutoCollect"] = true
        StartAutoCollect()
    end,
    StopAutoCollect = function()
        State.EnabledFlags["AutoCollect"] = false
        StopAutoCollect()
    end,
    -- Movement Functions
    StartFly = function()
        State.EnabledFlags["Fly"] = true
        EnableFly()
    end,
    StopFly = function()
        State.EnabledFlags["Fly"] = false
        DisableFly()
    end,
    StartNoClip = function()
        State.EnabledFlags["NoClip"] = true
        EnableNoClip()
    end,
    StopNoClip = function()
        State.EnabledFlags["NoClip"] = false
        DisableNoClip()
    end,
    -- ESP Functions
    StartESP = function()
        State.EnabledFlags["OreESP"] = true
        EnableESP()
    end,
    StopESP = function()
        State.EnabledFlags["OreESP"] = false
        DisableESP()
    end,
    -- Get current states
    GetStatus = function()
        return {
            autoCollect = State.EnabledFlags["AutoCollect"],
            fly = State.EnabledFlags["Fly"],
            noClip = State.EnabledFlags["NoClip"],
            esp = State.EnabledFlags["OreESP"],
            nearOre = State.IsNearOre
        }
    end
}

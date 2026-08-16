while not game.Players.LocalPlayer.Character
   or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Marines")
    task.wait(1)
end
status = function(a)
	print(a)
end
    Services = {}
    setmetatable(Services, {__index = function(J, J) return game:GetService(J) end})
    Remotes = {}
    local J = {}
    setmetatable(Remotes, {__index = function(W, W)
        if W ~= 'CommF_' then
            return Services.ReplicatedStorage.Remotes[W]
        end
        local W = {InvokeServer = function(a, ...)
            local a, h = ...
            return Services.ReplicatedStorage.Remotes.CommF_:InvokeServer(...)
        end}
        return W
    end})
    TDT = {Backpack = {}}
local ItemRepService, ItemRepModule, ItemRepKEYS, ItemConfigModule
local function EnsureItemRep()
    if ItemRepModule and ItemRepKEYS and ItemConfigModule then return true end
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        ItemRepService   = ItemRepService   or RS:WaitForChild("ItemReplicationService", 10)
        ItemRepModule    = ItemRepModule    or (ItemRepService and require(ItemRepService))
        ItemRepKEYS      = ItemRepKEYS      or (ItemRepService and require(ItemRepService.KEYS))
        ItemConfigModule = ItemConfigModule or require(RS:WaitForChild("ItemConfig", 10))
    end)
    return (ItemRepModule ~= nil) and (ItemRepKEYS ~= nil) and (ItemConfigModule ~= nil)
end

local function GetInventoryItems()
    local items = {}
    if not EnsureItemRep() then return items end
    local timeout = tick() + 5
    while ItemRepModule.IsInitialized ~= true and tick() < timeout do
        task.wait()
    end
    local ok, quantityItems = pcall(function()
        return ItemRepModule:GetItems(ItemRepKEYS.QUANTITY)
    end)
    if ok and quantityItems then
        for _, item in pairs(quantityItems) do
            if item.Value and item.Value > 0 then
                local nameOk, label = pcall(function()
                    return ItemConfigModule.match(item.ItemId):unwrap().Index.DebugLabel
                end)
                if nameOk and label then
                    local cleanName = label:gsub("%s*%[.-%]%s*$", "")
                    table.insert(items, {
                        Name   = cleanName,
                        Count  = item.Value,
                        ItemId = item.ItemId,
                    })
                end
            end
        end
    end
    return items
end
    function RefreshInventory()
        while true do
            local snapshot = {}
            for _, item in ipairs(GetInventoryItems()) do snapshot[item.Name] = item end
            TDT.Backpack = snapshot
            task.wait(1)
        end
    end
local function CheckItem(itemName)
    hasItem = false
    pcall(function()
        local inventory = GetInventoryItems()
        for _, item in pairs(inventory) do
            if item.Name == itemName then
                hasItem = true
                break
            end
        end
    end)
    return hasItem
end
LocalPlayer = game.Players.LocalPlayer

function GetSpawnFolder()
    local WorldOrigin = workspace:FindFirstChild("_WorldOrigin")
    local PlayerSpawns = WorldOrigin and WorldOrigin:FindFirstChild("PlayerSpawns")
    if not PlayerSpawns then return nil end
    local teamName = LocalPlayer.Team and LocalPlayer.Team.Name or "Pirates"
    return PlayerSpawns:FindFirstChild(teamName) or PlayerSpawns:FindFirstChild("Pirates") or PlayerSpawns:FindFirstChild("Marines")
end

function InArea(pos)
    local WorldOrigin = workspace:FindFirstChild("_WorldOrigin")
    if not WorldOrigin or not WorldOrigin:FindFirstChild("Locations") then return nil end
    local posVec = typeof(pos) == "CFrame" and pos.Position or pos
    local best, bestScale = nil, 0
    for _, v in next, WorldOrigin.Locations:GetChildren() do
        if v:FindFirstChild("Mesh") and (posVec - v.Position).Magnitude <= (v.Mesh.Scale.X / 2) + 500 then
            if v.Mesh.Scale.X > bestScale then
                bestScale = v.Mesh.Scale.X
                best = v
            end
        end
    end
    return best
end

function GetSpawnPoint(pos)
    local spawns = GetSpawnFolder()
    if not spawns then return nil end
    local posVec = typeof(pos) == "CFrame" and pos.Position or typeof(pos) == "Vector3" and pos or pos.Position
    for _, v in next, spawns:GetChildren() do
        if v:FindFirstChild("Part") and (v.Part.Position - posVec).Magnitude <= 2500 then
            return v
        end
    end
    return nil
end

function HasRelocateItem()
    local names = { "God's Chalice", "Fist of Darkness", "Sweet Chalice", "Hallow Essence", "Flower1" }
    for _, container in ipairs({ LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }) do
        if container then
            for _, v in ipairs(container:GetChildren()) do
                if v:IsA("Tool") then
                    for _, n in ipairs(names) do
                        if v.Name == n or string.find(v.Name, n, 1, true) then return true end
                    end
                end
            end
        end
    end
    return false
end
    function C(itemName)
        for _, v in next, game.Players.LocalPlayer.Backpack:GetChildren() do
            if v:IsA('Tool') and (v.Name == itemName or string.find(v.Name, itemName)) then return v end
        end
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, v in next, char:GetChildren() do
                if v:IsA('Tool') and (v.Name == itemName or string.find(v.Name, itemName)) then return v end
            end
        end
        return false
    end
function CanBypassTeleport(targetPos)
    local area = InArea(targetPos)
    if not area then return false end
    local areaName = area.Name
    if areaName:find("Dimension") or areaName:find("Submerged") or areaName == "Sealed Cavern" or areaName:lower():find("under") then return false end
    -- carrying these items makes the server relocate you on respawn
    if HasRelocateItem() then return false end
    local data = LocalPlayer:FindFirstChild("Data")
    local lsp = data and data:FindFirstChild("LastSpawnPoint")
    if lsp and lsp.Value == "SubmergedIsland" then return false end
    if LocalPlayer:GetAttribute("ExactLocation") == "Submerged Island" then return false end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if (targetPos - hrp.Position).Magnitude <= 3500 then return false end
    return true
end

function GetBypassCFrame(targetPos)
    local spawns = GetSpawnFolder()
    if not spawns then return nil end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local currentSpawn = GetSpawnPoint(hrp)
    local bestVal, bestSpawn = math.huge, nil
    for _, v in next, spawns:GetChildren() do
        if v:FindFirstChild("Part") then
            local toTarget = (targetPos - hrp.Position).Magnitude
            local spawnToPlayer = (v.Part.Position - hrp.Position).Magnitude
            local spawnToTarget = (v.Part.Position - targetPos).Magnitude
            if toTarget >= 3000 and GetSpawnPoint(v.Part) ~= currentSpawn and spawnToPlayer <= 10000 and spawnToTarget <= bestVal then
                bestVal = spawnToTarget
                bestSpawn = v
            end
        end
    end
    return bestSpawn
end

function BypassTP(targetPos)
    if getgenv().DisableBypassTP then return false end
    local ok, result = pcall(function()
        if not CanBypassTeleport(targetPos) then return false end
        local targetSpawn = GetBypassCFrame(targetPos)
        if not targetSpawn then return false end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if TweenInstance then pcall(function() TweenInstance:Cancel() end) end
        pcall(function() char.LastSpawnPoint.Disabled = true end)
        Remotes.CommF_:InvokeServer("SetLastSpawnPoint", targetSpawn.Name)
        Remotes.CommF_:InvokeServer("SetSpawnPoint")
        char:PivotTo(targetSpawn.Part.CFrame)
        hum:ChangeState(15)
        local timeout = tick() + 10
        repeat task.wait()
        until tick() > timeout
            or (LocalPlayer.Character
                and LocalPlayer.Character ~= char
                and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health > 0
                and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        return true
    end)
    return ok and result or false
end

-- new character right after respawn is still being replicated; tween before it settles gets rubber-banded
function WaitCharacter(waitTime)
    local timeout = tick() + (waitTime or 10)
    local char, hrp, hum
    repeat
        task.wait()
        char = LocalPlayer.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        hum = char and char:FindFirstChildOfClass("Humanoid")
    until (hrp and hum and hum.Health > 0 and hrp:IsDescendantOf(workspace)) or tick() > timeout
    if not (hrp and hum) then return nil end
    local settle = tick() + 1
    repeat task.wait() until tick() > settle or hrp.AssemblyLinearVelocity.Magnitude < 5
    return char
end

TweenTarget, TweenChar = nil, nil
function TweenTo(Position)
    if not Position then
        return
    end
    local Position = typeof(Position) ~= 'CFrame' and ConvertTo(CFrame, Position) or Position

    local Char = LocalPlayer.Character
    local hrp = Char and Char:FindFirstChild("HumanoidRootPart")
    if TweenInstance and TweenInstance.PlaybackState == Enum.PlaybackState.Playing
        and TweenChar == Char and TweenTarget and (TweenTarget - Position.Position).Magnitude <= 20 then
        return
    end

    if TweenInstance then
        pcall(function()
            TweenInstance:Cancel()
        end)
    end

    if hrp and (Position.Position - hrp.Position).Magnitude >= 5000 and BypassTP(Position.Position) then
        Char = WaitCharacter()
        hrp = Char and Char:FindFirstChild("HumanoidRootPart")
    end
    if game.Players.LocalPlayer:GetAttribute("ExactLocation") and game.Players.LocalPlayer:GetAttribute("ExactLocation") ==
        "Submerged Island" then
        local args = { "TeleportToSpawn" }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
        task.wait(6)
        Char = WaitCharacter()
        hrp = Char and Char:FindFirstChild("HumanoidRootPart")
    end
    if not Char or not hrp then return end

    for _, Part in Char:GetDescendants() do
        if Part:IsA('BasePart') then
            Part.CanCollide = false
        end
    end

    -- on the ground (spawn points like Cafe) the humanoid walk/land state fights the tween
    local Humanoid = Char:FindFirstChildOfClass('Humanoid')
    if Humanoid and Humanoid.FloorMaterial ~= Enum.Material.Air then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    local Head = Char:WaitForChild('Head')
    local BodyVelocity = Head:FindFirstChild('cho nam gg')
    if not BodyVelocity then
        BodyVelocity = Instance.new('BodyVelocity')
        BodyVelocity.Name = 'cho nam gg'
        BodyVelocity.Parent = Head
    end
    -- Y-only: forcing X/Z too makes it fight the tween and stutter
    BodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    BodyVelocity.Velocity = Vector3.zero

    Position = CFrame.new(Position.Position)

    local PlayerPos = hrp.CFrame
    local flatDist = (Vector3.new(PlayerPos.X, 0, PlayerPos.Z) - Vector3.new(Position.X, 0, Position.Z)).Magnitude
    local Dist = CaculateDistance(hrp.CFrame, Position)
    TweenTarget, TweenChar = Position.Position, Char
    TweenInstance = Services.TweenService:Create(hrp, TweenInfo.new(
        Dist / 250 , Enum.EasingStyle.Linear), {
        CFrame = Position
    })
    TweenInstance:Play()
end
RS = game:GetService("ReplicatedStorage")
ReplicatedStorage = RS
LP = LocalPlayer

function ConvertTo(W, a) return W.new(a.X, a.Y, a.Z) end
function CaculateDistance(W, a)
    if not W then return 0 end
    a = a or game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
    local h, X = ConvertTo(Vector3, W), ConvertTo(Vector3, a)
    return (h - X).magnitude
end

function GetConnectionEnemies(a)
    for _, v in pairs(RS:GetChildren()) do
        if v:IsA("Model") and ((typeof(a) == "table" and table.find(a, v.Name)) or v.Name == a)
            and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then return v end
    end
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:IsA("Model") and ((typeof(a) == "table" and table.find(a, v.Name)) or v.Name == a)
            and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then return v end
    end
    return nil
end

Hop = {}
function Hop.A(maxPlayers)
    maxPlayers = maxPlayers or 8
    local ok, servers = pcall(function()
        return game:GetService('HttpService'):JSONDecode(
            game:HttpGetAsync('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=Asc&limit=100')
        ).data
    end)
    if not ok or not servers then return end
    for _, server in pairs(servers) do
        if server.playing < maxPlayers and server.id ~= game.JobId then
            pcall(function()
                game:GetService('ReplicatedStorage'):WaitForChild('__ServerBrowser'):InvokeServer('teleport', server.id)
            end)
            break
        end
    end
end

function Hop.API(filterNames, maxPlayers, waitTime)
    Hop.A(maxPlayers)
end

function HopServer(maxPlayers)
    Hop.A(maxPlayers)
end

MAX_CHESTS_PER_SERVER = 30
Config = Config or { ["Chest Farm"] = { Hop = true } }
getgenv().KilledBosses = getgenv().KilledBosses or {}

function SetText(a)
    status(a)
end

FastAttack = loadstring([[
        local Modules = game.ReplicatedStorage.Modules
        local Net = Modules.Net
        local Register_Hit, Register_Attack = Net:WaitForChild('RE/RegisterHit'), Net:WaitForChild('RE/RegisterAttack')
        local Funcs = {}
        function GetAllBladeHits()
            bladehits = {}
            for _, v in pairs(workspace.Enemies:GetChildren()) do
                if v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 
                and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
                    table.insert(bladehits, v)
                end
            end
            return bladehits
        end
        function Getplayerhit()
            bladehits = {}
            for _, v in pairs(workspace.Characters:GetChildren()) do
                if v.Name ~= game.Players.LocalPlayer.Name and v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 
                and (v.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 65 then
                    table.insert(bladehits, v)
                end
            end
            return bladehits
        end

        local Net = (Services.ReplicatedStorage.Modules.Net)

        local RegisterAttack = require(Net):RemoteEvent('RegisterAttack', true)
        local RegisterHit = require(Net):RemoteEvent('RegisterHit', true)

        function Funcs:Attack()
            
            
            local bladehits = {}
            for r,v in pairs(GetAllBladeHits()) do
                table.insert(bladehits, v)
        
            end
            for r,v in pairs(Getplayerhit()) do
                table.insert(bladehits, v)
            end
            
            if #bladehits == 0 then
                
                return
            end
            
            local args = {
                [1] = nil;
                [2] = {},
                [4] = '078da341'
            }
            for r, v in pairs(bladehits) do
                
                
                RegisterAttack:FireServer(0)
                if not args[1] then
                    args[1] = v.Head
                end
                table.insert(args[2], {
                    [1] = v,
                    [2] = v.HumanoidRootPart
                })
                table.insert(args[2], v)
            end
            
            
            RegisterHit:FireServer(unpack(args))
        end

        task.spawn(function() 
            while task.wait(.05) do 
                if _G.FastAttack == os.time() then 
                    pcall(function() 
                        Funcs:Attack() 
                    end)
                end 
            end
        end)

        getgenv().Attack = function(MonResult) 
            pcall(function() 
                _G.FastAttack = os.time()
            end)
        end 
        ]])

FastAttack()
task.spawn(function()
    while wait(0.2) do
        getgenv().Attack()
    end
end)
local function CheckTool(v) return (LP.Backpack:FindFirstChild(v) or (LP.Character and LP.Character:FindFirstChild(v))) and true or false end
local function GetBP(v) return LP.Backpack:FindFirstChild(v) or (LP.Character and LP.Character:FindFirstChild(v)) end
local function EquipByTip(toolTip)
    if not LP.Character then return end
    local equipped = LP.Character:FindFirstChildOfClass("Tool")
    if equipped and equipped.ToolTip == toolTip then return equipped end
    for _, tool in pairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == toolTip then
            LP.Character:FindFirstChildOfClass("Humanoid"):EquipTool(tool); return tool
        end
    end
    return nil
end
    local RaceV4CheckCache, RaceV4CheckTime = nil, 0
    if Remotes.CommF_:InvokeServer('CheckTempleDoor') then return end
    local currentRaceLevel = game.ReplicatedStorage.Remotes.CommF_:InvokeServer("getRaceLevel")
    if currentRaceLevel < 3 then
        status("Race level " .. tostring(currentRaceLevel) .. " < 3, đang up V3...")
        local RS = game:GetService("ReplicatedStorage")
        local LP = game.Players.LocalPlayer
        local TS = game:GetService("TweenService")
        local VIM = game:GetService("VirtualInputManager")

        local function getCurrentRace()
            local ok, r = pcall(function() return LP.Data.Race.Value end)
            return ok and r or nil
        end

        local titleMap = {Human="Human",Mink="Rabbit",Fishman="Shark",Skypiea="Angel",Ghoul="Ghoul",Cyborg="Cyborg"}

        local function HasRaceV3(raceName)
            local ok, titles = pcall(function() return RS.Remotes.CommF_:InvokeServer("getTitles") end)
            if not ok or not titles or typeof(titles) ~= "table" then return false end
            local keyword = titleMap[raceName]
            if not keyword then return false end
            for _, title in pairs(titles) do
                if title.Unlocked and title.Description and title.Description:find("V3") and title.Description:find(keyword) then return true end
            end
            return false
        end

        local function UseSkill(key)
            VIM:SendKeyEvent(true, key, false, game); task.wait(0.05)
            VIM:SendKeyEvent(false, key, false, game); task.wait(0.3)
        end

        local function EquipTip(tip)
            for _, tool in pairs(LP.Backpack:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == tip then
                    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:EquipTool(tool); return tool.Name end
                end
            end
            if LP.Character then
                for _, tool in pairs(LP.Character:GetChildren()) do
                    if tool:IsA("Tool") and tool.ToolTip == tip then return tool.Name end
                end
            end
            return nil
        end

        local function GetEnemy(name)
            for _, v in pairs(workspace.Enemies:GetChildren()) do
                if v:IsA("Model") and v.Name == name and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then return v end
            end
            for _, v in pairs(RS:GetChildren()) do
                if v:IsA("Model") and v.Name == name and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then return v end
            end
            return nil
        end

 KillMonster = function(x)
    xpcall(function()
        for _, v in next, workspace.Enemies:GetChildren() do
            local vh = v:FindFirstChildWhichIsA("Humanoid")
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if vh and vh.Health > 0 and vhrp and ((typeof(x) == "table" and table.find(x, v.Name)) or v.Name == x) then
                local myPos = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character.HumanoidRootPart.Position
                if not myPos then return end
                TweenTo(vhrp.Position + Vector3.new(0, 35, 0))
                EquipByTip("Melee")

                return  
            end
        end
        for _, v in next, Services.ReplicatedStorage:GetChildren() do
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and ((typeof(x) == "table" and table.find(x, v.Name)) or v.Name == x) then
                TweenTo(vhrp.Position + Vector3.new(0, 35, 0))
                return
            end
        end
    end, function(e) warn("KillMonster ERROR:", e) end)
end
        task.spawn(function()
            task.wait(6)
            if LocalPlayer.Character:FindFirstChild('HasBuso') then return end
            Remotes.CommF_:InvokeServer("Buso")
        end)
        local function BringMob(name)
            pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
            if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
            local myPos = LP.Character.HumanoidRootPart.Position
            for _, v in pairs(workspace.Enemies:GetChildren()) do
                if (not name or v.Name == name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                    local dist = (v.HumanoidRootPart.Position - myPos).Magnitude
                    if dist <= 350 then
                        v.HumanoidRootPart.CFrame = CFrame.new(myPos + Vector3.new(0, 0, 5))
                        v.HumanoidRootPart.CanCollide = false
                        v.Humanoid.WalkSpeed = 0; v.Humanoid.JumpPower = 0
                    end
                end
            end
        end

local function FarmChestFast(raceName)
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local ChestFolder = workspace:WaitForChild("ChestModels")
    local sorted = {}
    local myPos = LP.Character.HumanoidRootPart.Position

    for _, chest in ipairs(ChestFolder:GetChildren()) do
        if chest:IsA("Model") then
            local root = chest.PrimaryPart or chest:FindFirstChild("RootPart", true)
            if root then
                table.insert(sorted, {
                    Model = chest,
                    Root  = root,
                    Dist  = (root.Position - myPos).Magnitude
                })
            end
        end
    end

    table.sort(sorted, function(a, b) return a.Dist < b.Dist end)

    if #sorted == 0 then
        SetText("Not Found Chest => Hop")
        HopServer(5)
        return
    end

    local collected = 0
    for _, data in ipairs(sorted) do
        if getgenv().StopV3 then break end

        if CheckTool("Fist of Darkness") then
            SetText("Đã có Fist of Darkness!")
            return "FOD"
        end

        if collected >= MAX_CHESTS_PER_SERVER then
            SetText("Đủ " .. MAX_CHESTS_PER_SERVER .. " chest => Hop")
            if raceName ~= "Mink" then
                HopServer(5)
            end
            return
        end
        local chest = data.Model
        if not chest or not chest.Parent or not chest:IsDescendantOf(ChestFolder) then
            continue
        end

        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        local attempts = 0
        repeat
            attempts += 1

            if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then break end
            if not chest or not chest.Parent or not chest:IsDescendantOf(ChestFolder) then break end
            if CheckTool("Fist of Darkness") then return "FOD" end

            LP.Character.HumanoidRootPart.CFrame = data.Root.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.1)
        until not chest.Parent
            or not chest:IsDescendantOf(ChestFolder)
            or attempts >= 20

        if not chest.Parent or not chest:IsDescendantOf(ChestFolder) then
            collected += 1
            SetText(("Chest | %d/%d"):format(collected, MAX_CHESTS_PER_SERVER))
        end

        if collected > 0 and collected % 10 == 0 then
            SetText("Reset Character")
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
                repeat task.wait(0.5)
                until LP.Character
                    and LP.Character:FindFirstChild("HumanoidRootPart")
                    and LP.Character:FindFirstChildOfClass("Humanoid")
                    and LP.Character:FindFirstChildOfClass("Humanoid").Health > 0
            end
        end
    end

    SetText("Hết Chest ")
    if (Config["Chest Farm"]["Hop"] and raceName == "Mink") or raceName ~= "Mink" then
    HopServer(5)
    end
end

        local function CheckSeaBeast()
            if not workspace:FindFirstChild("SeaBeasts") then return nil end
            for _, v in pairs(workspace.SeaBeasts:GetChildren()) do
                if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Health") and v.Health.Value > 0 then return v end
            end
            return nil
        end

        local function AttackSeaBeast(seaBeast)
            if not seaBeast then return false end
            repeat
                task.wait(0.3)
                if not seaBeast or not seaBeast.Parent then break end
                if not seaBeast:FindFirstChild("Health") or seaBeast.Health.Value <= 0 then break end
                if not seaBeast:FindFirstChild("HumanoidRootPart") then break end
                if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then break end
                local bPos = seaBeast.HumanoidRootPart.Position
                local waterY = workspace.Map:FindFirstChild("WaterBase-Plane")
                local yPos = waterY and waterY.Position.Y + 200 or 200
                TweenTo(CFrame.new(bPos.X, yPos, bPos.Z))
                status("Fishman V3 | Sea Beast HP: " .. math.floor(seaBeast.Health.Value))
                EquipTip("Blox Fruit"); UseSkill("Z"); UseSkill("X"); UseSkill("C")
                EquipTip("Melee"); UseSkill("Z"); UseSkill("X"); UseSkill("C")
                EquipTip("Sword"); UseSkill("Z"); UseSkill("X")
                EquipTip("Gun"); UseSkill("Z"); UseSkill("X")
            until not seaBeast or not seaBeast.Parent or not seaBeast:FindFirstChild("Health") or seaBeast.Health.Value <= 0
            return seaBeast and seaBeast:FindFirstChild("Health") and seaBeast.Health.Value <= 0
        end

        local function FarmFishmanV3()
            local sb = CheckSeaBeast()
            if sb then
                if LP.Character.Humanoid.Sit then LP.Character.Humanoid.Sit = false; task.wait(1) end
                AttackSeaBeast(sb)
                return
            end
            local myBoat = nil
            for _, v in pairs(workspace.Boats:GetChildren()) do
                if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == LP.Name then myBoat = v; break end
            end
            if not myBoat then
                status("Fishman V3 | Mua thuyền")
                TweenTo(CFrame.new(-110.271713, 9.76438141, 2956.36841))
                task.wait(2)
                if LP.Character and (CFrame.new(-110.271713, 9.76438141, 2956.36841).Position - LP.Character.HumanoidRootPart.Position).Magnitude <= 15 then
                    RS.Remotes.CommF_:InvokeServer("BuyBoat", "MarineBrigade"); task.wait(2)
                end
                return
            end
            if not LP.Character.Humanoid.Sit then
                status("Fishman V3 | Lên thuyền")
                TweenTo(myBoat.VehicleSeat.CFrame * CFrame.new(0, 1, 0))
                task.wait(2); return
            end
            local sb2 = CheckSeaBeast()
            if sb2 then
                LP.Character.Humanoid.Sit = false; task.wait(1); AttackSeaBeast(sb2)
            else
                status("Fishman V3 | Lái thuyền tìm Sea Beast")
                TweenTo(CFrame.new(-10000000, 31, 37016.25) * CFrame.new(0, 50, 0))
            end
        end

        local function GetPlayers()
            local players = {}
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    table.insert(players, p)
                end
            end
            return players
        end

        local function IsValidLevel(p)
            local ok, lv = pcall(function() return p.Data.Level.Value end)
            local myLv = LP.Data and LP.Data.Level.Value or 0
            return ok and math.abs(myLv - lv) <= 200
        end

        local function IsPvpEnabled()
            local ok, r = pcall(function() return not LP.PlayerGui.Main.PvpDisabled.Visible end)
            return ok and r
        end

        local function AttackSkypiea()
            local target = nil
            for _, p in pairs(GetPlayers()) do
                local ok, race = pcall(function() return p.Data.Race.Value end)
                if ok and race == "Skypiea" and IsValidLevel(p) then target = p; break end
            end
            if not target then
                status("Skypiea V3 | Không tìm thấy target → Hop")
                Hop.A(10); return
            end
            if not IsPvpEnabled() then
                pcall(function() RS.Remotes.CommF_:InvokeServer("EnablePvp") end)
            end
            local tChar = target.Character
            local tHum = tChar:FindFirstChild("Humanoid")
            local tHrp = tChar:FindFirstChild("HumanoidRootPart")
            status("Skypiea V3 | Attack: " .. target.Name)
            repeat
                task.wait(0.1)
                if not tChar or not tHum or tHum.Health <= 0 then break end
                tHrp = tChar:FindFirstChild("HumanoidRootPart"); if not tHrp then break end
                TweenTo(tHrp.CFrame * CFrame.new(0, 5, 2))
                local dist = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and (LP.Character.HumanoidRootPart.Position - tHrp.Position).Magnitude or 999
                if dist < 40 then
                    EquipTip("Melee")
                    game:GetService("VirtualUser"):ClickButton1(Vector2.new())
                    UseSkill("Z"); UseSkill("X"); UseSkill("C")
                end
            until not tHum or tHum.Health <= 0
        end

        local function GetV2()
            while task.wait(0.5) do
                local state = RS.Remotes.CommF_:InvokeServer("Alchemist", "1")
                if state == 0 then
                    status("V2 | Get quest")
                    RS.Remotes.CommF_:InvokeServer("Alchemist", "2")
                elseif state == 1 then
                    local function hasTool(name) return LP.Backpack:FindFirstChild(name) or (LP.Character and LP.Character:FindFirstChild(name)) end
                    if not hasTool("Flower 1") then
                        status("V2 | Flower 1"); TweenTo(workspace.Flower1.CFrame)
                    elseif not hasTool("Flower 2") then
                        status("V2 | Flower 2"); TweenTo(workspace.Flower2.CFrame)
                    elseif not hasTool("Flower 3") then
                        status("V2 | Kill Swan Pirate")
                        local v = GetEnemy("Swan Pirate")
                        if v then
                            BringMob("Swan Pirate"); KillMonster("Swan Pirate")
                        else
                            TweenTo(CFrame.new(980.099, 121.331, 1287.209))
                        end
                    end
                elseif state == 2 then
                    status("V2 | Nộp quest")
                    RS.Remotes.CommF_:InvokeServer("Alchemist", "3"); task.wait(1)
                elseif state == -2 then
                    status("V2 Done!"); break
                end
            end
        end

        local function GetV3()
            local raceName = getCurrentRace()
            if not raceName then status("Không lấy được race"); return end
            status("Up V3 cho: " .. raceName)

            local lv = RS.Remotes.CommF_:InvokeServer("getRaceLevel")
            if lv == 1 then
                status(raceName .. " | Up V2 trước...")
                GetV2(); task.wait(2)
                lv = RS.Remotes.CommF_:InvokeServer("getRaceLevel")
            end

            if lv ~= 2 then return end

            while not HasRaceV3(raceName) do
                if getgenv().StopV3 then break end
                local ws = RS.Remotes.CommF_:InvokeServer("Wenlocktoad", "1")
                if ws == 0 then
                    status(raceName .. " V3 | Nhận quest")
                    RS.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")

                elseif ws == 1 then
                    if raceName == "Human" then
                        local bosses = {{name="Orbitus",pos=CFrame.new(-2172,103,-4015)},{name="Jeremy",pos=CFrame.new(2099.88159, 448.931, 648.997375)},{name="Diamond",pos=CFrame.new(-1576,198,13)}}
                local found = false
                for i, b in ipairs(bosses) do
                    if getgenv().StopV3 then break end
                    if getgenv().KilledBosses[b.name] then continue end
                    local v = GetConnectionEnemies(b.name)
                    if v then
                        found = true
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then TweenTo(hrp.Position + Vector3.new(0,25,0)) end
                        repeat task.wait(0.3)
                            SetText("Human V3 | Boss "..i..": "..b.name.." | "..math.floor(v.Humanoid.Health/v.Humanoid.MaxHealth*100).."%")
                            EquipByTip("Melee"); hrp = v:FindFirstChild("HumanoidRootPart"); if not hrp then break end
                            if (LP.Character.HumanoidRootPart.Position-hrp.Position).Magnitude > 80 then TweenTo(hrp.Position + Vector3.new(0,25,0)) end
                        until not v.Parent or v.Humanoid.Health<=0 or getgenv().StopV3
                        getgenv().KilledBosses[b.name] = true; break
                    else Hop.A(10)
                    end
                end
                if not found then
                    for i, b in ipairs(bosses) do
                        if not getgenv().KilledBosses[b.name] then SetText("Human V3 | Chờ "..b.name); TweenTo(b.pos); break end
                    end
                end

                    elseif raceName == "Mink" then
                        status("Mink V3 | Farm Chest")
                        FarmChestFast("Mink")

                    elseif raceName == "Fishman" then
                        FarmFishmanV3()

                    elseif raceName == "Skypiea" then
                        AttackSkypiea()

                    else
                        status(raceName .. " V3 | Quest đang làm...")
                    end

                elseif ws == 2 then
                    status(raceName .. " V3 | Nộp quest")
                    RS.Remotes.CommF_:InvokeServer("Wenlocktoad", "3")
                    getgenv().KilledBossesV3 = {}
                    task.wait(1)

                elseif ws == -2 then
                    status(raceName .. " V3 DONE!")
                    getgenv().KilledBossesV3 = {}
                    break
                end
                task.wait(1)
            end
        end

        GetV3()
        return
    end

    if RaceV4CheckCache == nil or tick() - RaceV4CheckTime > 3 then
        RaceV4CheckCache = Remotes.CommF_:InvokeServer('RaceV4Progress', 'Check')
        RaceV4CheckTime = tick()
    end

    AiChoMaDiGatCan = RaceV4CheckCache
    getgenv().FailedJobIds = {}
    getgenv().LastApiRefresh = 0
    HttpService = game:GetService("HttpService")

function status(a)
    print("[Pull Lever] " .. a)
end
function getBlueGear()
    if not workspace.Map:FindFirstChild('MysticIsland') then return nil end
    for _, v in workspace.Map.MysticIsland:GetDescendants() do
        if v:IsA('MeshPart') then
            if v.MeshId == 'rbxassetid://10153114969' then
                if v.Transparency ~= 1 then
                    return v.CFrame
                end
            end
        end
    end
end
    if RaceV4CheckCache == nil or tick() - RaceV4CheckTime > 3 then
        RaceV4CheckCache = Remotes.CommF_:InvokeServer('RaceV4Progress', 'Check')
        RaceV4CheckTime = tick()
    end
task.spawn(RefreshInventory)
local function MainStep()
    if tick() - RaceV4CheckTime > 3 then
        RaceV4CheckCache = Remotes.CommF_:InvokeServer('RaceV4Progress', 'Check')
        RaceV4CheckTime = tick()
    end
    AiChoMaDiGatCan = RaceV4CheckCache
    if not AiChoMaDiGatCan or AiChoMaDiGatCan == 0 then
        if not CheckItem("Valkyrie Helm") then
            print("rip")
            if GetConnectionEnemies('rip_indra True Form') then
                KillMonster('rip_indra True Form')
                return
            else
                elites = { "Diablo", "Deandre", "Urban"}
                for _, e in ipairs(elites) do
                    if GetConnectionEnemies(e) then
                        KillMonster(e)
                        return
                    elseif C("God's Chalice") then
                        TweenTo(CFrame.new(-5563.5459, 316.06601, -2662.56396))
                        -- FIX: C() tìm cả Backpack lẫn Character, nhưng trước đây chỉ Activate()
                        -- đúng Character -> nếu Chalice còn trong Backpack thì FindFirstChild trả nil,
                        -- gọi Activate() trên nil làm crash cả MainStep mỗi tick.
                        local chaliceTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("God's Chalice")
                        if not chaliceTool then
                            local backpackChalice = LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("God's Chalice")
                            if backpackChalice and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                                LocalPlayer.Character.Humanoid:EquipTool(backpackChalice)
                                task.wait(0.2)
                                chaliceTool = LocalPlayer.Character:FindFirstChild("God's Chalice")
                            end
                        end
                        if chaliceTool then
                            pcall(function() chaliceTool:Activate() end)
                        end
                        return
                    elseif not GetConnectionEnemies(EliteName) and not C("God's Chalice") then 
                        Hop.A(12)
                        return -- FIX: thiếu return -> for loop gọi Hop.A 3 lần chồng nhau trong 1 tick
                    end
                end
            end
        elseif not CheckItem("Mirror Fractal") and CheckItem("Valkyrie Helm") then
            print("dough")
            if GetConnectionEnemies('Dough King') then
                KillMonster('Dough King')
                return
            else 
                for _, EliteName in { 'Diablo', 'Urban', 'Deandre' } do
                    if GetConnectionEnemies(EliteName) then
                        KillMonster(EliteName)
                        return
                    elseif C("God's Chalice") then
                        local cac = tostring(game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('CakePrinceSpawner'))
                        local killed = tonumber(string.match(cac, "%d+")) or 0
                        local cocoa = TDT.Backpack["Conjured Cocoa"]
                        cocoa = cocoa and cocoa.Count or 0
                        if killed < 500 then
                            local mobs = cocoa < 10
                                and { 'Chocolate Bar Battler', 'Cocoa Warrior' }
                                or { "Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker" }
                            for _, m in mobs do
                                if GetConnectionEnemies(m) then
                                    KillMonster(m)
                                    return
                                end
                            end
                        else
                            Remotes.CommF_:InvokeServer("SweetChaliceNpc")
                            task.wait(1)
                            Remotes.CommF_:InvokeServer("CakePrinceSpawner")
                            return
                        end

                    elseif not GetConnectionEnemies(EliteName) and not C("God's Chalice") then 
                        Hop.A(12)
                        return -- FIX: thiếu return -> for loop gọi Hop.A nhiều lần chồng nhau trong 1 tick
                    end
                end
            end
        elseif CheckItem("Valkyrie Helm") and CheckItem("Mirror Fractal") then
                status("Get Pull Lever")
                    local leverPos = CFrame.new(3032, 2280, -7325)
                        TweenTo(leverPos)
                            if CaculateDistance(leverPos) < 30 then
                                PullLeverQuestDebounce = tick()
                                        if not game.Workspace.Map:FindFirstChild("Temple of Time") then
                                             game.ReplicatedStorage.MapStash["Temple of Time"].Parent = workspace.Map
                                         end
                            Remotes.CommF_:InvokeServer('RaceV4Progress', 'Begin')
                            game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('RaceV4Progress', 'Check')
                            game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('RaceV4Progress',
                                'Teleport')
                            task.wait(2)
                            TweenTo(CFrame.new(28613, 14896, 106))
                            game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('RaceV4Progress', 'Check')
                            game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('RaceV4Progress',
                                'TeleportBack')
                            AiChoMaDiGatCan = Remotes.CommF_:InvokeServer('RaceV4Progress', 'Check')
                            Hop.A()
                                return
                                end
                            else
                                local MirageIsland = workspace.Map:FindFirstChild('MysticIsland')
                                    if MirageIsland then
                                        if math.floor(game.Lighting.ClockTime) >= 12 or math.floor(game.Lighting.ClockTime) < 5 then
                                            local BlueGear = getBlueGear()
                                            print("Blue GEar", BlueGear)
                                            if BlueGear then
                                                print("THAY R BO OI ")
                                                    TweenTo(BlueGear)
                                                        task.spawn(function()
                                                                task.wait(2)
                                                            while TweenInstance and TweenInstance.PlaybackState == Enum.PlaybackState.Playing do
                                                                if not workspace.Map:FindFirstChild('MysticIsland') then
                                                                    status("Mirage Island disappeared during tween, hopping...")
                                                                    Hop.API("Mirage",12,5)
                                                                    if TweenInstance then
                                                                    pcall(function() TweenInstance:Cancel() end)
                                                                    end
                                                                    return
                                                                end
                                                                 task.wait(1)
                                                            end
                                                        end)
                                                return
                                    else
                                            status("Tween to Mirage Island")
                                                    local wasAtMirage = true
                                    task.spawn(function()
                                        local prevHealth = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health or 0
                                        while wasAtMirage do
                                            task.wait(0.5)
                                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                                                local currentHealth = LocalPlayer.Character.Humanoid.Health
                                                if prevHealth > 0 and currentHealth > prevHealth + 50 then
                                                    status("returning to Mirage Island...")
                                                    task.wait(2)
                                                    if workspace.Map:FindFirstChild('MysticIsland') then
                                                        TweenTo(workspace.Map.MysticIsland:GetModelCFrame() + Vector3.new(0, 300, 0))
                                                    end
                                                end
                                                prevHealth = currentHealth
                                            end
                                        end
                                    end)

                                    TweenTo(MirageIsland:GetModelCFrame() + Vector3.new(0, 300, 0))

                                    task.spawn(function()
                                        task.wait(2)
                                        while TweenInstance and TweenInstance.PlaybackState == Enum.PlaybackState.Playing do
                                            if not workspace.Map:FindFirstChild('MysticIsland') then
                                                status("hopping...")
                                                if TweenInstance then
                                                    pcall(function() TweenInstance:Cancel() end)
                                                end
                                                wasAtMirage = false
                                                Hop.API("Mirage",12,5)
                                                return
                                            end
                                            task.wait(1)
                                        end
                                    end)

                                    if CaculateDistance(MirageIsland:GetModelCFrame() + Vector3.new(0, 300, 0)) < 20 then
                                        LocalPlayer.CameraMaxZoomDistance = 0.5
                                        LocalPlayer.CameraMaxZoomDistance = 200
                                        workspace.CurrentCamera.CFrame = CFrame.new(
                                            workspace.CurrentCamera.CFrame.Position,
                                            game.Lighting:GetMoonDirection() + workspace.CurrentCamera.CFrame.Position)
                                        game.ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
                                    end
                                    return -- ua ki ta
                                end
                            else
                                print("Hop for Mirage Island | Night")
                                Hop.API("Mirage",12,5)
                            end
                        else
                            print("Hop for Mirage Island")
                           Hop.API("Mirage",12,5)
                        end
                    end
                    end
end

while task.wait(1) do
    local ok, err = pcall(MainStep)
    if not ok then warn("[Pull Lever] " .. tostring(err)) end
end
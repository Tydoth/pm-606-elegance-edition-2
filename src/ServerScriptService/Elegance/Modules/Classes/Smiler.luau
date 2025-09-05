--!strict
--!optimize 2

-- services
local Debris = game:GetService("Debris")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- modules and references
local default = require(ServerScriptService.Elegance.defaults.Smiler) -- default params stored in a seperate module for organization and ease
local InstanceCalculator = require(ReplicatedStorage.Elegance.Modules.Math.InstanceCalculator)
local chaseEventClient: RemoteEvent = ReplicatedStorage.Elegance.Events:WaitForChild("SmilerChasing", 5)

local Smiler = {}
Smiler.__index = Smiler

function Smiler.new(model: Model): self
  local self = setmetatable({}, Smiler)
  self.model = model
  self.humanoid = model:FindFirstChild("Humanoid") :: Humanoid
  self.rootPart = model:FindFirstChild("HumanoidRootPart") :: Part
  
  self.chase = self.rootPart:FindFirstChild("Chase") :: Sound
  self.waypointWent = self.rootPart:FindFirstChild("WaypointWent") :: Sound
  self.yawn = self.rootPart:FindFirstChild("Yawn") :: Sound
  self.playerSpotted = self.rootPart:FindFirstChild("PlayerSpotted") :: Sound
  self.playerLost = self.rootPart:FindFirstChild("PlayerLost") :: Sound
  self.hitSounds = {self.rootPart:FindFirstChild("Hit1") :: Sound} :: {Sound}
  
  self.data = (self.rootPart:FindFirstChild(".default") and require(self.rootPart:FindFirstChild(".default")) :: {} or default) :: propeties
  self.hitCooldowns = {}
  self.hitCooldown = default.COOLDOWN_TIME
  self._currentState = 0

  if (self.model.Parent) then
    local waypoints = self.model.Parent:FindFirstChild("Waypoints"):GetChildren() :: {Instance}
    self.waypoints = {}
    for _, point in waypoints do
      table.insert(self.waypoints, (point :: Part).Position)
    end
  end

  self.model:AddTag("Smiler")
  task.spawn(function() self.Patrol(self) end)
  return self :: self
end

function Smiler.Attack(self: self, who: Model): ()
  if (not who) then
    return
  end

  local rootPart: Part = (who:FindFirstChild("HumanoidRootPart") or who.PrimaryPart) :: Part
  if (not rootPart) then
    return
  end
  local humanoid = who:FindFirstChildOfClass("Humanoid") :: Humanoid -- stupid type checking

  self.playerSpotted:Play()
  self.chase:Play()
  if (not self.hitCooldowns) then
    self.hitCooldowns = {}
  end

  while InstanceCalculator.canSeeTarget(self.model, who) do
    task.wait(0.2)
    if humanoid.Health <= 0 then
      break
    end
    self.humanoid:MoveTo(rootPart.Position)
    local dist = (self.rootPart.Position - rootPart.Position).Magnitude
    if (dist <= self.data.ATTACK_RADIUS) then
      local now = os.clock()
      local lastHit = self.hitCooldowns[who] or 0
      if now - lastHit < self.data.COOLDOWN_TIME then
        continue
      end
      self.hitCooldowns[who] = now
      humanoid:TakeDamage(self.data.DAMAGE or 20)
      self.hitSounds[math.random(1, #self.hitSounds)]:Play()
    elseif (dist >= default.MAX_VIEW) then
      break
    end
  end
  chaseEventClient:FireClient(Players:GetPlayerFromCharacter(who), false)
  self.humanoid:MoveTo(self.rootPart.Position)
  self.playerLost:Play()
  self.chase:Pause()
  task.wait(self.data.ENDLAG)
end

function Smiler.Raycast(self: self): Model
  local players: {Player} = Players:GetPlayers()
  local maxDist: number = default.MAX_VIEW
  local nearestTarget: Model

  for _, player in players do
    if (player.Character) then
      local target = player.Character
      local rootPart = target:FindFirstChild("HumanoidRootPart") :: Part
      local distance = (self.rootPart.Position - rootPart.Position).Magnitude
      if (distance < maxDist) and (InstanceCalculator.canSeeTarget(self.model, target)) then
        nearestTarget = target
        maxDist = distance
        self._currentState = 1
        chaseEventClient:FireClient(player, true, default.CHASE_EFFECT)
      else
        self._currentState = 0
        chaseEventClient:FireClient(player, false)
      end
    end
  end

  return nearestTarget
end

function Smiler.GoTo(self: self, point: Vector3): ()
  if (not self.humanoid) then
    return
  end
  local path = PathfindingService:CreatePath(default.PATH_PARAMS); path:ComputeAsync(self.rootPart.Position, point)
  if path.Status == Enum.PathStatus.Success then
    local waypoints = path:GetWaypoints()
    for _, waypoint in waypoints do
      local model = self:Raycast()
      if model then
        self.Attack(self, model)
        break
      end
      self.humanoid:MoveTo(waypoint.Position)
      self.humanoid.MoveToFinished:Wait()
    end
    if math.random(1, self.data.YAWN_CHANCE) == 1 then
      self.yawn:Play()
    end
    self.waypointWent:Play()
  else
    warn("Path not found!")
  end
end

function Smiler.Patrol(self: self): ()
  if (not self.humanoid) then
    return
  end
  local humanoid: Humanoid = self.humanoid :: Humanoid
  while self.model do
    self.GoTo(self, self.waypoints[math.random(1, #self.waypoints)])
    task.wait(self.data.FINISHED_WAYPOINT_ENDLAG)
  end
end

type propeties = typeof(default)
type smilerBase = {
  model         : Model,
  rootPart      : Part,
  humanoid      : Humanoid,
  waypoints     : {Vector3},
  _currentState : number,
  data          : propeties,
  yawn          : Sound,
  chase         : Sound,
  playerLost    : Sound,
  playerSpotted : Sound,
  waypointWent  : Sound,
  hitSounds     : {Sound},
  hitCooldown   : number,
  hitCooldowns  : {[Model]: number}
}
type Smiler = typeof(Smiler)
type self = typeof(setmetatable({} :: smilerBase, {} :: Smiler))

return Smiler

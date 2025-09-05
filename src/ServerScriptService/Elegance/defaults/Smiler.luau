--!strict
local defaults = {
  COOLDOWN_TIME = 1.5, -- Smiler attack cooldown
  DAMAGE = 20,
  ATTACK_RADIUS = 5,
  ENDLAG = 3, -- When Smiler loses sight of the player, delay before it starts chasing again
  FINISHED_WAYPOINT_ENDLAG = 0.2,
  MAX_VIEW = 35, -- Max distance of vision
  LOSE_VIEW = 40,
  YAWN_CHANCE = 10, -- math.random(1, YAWN_CHANCE)
  CHASE_EFFECT = {
    Contrast  = 1,
    TintColor = Color3.new(1, 0, 0)
  },
  PATH_PARAMS = {
    AgentHeight     = 5,
    AgentRadius     = 4,
    AgentCanJump    = false,
    AgentCanClimb   = false,
    WaypointSpacing = 5
  }
}

type defaults = typeof(defaults)

return defaults :: defaults

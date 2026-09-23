local module = ...

local function enabled()
    return Network:is_server() and MutatorHelper and MutatorHelper.is_active
        and MutatorHelper.is_active("gradual_bot_catchup_mutator")
end

local function multiplier(action)
    if not enabled() then
        return 1
    end

    local unit = action._unit
    if not alive(unit) then
        return 1
    end
    local state = managers.groupai:state()
    if not state:all_AI_criminals()[unit:key()] then
        return 1
    end

    local brain = unit:brain()
    local objective = brain and brain:objective()
    if not objective or (objective.type ~= "follow" and objective.type ~= "revive") then
        return 1
    end
    local target = objective.follow_unit
    if not alive(target) then
        return 1
    end
    local target_base = target:base()
    if not target_base or not (target_base.is_local_player or target_base.is_husk_player) then
        return 1
    end

    local target_movement = target:movement()
    local bot_movement = unit:movement()
    if not target_movement or not bot_movement then
        return 1
    end
    local minimum, maximum, max_multiplier, height_multiplier = module:get_catchup_settings()
    local start_distance = minimum * 100
    local full_distance = maximum * 100
    local bot_pos = bot_movement:m_pos()
    local target_pos = target_movement:m_pos()
    local dx = bot_pos.x - target_pos.x
    local dy = bot_pos.y - target_pos.y
    local dz = (bot_pos.z - target_pos.z) * height_multiplier
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    local fraction = math.max(0, math.min(1, (distance - start_distance) / (full_distance - start_distance)))
    return 1 + (max_multiplier - 1) * fraction
end

local Walk = module:hook_class("CriminalActionWalk")

module:hook(Walk, "_get_max_walk_speed", function(self, ...)
    local normal_speed = module:call_orig(Walk, "_get_max_walk_speed", self, ...)
    return normal_speed * multiplier(self)
end, false)

module:hook(Walk, "_nav_chk_walk", function(self, ...)
    if enabled() then
        self._walk_velocity = self:_get_max_walk_speed()
        self._catchup_applied = true
    elseif Network:is_server() and self._catchup_applied then
        self._walk_velocity = self:_get_max_walk_speed()
        self._catchup_applied = nil
    end
    return module:call_orig(Walk, "_nav_chk_walk", self, ...)
end, false)

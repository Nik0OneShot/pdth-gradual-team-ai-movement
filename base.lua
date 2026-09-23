local module = DMod:new("gradual_bot_catchup", {
    name = "Gradual Team A.I Movement",
    abbr = "GTAIM",
    version = "1.4.0",
    author = "ChatGPT Astra, Niko",
    dependencies = "ovk_193",
    categories = { "gameplay", "mutator" },
    description = {
        english = "Makes Team A.I have gradual movement speeds that smoothly increase or decrease depending on follow / revive/arrest distance."
    },
    localization = {
        gradual_bot_catchup_mutator = { english = "Gradual Team A.I Movement" },
        gradual_bot_catchup_mutator_help = {
            english = "Makes Team A.I have gradual movement speeds that smoothly increase or decrease depending on follow / revive/arrest distance."
        },
        gradual_bot_catchup_mutator_motd = {
            english = "Gradual Team A.I Movement is enabled: Team A.I may speed up or speed down dependant on distance."
        },
        gtaim_min_distance = { english = "Minimum distance (metres)" },
        gtaim_min_distance_help = {
            english = "Team A.I use normal speed within this distance."
        },
        gtaim_max_distance = { english = "Maximum distance (metres)" },
        gtaim_max_distance_help = {
            english = "Team A.I reach the maximum speed multiplier at this distance."
        },
        gtaim_max_multiplier = { english = "Maximum speed multiplier" },
        gtaim_max_multiplier_help = {
            english = "Maximum travel speed relative to normal speed."
        },
        gtaim_height_multiplier = { english = "Height distance multiplier" },
        gtaim_height_multiplier_help = {
            english = "Weight given to height differences when calculating distance. 10 makes a 4 metre height difference count as 40 metres."
        },
        mutator_gradual_bot_catchup_mutator = { english = "Gradual Team A.I Movement" },
        mutator_gradual_bot_catchup_mutator_help = {
            english = "Makes Team A.I have gradual movement speeds that smoothly increase or decrease depending on follow / revive/arrest distance."
        },
        mutator_gradual_bot_catchup_mutator_motd = {
            english = "Gradual Team A.I Movement is enabled: Team A.I may speed up or speed down dependant on distance."
        }
    }
})

local function finite_number(value, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return value
end

function module:get_catchup_settings()
    local minimum = math.max(0, finite_number(self:conf("start_distance"), 10))
    local maximum = math.max(minimum + 1, finite_number(self:conf("full_distance"), 150))
    local multiplier = math.max(1, finite_number(self:conf("max_multiplier"), 3))
    local height_multiplier = math.max(1, finite_number(self:conf("height_multiplier"), 10))
    return minimum, maximum, multiplier, height_multiplier
end

local function add_number_option(key, default, text_id, normalize)
    module:add_menu_option(key, {
        type = "number",
        precision = 2,
        ignore_prefix = false,
        text_id = text_id,
        help_id = text_id .. "_help",
        default_value = default,
        on_value_changed = function(config_key, value, old_value, was_user_set, options, item)
            value = normalize(finite_number(value, finite_number(old_value, default)))
            if item then
                item:set_value(value)
            end
            return true, nil, value
        end
    })
end

add_number_option("start_distance", 10, "gtaim_min_distance", function(value)
    local _, maximum = module:get_catchup_settings()
    return math.max(0, math.min(value, maximum - 1))
end)

add_number_option("full_distance", 150, "gtaim_max_distance", function(value)
    local minimum = module:get_catchup_settings()
    return math.max(minimum + 1, value)
end)

add_number_option("max_multiplier", 10, "gtaim_max_multiplier", function(value)
    return math.max(1, value)
end)

add_number_option("height_multiplier", 10, "gtaim_height_multiplier", function(value)
    return math.max(1, value)
end)

module:hook("OnModuleLoading", "gradual_bot_catchup_mutator_register_mutator", function(m)
    if MutatorHelper and MutatorHelper.setup_mutator
        and MutatorHelper.setup_mutator(m, "gradual_bot_catchup_mutator", { all = true }, nil, false) then
        m:hook_post_require("lib/units/player_team/actions/lower_body/criminalactionwalk", "catchup")
    end
end)
return module

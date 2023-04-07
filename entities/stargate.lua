local path = "__multiplanet__/entities/"
local stargate =  table.deepcopy(data.raw["land-mine"]["land-mine"])
local name = 'stargate'
local localised_name = {name}

stargate.name = name
stargate.localised_name = localised_name
stargate.trigger_radius = 1
stargate.timeout = 5 * 60
stargate.max_health = 200
stargate.dying_explosion = nil
stargate.energy_usage = "25MW"
stargate.collision_box = {{-2.8, -2.8}, {2.8, 2.8}},
stargate.selection_box = {{-3, -3}, {3, 3}}
stargate.drawing_box = {{-3, -3.5}, {3, 3}}
stargate.se_allow_in_space = false
stargate.action =
{
  type = "direct",
  action_delivery =
  {
    type = "instant",
    target_effects =
    {
      {
        type = "create-sticker",
        sticker = "stargate-sticker",
        trigger_created_entity = true
      }
    }
  }
}
stargate.force_die_on_attack = false
stargate.trigger_force = "all"
stargate.order = name
stargate.picture_safe =
{
  filename = path.."stargate-open.png",
  priority = "medium",
  width = 500,
  height = 500,
  hr_version = {
    filename = path.."hr-stargate-open.png",
    priority = "medium",
    width = 1000,
    height = 1000,
    scale = 0.5,
  }
}
stargate.picture_set =
{
  filename = path.."stargate-open.png",
  priority = "medium",
  width = 500,
  height = 500,
  hr_version = {
    filename = path.."hr-stargate-open.png",
    priority = "medium",
    width = 1000,
    height = 1000,
    scale = 0.5,
  }
}
stargate.picture_set_enemy =
{
  filename = path.."stargate-open.png",
  priority = "medium",
  width = 500,
  height = 500,
  hr_version = {
    filename = path.."hr-stargate-open.png",
    priority = "medium",
    width = 1000,
    height = 1000,
    scale = 0.5,
  }
}
stargate.minable = {result = name, mining_time = 3}
stargate.flags =
{
  --"not-blueprintable",
  "placeable-neutral",
  "placeable-player",
  "player-creation",
  "not-upgradable"
}
stargate.collision_box = {{-1, -1},{1, 1}}
stargate.selection_box = {{-1, -1},{1, 1}}
stargate.map_color = {r = 0.5, g = 1, b = 1}

local sticker =
{
  type = "sticker",
  name = "stargate-sticker",
  --icon = "__base__/graphics/icons/slowdown-sticker.png",
  flags = {},
  animation = util.empty_sprite(),
  duration_in_ticks = 1,
  --target_movement_modifier = 1
}


local stargate_item =  table.deepcopy(data.raw.item["land-mine"])
stargate_item.name = name
stargate_item.localised_name = localised_name
stargate_item.place_result = name
stargate_item.icon = path.."stargate-icon.png"
stargate_item.icon_size = 500
stargate_item.icon_mipmaps = 0
stargate_item.subgroup = "circuit-network"


-- local fire = require("data/tf_util/tf_fire_util")

-- local stargate_explosion = util.copy(data.raw.explosion.explosion)
-- stargate_explosion.name = "stargate-explosion"
-- stargate_explosion.animations = fire.create_fire_pictures({scale = 1, animation_speed = 0.3})
-- stargate_explosion.sound =
-- {
--   filename = path.."stargate-explosion.ogg",
--   volume = 0.45
-- }

-- local stargate_explosion_2 = util.copy(stargate_explosion)
-- stargate_explosion_2.name = "stargate-explosion-no-sound"
-- stargate_explosion_2.sound = nil

local recipe = {
  type = "recipe",
  name = name,
  localised_name = localised_name,
  enabled = false,
  ingredients =
  {
    {"steel-plate", 45},
    {"advanced-circuit", 20},
    {"battery", 25},
  },
  energy_required = 5,
  result = name
}

local technology =
{
  type = "technology",
  name = name,
  localised_name = localised_name,
  localised_description = "",
  icon_size = 500,
  icon = path.."stargate-technology.png",
  effects =
  {
    {
      type = "unlock-recipe",
      recipe = name
    }
  },
  unit =
  {
    count = 500,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
    },
    time = 30
  },
  prerequisites = {"advanced-electronics", "battery"},
  order = "y-a"
}

local stargate_flying_text = util.copy(data.raw["flying-text"]["tutorial-flying-text"])
stargate_flying_text.name = "stargate-flying-text"

-- local hotkey_name = require"shared".hotkeys.focus_search
-- local hotkey =
-- {
--   type = "custom-input",
--   name = hotkey_name,
--   linked_game_control = "focus-search",
--   key_sequence = "Control + F"
-- }

data:extend
{
  stargate,
  stargate_item,
--   stargate_explosion,
--   stargate_explosion_2,
  recipe,
  technology,
  stargate_flying_text,
--   hotkey,
  sticker
}
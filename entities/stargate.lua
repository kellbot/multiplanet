local path = "__multiplanet__/entities/"
local stargate =  table.deepcopy(data.raw["land-mine"]["land-mine"])
local name = 'stargate'
local localised_name = {name}

local stargate = {
    type = "electric-energy-interface",
    name = "stargate",
    collision_box = {{-2, -2}, {2, 2}},
    selection_box = {{-3, -3}, {3, 3}},
    drawing_box = {{-3, -3.5}, {3, 3}},
--  timeout_to_close = 5 * 60    
    max_health = 5000,
    corpse = "medium-remnants",
    flags = {
        "not-blueprintable",
        "placeable-neutral",
        "placeable-player",
        "player-creation",
        "not-upgradable"
    },
    energy_source = {
        buffer_capacity = "1GJ",
        input_flow_limit = "50GW",
        output_flow_limit = "0kW",
        type = "electric",
        usage_priority = "secondary-input"
      },
    energy_production = "0KW",
    energy_usage = "10MW",
    se_allow_in_space = false,
    minable = {result = name, mining_time = 3},
    icon = path.."stargate-icon.png",
    icon_size = 1000,

    pictures =
    {
        north = 
            {
            filename = path.."stargate-north.png",
            priority = "medium",
            width = 1000,
            height = 1000,
            scale = 1,
            },
        south = 
            {
            filename = path.."stargate-south.png",
            priority = "medium",
            width = 1000,
            height = 1000,
            scale = 1,
            },
        east = 
            {
            filename = path.."stargate-east.png",
            priority = "medium",
            width = 1000,
            height = 1000,
            scale = 1,
            },
        west = 
            {
            filename = path.."stargate-west.png",
            priority = "medium",
            width = 1000,
            height = 1000,
            scale = 1,
        }
    },


}

local stargate_item = {
    type = "item",
    name = name,
    icon = path.."stargate-icon.png",
    icon_size = 1000,
    subgroup = "transport",
    stack_size = 1,
    place_result = name
}


local recipe = {
  type = "recipe",
  name = name,
  localised_name = localised_name,
  enabled = false,
  ingredients = {
    { "glass", 200 },
    { "copper-plate", 200 },
    { "steel-plate", 200 },
    { "concrete", 200 },
    { "battery", 100 },
    { "processing-unit", 100 },
  },
  energy_required = 10,
  result = name
}

local technology =
{
  type = "technology",
  name = name,
  localised_name = localised_name,
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

data:extend
{
  stargate,
  stargate_item,
  recipe,
  technology
}
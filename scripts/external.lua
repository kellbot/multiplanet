-- This is only here beacuse the crash site builder in AAI Industry is hardcoded to Nauvis
function build_crash_site(surface_id)
  local surface = game.surfaces[surface_id]
  local range = 20
  local trees = surface.find_entities_filtered{type="tree", area={{-range, -range}, {range, range}}}
  for _, tree in pairs(trees) do
      local distance = math.sqrt(tree.position.x * tree.position.x +  tree.position.y * tree.position.y)
      if math.random() > (distance / range) * 3 - 2 then
        if math.random() < 0.1 and distance > range / 2 then
          --surface.create_entity{name="fire-flame-on-tree", position = tree.position}
        else
          tree.destroy()
        end
      end
  end

  local create_list = {
    {names = {"rock-small"}, count = 30, radius = 5},
    {names = {"rock-small"}, count = 30, radius = 10},
    {names = {"rock-small"}, count = 30, radius = 20},
    {names = {"big-remnants"}, count = 5, radius = 12},
    {names = {"medium-remnants"}, count = 10, radius = 16},
    {names = {"small-remnants"}, count = 15, radius = 20},
    {names = {"aai-big-ship-wreck-1", "massive-explosion"}, count = 1, radius = 5},
    {names = {"aai-big-ship-wreck-2", "big-explosion"}, count = 1, radius = 5},
    {names = {"aai-big-ship-wreck-3"}, count = 1, radius = 5},
    {names = {"aai-medium-ship-wreck-1", "medium-explosion"}, count = 1, radius = 10},
    {names = {"aai-medium-ship-wreck-2"}, count = 1, radius = 10},
    {names = {"aai-small-ship-wreck"}, count = 30, radius = 20},
    {names = {"fire-flame-on-tree"}, count = 15, radius = 15, min_radius = 5},
    {names = {"dead-dry-hairy-tree", "fire-flame-on-tree", "fire-flame-on-tree"}, count = 10, radius = 20, min_radius = 5}
  }
  local containers = {}
  for _, settings in pairs(create_list) do
    local min_radius = settings.min_radius or 0
    for i = 1, settings.count, 1 do
      local try_position = {x = 0, y = 0}
      local safe_position = surface.find_non_colliding_position("aai-big-ship-wreck-1", try_position, 50, 1)
      safe_position = safe_position or try_position
      for _, name in pairs(settings.names) do
        if name == "rock-small" then
          surface.create_decoratives{check_collision = false, decoratives={{name=name, position = safe_position, amount = math.ceil(math.random() * 7)}}}
        else
          local entity = surface.create_entity{name=name, position=safe_position, force = game.forces["player"]}
          if not script.active_mods.IndustrialRevolution then
            if name == "aai-big-ship-wreck-1" and not game.item_prototypes["burner-assembling-machine"].has_flag("hidden") then
              entity.insert({name = "burner-assembling-machine"})
            end
            if name == "aai-big-ship-wreck-1" and not game.item_prototypes["burner-lab"].has_flag("hidden") then
              entity.insert({name = "burner-lab"})
            end
          end
          if not game.item_prototypes["transport-belt"].has_flag("hidden") then
            if name == "aai-big-ship-wreck-2" or name == "aai-big-ship-wreck-3" then
              entity.insert({name = "transport-belt", count = 42})
            end
          end
          if not game.item_prototypes["motor"].has_flag("hidden") then
            if name == "aai-big-ship-wreck-2" or name == "aai-big-ship-wreck-3" then
              entity.insert({name = "motor", count = 12})
            end
          end
          if entity.type == "container" then
            table.insert(containers, entity)
          end
        end
      end
    end
  end
  global.starting_containers = containers
end

-- from https://github.com/Oarcinae/FactorioScenarioMultiplayerSpawn
-- Function to generate a resource patch, of a certain size/amount at a pos.
function GenerateResourcePatch(surface, resourceName, diameter, pos, amount)
  local midPoint = math.floor(diameter/2)
  if (diameter == 0) then
      return
  end
  for y=-midPoint, midPoint do
      for x=-midPoint, midPoint do
          if ((x)^2 + (y)^2 < midPoint^2) then
              surface.create_entity({name=resourceName, amount=amount,
                  position={pos.x+x, pos.y+y}})
          end
      end
  end
end

-- Generate the basic starter resource around a given location.
function GenerateStartingResources(pos, surface)

  local rand_settings = {enabled = true, radius = 45, angle_offset = 2.32, angle_final = 4.46}
  local resource_tiles =  {
      ["iron-ore"] =
      {
          amount = 1500,
          size = 18,
          x_offset = -29,
          y_offset = 16
      },
      ["copper-ore"] =
      {
          amount = 1200,
          size = 18,
          x_offset = -28,
          y_offset = -3
      },
      ["stone"] =
      {
          amount = 1200,
          size = 16,
          x_offset = -27,
          y_offset = -34
      },
      ["coal"] =
      {
          amount = 1200,
          size = 16,
          x_offset = -27,
          y_offset = -20
      }
    }
    resource_patches =
    {
        ["crude-oil"] =
        {
            num_patches = 2,
            amount = 900000,
            x_offset_start = -3,
            y_offset_start = 48,
            x_offset_next = 6,
            y_offset_next = 0
        }
    }
  -- Generate all resource tile patches


    -- Create list of resource tiles
    local r_list = {}
    for k,_ in pairs(resource_tiles) do
        if (k ~= "") then
            table.insert(r_list, k)
        end
    end
    local shuffled_list = FYShuffle(r_list)

    -- This places resources in a semi-circle
    -- Tweak in config.lua
    local angle_offset = rand_settings.angle_offset
    local num_resources = #resource_tiles
    local theta = ((rand_settings.angle_final - rand_settings.angle_offset) / num_resources);
    local count = 0

    for _,k_name in pairs (shuffled_list) do
        local angle = (theta * count) + angle_offset;

        local tx = (rand_settings.radius * math.cos(angle)) + pos.x
        local ty = (rand_settings.radius * math.sin(angle)) + pos.y

        local pos = {x=math.floor(tx), y=math.floor(ty)}
        GenerateResourcePatch(surface, k_name, resource_tiles[k_name].size, pos, resource_tiles[k_name].amount)
        count = count+1
    end


  -- Generate special resource patches (oil)
  for p_name,p_data in pairs (resource_patches) do
      local oil_patch_x=pos.x+p_data.x_offset_start
      local oil_patch_y=pos.y+p_data.y_offset_start
      for i=1,p_data.num_patches do
          surface.create_entity({name=p_name, amount=p_data.amount,
                      position={oil_patch_x, oil_patch_y}})
          oil_patch_x=oil_patch_x+p_data.x_offset_next
          oil_patch_y=oil_patch_y+p_data.y_offset_next
      end
  end
end

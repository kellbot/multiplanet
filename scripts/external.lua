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
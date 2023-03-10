-- This is only here beacuse the crash site builder in AAI Industry is hardcoded to Nauvis
function build_crash_site(surface_id, pos, force)
  local surface = game.surfaces[surface_id]
  local range = 20
  local trees = surface.find_entities_filtered{type="tree", area={{-range + pos.x, -range + pos.y}, {range + pos.x, range+pos.y}}}
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
    {names = {"crash-site-spaceship"}, count = 1, radius = 20},
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
      local try_position = mpse_orientation_to_vector(math.random(), min_radius + (settings.radius - min_radius) * math.random()) --{x = 0, y = 0}
      try_position = mpse_vectors_add(pos, try_position)
      local safe_position = surface.find_non_colliding_position("aai-big-ship-wreck-1", try_position, 50, 1)
      safe_position = safe_position or try_position
      for _, name in pairs(settings.names) do
        if name == "rock-small" then
          surface.create_decoratives{check_collision = false, decoratives={{name=name, position = safe_position, amount = math.ceil(math.random() * 7)}}}
        else
          local entity = surface.create_entity{name=name, position=safe_position, force = force}
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


-- This is here because I don't know of another way to create staring resources
function mpse_vectors_add(a, b)
  return {x = a.x + b.x, y = a.y + b.y}
end

function mpse_orientation_to_vector(orientation, length)
  return {x = length * math.sin(orientation * 2 * math.pi), y = -length * math.cos(orientation * 2 * math.pi)}
end
function mpse_tile_to_position(tile_position)
  return {x = math.floor(tile_position.x)+0.5, y = math.floor(tile_position.y)+0.5}
end


function mpse_spawn_small_resources(surface, pos)

  local seed = surface.map_gen_settings.seed
  local rng = game.create_random_generator(seed)
  -- The starting resourecs of the map generation are inconsistent and spread out.
  -- Add some tiny patches to reduce the amount of running around at the start.
  -- We only care about super-early game, so just iron, copper, stone, and coal.
  -- If there are other resources added to the game then the naturally spawned resources will have to do for now.
  -- These resources are not designed to replace the normal starting resources at all.
  local valid_position_search_range = 256
  local cluster_primary_radius = 1-- get away from crash site
  local cluster_secondary_radius = 50
  local resources = {}
  if game.entity_prototypes["iron-ore"] then table.insert(resources, { name = "iron-ore", tiles = 200, amount = 100000}) end
  if game.entity_prototypes["copper-ore"] then table.insert(resources, { name = "copper-ore", tiles = 150, amount = 80000}) end
  if game.entity_prototypes["stone"] then table.insert(resources, { name = "stone", tiles = 150, amount = 80000}) end
  if game.entity_prototypes["coal"] then table.insert(resources, { name = "coal", tiles = 150, amount = 80000}) end

  local cluster_orientation = rng()
  local secondary_orientation = rng()
  local cluster_position = pos --mpse_orientation_to_vector(cluster_orientation, cluster_primary_radius)
  surface.request_to_generate_chunks(cluster_position, 4)
  surface.force_generate_chunk_requests()

  log("[gps="..math.floor(cluster_position.x)..","..math.floor(cluster_position.y).."]")
  local closed_tiles = {} -- 2d disctionary
  local open_tiles = {} -- 1d array

  local function close_tile(position)
    closed_tiles[position.x] = closed_tiles[position.x] or {}
    closed_tiles[position.x][position.y] = true
  end
  local function open_tile(set, position) -- don't open if closed
    if not (closed_tiles[position.x] and closed_tiles[position.x][position.y]) then
      table.insert(set, position)
      close_tile(position)
    end
  end
  local function open_neighbour_tiles(set, position)
    open_tile(set, mpse_vectors_add(position, {x=0,y=-1}))
    open_tile(set, mpse_vectors_add(position, {x=1,y=0}))
    open_tile(set, mpse_vectors_add(position, {x=0,y=1}))
    open_tile(set, mpse_vectors_add(position, {x=-1,y=0}))
  end

  for i, resource in pairs(resources) do
    resource.orientation = secondary_orientation + rng()
    local offset = mpse_orientation_to_vector(resource.orientation, rng(cluster_secondary_radius/2, cluster_secondary_radius))
    local position = mpse_tile_to_position(mpse_vectors_add(offset, cluster_position))

    local valid = surface.find_non_colliding_position(resource.name, position, valid_position_search_range, 1, true)
    if not valid then log("no valid position found") end
    resource.start_point = surface.find_non_colliding_position(resource.name, position, valid_position_search_range, 1, true) or position
    resource.open_tiles = {resource.start_point}
    resource.entities = {}
    resource.amount_placed = 0
  end
  local continue = true
  local repeats = 0
  while continue and repeats < 1000 do
    repeats = repeats + 1
    continue = false
    for _, resource in pairs(resources) do
      --if #resource.entities < resource.tiles then
      if resource.amount_placed < resource.amount then
        continue = true
        local try_tile
        if #resource.open_tiles > 0 then
          local choose = rng(#resource.open_tiles)
          try_tile = resource.open_tiles[choose]
          close_tile(try_tile)
        end
        if not try_tile then -- handle tiny island case
          try_tile = resource.start_point
        end
        local position = surface.find_non_colliding_position(resource.name, try_tile, valid_position_search_range, 1, true)
        if not position then -- exit
          resource.amount_placed = resource.amount
          log("Space Exploration failed to place starting resource, no valid positions in range. [".. resource.name.."]")
        else
          close_tile(try_tile)
          close_tile(position)
          local remaining = resource.amount - resource.amount_placed
          local amount = math.ceil(math.min( remaining * (0.01 + rng() * 0.005) + 100 + rng() * 100, remaining))
          resource.amount_placed = resource.amount_placed + amount
          table.insert(resource.entities, surface.create_entity{name = resource.name, position=position, amount=amount, enable_tree_removal=true, snap_to_tile_center =true})
          --Log.trace("Starting resource entity created "..resource.name.." ".. position.x.." "..position.y)
          open_neighbour_tiles(resource.open_tiles, position)
        end
      end
    end
  end

end


----------------------------
---- Biter Remover
---- This is taken from Biter-Remover
---- I have asked the author to provide a remote call so I can access it directly
------------------------------


global.remover = {}


--- Removes hostile biters, spawners, and worms from the passed-in surfaces.
--
-- @param force LuaForce Friendly force for which to find all hostile forces.
-- @param surfaces {LuaSurface} List of surfaces from which to remove the entities.
--
function remove_hostile_biters(force, surfaces)
    local hostile_forces = {}

    -- Create a list of forces that are hostile to the passed-in force.
    for _, game_force in pairs(game.forces) do
        if force.is_enemy(game_force) then
            table.insert(hostile_forces, game_force)
        end
    end

    -- Iterate over surfaces, and for each hostile force remove the (most likely) biter/spitter units, spawners, and
    -- worm turrets.
    for _, surface in pairs(surfaces) do
        for _, hostile_force in pairs(hostile_forces) do
            for _, entity in pairs(surface.find_entities_filtered({force = hostile_force})) do
                if entity.prototype.type == "unit" and
                   (string.find(entity.name, "biter") or string.find(entity.name, "spitter")) then
                   entity.destroy()
                elseif entity.prototype.type == "unit-spawner" then
                    entity.destroy()
                elseif entity.prototype.type == "turret" and string.find(entity.name, "worm") then
                    entity.destroy()
                end
            end
        end
    end
    -- Initialise the structure for backing-up existing values.
    global.biter_base_generation_size = global.biter_base_generation_size or {}

    -- List of surfaces that have been processed, used for informing players.
    local processed_surface_names = {}

    -- Drop biter base generation from map generation settings.
    for _, surface in pairs(surfaces) do
        local map_gen_settings = surface.map_gen_settings

        -- Ignore surfaces without autplace controls for enemy bases (such as ones from Factorissimo 2 and similar
        -- mods).
        if map_gen_settings.autoplace_controls and map_gen_settings.autoplace_controls["enemy-base"] then

            -- Store the original values for eventual re-enabling.
            if global.biter_base_generation_size[surface.name] ~= 0 then
                global.biter_base_generation_size[surface.name] = map_gen_settings.autoplace_controls["enemy-base"].size
            end

            map_gen_settings.autoplace_controls["enemy-base"].size = 0

            surface.map_gen_settings = map_gen_settings

            table.insert(processed_surface_names, surface.name)

        end

    end
    
    -- Output informative message to all players.
    local surface_names = {}
    for _, surface in pairs(surfaces) do
        table.insert(surface_names, surface.name)
    end

    
    table.sort(surface_names)
    game.print({"mpse.br-biters-removed", table.concat(surface_names, ", ")})
end
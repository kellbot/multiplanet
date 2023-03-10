-- Based on https://github.com/FentusGames/FactorioStartingLocations
-- Configurable
local request_gen_size = 7
local chart_size = (request_gen_size * 32) + 32
local debug = false

-- Globals
global.radius_distance = 500

function distance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt ( dx * dx + dy * dy )
end

function generate(action)
    local player = action.player
    local x = action.x
    local y = action.y
    
    if (debug) then player.print("Generate...", {r=0.1, g=0.7, b=0.1, a=1}) end
    
    player.surface.request_to_generate_chunks({x, y}, request_gen_size)
	player.surface.force_generate_chunk_requests()
    
    local area = {lefttop = {x = x-chart_size, y = y-chart_size}, rightbottom = {x = x+chart_size, y = y+chart_size}}
    
      
    for _, entity in pairs(player.surface.find_entities_filtered{area = area, force = "enemy"}) do 
        entity.destroy()
    end
    
    player.force.chart(player.surface, area)
    
	water_exists = false
	
	for _, water in pairs({"water", "deepwater", "water-green", "deepwater-green"}) do
		for _, t in pairs(player.surface.find_tiles_filtered {area = area, name = water}) do
			water_exists = true
		end
	end
	
	if (water_exists) then
		teleport({player = player, x = x, y = y, tick = game.tick, delay = 0, area = area})
	else
		create_spawn(player)
	end
end

function teleport(action)
    local player = action.player
    local x = action.x
    local y = action.y
    local area = action.area
    local spawn = {x = x, y = y, tries = 0, name = player.force.name}
 
    
    local safe_position = player.surface.get_tile({x, y}).collides_with("ground-tile")
    while safe_position == false do
        x = math.floor(math.random(area.lefttop.x, area.rightbottom.x))
        y = math.floor(math.random(area.lefttop.y, area.rightbottom.y))
        safe_position = player.surface.get_tile({x, y}).collides_with("ground-tile")
        spawn.tries = spawn.tries + 1
        if spawn.tries > 5 then --try a new spot
            spawn.tries = 0
            create_spawn(player)
        end
    end

    if safe_position then		
        table.insert(global.spawns, spawn)
        player.teleport({x, y}, player.surface)
        pos = { x = x, y = y}
        player.force.set_spawn_position(pos, player.surface.name)
        mpse_spawn_small_resources(player.surface, pos)
        build_crash_site(player.surface.index, {x = x-10, y = y-10})
        script.raise_event(global.mpse.relocate_event, {})
    else

    end
    
end

function create_spawn(player)
    player.print('Locating a new spawn, Please wait...')
    local min_distance_from_others = global.mpse.min_distance
    local radius_increment = (min_distance_from_others / 10)
    -- Distance spawns
    repeat
        local check = true
        
        
        -- Uniformly generate a random point within a circle (radius_distance)
        local angle = math.random() * math.pi * 2
        local radius = global.radius_distance
        local x = math.floor(radius * math.cos(angle))
        local y = math.floor(radius * math.sin(angle))
        
        -- Insure the random point is greater then min_distance_from_others
        for _, spawn in pairs(global.spawns) do
            game.print("Checking " .. spawn.name)
            if min_distance_from_others > distance(spawn.x, spawn.y, x, y) then
                check = false
            end
        end
        
        -- Check passed
        if check then
            generate({player = player, x = x, y = y, tick = game.tick, delay = 0})
        else
            global.radius_distance = global.radius_distance + radius_increment
        end
    until check
end

commands.add_command("mpse_list_spawns", "", function ()
    for __, spawn in pairs(global.spawns) do
        game.print(spawn.name)
    end
end)

commands.add_command("sl_respawn", "", function (event)
    local player = game.players[event.player_index]
    create_spawn(player)
end)
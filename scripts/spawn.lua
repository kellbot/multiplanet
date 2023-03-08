-- Based on https://github.com/FentusGames/FactorioStartingLocations
-- Configurable
local request_gen_size = 7
local chart_size = (request_gen_size * 32) + 32

local debug = false

-- Globals
global.spawns = {{name = 'player', x = 0, y = 0, lock = true, no_items_added = true}}
global.delayed_actions = {}
global.radius_distance = 0

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
    
    chart({player = player, x = x, y = y, tick = game.tick, delay = 600, area = area})
end

function chart(action)
    local player = action.player
    local x = action.x
    local y = action.y
    local area = action.area
    
    if (debug) then player.print("Chart...", {r=0.1, g=0.7, b=0.1, a=1}) end
    
    player.force.chart(player.surface, area)
    
    clear({player = player, x = x, y = y, tick = game.tick, delay = 300, area = area})
end

function clear(action)
    local player = action.player
    local x = action.x
    local y = action.y
    local area = action.area
    
    if (debug) then player.print("Clear...", {r=0.1, g=0.7, b=0.1, a=1}) end
    
    for _, entity in pairs(player.surface.find_entities_filtered{area = area, force = "enemy"}) do 
        entity.destroy()
    end
    
    ore({player = player, x = x, y = y, tick = game.tick, delay = 0, area = area})
end

function ore(action)
    local player = action.player
    local x = action.x
    local y = action.y
    local area = action.area
    
    if (debug) then player.print("Spawn Ore...", {r=0.1, g=0.7, b=0.1, a=1}) end
    pos = { x = x, y = y}
    player.print(player.surface.name)
    player.force.set_spawn_position(pos, player.surface.name)
    GenerateStartingResources(pos, player.surface)
    rechart({player = player, x = x, y = y, tick = game.tick, delay = 0, area = area})
end

function rechart(action)
    local player = action.player
    local x = action.x
    local y = action.y
    local area = action.area
    
    if (debug) then player.print("Rechart...", {r=0.1, g=0.7, b=0.1, a=1}) end
    
    player.force.chart(player.surface, area)
    
    water({player = player, x = x, y = y, tick = game.tick, delay = 300, area = area} )
end

function water(action)
    local player = action.player
    local x = action.x
    local y = action.y
    local area = action.area
    
    if (debug) then player.print("Water...", {r=0.1, g=0.7, b=0.1, a=1}) end
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
    
    if (debug) then player.print("Teleport...", {r=0.1, g=0.7, b=0.1, a=1}) end
    
    x = math.random(area.lefttop.x, area.rightbottom.x)
    y = math.random(area.lefttop.y, area.rightbottom.y)
    
    for _, spawn in pairs(global.spawns) do
        if spawn.name == player.name then
            if spawn.tries == nil then
                spawn.tries = 1
            else
                spawn.tries = spawn.tries + 1
                if spawn.tries > 5 then
                    spawn.tries = 0
                    global.delayed_actions = {}
                    create_spawn(player)
                end
            end
        end
    end
    
    if player.surface.get_tile({x, y}).collides_with("ground-tile") then
		action.x = x
		action.y = y
		
        player.teleport({x, y}, player.surface)
    end
end

function create_spawn(player)
    player.print('Locating a new spawn, Please wait...', {r=0.1, g=0.1, b=0.8, a=1})
    local min_distance_from_others = global.mpse.min_distance
    local radius_increment = (min_distance_from_others / 10)
    -- Distance spawns
    repeat
        local check = true
        
        
        -- Uniformly generate a random point within a circle (radius_distance)
        local angle = math.random() * math.pi * 2
        local radius = math.sqrt(math.random()) * global.radius_distance
        local x = math.floor(radius * math.cos(angle))
        local y = math.floor(radius * math.sin(angle))
        
        -- Insure the random point is greater then min_distance_from_others
        for _, spawn in pairs(global.spawns) do
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

commands.add_command("sl_reset", "", function ()
    global.delayed_actions = {}
end)

commands.add_command("sl_respawn", "", function (event)
    local player = game.players[event.player_index]
    create_spawn(player)
end)

script.on_event(defines.events, function(event)
    -- On Tick Event
    if event.name == defines.events.on_tick then
        -- Every 30 Ticks
        if game.tick % 30 == 0 then
            for i, action in pairs(global.delayed_actions) do
                if game.tick >= action.tick + action.delay then
                    if action.name == "generate"    then generate(i, action)    end
                    if action.name == "chart"		then chart(i, action)    	end
                    if action.name == "clear"       then clear(i, action)       end
                    if action.name == "ore"         then ore(i, action)         end
                    if action.name == "rechart"		then rechart(i, action)    	end
                    if action.name == "water"		then water(i, action)    	end
                    if action.name == "teleport"    then teleport(i, action)    end
                end
            end
        end
    end


end)

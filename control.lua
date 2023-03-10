-- control.lua
-- Mar 2022
require "scripts/external"
require "scripts/utils"
require "scripts/spawn"


SPAWN_COUNT = 60

script.on_init(function()
    local freeplay = remote.interfaces["freeplay"]
    if freeplay then  -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
    end
    global.players = {}
    global.spawns = {{name = 'player', x = 0, y = 0, tries = 0}}
    global.mpse = { min_distance = 1500, spawn_type= "shared" }
    global.mpse.relocate_event = script.generate_event_name()
    global.mpse.system_forces = {   enemy = true,
                                    neutral = true,
                                    capture= true,
                                    conquest= true,
                                    ignore= true,
                                    friendly= true}


end)


----------------------------------------
-- Gui 
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    
    local player_global = global.players[event.player_index]
    local player = game.get_player(event.player_index)
    
    local main_frame = player.gui.screen.mpse_main_frame
    local button_flow = player.gui.screen.mpse_main_frame.content_frame.button_flow
    local shared_flow = player.gui.screen.mpse_main_frame.content_frame.shared_flow

    if event.element.name == "mpse_new_planet" then
        player_global.spawn_type = 'own_planet'
    end
    if event.element.name == "mpse_new_base" then
        player_global.spawn_type = 'own_base'

    end
    if event.element.name == "mpse_shared_base" then
        player_global.spawn_type = 'shared'
    end
    if event.element.name == "mpse_continue" then
        local st = player_global.spawn_type 
        if (st == "own_planet") then


            local fn = "Planet-"..player.name
            remote.call("space-exploration", "setup_multiplayer_test", { force_name = fn, players = {player}, match_nauvis_seed = false})
            local pos = {x = 0, y = 0}
            build_crash_site(player.surface.index, pos, player.force)
            player.force.set_friend('player', true)

            for __, force in pairs(game.forces) do
                if not is_system_force(force.name) then player.force.set_friend(force, true) end
            end
            script.raise_event(global.mpse.relocate_event, {})
            table.insert(global.spawns, {name = fn, x = 0, y = 0, tries = 0})
            if game.active_mods['biter-remover'] then
                remove_hostile_biters(player.force, {player.surface})
            end
            
        elseif (st == 'own_base') then --if they want their own spawn on Nauvis
            local fn = 'Nauvis-'..player.name
            if not game.forces[fn] then player.force = game.create_force(fn)  end
            local spawn = create_spawn(player)

            -- no biters on nauvis                                
            remove_hostile_biters(game.forces['player'], {game.surfaces[1]})
        elseif (st == 'shared') then
            
            player.force = game.forces['Nauvis-Main'] and game.forces['Nauvis-Main'] or game.create_force('Nauvis-Main')
            remove_hostile_biters(game.forces['player'], {game.surfaces[1]})
            table.insert(global.spawns, {name = player.force.name, x = 0, y = 0, tries = 0})
            script.raise_event(global.mpse.relocate_event, {})
        end
    end


    shared_flow.mpse_shared_slider.enabled = (player_global.spawn_type == 'own_base')
    shared_flow.mpse_shared_textfield.enabled = (player_global.spawn_type == 'own_base')

    button_flow.mpse_new_planet.style = player_global.spawn_type == 'own_planet' and 'green_button' or 'button'
    button_flow.mpse_new_base.style = player_global.spawn_type == 'own_base' and 'green_button' or 'button'
    button_flow.mpse_shared_base.style = player_global.spawn_type == 'shared' and 'green_button' or 'button'



end)

script.on_event(defines.events.on_gui_value_changed, function(event)
    local player_global = global.players[event.player_index]
    local player = game.get_player(event.player_index)

    if event.element.name == "mpse_shared_slider" then
        local new_distance_count = event.element.slider_value
        global.mpse.min_distance = new_distance_count

        local shared_flow = player.gui.screen.mpse_main_frame.content_frame.shared_flow
        shared_flow.mpse_shared_textfield.text = tostring(new_distance_count)
    end

    script.on_event(defines.events.on_gui_text_changed, function(event)
        if event.element.name == "mpse_shared_textfield" then
            local player = game.get_player(event.player_index)
            local player_global = global.players[player.index]
    
            local new_distance_count = tonumber(event.element.text) or 200
            global.mpse.min_distance = new_distance_count
    
            local shared_flow = player.gui.screen.mpse_main_frame.content_frame.shared_flow
            shared_flow.mpse_shared_slider.slider_value = new_distance_count
        end
    end)
end)


function init_gui(player)

    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", direction="vertical", name="mpse_main_frame", caption={"mpse.join_window"}}
    main_frame.auto_center = true
    main_frame.style.vertically_stretchable = "on"
    


    local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="mpse_content_frame"}
    local button_flow = content_frame.add{type="flow", name="button_flow", direction="horizontal", style="mpse_controls_flow"}
  
    local shared_flow = content_frame.add{type="table", name="shared_flow", column_count = 3, style="relative_gui_table"}
    shared_flow.style.horizontal_spacing = 10

    button_flow.add{type="button", name="mpse_new_planet", caption={"mpse.own_planet"}}
    button_flow.add{type="button", name="mpse_new_base", caption={"mpse.own_base"}}
    button_flow.add{type="button", name="mpse_shared_base", caption={"mpse.shared_base"}, style="green_button"}
    shared_flow.add{type="label", name="mpse_shared_label", caption={"mpse.base_distance"}}
    local slider = shared_flow.add{type="slider", name="mpse_shared_slider", value= global.mpse.min_distance, minimum_value=750, maximum_value=5000, value_step=250, style="notched_slider"}
    slider.enabled = false
    slider.style.width = 250
    local distance_text = shared_flow.add{type="textfield", name="mpse_shared_textfield", text=  tostring(global.mpse.min_distance), numeric=true, allow_decimal=false, allow_negative=false, style="mpse_controls_textfield", enabled=false}
    distance_text.enabled = false;

    local confirm_flow = main_frame.add{type="flow", name="confirm_flow", direction="horizontal", style="mpse_bottom_flow"}
    local filler = confirm_flow.add{type="empty-widget", style="draggable_space_with_no_left_margin"}
    filler.style.height = 30
    filler.style.width = 300
    filler.style.vertically_stretchable = false
    local continue_button = confirm_flow.add{type="button", name="mpse_continue", caption={"continue"}, style="confirm_button"}
    confirm_flow.style.horizontal_align = "right"

    script.on_event(global.mpse.relocate_event, function(event)
        gui_close(player)
    end)
end

function gui_open(player)
    if not  player.gui.screen.mpse_main_frame then 
        init_gui(player)
    elseif not player.gui.screen.mpse_main_frame.visible then
        player.gui.screen.mpse_main_frame.visible = true
    end
end

function gui_close(player)
    if player.gui.screen.mpse_main_frame.visible then
        player.gui.screen.mpse_main_frame.visible = false
    end

end


----------------------------------------
-- Player Events
-- 
----------------------------------------

script.on_event(defines.events.on_player_created, function(event)
    global.open_informatron_check = true -- triggers a check in `on_nth_tick_60`

    local player = game.players[event.player_index]
    global.players[player.index] = { spawn_type = global.mpse.spawn_type}
 

end)

----------------------------------------
----- Research 
----------------------------------------
-- Research Complete
script.on_event(defines.events.on_research_finished, function(event)
    local technology = event.research
    -- look for forces who haven't completed the research
    for __, f in pairs(game.forces) do
        if not f.technologies[technology.name].researched then
        -- Give them a 25% completion bump
            local progress = f.get_saved_technology_progress(technology.name)
            local current_research = f.current_research
            local queue = f.research_queue
            local is_active = false
            if current_research and current_research.name == technology.name then -- if they're currently working on it we need to pause it
                is_active = true 
                f.research_queue = nil
            end

            if not progress then --they haven't started it
                f.set_saved_technology_progress(technology.name, 0.25)
            else 
                local new_progress = progress + 0.25
                if new_progress >= 1 then 
                    if is_active then
                        new_progress = 0.99
                        f.set_saved_technology_progress(technology.name, new_progress)
                    else 
                        f.researched = true
                    end
                else 
                    f.set_saved_technology_progress(technology.name, new_progress)
                end
            end
            if is_active then
                f.add_research(technology.name)
                f.research_queue = queue
            end
            -- TODO : localize this
            f.print("Congratulations, " .. technology.force.name .. " have completed " .. technology.name .. " and contributed their knowledge to your progress")
        end
    end
end)


----------------------------------------
---- Cutscene / GUI stuff
----------------------------------------

script.on_event(defines.events.on_cutscene_cancelled, function (event)
    local player = game.players[event.player_index]
    gui_open(player)
end)

function on_nth_tick_30(event)
    if global.open_informatron_check and event.tick >= 600 then
        for _, player in pairs(game.connected_players) do
            if player.force.name == 'player' then gui_open(player) end -- if they're still on the default team
        end
        global.open_informatron_check = nil
    end
end
script.on_nth_tick(30, on_nth_tick_30)
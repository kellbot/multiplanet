-- control.lua
-- Mar 2022
require('scripts/external.lua')

script.on_init(function()
    local freeplay = remote.interfaces["freeplay"]
    if freeplay then  -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
    end
    global.players = {}
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
            build_crash_site(player.surface.index)
            player.print("Welcome to planet "..player.surface.name)
            main_frame.visible = false
        elseif (st == 'own_base') then
            local fn = 'Nauvis-'..player.name
            -- game.forces['name'].set_spawn_position({x = #, y = #}, game.surfaces[1])
        elseif (st == 'shared') then
            player.force = 'Nauvis-Main'
        end
    end


    shared_flow.mpse_shared_slider.enabled = (player_global.spawn_type == 'shared')
    shared_flow.mpse_shared_textfield.enabled = (player_global.spawn_type == 'shared')

    button_flow.mpse_new_planet.style = player_global.spawn_type == 'own_planet' and 'green_button' or 'button'
    button_flow.mpse_new_base.style = player_global.spawn_type == 'own_base' and 'green_button' or 'button'
    button_flow.mpse_shared_base.style = player_global.spawn_type == 'shared' and 'green_button' or 'button'



end)

script.on_event(defines.events.on_gui_value_changed, function(event)
    local player_global = global.players[event.player_index]
    local player = game.get_player(event.player_index)

    if event.element.name == "mpse_shared_slider" then
        local new_distance_count = event.element.slider_value
        player_global.spawn_distance = new_distance_count

        local shared_flow = player.gui.screen.mpse_main_frame.content_frame.shared_flow
        shared_flow.mpse_shared_textfield.text = tostring(new_distance_count)
    end

    script.on_event(defines.events.on_gui_text_changed, function(event)
        if event.element.name == "mpse_shared_textfield" then
            local player = game.get_player(event.player_index)
            local player_global = global.players[player.index]
    
            local new_distance_count = tonumber(event.element.text) or 0
            player_global.spawn_distance = new_distance_count
    
            local shared_flow = player.gui.screen.mpse_main_frame.content_frame.shared_flow
            shared_flow.mpse_shared_slider.slider_value = capped_button_count
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
  
    local shared_flow = content_frame.add{type="flow", name="shared_flow", direction="horizontal", style="mpse_controls_flow"}

    button_flow.add{type="button", name="mpse_new_planet", caption={"mpse.own_planet"}}
    button_flow.add{type="button", name="mpse_new_base", caption={"mpse.own_base"}}
    button_flow.add{type="button", name="mpse_shared_base", caption={"mpse.shared_base"}, style="green_button"}
    shared_flow.add{type="slider", name="mpse_shared_slider", value=1000, minimum_value=300, maximum_value=2000, value_step=100, style="notched_slider", enabled=false}
    shared_flow.add{type="textfield", name="mpse_shared_textfield", text="1000", numeric=true, allow_decimal=false, allow_negative=false, style="mpse_controls_textfield", enabled=false}
    shared_flow.mpse_shared_slider.enabled = false;

    local confirm_flow = main_frame.add{type="flow", name="confirm_flow", direction="horizontal", style="mpse_bottom_flow"}
    local continue_button = confirm_flow.add{type="button", name="mpse_continue", caption={"continue"}, style="confirm_button"}
    continue_button.style.horizontal_align = "right"
end

function gui_open(player)
    init_gui(player)
end
----------------------------------------
-- Player Events
-- 
----------------------------------------

script.on_event(defines.events.on_player_created, function(event)
    global.open_informatron_check = true -- triggers a check in `on_nth_tick_60`

    local player = game.players[event.player_index]
    global.players[player.index] = { spawn_type = "shared" }
 

end)

function on_nth_tick_30(event)
    if global.open_informatron_check and event.tick >= 600 then
        for _, player in pairs(game.connected_players) do
            gui_open(player)
        end
        global.open_informatron_check = nil
    end
end
script.on_nth_tick(30, on_nth_tick_30)
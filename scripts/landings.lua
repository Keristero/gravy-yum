-- Automatically adds landings for server warps to your server
-- Just gotta add some custom properties to your Server Warps
--   "IncomingData" (string) secret to share with the server that is linking to you; for their "Data"
--   "Direction" (string) direction the warp will make the player walk on arrival; defaults to "Down"
--   "WarpIn" (boolean) should the warp in animation be shown (laser from sky)
--   "SpecialAnimation" (string) name of special animation which should play on warp in, not compatible with "WarpIn"
--      fall_in
local landings = {}
local delay = require('scripts/libs/delay')
local player_animations = {}

function tick(delta_time)
    delay.on_tick(delta_time)
end


--Animations
local fall_in_animation = {
    --these offsets will modify the warp landing location so that the player can animate from their spawn location nicely
    pre_animation_offsets={
        x=0,
        y=0,
        z=20
    },
    lock_camera_on_landing=true,
    animate=function(player_id)
        local player_pos = Net.get_player_position(player_id)
        local area_id = Net.get_player_area(player_id)
        local landing_z = player_pos.z-20
        local fall_duration = 1
        local keyframes = {{
            properties={{
                property="Z",
                value=player_pos.z
            }},
            duration=0.0
        }}
        keyframes[#keyframes+1] = {
            properties={{
                property="Z",
                ease="Linear",
                value=landing_z
            }},
            duration=1
        }
        Net.animate_player_properties(player_id, keyframes)
        delay.seconds(function ()
            local sound_path = '/server/assets/landings/earthquake.ogg'
            Net.play_sound(area_id, sound_path)
            Net.shake_player_camera(player_id, 3, 2)
            Net.unlock_player_input(player_id)
        end,fall_duration)
    end
}

local lev_beast_in_animation = {
    --these offsets will modify the warp landing location so that the player can animate from their spawn location nicely
    pre_animation_offsets={
        x=0,
        y=0,
        z=0
    },
    lock_camera_on_landing=false,
    animate=function(player_id)
        local player_pos = Net.get_player_position(player_id)
        local area_id = Net.get_player_area(player_id)
        
        local lev_beast_id = "lev_beast"..player_id
        Net.create_bot(lev_beast_id, {
            texture_path = "/server/assets/landings/lev-beast-64-65.png",
            animation_path = "/server/assets/landings/lev-beast-64-65.animation",
            area_id = area_id,
            x = player_pos.x,
            y = player_pos.y-5,
            z = player_pos.z+5
        })

        local beast_z_offset = 3
        local seconds_arriving = 3
        local seconds_here = 1
        local seconds_leaving = 3

        local player_keyframes = {{
            properties={{
                property="Y",
                value=player_pos.y-3,
            },{
                property="Z",
                value=player_pos.z+17
            }},
            duration=0
        }}
        player_keyframes[#player_keyframes+1] = {
            properties={{
                property="Y",
                ease="Out",
                value=player_pos.y
            },{
                property="Z",
                ease="Out",
                value=player_pos.z
            }},
            duration=seconds_arriving
        }

        local beast_keyframes = {{
            properties={{
                property="Y",
                value=player_pos.y-3,
            },{
                property="Z",
                value=player_pos.z+17+beast_z_offset
            }},
            duration=0
        }}
        beast_keyframes[#beast_keyframes+1] = {
            properties={{
                property="Y",
                ease="Out",
                value=player_pos.y
            },{
                property="Z",
                ease="Out",
                value=player_pos.z+beast_z_offset
            }},
            duration=seconds_arriving
        }
        beast_keyframes[#beast_keyframes+1] = {
            properties={{
                property="Y",
                value=player_pos.y
            },{
                property="Z",
                value=player_pos.z+beast_z_offset
            }},
            duration=seconds_here
        }
        beast_keyframes[#beast_keyframes+1] = {
            properties={{
                property="Y",
                ease="In",
                value=player_pos.y+3
            },{
                property="Z",
                ease="In",
                value=player_pos.z+17+beast_z_offset
            }},
            duration=seconds_leaving
        }
        Net.animate_player(player_id, "IDLE_DL",true)
        Net.animate_player_properties(player_id, player_keyframes)
        Net.animate_bot_properties(lev_beast_id, beast_keyframes)
        delay.seconds(function ()
            local sound_path = '/server/assets/landings/lev-bus-arrive.ogg'
            Net.play_sound_for_player(player_id, sound_path)
        end,0.1)
        delay.seconds(function ()
            local sound_path = '/server/assets/landings/lev-bus-leave.ogg'
            Net.play_sound_for_player(player_id, sound_path)
            Net.unlock_player_input(player_id)
        end,seconds_arriving+seconds_here)
        delay.seconds(function ()
            Net.remove_bot(lev_beast_id)
        end,seconds_arriving+seconds_here+seconds_leaving)
    end
}

local lev_beast_out_animation = {
    --these offsets will modify the warp landing location so that the player can animate from their spawn location nicely
    pre_animation_offsets={
        x=0,
        y=0,
        z=0
    },
    lock_camera_on_landing=false,
    leave_animation_duration = 7,
    animate=function(player_id)
        local player_pos = Net.get_player_position(player_id)
        local area_id = Net.get_player_area(player_id)
        
        local lev_beast_id = "lev_beast"..player_id
        Net.create_bot(lev_beast_id, {
            texture_path = "/server/assets/landings/lev-beast-64-65.png",
            animation_path = "/server/assets/landings/lev-beast-64-65.animation",
            area_id = area_id,
            x = player_pos.x,
            y = player_pos.y-5,
            z = player_pos.z+5
        })

        local beast_z_offset = 3
        local seconds_arriving = 3
        local seconds_here = 1
        local seconds_leaving = 3

        local player_keyframes = {{
            properties={{
                property="Y",
                value=player_pos.y,
            },{
                property="Z",
                value=player_pos.z
            }},
            duration=seconds_arriving+seconds_here
        }}
        player_keyframes[#player_keyframes+1] = {
            properties={{
                property="Y",
                ease="In",
                value=player_pos.y+3
            },{
                property="Z",
                ease="In",
                value=player_pos.z+17
            }},
            duration=seconds_arriving
        }

        local beast_keyframes = {{
            properties={{
                property="Y",
                value=player_pos.y-3,
            },{
                property="Z",
                value=player_pos.z+17+beast_z_offset
            }},
            duration=0
        }}
        beast_keyframes[#beast_keyframes+1] = {
            properties={{
                property="Y",
                ease="Out",
                value=player_pos.y
            },{
                property="Z",
                ease="Out",
                value=player_pos.z+beast_z_offset
            }},
            duration=seconds_arriving
        }
        beast_keyframes[#beast_keyframes+1] = {
            properties={{
                property="Y",
                value=player_pos.y
            },{
                property="Z",
                value=player_pos.z+beast_z_offset
            }},
            duration=seconds_here
        }
        beast_keyframes[#beast_keyframes+1] = {
            properties={{
                property="Y",
                ease="In",
                value=player_pos.y+3
            },{
                property="Z",
                ease="In",
                value=player_pos.z+17+beast_z_offset
            }},
            duration=seconds_leaving
        }
        local player_mugshot = Net.get_player_mugshot(player_id)
        local sound_path = '/server/assets/landings/lev-bus-arrive.ogg'
        Net.play_sound(area_id, sound_path)
        Net.animate_player(player_id, "IDLE_DL",true)
        Net.animate_player_properties(player_id, player_keyframes)
        Net.animate_bot_properties(lev_beast_id, beast_keyframes)
        delay.seconds(function ()
            Net.message_player(player_id, "AHHH! The Lev Beast is here!?", player_mugshot.texture_path, player_mugshot.animation_path)
        end,0.1)
        delay.seconds(function ()
            local sound_path = '/server/assets/landings/lev-bus-leave.ogg'
            Net.play_sound(area_id, sound_path)
        end,seconds_arriving+seconds_here)
        delay.seconds(function ()
            Net.remove_bot(lev_beast_id)
        end,seconds_arriving+seconds_here+seconds_leaving)
    end
}

--Map animation functions to text labels
local special_animations = {
    fall_in = fall_in_animation,
    lev_beast_in = lev_beast_in_animation,
    lev_beast_out = lev_beast_out_animation
}

function doAnimationForWarp(player_id,animation_name)
    print('[Landings] doing special animation '..animation_name)
    Net.lock_player_input(player_id)
    special_animations[animation_name].animate(player_id)
end

function add_landing(area_id, incoming_data, x, y, z, direction, warp_in, special_animation)
    local new_landing = {
        area_id = area_id,
        warp_in = warp_in,
        x = x,
        y = y,
        z = z,
        pre_animation_x=x,
        pre_animation_y=y,
        pre_animation_z=z,
        direction = direction,
        special_animation = special_animation
    }
    landings[incoming_data] = new_landing
    
    print('[Landings] added landing in '..area_id)
end

local areas = Net.list_areas()
for i, area_id in next, areas do
    local objects = Net.list_objects(area_id)
    for i, object_id in next, objects do
        local object = Net.get_object_by_id(area_id, object_id)
        local incoming_data = object.custom_properties.IncomingData
        local special_animation = object.custom_properties.SpecialAnimation
        if object.type == "Server Warp" and incoming_data then
            local direction = object.custom_properties.Direction or "Down"
            local warp_in = object.custom_properties.WarpIn == "true"
            add_landing(area_id, incoming_data, object.x+0.5, object.y+0.5, object.z, direction, warp_in,special_animation)
        end
    end
end

function handle_player_request(player_id, data)
    if data == nil or data == "" then
        return
    end
    for key, l in next, landings do
        if data == key then
            local entry_x = l["x"]
            local entry_y = l["y"]
            local entry_z = l["z"]
            if l["special_animation"] then
                local special_animation_name = l["special_animation"]
                if special_animations[special_animation_name] then
                    local special_animation = special_animations[special_animation_name]
                    player_animations[player_id] = special_animation_name
                    entry_x = entry_x + special_animation.pre_animation_offsets.x
                    entry_y = entry_y + special_animation.pre_animation_offsets.y
                    entry_z = entry_z + special_animation.pre_animation_offsets.z
                end
            end
            Net.transfer_player(player_id, l["area_id"], l["warp_in"], entry_x, entry_y, entry_z, l["direction"])
            return
        end
    end
    print('[Landings] no landing for '..data)
end

function handle_object_interaction(player_id, object_id)
    local area_id = Net.get_player_area(player_id)
    local warp_object = Net.get_object_by_id(area_id,object_id)
    if warp_object.type ~= "Lev Beast Warp" then
        return
    end
    local warp_properties = warp_object.custom_properties
    if warp_properties.Address and warp_properties.Port then
        local warp_out = warp_properties.WarpOut == "true"
        local data = warp_properties.Data
        if warp_properties.LeaveAnimation then
            doAnimationForWarp(player_id,warp_properties.LeaveAnimation)
        end
        delay.seconds(function ()
            Net.transfer_server(player_id, warp_properties.Address, warp_properties.Port, warp_out, data)
        end,special_animations[warp_properties.LeaveAnimation].leave_animation_duration)
    end
end

function handle_player_join(player_id)
    if player_animations[player_id] then
        local special_animation = special_animations[player_animations[player_id]]
        doAnimationForWarp(player_id,player_animations[player_id])
        player_animations[player_id] = nil
    end
end

print('[Landings] Loaded')
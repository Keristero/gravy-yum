local arrow_up_left_out = {
    --these offsets will modify the warp landing location so that the player can animate from their spawn location nicely
    pre_animation_offsets={
        x=0,
        y=0,
        z=0
    },
    lock_camera_on_landing=false,
    duration = 1,--delay in seconds from start of animation till player warps out
    animate=function(player_id)
        local player_pos = Net.get_player_position(player_id)
        local area_id = Net.get_player_area(player_id)
        
        local seconds_leaving = 1

        local player_keyframes = {{
            properties={{
                property="X",
                ease="Linear",
                value=player_pos.x,
            }},
            duration=0
        }}
        player_keyframes[#player_keyframes+1] = {
            properties={{
                property="X",
                ease="Linear",
                value=player_pos.x-1
            }},
            duration=seconds_leaving
        }
        Net.animate_player_properties(player_id,player_keyframes)
    end
}

return arrow_up_left_out
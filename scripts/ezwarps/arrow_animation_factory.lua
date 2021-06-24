local delay = require('scripts/libs/delay')

local Direction = {
    UP_LEFT = "Up Left",
    UP_RIGHT = "Up Right",
    DOWN_LEFT = "Down Left",
    DOWN_RIGHT = "Down Right",
  }
  
  local reverse_table = {
    ["Up Left"] = "Down Right",
    ["Up Right"] = "Down Left",
    ["Down Left"] = "Up Right",
    ["Down Right"] = "Up Left",
  }

local animation_length = 1

function create_arrow_animation(is_arriving,direction_str)
    local x_distance = 0
    local y_distance = 0
    local x_start_offset = 0
    local y_start_offset = 0
    if direction_str == Direction.UP_LEFT then
        x_distance = -1
    elseif direction_str == Direction.DOWN_RIGHT then
        x_distance = 1
    elseif direction_str == Direction.UP_RIGHT then
        y_distance = -1
    elseif direction_str == Direction.DOWN_LEFT then
        y_distance = 1
    end
    if is_arriving then
        x_start_offset = x_distance
        y_start_offset = y_distance
        x_distance = x_distance*-1
        y_distance = y_distance*-1
    end

    local new_animation = {
        pre_animation_offsets={
            x=x_start_offset,
            y=y_start_offset,
            z=0
        },
        duration = animation_length,--delay in seconds from start of animation till player warps out
        animate=function(player_id)
            local player_pos = Net.get_player_position(player_id)
            local area_id = Net.get_player_area(player_id)
            local player_keyframes = {{
                properties={{
                    property="X",
                    ease="Linear",
                    value=player_pos.x,
                },
                {
                    property="Y",
                    ease="Linear",
                    value=player_pos.y
                }},
                duration=0
            }}
            player_keyframes[#player_keyframes+1] = {
                properties={{
                    property="X",
                    ease="Linear",
                    value=player_pos.x+x_distance
                },
                {
                    property="Y",
                    ease="Linear",
                    value=player_pos.y+y_distance
                }},
                duration=animation_length
            }
            if is_arriving then
                Net.move_player_camera(player_id, player_pos.x+x_distance, player_pos.y+y_distance, player_pos.z, animation_length)
            else
                Net.move_player_camera(player_id, player_pos.x, player_pos.y, player_pos.z, animation_length)
            end
            Net.animate_player_properties(player_id,player_keyframes)
            delay.for_player(player_id,function ()
                Net.unlock_player_camera(player_id)
            end,animation_length)
        end
    }
    return new_animation
end

return create_arrow_animation
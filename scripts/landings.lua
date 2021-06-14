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

--Map animation functions to text labels
local special_animations = {
    fall_in = fall_in_animation
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

function handle_player_join(player_id)
    if player_animations[player_id] then
        local special_animation = special_animations[player_animations[player_id]]
        doAnimationForWarp(player_id,player_animations[player_id])
        player_animations[player_id] = nil
    end
end

print('[Landings] Loaded')
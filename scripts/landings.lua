-- Automatically adds landings for server warps to your server
-- Just gotta add some custom properties to your Server Warps
--   "IncomingData" (string) secret to share with the server that is linking to you; for their "Data"
--   "Direction" (string) direction the warp will make the player walk on arrival; defaults to "Down"
local landings = {}
local player_animations = {}


--Animations
function animate_fall_in(player_id)
    local player_pos = Net.get_player_position(player_id)
    print('player pos x'..player_pos.x)
    local keyframes = {{
        properties={{
            property="Z",
            value=player_pos.z+20
        }},
        duration=0.0
    }}
    print('landing start pos'..player_pos.z-20)
    keyframes[#keyframes+1] = {
        properties={{
            property="Z",
            ease="Linear",
            value=player_pos.z
        }},
        duration=1
    }
    Net.animate_player_properties(player_id, keyframes)
    Net.shake_player_camera(player_id, 3, 3)
end

--Map animation functions to text labels
local animation_functions = {
    fall_in = animate_fall_in
}

function doAnimationForWarp(player_id,animation_name)
    print('[Landings] doing special animation '..animation_name)
    Net.lock_player_input(player_id)
    animation_functions[animation_name](player_id)
    Net.unlock_player_input(player_id)
end

function add_landing(area_id, incoming_data, x, y, z, direction, warp_in, special_animation)
    local new_landing = {
        area_id = area_id,
        warp_in = warp_in,
        x = x,
        y = y,
        z = z,
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
            Net.transfer_player(player_id, l["area_id"], l["warp_in"], l["x"], l["y"], l["z"], l["direction"])
            if l["special_animation"] then
                player_animations[player_id] = l["special_animation"]
            end
            return
        end
    end
    print('[Landings] no landing for '..data)
end

function handle_player_join(player_id)
    if player_animations[player_id] then
        doAnimationForWarp(player_id,player_animations[player_id])
        player_animations[player_id] = nil
    end
end

print('[Landings] Loaded')
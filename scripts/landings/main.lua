--for timed events
local delay = require('scripts/libs/delay')

--arrival / leaving animations
local special_animations = {
    fall_in = require('scripts/landings/fall_in_animation'),
    lev_beast_in = require('scripts/landings/lev_beast_in_animation'),
    lev_beast_out = require('scripts/landings/lev_beast_out_animation')
}

local landings = {}
local player_animations = {}
local player_interactions = {}

function tick(delta_time)
    delay.on_tick(delta_time)
end

function doAnimationForWarp(player_id,animation_name)
    print('[Landings] doing special animation '..animation_name)
    Net.lock_player_input(player_id)
    special_animations[animation_name].animate(player_id)
end

function add_landing(area_id, incoming_data, x, y, z, direction, warp_in, arrival_animation)
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
        arrival_animation = arrival_animation
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
        local arrival_animation = object.custom_properties.ArrivalAnimation
        if incoming_data then
            if object.type == "Server Warp" or "Custom Warp" or "Interact Warp" then
                local direction = object.custom_properties.Direction or "Down"
                local warp_in = object.custom_properties.WarpIn == "true"
                add_landing(area_id, incoming_data, object.x+0.5, object.y+0.5, object.z, direction, warp_in,arrival_animation)
            end
        end
    end
end

function handle_player_request(player_id, data)
    print('[Landings] player '..player_id..' requested connection with data: '..data)
    if data == nil or data == "" then
        return
    end
    for key, l in next, landings do
        if data == key then
            local entry_x = l["x"]
            local entry_y = l["y"]
            local entry_z = l["z"]
            if l["arrival_animation"] then
                local special_animation_name = l["arrival_animation"]
                if special_animations[special_animation_name] then
                    local special_animation = special_animations[special_animation_name]
                    player_animations[player_id] = special_animation_name
                    entry_x = entry_x + special_animation.pre_animation_offsets.x
                    entry_y = entry_y + special_animation.pre_animation_offsets.y
                    entry_z = entry_z + special_animation.pre_animation_offsets.z
                    print('[Landings] stored arrival animation '..special_animation_name..' to run when player joins')
                end
            end
            Net.transfer_player(player_id, l["area_id"], l["warp_in"], entry_x, entry_y, entry_z, l["direction"])
            return
        end
    end
    print('[Landings] no landing for '..data)
end

function duplicate_player_interaction(player_id,object_id)
    if player_interactions[player_id] == object_id then
        return true
    else
        player_interactions[player_id] = object_id
        return false
    end
end

function handle_object_interaction(player_id, object_id)
    if duplicate_player_interaction(player_id, object_id) then
        return
    end
    local area_id = Net.get_player_area(player_id)
    local warp_object = Net.get_object_by_id(area_id,object_id)
    if warp_object.type ~= "Interact Warp" then
        return
    end
    use_warp(player_id,warp_object)
end

function use_warp(player_id,warp_object)
    local warp_properties = warp_object.custom_properties
    if warp_properties.Address and warp_properties.Port then
        local warp_out = warp_properties.WarpOut == "true"
        local data = warp_properties.Data
        local warp_delay = 0
        if warp_properties.LeaveAnimation then
            doAnimationForWarp(player_id,warp_properties.LeaveAnimation)
            warp_delay = special_animations[warp_properties.LeaveAnimation].leave_animation_duration
        end
        delay.seconds(function ()
            Net.transfer_server(player_id, warp_properties.Address, warp_properties.Port, warp_out, data)
            player_interactions[player_id] = nil
        end,warp_delay)
    end
end

function handle_player_join(player_id)
    if player_animations[player_id] then
        doAnimationForWarp(player_id,player_animations[player_id])
        player_animations[player_id] = nil
    end
end

print('[Landings] Loaded')
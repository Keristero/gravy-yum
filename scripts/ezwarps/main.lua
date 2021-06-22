--for timed events
local delay = require('scripts/libs/delay')

--arrival / leaving animations
local special_animations = {
    fall_in = require('scripts/landings/fall_in_animation'),
    lev_beast_in = require('scripts/landings/lev_beast_in_animation'),
    lev_beast_out = require('scripts/landings/lev_beast_out_animation')
}

local landings = {}
local radius_warps = {}
local player_animations = {}
local player_interactions = {}
local warp_types_with_landings = {"Server Warp","Custom Warp","Interact Warp","Radius Warp"}
local radius_warp_immunity = {}

function tick(delta_time)
    delay.on_tick(delta_time)
    check_radius_warps()
end

function check_radius_warps()
    local areas = Net.list_areas()
    for i, area_id in next, areas do
        local players = Net.list_players(area_id)
        for i, player_id in next, players do
            for index, radius_warp in ipairs(radius_warps) do
                if radius_warp_immunity[player_id] ~= radius_warp.object.id then
                    --If the player is not currently immune to the warp
                    local player_pos = Net.get_player_position(player_id)
                    if player_pos.z == radius_warp.object.x then
                        local distance = math.sqrt((player_pos.x - radius_warp.object.x) ^ 2 + (player_pos.y - radius_warp.object.y) ^ 2)
                        if distance < radius_warp.activation_radius then
                            use_warp(player_id,radius_warp.object)
                        end
                    end
                end
            end
        end
    end
end


function doAnimationForWarp(player_id,animation_name)
    print('[ezwarps] doing special animation '..animation_name)
    Net.lock_player_input(player_id)
    special_animations[animation_name].animate(player_id)
end

local areas = Net.list_areas()
for i, area_id in next, areas do
    local objects = Net.list_objects(area_id)
    for i, object_id in next, objects do
        local object = Net.get_object_by_id(area_id, object_id)
        local arrival_animation = object.custom_properties.ArrivalAnimation

        if table_has_value(warp_types_with_landings,object.type) then
            --For inter server warps, add landings
            local incoming_data = object.custom_properties.IncomingData
            if incoming_data then
                local direction = object.custom_properties.Direction or "Down"
                local warp_in = object.custom_properties.WarpIn == "true"
                add_landing(area_id, incoming_data, object.x+0.5, object.y+0.5, object.z, direction, warp_in,arrival_animation)
            end
        end

        if object.type == "Radius Warp" then
            --radius warp, activates when you walk in range
            local target_object = object.custom_properties["Target Object"]
            local activation_radius = object.custom_properties["Activation Radius"]
            local target_area = object.custom_properties["Target Area"]
            if target_object and target_area and activation_radius then
                local new_radius_warp = {
                    target_object=target_object,
                    object=object,
                    activation_radius=activation_radius,
                    target_area=target_area,
                    area_id=area_id
                }
                radius_warps[#radius_warps+1] = new_radius_warp
                print('[ezwarps] added radius warp '..object_id)
            else
                print('[ezwarps] did not add invalid radius warp '..object_id)
            end
        end
    end
end

function handle_player_request(player_id, data)
    print('[ezwarps] player '..player_id..' requested connection with data: '..data)
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
    print('[ezwarps] no landing for '..data)
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

function table_has_value (table, val)
    for index, value in ipairs(table) do
        if value == val then
            return true
        end
    end
    return false
end

print('[ezwarps] Loaded')
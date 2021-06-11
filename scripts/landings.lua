-- Automatically adds landings for server warps to your server
-- Just gotta add some custom properties to your Server Warps
--   "IncomingData" (string) secret to share with the server that is linking to you; for their "Data"
--   "Direction" (string) direction the warp will make the player walk on arrival; defaults to "Down"
local landings = {}

function add_landing(area_id, incoming_data, x, y, z, direction, warp_in)
    landings[incoming_data] = {
        area_id = area_id,
        warp_in = warp_in,
        x = x,
        y = y,
        z = z,
        direction = direction
    }
    print('[Landings] added landing in '..area_id)
end

local areas = Net.list_areas()
for i, area_id in next, areas do
    local objects = Net.list_objects(area_id)
    for i, object_id in next, objects do
        local object = Net.get_object_by_id(area_id, object_id)
        local incoming_data = object.custom_properties.IncomingData
        if object.type == "Server Warp" and incoming_data then
            local direction = object.custom_properties.Direction or "Down"
            local warp_in = true
            add_landing(area_id, incoming_data, object.x+0.5, object.y+0.5, object.z, direction, warp_in)
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
            return
        end
    end
    print('[Landings] no landing for '..data)
end

print('[Landings] Loaded')

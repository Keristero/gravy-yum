--
-- Default map connection overrides for advertise_server
-- This file can be replaced per-server to customize how map connections are detected.
--
-- Return a table with:
--   process_object(area_id, map_info, object)
--     Called for each object on each map. Should populate:
--       map_info.l[target_area] = {id=...}         -- local connections (same server)
--       map_info.r[address:port] = {data=..., incoming_data=...}  -- remote connections
--       map_info.has_shop, map_info.has_board, etc. -- extra map info
--

local overrides = {}

function overrides.process_object(area_id, map_info, object)
    local custom_p = object.custom_properties

    --local connections (ezlibs warps)
    if custom_p["Target Area"] then
        map_info.l[custom_p["Target Area"]] = {id=custom_p["Target Object"]}
    end

    --remote connections (server warps)
    local address = custom_p["Address"]
    local port = custom_p["Port"]
    if address and port then
        map_info.r[address..":"..port] = {data=custom_p["Data"],incoming_data=custom_p["Incoming Data"]}
    end

    --extra map info
    if object.class == "Shop" then
        map_info.has_shop = true
    elseif object.class == "Board" then
        map_info.has_board = true
    end
end

return overrides

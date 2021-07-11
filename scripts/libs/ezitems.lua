local json = require('scripts/libs/json')
local helpers = require('scripts/libs/helpers')
local ezitems = {}

local key_item_descriptions = {}

--When the server starts, load item descriptions
local read_file_promise = Async.read_file('./memory/items/descriptions.json')
read_file_promise.and_then(function(value)
    if value then
        local decoded = json.decode(value)
        key_item_descriptions = decoded
    end
end)


function ezitems.update_key_item_description(name,description)
    if key_item_descriptions[name] ~= description then
        key_item_descriptions[name] = description
        Async.write_file('./memory/items/descriptions.json', json.encode(key_item_descriptions))
    end
end

function ezitems.get_item_description(name)
    if key_item_descriptions[name] then
        return key_item_descriptions[name]
    end
    return "???"
end

function ezitems.give_player_item(player_id, name,description)
    print('[ezitems] gave '..player_id..' a '..name)
    local url_secret = helpers.get_safe_player_secret(player_id)
    ezitems.update_key_item_description(name, description)
    Net.give_player_item(player_id, name, description)
    local player_items = Net.get_player_items(player_id)
    Async.write_file('./memory/items/'..url_secret..'.json', json.encode(player_items))
end

function ezitems.handle_player_join(player_id)
    local url_secret = helpers.get_safe_player_secret(player_id)
    local read_file_promise = Async.read_file('./memory/items/'..url_secret..'.json')
    read_file_promise.and_then(function(value)
        if value then
            local decoded = json.decode(value)
            for key, item_name in pairs(decoded) do
                local description = ezitems.get_item_description(item_name)
                Net.give_player_item(player_id, item_name, description)
            end
        end
    end)
end

return ezitems
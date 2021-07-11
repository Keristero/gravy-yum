local ezmystery = {}
local ezitems = require('scripts/libs/ezitems')
local helpers = require('scripts/libs/helpers')
local json = require('scripts/libs/json')

local collected = {}

local sfx = {
    item_get='/server/assets/sfx/item_get.ogg',
}

--When the server starts, load which mystery data players have collected
local read_file_promise = Async.read_file('./memory/bluemysterydata.json')
read_file_promise.and_then(function(value)
    if value then
        local decoded = json.decode(value)
        collected = decoded
    end
end)

function ezmystery.handle_player_join(player_id)
    --Load assets
    for name,path in pairs(sfx) do
        Net.provide_asset_for_player(player_id, path)
    end

    --Hide all mystery data they have already collected
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local excluded_data = collected[safe_secret]
    if excluded_data then
        for i,object_id in pairs(excluded_data) do
            Net.exclude_object_for_player(player_id, object_id)
            print('excluded '..object_id)
        end
    end
end

function collect_datum(player_id,object)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_collected_data = collected[safe_secret]
    if not player_collected_data then
        collected[safe_secret] = {}
        player_collected_data = collected[safe_secret]
    end
    player_collected_data[#player_collected_data+1] = object.id
    Async.write_file('./memory/bluemysterydata.json', json.encode(collected))
    
    if object.custom_properties["Type"] == "keyitem" then
        local name = object.custom_properties["Name"]
        local description = object.custom_properties["Description"]
        ezitems.give_player_item(player_id,name,description)
    end
    Net.exclude_object_for_player(player_id, object.id)
end

function ezmystery.handle_object_interaction(player_id, object_id)
    local area_id = Net.get_player_area(player_id)
    local object = Net.get_object_by_id(area_id,object_id)
    if object.type == "Mystery Data" or object.type == "Mystery Datum" then
        collect_datum(player_id,object)
    end
end

return ezmystery
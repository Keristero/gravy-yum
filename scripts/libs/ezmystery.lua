local ezmystery = {}
local ezmemory = require('scripts/libs/ezmemory')
local helpers = require('scripts/libs/helpers')

local unlocker_questions = {}

local sfx = {
    item_get='/server/assets/sfx/item_get.ogg',
}

--Type Mystery Data (or Mystery Datum) have these custom_properties
--Locked (bool) do you need an unlocker to open this?
--Once (bool) should this never respawn for this player?
--Type (string) either 'keyitem' or 'money'
--(for keyitem type)
--    Name (string) name of keyitem
--    Description (string) description of keyitem
--(for money type)
--    Amount (number) amount of money to give

function ezmystery.handle_player_join(player_id)
    --Load assets
    for name,path in pairs(sfx) do
        Net.provide_asset_for_player(player_id, path)
    end

    --Hide all mystery data they have already collected
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    for i,object_id in pairs(player_memory.hidden_objects) do
        Net.exclude_object_for_player(player_id, object_id)
        print('[ezmystery] hid '..object_id)
    end
end

function ezmystery.handle_textbox_response(player_id, response)
    if unlocker_questions[player_id] then
        print('[ezmystery] '..player_id..' responded '..response..' about unlocking data')
        local object = unlocker_questions[player_id]
        if response == 1 then
            collect_datum(player_id,object)
        end
        unlocker_questions[player_id] = nil
    end
end

function try_collect_datum(player_id,object)
    Net.message_player(player_id,"Accessing the mystery data\x01...\x01")

    if object.custom_properties["Locked"] == "true" then
        Net.message_player(player_id,"The Mystery Data is locked.")
        local unlocker_index = ezmemory.get_first_index_of_item_of_player(player_id, "Unlocker")
        if unlocker_index ~= nil then
            unlocker_questions[player_id] = object
            Net.question_player(player_id, "Use an Unlocker to open it?")
        end
    else
        --If the data is not locked, collect it
        collect_datum(player_id,object)
    end
end

function collect_datum(player_id,object)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    
    if object.custom_properties["Type"] == "keyitem" then
        local name = object.custom_properties["Name"]
        local description = object.custom_properties["Description"]
        if not name or not description then
            print('[ezmystery] '..object.id..' has either no name or description')
            return
        end
        --Give the player an item
        ezmemory.give_player_item(player_id,name,description)
        Net.message_player(player_id,"Got "..name.."!")
    elseif object.custom_properties["Type"] == "money" then
        local amount = object.custom_properties["Amount"]
        if not amount then
            print('[ezmystery] '..object.id..' has no amount')
            return
        end
        --Give the player money
        local player_money = Net.get_player_money(player_id)
        ezmemory.set_player_money(player_id,player_money+amount)
        Net.message_player(player_id,"Got "..amount.."$!")
    end

    if object.custom_properties["Once"] == "true" then
        --If this mystery data should only be available once (not respawning)
        local player_collected_data = player_memory.hidden_objects
        player_collected_data[#player_collected_data+1] = object.id
        ezmemory.save_player_memory(safe_secret)
    end

    --Now remove the mystery data
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
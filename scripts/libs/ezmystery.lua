local ezmystery = {}
local ezmemory = require('scripts/libs/ezmemory')
local helpers = require('scripts/libs/helpers')
local math = require('math')

local data_dialogues = {}
local data_hidden_till_rejoin_for_player = {}

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
    --Load sound effects for mystery data interaction
    data_hidden_till_rejoin_for_player[player_id] = {}
    for name,path in pairs(sfx) do
        Net.provide_asset_for_player(player_id, path)
    end
    --Pretend to do a transfer too, to hide data in entry map
    ezmystery.handle_player_transfer(player_id)
end

function ezmystery.handle_player_transfer(player_id)
    --Load sound effects for mystery data interaction
    local area_id = Net.get_player_area(player_id)
    if data_hidden_till_rejoin_for_player[player_id][area_id] then
        for object_id, is_hidden in pairs(data_hidden_till_rejoin_for_player[player_id][area_id]) do
            Net.exclude_object_for_player(player_id, object_id)
        end
    else
        data_hidden_till_rejoin_for_player[player_id][area_id] = {}
    end
end

function ExtractNumberedProperties(object,property_prefix)
    local out_table = {}
    for i=1,10 do
        local text = object.custom_properties[property_prefix..i]
        if text then
            out_table[i] = text
        end
    end
    return out_table
end

function ezmystery.handle_textbox_response(player_id, response)
    if data_dialogues[player_id] then
        print('[ezmystery] '..player_id..' responded '..response..' in data dialogue')
        if data_dialogues[player_id].state == 'accessing' then
            --If player collects an item
            collect_datum(player_id,data_dialogues[player_id].object,data_dialogues[player_id].object.id)
            data_dialogues[player_id] = nil
        elseif data_dialogues[player_id].state == 'say_locked' then
            Net.question_player(player_id, "Use an Unlocker to open it?")
            data_dialogues[player_id].state = 'ask_unlock'
        elseif data_dialogues[player_id].state == 'ask_unlock' then
            if response == 1 then
                ezmemory.remove_player_item(player_id, "Unlocker",1)
                collect_datum(player_id,data_dialogues[player_id].object,data_dialogues[player_id].object.id)
                data_dialogues[player_id] = nil
            end
        else
            data_dialogues[player_id] = nil
        end
    end
end

function try_collect_datum(player_id,object)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    local area_id = Net.get_player_area(player_id)
    local player_area_memory = ezmemory.get_player_area_memory(safe_secret,area_id)
    if player_area_memory.hidden_objects[tostring(object.id)] or data_hidden_till_rejoin_for_player[player_id][area_id][tostring(object.id)] then
        --Anti spam protection
        return
    end
    if object.custom_properties["Locked"] == "true" then
        Net.message_player(player_id,"The Mystery Data is locked.")
        if ezmemory.count_player_item(player_id, "Unlocker") > 0 then
            data_dialogues[player_id] = {state="say_locked",object=object}
        end
    else
        --If the data is not locked, collect it
        Net.message_player(player_id,"Accessing the mystery data\x01...\x01")
        data_dialogues[player_id] = {state="accessing",object=object}
    end
end

function collect_datum(player_id,object,datum_id_override)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    local area_id = Net.get_player_area(player_id)
    local player_area_memory = ezmemory.get_player_area_memory(safe_secret,area_id)
    if player_area_memory.hidden_objects[tostring(datum_id_override)] or data_hidden_till_rejoin_for_player[player_id][area_id][tostring(datum_id_override)] then
        --Anti spam protection
        return
    end
    if object.custom_properties["Type"] == "random" then
        local random_options = ExtractNumberedProperties(object,"Next ")
        local random_selection_id = random_options[math.random(#random_options)]
        if random_selection_id then
            randomly_selected_datum = Net.get_object_by_id(area_id,random_selection_id)
            collect_datum(player_id,randomly_selected_datum,datum_id_override)
        end
    elseif object.custom_properties["Type"] == "keyitem" then
        local name = object.custom_properties["Name"]
        local description = object.custom_properties["Description"]
        if not name or not description then
            print('[ezmystery] '..object.id..' has either no name or description')
            return
        end
        --Give the player an item
        ezmemory.create_or_update_item(name,description,true)
        ezmemory.give_player_item(player_id,name,1)
        Net.message_player(player_id,"Got "..name.."!")
        Net.play_sound_for_player(player_id,sfx.item_get)
    elseif object.custom_properties["Type"] == "money" then
        local amount = object.custom_properties["Amount"]
        if not amount then
            print('[ezmystery] '..object.id..' has no amount')
            return
        end
        --Give the player money
        ezmemory.spend_player_money(player_id,-amount)
        Net.message_player(player_id,"Got "..amount.."$!")
        Net.play_sound_for_player(player_id,sfx.item_get)
    end

    if object.custom_properties["Once"] == "true" then
        --If this mystery data should only be available once (not respawning)
        player_area_memory.hidden_objects[tostring(datum_id_override)] = true
        ezmemory.save_player_memory(safe_secret)
    end

    --Now remove the mystery data
    data_hidden_till_rejoin_for_player[player_id][area_id][tostring(datum_id_override)] = true
    Net.exclude_object_for_player(player_id, datum_id_override)
end

function ezmystery.handle_object_interaction(player_id, object_id)
    local area_id = Net.get_player_area(player_id)
    local object = Net.get_object_by_id(area_id,object_id)
    if object.type == "Mystery Data" or object.type == "Mystery Datum" then
        try_collect_datum(player_id,object)
    end
end

return ezmystery
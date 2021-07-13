local ezmystery = {}
local ezmemory = require('scripts/libs/ezmemory')
local helpers = require('scripts/libs/helpers')
local math = require('math')

local unlocker_questions = {}
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
        for i, object_id in ipairs(data_hidden_till_rejoin_for_player[player_id][area_id]) do
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
    if unlocker_questions[player_id] then
        print('[ezmystery] '..player_id..' responded '..response..' about unlocking data')
        if unlocker_questions[player_id].state == 'say_locked' then
            Net.question_player(player_id, "Use an Unlocker to open it?")
            unlocker_questions[player_id].state = 'ask_unlock'
        elseif unlocker_questions[player_id].state == 'ask_unlock' then
            if response == 1 then
                ezmemory.remove_player_item(player_id, "Unlocker")
                collect_datum(player_id,unlocker_questions[player_id].object,unlocker_questions[player_id].object.id)
                unlocker_questions[player_id] = nil
            end
        else
            unlocker_questions[player_id] = nil
        end
    end
end

function try_collect_datum(player_id,object)

    if object.custom_properties["Locked"] == "true" then
        Net.message_player(player_id,"The Mystery Data is locked.")
        local unlocker_index = ezmemory.get_first_index_of_item_of_player(player_id, "Unlocker")
        if unlocker_index ~= nil then
            unlocker_questions[player_id] = {state="say_locked",object=object}
        end
    else
        --If the data is not locked, collect it
        Net.message_player(player_id,"Accessing the mystery data\x01...\x01")
        collect_datum(player_id,object,object.id)
    end
end

function collect_datum(player_id,object,datum_id_override)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    local area_id = Net.get_player_area(player_id)
    if object.custom_properties["Type"] == "random" then
        local random_options = ExtractNumberedProperties(object,"Next ")
        local random_selection_id = random_options[math.random(#random_options)]
        if random_selection_id then
            randomly_selected_datum = Net.get_object_by_id(area_id,random_selection_id)
            collect_datum(player_id,randomly_selected_datum,random_selection_id)
        end
    elseif object.custom_properties["Type"] == "keyitem" then
        local name = object.custom_properties["Name"]
        local description = object.custom_properties["Description"]
        if not name or not description then
            print('[ezmystery] '..object.id..' has either no name or description')
            return
        end
        --Give the player an item
        ezmemory.give_player_item(player_id,name,description)
        Net.message_player(player_id,"Got "..name.."!")
        Net.play_sound_for_player(player_id,sfx.item_get)
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
        Net.play_sound_for_player(player_id,sfx.item_get)
    end

    if object.custom_properties["Once"] == "true" then
        --If this mystery data should only be available once (not respawning)
        local player_area_memory = ezmemory.get_player_area_memory(safe_secret,area_id)
        player_area_memory.hidden_objects[#player_area_memory.hidden_objects+1] = datum_id_override
        ezmemory.save_player_memory(safe_secret)
    end

    --Now remove the mystery data
    --TODO make this line shorter lol
    data_hidden_till_rejoin_for_player[player_id][area_id][#data_hidden_till_rejoin_for_player[player_id][area_id]+1] = datum_id_override
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
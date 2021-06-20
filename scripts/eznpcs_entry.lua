local eznpcs = require('scripts/libs/eznpcs/eznpcs')

eznpcs.load_npcs()
function handle_actor_interaction(player_id, actor_id)
    --handle interactions with NPCs
    eznpcs.on_actor_interaction(player_id,actor_id)
end
function tick(delta_time)
    --handle on tick behaviours for NPCs
    eznpcs.on_tick(delta_time)
end
function handle_player_disconnect(player_id)
    eznpcs.on_player_disconnect(player_id)
end
function handle_object_interaction(player_id, object_id)
    eznpcs.on_object_interact(player_id, object_id)
end
function handle_player_transfer(player_id)
    eznpcs.on_player_transfer(player_id)
end
function handle_textbox_response(player_id, response)
    eznpcs.on_textbox_response(player_id,response)
end

local sfx = {
    hurt='/server/assets/sfx/hurt.ogg',
    item_get='/server/assets/sfx/item_get.ogg',
    recover='/server/assets/sfx/recover.ogg'
}

--Provide assets for custom events
function handle_player_join(player_id)
    for name,path in pairs(sfx) do
        Net.provide_asset_for_player(player_id, path)
    end
end

--custom events
--custom events need a name and an action
--you can return the information of the next dialouge object that you want to use
--next dialouge options = {id,wait_for_response}
--wait_for_response should be true if your event sends a message
local event1 = {
    name="Punch",
    action=function (npc,player_id,dialogue)
        local player_mugshot = Net.get_player_mugshot(player_id)
        Net.play_sound_for_player(player_id,sfx.hurt)
        Net.message_player(player_id,"owchie!",player_mugshot.texture_path,player_mugshot.animation_path)
    end
}
eznpcs.add_event(event1)

local event2 = {
    name="Buy Gravy",
    action=function (npc,player_id,dialogue)
        local player_cash = Net.get_player_money(player_id)
        if player_cash >= 300 then
            Net.set_player_money(player_id,player_cash-300)
            Net.play_sound_for_player(player_id,sfx.item_get)
            Net.message_player(player_id,"Got net gravy!")
            local next_dialouge_options = {
                id=dialogue.custom_properties["Got Gravy"],
                wait_for_response=true
            }
            return next_dialouge_options
        else
            local next_dialouge_options = {
                id=dialogue.custom_properties["No Gravy"],
                wait_for_response=false
            }
            return next_dialouge_options
        end
    end
}
eznpcs.add_event(event2)

local event3 = {
    name="Drink Gravy",
    action=function (npc,player_id,dialogue)
        local player_mugshot = Net.get_player_mugshot(player_id)
        Net.play_sound_for_player(player_id,sfx.recover)
        Net.message_player(player_id,"\x01...\x01mmm gravy yum",player_mugshot.texture_path,player_mugshot.animation_path)
        local next_dialouge_options = {
            wait_for_response=true,
            id=dialogue.custom_properties["Next 1"]
        }
        return next_dialouge_options
    end
}
eznpcs.add_event(event3)

local event4 = {
    name="Cafe Counter Check",
    action=function (npc,player_id,dialogue,relay_object)
        local next_dialouge_options = nil
        if relay_object then
            next_dialouge_options = {
                wait_for_response=false,
                id=dialogue.custom_properties["Counter Chat"]
            }
        else
            next_dialouge_options = {
                wait_for_response=false,
                id=dialogue.custom_properties["Direct Chat"]
            }
        end
        return next_dialouge_options
    end
}
eznpcs.add_event(event4)

local gift_zenny = {
    name="Gift Zenny",
    action=function (npc,player_id,dialogue)
        local zenny_amount = tonumber(dialogue.custom_properties["Amount"])
        local player_cash = Net.get_player_money(player_id)
        Net.set_player_money(player_id,player_cash+zenny_amount)
        Net.play_sound_for_player(player_id,sfx.item_get)
        Net.message_player(player_id,"Got "..zenny_amount.. "$!")
        if dialogue.custom_properties["Next 1"] then
            local next_dialouge_options = {
                wait_for_response=true,
                id=dialogue.custom_properties["Next 1"]
            }
            return next_dialouge_options
        end
    end
}
eznpcs.add_event(gift_zenny)
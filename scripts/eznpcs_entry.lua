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
--you can return the id of the next dialouge object that you want to use
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
        print('buying gravy ')
        local player_cash = Net.get_player_money(player_id)
        print('player cash '..player_cash)
        if player_cash >= 300 then
            print('enough cash')
            Net.set_player_money(player_id,player_cash-300)
            local player_mugshot = Net.get_player_mugshot(player_id)
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
        print('drinking gravy ')
        local player_mugshot = Net.get_player_mugshot(player_id)
        Net.play_sound_for_player(player_id,sfx.recover)
        Net.message_player(player_id,"\x01...mmm\x01 gravy yum",player_mugshot.texture_path,player_mugshot.animation_path)
        local next_dialouge_options = {
            wait_for_response=true,
            id=dialogue.custom_properties["Next 1"]
        }
        return next_dialouge_options
    end
}
eznpcs.add_event(event3)
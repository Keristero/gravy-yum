local eznpcs = require('scripts/libs/eznpcs/eznpcs')
local ezmemory = require('scripts/libs/ezmemory')
local ezmystery = require('scripts/libs/ezmystery')
local ezfarms = require('scripts/libs/ezfarms')

local plugins = {eznpcs,ezmemory,ezmystery,ezfarms}

local sfx = {
    hurt='/server/assets/sfx/hurt.ogg',
    item_get='/server/assets/sfx/item_get.ogg',
    recover='/server/assets/sfx/recover.ogg',
    card_error='/server/assets/sfx/card_error.ogg'
}

eznpcs.load_npcs()

--Pass handlers on to all the libraries we are using
function handle_tile_interaction(player_id, x, y, z, button)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_tile_interaction then
            function handle_tile_interaction(player_id, x, y, z, button)
        end
    end
end

function handle_post_selection(player_id, post_id)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_post_selection then
            plugin.handle_post_selection(player_id, post_id)
        end
    end
end

function handle_board_close(player_id)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_board_close then
            plugin.handle_board_close(player_id)
        end
    end
end

function handle_player_join(player_id)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_player_join then
            plugin.handle_player_join(player_id)
        end
    end
    --Provide assets for custom events
    for name,path in pairs(sfx) do
        Net.provide_asset_for_player(player_id, path)
    end
end
function handle_actor_interaction(player_id, actor_id)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_actor_interaction then
            plugin.handle_actor_interaction(player_id,actor_id)
        end
    end
end
function tick(delta_time)
    for i,plugin in ipairs(plugins)do
        if plugin.on_tick then
            plugin.on_tick(delta_time)
        end
    end
end
function handle_player_disconnect(player_id)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_player_disconnect then
            plugin.handle_player_disconnect(player_id)
        end
    end
end
function handle_object_interaction(player_id, object_id)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_object_interaction then
            plugin.handle_object_interaction(player_id,object_id)
        end
    end
end
function handle_player_transfer(player_id)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_player_transfer then
            plugin.handle_player_transfer(player_id)
        end
    end
end
function handle_textbox_response(player_id, response)
    for i,plugin in ipairs(plugins)do
        if plugin.handle_textbox_response then
            plugin.handle_textbox_response(player_id,response)
        end
    end
end

--custom events, remove them if you dont want them.
local event1 = {
    name="Punch",
    action=function (npc,player_id,dialogue,relay_object)
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
            ezmemory.set_player_money(player_id,player_cash-300)
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
    action=function (npc,player_id,dialogue,relay_object)
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
        ezmemory.set_player_money(player_id,player_cash+zenny_amount)
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
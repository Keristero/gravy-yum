local eznpcs = require('scripts/libs/eznpcs/eznpcs')
local ezmemory = require('scripts/libs/ezmemory')
local ezmystery = require('scripts/libs/ezmystery')

local plugins = {eznpcs,ezmemory,ezmystery}

local sfx = {
    hurt='/server/assets/sfx/hurt.ogg',
    item_get='/server/assets/sfx/item_get.ogg',
    recover='/server/assets/sfx/recover.ogg',
    card_error='/server/assets/sfx/card_error.ogg'
}

eznpcs.load_npcs()

--Pass handlers on to all the libraries we are using
function handle_player_join(player_id)
    --Run plugins
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
    --Run plugins
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

local plant_data = {
    Turnip={price=100},
    Cauliflower={price=150},
    Garlic={price=175},
    Tomato={price=200},
    Chili={price=220},
    Beetroot={price=180},
    Star={price=300},
    Eggplant={price=230},
    Pumpkin={price=250},
    Yam={price=90},
    ["Beetroot 2"]={price=169},
    ["Ancient"]={price=1000},
    ["Sweet Gem"]={price=500},
    Blueberry={price=400}
}

--Gravy Farm stuff

local players_using_bbs = {}

function handle_post_selection(player_id, post_id)
    if players_using_bbs[player_id] then
        if players_using_bbs[player_id] == "Buy Seeds" then
            try_buy_seed(player_id,post_id)
        end
    end
end

function handle_board_close(player_id)
    players_using_bbs[player_id] = nil
end

function try_buy_seed(player_id,plant_name)
    local player_cash = Net.get_player_money(player_id)
    local price = plant_data[plant_name].price
    if player_cash >= price then
        ezmemory.set_player_money(player_id,player_cash-price)
        Net.play_sound_for_player(player_id,sfx.item_get)
        ezmemory.give_player_item(player_id, plant_name.." seed", "seed for planting "..plant_name)
    else
        Net.message_player(player_id,"Not enough $")
        Net.play_sound_for_player(player_id,sfx.card_error)
    end
end

local seed_stall = {
    name="seed_stall",
    action=function (npc,player_id,dialogue)
        local board_color = { r= 128, g= 255, b= 128 }
        local posts = {}
        for plant_name, data in pairs(plant_data) do
            local seed_name = plant_name.." seed"
            posts[#posts+1] = { id=plant_name, read=true, title=seed_name , author=tostring(data.price) }
        end
        local bbs_name = "Buy Seeds"
        players_using_bbs[player_id] = bbs_name
        Net.open_board(player_id, bbs_name, board_color, posts)
        local next_dialouge_options = {
            wait_for_response=true,
            id=dialogue.custom_properties["Next 1"]
        }
        return next_dialouge_options
    end
}
eznpcs.add_event(seed_stall)
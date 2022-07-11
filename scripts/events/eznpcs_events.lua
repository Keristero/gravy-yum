local eznpcs_events = {}
local eznpcs = require('scripts/ezlibs-scripts/eznpcs/eznpcs')
local ezmemory = require('scripts/ezlibs-scripts/ezmemory')
local ezmystery = require('scripts/ezlibs-scripts/ezmystery')
local ezfarms = require('scripts/ezlibs-scripts/ezfarms')
local ezweather = require('scripts/ezlibs-scripts/ezweather')
local ezwarps = require('scripts/ezlibs-scripts/ezwarps/main')
local ezencounters = require('scripts/ezlibs-scripts/ezencounters/main')
local helpers = require('scripts/ezlibs-scripts/helpers')

local sfx = {
    hurt = '/server/assets/ezlibs-assets/sfx/hurt.ogg',
    item_get = '/server/assets/ezlibs-assets/sfx/item_get.ogg',
    recover = '/server/assets/ezlibs-assets/sfx/recover.ogg',
    card_error = '/server/assets/ezlibs-assets/ezfarms/card_error.ogg'
}

local event1 = {
    name = "Punch",
    action = function(npc, player_id, dialogue, relay_object)
        return async(function()
            local player_mugshot = Net.get_player_mugshot(player_id)
            local next_dialogues = helpers.extract_numbered_properties(dialogue,"Next ")
            Net.play_sound_for_player(player_id, sfx.hurt)
            await(Async.message_player(player_id, "owchie!", player_mugshot.texture_path, player_mugshot.animation_path))
            return first_value_from_table(next_dialogues)
        end)
    end
}
eznpcs.add_event(event1)

local event_snow = {
    name = "Snow",
    action = function(npc, player_id, dialogue, relay_object)
        return async(function()
            local area_id = Net.get_player_area(player_id)
            ezweather.start_snow_in_area(area_id)
            return dialogue.custom_properties["Next 1"]
        end)
    end
}
eznpcs.add_event(event_snow)


local event2 = {
    name = "Buy Gravy",
    action = function(npc, player_id, dialogue)
        return async(function()
            if ezmemory.spend_player_money(player_id, 300) then
                Net.play_sound_for_player(player_id, sfx.item_get)
                await(Async.message_player(player_id, "Got net gravy!"))
                return dialogue.custom_properties["Got Gravy"]
            else
                return dialogue.custom_properties["No Gravy"]
            end
        end)
    end
}
eznpcs.add_event(event2)

local event3 = {
    name = "Drink Gravy",
    action = function(npc, player_id, dialogue, relay_object)
        return async(function()
            local player_mugshot = Net.get_player_mugshot(player_id)
            Net.play_sound_for_player(player_id, sfx.recover)
            Net.message_player(player_id, "\x01...\x01mmm gravy yum", player_mugshot.texture_path, player_mugshot.animation_path)
            return dialogue.custom_properties["Next 1"]
        end)
    end
}
eznpcs.add_event(event3)

local event4 = {
    name = "Cafe Counter Check",
    action = function(npc, player_id, dialogue, relay_object)
        return async(function()
            if relay_object then
                return dialogue.custom_properties["Counter Chat"]
            else
                return dialogue.custom_properties["Direct Chat"]
            end
        end)
    end
}
eznpcs.add_event(event4)

local gift_zenny = {
    name = "Gift Monies",
    action = function(npc, player_id, dialogue)
        return async(function()
            local zenny_amount = tonumber(dialogue.custom_properties["Amount"])
            ezmemory.spend_player_money(player_id, -zenny_amount)
            Net.play_sound_for_player(player_id, sfx.item_get)
            await(Async.message_player(player_id, "Got " .. zenny_amount .. "$!"))
            return dialogue.custom_properties["Next 1"]
        end)
    end
}
eznpcs.add_event(gift_zenny)

local deal_damage = {
    name = "Damage",
    action = function(npc, player_id, dialogue)
        return async(function()
            local damage_amount = tonumber(dialogue.custom_properties["Amount"])
            local player_hp = tonumber(Net.get_player_health(player_id))
            local new_hp = player_hp - damage_amount
            Net.play_sound_for_player(player_id, sfx.hurt)
            await(Async.message_player(player_id, "Took " .. damage_amount .. " damage!\n new hp =" .. new_hp))
            Net.set_player_health(player_id, new_hp)
            return dialogue.custom_properties["Next 1"]
        end)
    end
}
eznpcs.add_event(deal_damage)

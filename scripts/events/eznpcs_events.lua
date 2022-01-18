local eznpcs_events = {}
local eznpcs = require('scripts/ezlibs-scripts/eznpcs/eznpcs')
local ezmemory = require('scripts/ezlibs-scripts/ezmemory')
local ezmystery = require('scripts/ezlibs-scripts/ezmystery')
local ezfarms = require('scripts/ezlibs-scripts/ezfarms')
local ezweather = require('scripts/ezlibs-scripts/ezweather')
local ezwarps = require('scripts/ezlibs-scripts/ezwarps/main')
local ezencounters = require('scripts/ezlibs-scripts/ezencounters/main')

local event1 = {
    name="Punch",
    action=function (npc,player_id,dialogue,relay_object)
        local player_mugshot = Net.get_player_mugshot(player_id)
        Net.play_sound_for_player(player_id,sfx.hurt)
        Net.message_player(player_id,"owchie!",player_mugshot.texture_path,player_mugshot.animation_path)
    end
}
eznpcs.add_event(event1)

local event_snow = {
    name="Snow",
    action=function (npc,player_id,dialogue,relay_object)
        local area_id = Net.get_player_area(player_id)
        ezweather.start_snow_in_area(area_id)
        local next_dialouge_options = {
            id=dialogue.custom_properties["Next 1"],
            wait_for_response=false
        }
        return next_dialouge_options
    end
}
eznpcs.add_event(event_snow)


local event2 = {
    name="Buy Gravy",
    action=function (npc,player_id,dialogue)
        if ezmemory.spend_player_money(player_id,300) then
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
    name="Gift Monies",
    action=function (npc,player_id,dialogue)
        local zenny_amount = tonumber(dialogue.custom_properties["Amount"])
        ezmemory.spend_player_money(player_id,-zenny_amount)
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

local deal_damage = {
    name="Damage",
    action=function (npc,player_id,dialogue)
        local damage_amount = tonumber(dialogue.custom_properties["Amount"])
        local player_hp = tonumber(Net.get_player_health(player_id))
        local new_hp = player_hp-damage_amount
        Net.play_sound_for_player(player_id,sfx.hurt)
        Net.message_player(player_id,"Took "..damage_amount.. " damage!\n new hp ="..new_hp)
        Net.set_player_health(player_id, new_hp)

        if dialogue.custom_properties["Next 1"] then
            local next_dialouge_options = {
                wait_for_response=true,
                id=dialogue.custom_properties["Next 1"]
            }
            return next_dialouge_options
        end
    end
}
eznpcs.add_event(deal_damage)
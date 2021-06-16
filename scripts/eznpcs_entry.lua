local eznpcs = require('scripts/libs/eznpcs')

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
function handle_player_transfer(player_id)
    eznpcs.on_player_transfer(player_id)
end
function handle_textbox_response(player_id, response)
    eznpcs.on_textbox_response(player_id,response)
end

--custom events
--custom events need a name and an action
--you can return the id of the next dialouge object that you want to use
local Punch = {
    name="Punch",
    action=function (npc,player_id)
        local player_mugshot = Net.get_player_mugshot(player_id)
        Net.play_sound_for_player(player_id,'resources/sfx/hurt.ogg')
        Net.message_player(player_id,"owchie!",player_mugshot.texture_path,player_mugshot.animation_path)
        return 253
    end
}
eznpcs.add_event(Punch)
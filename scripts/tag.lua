/*
local it = ""
local tag_sfx = "resources/sfx/trap.ogg"

Net:on("player_request", function(event)
    if it == "" then
        print("[Tag] defaulted it to", event.player_id)
        it = event.player_id
    end
end)


Net:on("actor_interaction", function(event)
    if it == event.player_id then
        if Net.is_bot(event.actor_id) == false then
            local mugshot_info = Net.get_player_mugshot(event.player_id)
            Net.play_sound_for_player(event.player_id, tag_sfx)
            Net.play_sound_for_player(event.actor_id, tag_sfx)

            Net.exclusive_player_emote(event.player_id, event.actor_id, 11)
            Net.exclusive_player_emote(event.actor_id, event.player_id, 4)

            Net.message_player(event.actor_id, "You're it!", mugshot_info.texture_path, mugshot_info.animation_path)
            it = event.actor_id
            print("[Tag] " .. event.player_id, "tagged", event.actor_id)
        end
    end
end)

Net:on("player_disconnect", function(event)
    if it == event.player_id then
        it = ""
        print("[Tag] it left the server")
    end
end)

local timer = 0

Net:on("tick", function(event)
    timer = timer + event.delta_time
    if timer > 5 then
        if it ~= "" then
            Net.set_player_emote(it, 2)
            timer = 0
        end
    end
end)
*/
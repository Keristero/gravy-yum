local it = ""
local tag_sfx = "resources/sfx/trap.ogg"

function handle_player_request(player_id, data)
    if it == "" then
        print("[Tag] defaulted it to",player_id)
        it = player_id
    end
end


function handle_actor_interaction(player_id, actor_id)
    if it == player_id then
        if Net.is_bot(actor_id) == false then
            local mugshot_info = Net.get_player_mugshot(player_id)
            Net.play_sound_for_player(player_id, tag_sfx)
            Net.play_sound_for_player(actor_id, tag_sfx)

            Net.exclusive_player_emote(player_id, actor_id, 11)
            Net.exclusive_player_emote(actor_id, player_id, 4)

            Net.message_player(actor_id, "You're it!", mugshot_info.texture_path, mugshot_info.animation_path)
            it = actor_id
            print("[Tag] "..player_id,"tagged",actor_id)
        end
    end
end

function handle_player_disconnect(player_id)
    if it == player_id then
        it = ""
        print("[Tag] it left the server")
    end
end

local timer = 0

function tick(elapsed)
  timer = timer + elapsed
  if timer > 5 then
    if it ~= "" then
        Net.set_player_emote(it, 2)
        timer = 0
    end
  end
end

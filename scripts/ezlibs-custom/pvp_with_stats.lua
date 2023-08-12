local ezmemory = require('scripts/ezlibs-scripts/ezmemory')
local ezmenus = require('scripts/ezlibs-scripts/ezmenus')

local requests = {}
local questioned_requests = {}
local players_in_battle = {}
local timer = 0

Net:on("player_connect", function(event)
  local player_id = event.player_id
  requests[player_id] = {}
end)

Net:on("player_disconnect", function(event)
  local player_id = event.player_id
  requests[player_id] = nil
  questioned_requests[player_id] = nil
end)

Net:on("actor_interaction", function(event)
  local button = event.button
  if button ~= 0 then return end

  local player_id = event.player_id
  local other_id = event.actor_id

  if requests[other_id] == nil then
    -- other_id is not a player id, since they're not registered in the request list
    return
  end

  local question

  if requests[player_id][other_id] then
    -- we're responding to the other player's request
    question = "Accept battle with\n"..Net.get_player_name(other_id).."?"
  else
    -- we're making a request for the other player

    if questioned_requests[player_id] then
      -- we've been asked if we want to request a fight
      -- but have not yet answered
      -- return here to prevent question spam due to interact spam
      return
    end

    local request_status = requests[other_id][player_id]

    if request_status then
      question = "Request again from\n"..Net.get_player_name(other_id).."?"
    else
      question = "Request PVP with\n"..Net.get_player_name(other_id).."?"
    end
  end

  local mugshot = Net.get_player_mugshot(player_id)

  Net.question_player(
    player_id,
    question,
    mugshot.texture_path,
    mugshot.animation_path
  )

  questioned_requests[player_id] = other_id
end)

Net:on("textbox_response", function(event)
  local response = event.response
  local player_id = event.player_id
  if response == 0 then
    -- response was no, no action needs to be taken
    questioned_requests[player_id] = nil
    return
  end

  local other_id = questioned_requests[player_id]

  if not requests[other_id] then
    -- the other player disconnected, we were too slow
    return
  end

  if requests[player_id][other_id] then
    -- we're saying yes to the other player's request
    requests[player_id][other_id] = nil
    Net.initiate_pvp(player_id, other_id)
    players_in_battle[event.player_id] = true
  else
    -- we're making a request for the other player
    requests[other_id][player_id] = true
    Net.exclusive_player_emote(other_id, player_id, 10) -- question mark emote
  end

  questioned_requests[player_id] = nil
end)

Net:on("tick", function(event)
    timer = timer + event.delta_time
    if timer > 10 then
        for player_id, value in pairs(players_in_battle) do
            Net.set_player_emote(player_id, 7) --swords emote
        end  
        timer = 0
    end
end)

Net:on("object_interaction", function(event)
  --show leaderboard bbs for area when its interacted with
  local player_area = Net.get_player_area(event.player_id)
  print('PVP',event.player_id, event.object_id, event.button)
  local object = Net.get_object_by_id(player_area, event.object_id)
  if object.class == "Wins BBS" then
    --load pvp stats
    local area_memory = ezmemory.get_area_memory(player_area)
    if not area_memory.pvp_wins then
      return
    end
    local posts = {}
    for player_name, win_count in pairs(area_memory.pvp_wins) do
      table.insert(posts,{ id= player_name, read=true, title=player_name, author=win_count})
    end
    table.sort(posts, function(a, b) return tonumber(a.author) > tonumber(b.author) end)
    local gold_color = {r=245, g=190, b=40, a=255}
    local menu = ezmenus.open_menu(event.player_id,"Wins BBS",gold_color,posts)
  end
end)

local function record_pvp_victory(player_id)
  local area_id = Net.get_player_area(player_id)
  local area_memory = ezmemory.get_area_memory(area_id)
  local player_name = Net.get_player_name(player_id)
  if player_name == 'anon' then
    return
  end
  if not area_memory.pvp_wins then
    area_memory.pvp_wins = {}
  end
  if not area_memory.pvp_wins[player_name] then
    area_memory.pvp_wins[player_name] = 0
  end
  area_memory.pvp_wins[player_name] = area_memory.pvp_wins[player_name] + 1
  print('[PvP] recorded win for '..player_name..'!')
  ezmemory.save_area_memory(area_id)
end

Net:on("battle_results", function(event)
    if players_in_battle[event.player_id] then
        print(event.player_id, event.health, event.time, event.ran, event.emotion, event.turns, event.enemies)
        players_in_battle[event.player_id] = nil
        if not event.ran and event.health >= 1 then
          record_pvp_victory(event.player_id)
        end
    end
end)

return {}
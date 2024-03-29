local ezmemory = require('scripts/ezlibs-scripts/ezmemory')
local ezmenus = require('scripts/ezlibs-scripts/ezmenus')
local helpers = require('scripts/ezlibs-scripts/helpers')

local requests = {}
local questioned_requests = {}
local players_in_battle = {}
local timer = 0
local point_decay_timer = 0

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
    players_in_battle[event.player_id] = other_id
    players_in_battle[other_id] = event.player_id
  else
    -- we're making a request for the other player
    requests[other_id][player_id] = true
    Net.exclusive_player_emote(other_id, player_id, 10) -- question mark emote
  end

  questioned_requests[player_id] = nil
end)

Net:on("tick", function(event)
    timer = timer + event.delta_time
    point_decay_timer = point_decay_timer + event.delta_time
    if timer > 10 then
        for player_id, value in pairs(players_in_battle) do
            Net.set_player_emote(player_id, 7) --swords emote
        end  
        timer = 0
    end
    --points decay
    if point_decay_timer > 3600 then
      local area_list = Net.list_areas()
      for index, area_id in ipairs(area_list) do
        local area_memory = ezmemory.get_area_memory(area_id)
        if area_memory.pvp_points then
          for player_name, points in pairs(area_memory.pvp_points) do
            area_memory.pvp_points[player_name] = math.floor(area_memory.pvp_points[player_name]*0.99)
          end
        end
        ezmemory.save_area_memory(area_id)
      end
      point_decay_timer = 0
    end
end)

Net:on("object_interaction", function(event)
  --show leaderboard bbs for area when its interacted with
  local player_area = Net.get_player_area(event.player_id)
  local object = Net.get_object_by_id(player_area, event.object_id)
  if not (object.class == "Wins BBS" or object.class == "Points BBS") then
    return
  end
  --load pvp stats
  local area_memory = ezmemory.get_area_memory(player_area)
  local posts = {}
  if object.class == "Wins BBS" then
    if not area_memory.pvp_wins then
      Net.message_player(event.player_id,"...Theres nothing here yet")
      return
    end

    for player_name, win_count in pairs(area_memory.pvp_wins) do
      table.insert(posts,{ id= player_name, read=true, title=player_name, author=win_count})
    end
    table.sort(posts, function(a, b) return tonumber(a.author) > tonumber(b.author) end)
    local gold_color = {r=245, g=190, b=40, a=255}
    local menu = ezmenus.open_menu(event.player_id,"Total Wins BBS",gold_color,posts)
  end
  if object.class == "Points BBS" then
    if not area_memory.pvp_points then
      Net.message_player(event.player_id,"...Theres nothing here yet")
      return
    end
    for player_name, win_count in pairs(area_memory.pvp_points) do
      table.insert(posts,{ id= player_name, read=true, title=player_name, author=win_count})
    end
    table.sort(posts, function(a, b) return tonumber(a.author) > tonumber(b.author) end)
    local purple_color = {r=159, g=39, b=245, a=255}
    local menu = ezmenus.open_menu(event.player_id,"PVP Points BBS",purple_color,posts)
  end
end)

local function record_pvp_victory(player_id,other_player_id)
  local area_id = Net.get_player_area(player_id)
  local area_memory = ezmemory.get_area_memory(area_id)
  local player_name = Net.get_player_name(player_id)
  local other_player_name = Net.get_player_name(other_player_id)
  local award_points = 10
  if player_name == 'anon' then
    return
  end
  --ensure values exist
  if not area_memory.pvp_wins then
    area_memory.pvp_wins = {}
  end
  if not area_memory.pvp_points then
    area_memory.pvp_points = {}
  end
  --ensure players exist
  if not area_memory.pvp_wins[player_name] then
    area_memory.pvp_wins[player_name] = 0
  end
  if not area_memory.pvp_points[player_name] then
    area_memory.pvp_points[player_name] = 0
  end
  --if opponent had points, base points gain on those
  if area_memory.pvp_points[other_player_name] then
    --you get 10% of opponents points as bonus
    award_points = award_points + math.floor((area_memory.pvp_points[other_player_name]*0.1))
  end
  area_memory.pvp_wins[player_name] = area_memory.pvp_wins[player_name] + 1
  area_memory.pvp_points[player_name] = area_memory.pvp_points[player_name] + award_points
  print('[PvP] recorded win for '..player_name..'! gained'..award_points.." points!")
  ezmemory.save_area_memory(area_id)
end

Net:on("battle_results", function(event)
  if players_in_battle[event.player_id] then
      if not event.ran and event.health >= 1 then
        record_pvp_victory(event.player_id,players_in_battle[event.player_id])
      end
      players_in_battle[event.player_id] = nil
  end
end)

return {}
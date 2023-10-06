local ezmemory = require('scripts/ezlibs-scripts/ezmemory')
local helpers = require('scripts/ezlibs-scripts/helpers')

local winner_threshholds = {69,420,999,4200,6969,9999,1337}
local prizes = {"iPad","iPhone","Xbox360","Play Station 3","7950x3D"}

Net:on("player_join", function(event)
  local player_id = event.player_id
  local player_area = Net.get_player_area(player_id)
  local area_memory = ezmemory.get_area_memory(player_area)
  if not area_memory.visitors then
    area_memory.visitors = 0
  end
  area_memory.visitors = area_memory.visitors + 1
  ezmemory.save_area_memory(player_area)
  print('visits',area_memory.visitors)
  for i, value in ipairs(winner_threshholds) do
    if area_memory.visitors == value then
      local item_name = prizes[math.random(1,#prizes)].." "..i
      ezmemory.create_or_update_item(item_name, "prize for being the "..value.."th visitor to "..player_area.."!", true)
      ezmemory.give_player_item(player_id, item_name, 1)
      Net.message_player(player_id,"Congratulations, you are the "..value.."th visitor! you win...\na "..item_name.."!!!")
    end
  end
end)
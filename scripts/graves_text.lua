Net:on("object_interaction", function(event)
  local area_id = Net.get_player_area(event.player_id)
  local object = Net.get_object_by_id(area_id, event.object_id)
  local tileGid = object.data.gid;
  local tileset = Net.get_tileset_for_tile(area_id, tileGid)
  local flavorText = nil

  if tileset.path == "/server/assets/objects/Tombstone_exe6.tsx" then
    local naviName = object.custom_properties.Navi
    if naviName == nil then
      flavorText = '\x01...\x01\nThe plaque is too worn to read'
    else
      flavorText = 'It says:\n"Here lies\n' .. naviName .. '"'
    end
  end

  if flavorText ~= nil then
    Net.message_player(event.player_id, flavorText)
  end
end)

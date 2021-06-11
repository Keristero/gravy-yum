function handle_object_interaction(player_id, object_id)
  local area_id = Net.get_player_area(player_id)
  local object = Net.get_object_by_id(area_id, object_id)
  local tileGid = object.data.gid;
  local tileset = Net.get_tileset_for_tile(area_id, tileGid)
  local flavorText = nil

  if tileset.path == "/server/assets/objects/Tombstone_exe6.tsx" then
    local naviName = object.custom_properties.Navi
    if naviName == nil then
      flavorText = '\x01...\x01\nThe plaque is too worn to read'
    else
      flavorText = 'It says:\n"Here lies\n'..naviName..'"'
    end
  end

  if flavorText ~= nil then
    Net.message_player(player_id, flavorText)
  end
end
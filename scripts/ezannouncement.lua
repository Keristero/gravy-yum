local announcement_file_path = "./announcement.txt"
local delay_till_check = 0
local last_announcement = ""

function TryAnnouncement()
    local areas = Net.list_areas()
    local all_players = {}
    local player_count = 0
    for index, area_id in ipairs(areas) do
        local players = Net.list_players(area_id)
        for index, player_id in ipairs(players) do
            all_players[player_id] = true
            player_count = player_count + 1
        end
    end
    if player_count > 0 or last_announcement == "" then
        local read_file_promise = Async.read_file(announcement_file_path)
        read_file_promise.and_then(function(value)
            if last_announcement == "" then
                last_announcement = value
            elseif last_announcement ~= value then
                for player_id, is_online in pairs(all_players) do
                    Net.message_player(player_id, value)
                end
                print('[ezannouncement] sent announcement to '..player_count..' players')
                print('[ezannouncement] '..value)
                last_announcement = value
            end
        end)
    end
    return true
end

function tick(delta_time)
    if delay_till_check > 0 then
        delay_till_check = delay_till_check - delta_time
    else
        if TryAnnouncement() then
            
        else
            print('err reading '..announcement_file_path)
        end
        delay_till_check = 10
    end
end
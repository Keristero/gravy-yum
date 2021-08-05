local ezweather = {}

local memory = {}

--TODO, support areas being added during server runtime
local og_songs = {}
local areas = Net.list_areas()
for i, area_id in ipairs(areas) do
    local area_custom_properties = Net.get_area_custom_properties(area_id)
    if area_custom_properties["Song"] then
        og_songs[area_id] = area_custom_properties["Song"]
    end
end

function ezweather.start_rain_in_area(area_id)
    print('[ezweather] starting rain in '..area_id)

    memory[area_id] = {camera_tint={r=10, g=10, b=40, a=150},type="rain"}

    local area_custom_properties = Net.get_area_custom_properties(area_id)
    if area_custom_properties["Rain Song"] then
        Net.set_song(area_id, area_custom_properties["Rain Song"])
    end

    fade_camera_for_players_in_area(area_id)
end

function fade_camera_for_players_in_area(area_id)
    local players_in_area = Net.list_players(area_id)
    for i, player_id in ipairs(players_in_area) do
        Net.fade_player_camera(player_id, memory[area_id].camera_tint, 1)
    end
end

function ezweather.get_area_weather(area_id)
    if not memory[area_id] then
        local original_song_path = Net.get_song(area_id)
        memory[area_id] = {camera_tint={r=0, g=0, b=0, a=0},type="clear"}
    end
    return memory[area_id]
end

function ezweather.clear_weather_in_area(area_id)
    print('[ezweather] stopping rain in '..area_id)
    memory[area_id] = {camera_tint={r=0, g=0, b=0, a=0},type="clear"}

    fade_camera_for_players_in_area(area_id)
    local area_custom_properties = Net.get_area_custom_properties(area_id)
    if og_songs[area_id] then
        print('[ezweather] restoring default song for '..area_id)
        Net.set_song(area_id,og_songs[area_id])
    end
end

function ezweather.handle_player_transfer(player_id)
    print('[ezweather] player transfered '..player_id)
    local area_id = Net.get_player_area(player_id)
    local area_weather = ezweather.get_area_weather(area_id)
    Net.fade_player_camera(player_id, area_weather.camera_tint, 1)
end

return ezweather
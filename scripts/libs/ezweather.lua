local ezweather = {}

local memory = {}

local Fade = {
    NONE = 0,
    OUT = 1,
    IN = 3
}

function ezweather.start_rain_in_area(area_id,weather_song_path)
    local original_song_path = Net.get_song(area_id)
    memory[area_id] = {music_path=weather_song_path,camera_tint={r=10, g=10, b=40, a=75},type="rain"}
    Net.set_song(area_id, weather_song_path)
    --TODO, Loop over players in area and fade weather in
end

function ezweather.get_area_weather(area_id)
    if not memory[area_id] then
        local original_song_path = Net.get_song(area_id)
        memory[area_id] = {music_path=original_song_path,camera_tint={r=0, g=0, b=0, a=0},type="clear"}
    else
        return memory[area_id]
    end
end

function ezweather.stop_rain_in_area(area_id,weather_song_path)
    local original_song_path = memory[area_id].music_path
    memory[area_id] = {music_path=original_song_path,camera_tint={r=0, g=0, b=0, a=0},type="clear"}
    Net.set_song(area_id, original_song_path)
end

function ezweather.handle_player_transfer(player_id)
    local area_id = Net.get_player_area(player_id)
    if memory[area_id] then
        Net.fade_player_camera(player_id, Fade.IN, 1, memory[area_id].camera_tint)
    end
end

return ezweather
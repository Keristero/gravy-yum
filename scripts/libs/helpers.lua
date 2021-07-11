local helpers = {}
local urlencode = require('scripts/libs/urlencode')

function helpers.split(string,delimiter)
    local table = {}
    for tag, line in string:gmatch('([^'..delimiter..']+)') do
        table[#table+1] = tag
    end
    return table
end

function helpers.get_safe_player_secret(player_id)
    local player_secret = Net.get_player_secret(player_id)
    local secert_substr = player_secret:sub(2,32)
    return urlencode.string(secert_substr)
end

return helpers
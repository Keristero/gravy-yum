local json = require('scripts/libs/json')
local helpers = require('scripts/libs/helpers')
local ezmemory = {}

local player_memory = {}
local player_list = {}

--Load list of players that have existed
local read_file_promise = Async.read_file('./memory/player_list.json')
read_file_promise.and_then(function(value)
    if value then
        local decoded = json.decode(value)
        player_list = value
        local read_file_promises = {}
        for safe_secret, name in pairs(player_list) do
            local read_file_promise = Async.read_file('./memory/player/'..safe_secret..'.json')
            read_file_promise.and_then(function (value)
                if value then
                    player_memory[safe_secret] = value
                    print('[ezmemory] loaded memory for '..name)
                end
            end)
        end
    end
end)

--TODO when the server starts, load all player memory to player_memory

function ezmemory.save_player_memory(safe_secret)
    if player_memory[safe_secret] then
        Async.write_file('./memory/player/'..safe_secret..'.json', json.encode(player_memory[safe_secret]))
    end
end

function ezmemory.get_player_memory(safe_secret)
    if player_memory[safe_secret] then
        return player_memory[safe_secret]
    else
        player_memory[safe_secret] = {
            items={},
            money=0,
            meta={
                joins=0
            },
            hidden_objects={}
        }
        return player_memory[safe_secret]
    end
end

function update_player_list(safe_secret,name)
    player_list[safe_secret] = name
    Async.write_file('./memory/player_list.json', json.encode(player_list))
end

function ezmemory.give_player_item(player_id, name, description)
    print('[ezitems] gave '..player_id..' a '..name)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    Net.give_player_item(player_id, name, description)
    player_memory.items[#player_memory.items+1] = {name=name,description=description}
    ezmemory.save_player_memory(safe_secret)
end

function ezmemory.set_player_money(player_id, money)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    Net.set_player_money(player_id, money)
    player_memory.money = money
    ezmemory.save_player_memory(safe_secret)
end

function ezmemory.get_first_index_of_item_of_player(player_id, item_name)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    for i, item in ipairs(player_memory.items) do
        if item_name == item.name then
            return i
        end
    end
    return nil
end

function ezmemory.handle_player_join(player_id)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    --assumes that player memory has already been read from disk
    local player_memory = ezmemory.get_player_memory(safe_secret)
    --update join count
    player_memory.meta.joins = player_memory.meta.joins + 1
    --record player to list of players that have joined
    local player_name = Net.get_player_name(player_id)
    update_player_list(safe_secret,player_name)
    --Send player items
    for name, description in pairs(player_memory.items) do
        Net.give_player_item(player_id, name, description)
    end
    --Send player money
    Net.set_player_money(player_id, player_memory.money)
    --Save player memory
    ezmemory.save_player_memory(safe_secret)
end

return ezmemory
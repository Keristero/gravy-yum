local json = require('scripts/libs/json')
local helpers = require('scripts/libs/helpers')
local table = require('table')
local ezmemory = {}

local player_memory = {}
local player_list = {}

--Load list of players that have existed
local read_player_list_promise = Async.read_file('./memory/player_list.json')
read_player_list_promise.and_then(function(value)
    if value then
        player_list = json.decode(value)
        for safe_secret, name in pairs(player_list) do
            local read_player_memory_promise = Async.read_file('./memory/player/'..safe_secret..'.json')
            read_player_memory_promise.and_then(function (value)
                if value then
                    player_memory[safe_secret] = json.decode(value)
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
            area_memory={},
        }
        ezmemory.save_player_memory(safe_secret)
        return player_memory[safe_secret]
    end
end

function ezmemory.get_player_area_memory(safe_secret,area_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    if player_memory.area_memory[area_id] then
        return player_memory.area_memory[area_id]
    else
        player_memory.area_memory[area_id] = {hidden_objects={}}
        ezmemory.save_player_memory(safe_secret)
        return player_memory.area_memory[area_id]
    end
end

function update_player_list(safe_secret,name)
    player_list[safe_secret] = name
    Async.write_file('./memory/player_list.json', json.encode(player_list))
end

function ezmemory.give_player_item(player_id, name, description)
    print('[ezmemory] gave '..player_id..' a '..name)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    Net.give_player_item(player_id, name, description)
    player_memory.items[#player_memory.items+1] = {name=name,description=description}
    ezmemory.save_player_memory(safe_secret)
end

function ezmemory.remove_player_item(player_id, name)
    print('[ezmemory] removed a '..name..' from '..player_id)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    local item_index = ezmemory.get_first_index_of_item_of_player(player_id, name)
    if item_index ~= nil then
        table.remove(player_memory.items, item_index)
        Net.remove_player_item(player_id, name)
    end
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
    --record player to list of players that have joined
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_name = Net.get_player_name(player_id)
    --assumes that player memory has already been read from disk
    local player_memory = ezmemory.get_player_memory(safe_secret)
    update_player_list(safe_secret,player_name)
    --Send player items
    for i, item in ipairs(player_memory.items) do
        Net.give_player_item(player_id, item.name, item.description)
    end
    --Send player money
    Net.set_player_money(player_id, player_memory.money)
    --update join count
    player_memory.meta.joins = player_memory.meta.joins + 1
    --also treat join as player transfer to do per area logic
    ezmemory.handle_player_transfer(player_id)
    --Save player memory
    ezmemory.save_player_memory(safe_secret)
end

function ezmemory.handle_player_transfer(player_id)
    --record player to list of players that have joined
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_name = Net.get_player_name(player_id)
    local area_id = Net.get_player_area(player_id)
    --assumes that player memory has already been read from disk
    local player_area_memory = ezmemory.get_player_area_memory(safe_secret,area_id)
    for i, object_id in pairs(player_area_memory.hidden_objects) do
        Net.exclude_object_for_player(player_id, object_id)
    end
    print('[ezmemory] hid '..#player_area_memory.hidden_objects..' objects from '..player_name)
end

return ezmemory
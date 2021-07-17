local json = require('scripts/libs/json')
local helpers = require('scripts/libs/helpers')
local table = require('table')
local ezmemory = {}

local player_memory = {}
local area_memory = {}
local player_list = {}

local function load_file_and_then(filename,callback)
    local read_file_promise = Async.read_file(filename)
    read_file_promise.and_then(function(value)
        if value then
            callback(value)
        end
    end)
end

--Load list of players that have existed
load_file_and_then('./memory/player_list.json',function(value)
    player_list = json.decode(value)
    --Load memory files for every player
    for safe_secret, name in pairs(player_list) do
        load_file_and_then('./memory/player/'..safe_secret..'.json',function (value)
            player_memory[safe_secret] = json.decode(value)
            print('[ezmemory] loaded memory for '..name)
        end)
    end
end)

--Load area memory for every area
local net_areas = Net.list_areas()
for i, area_id in ipairs(net_areas) do
    load_file_and_then('./memory/area/'..area_id..'.json',function(value)
        area_memory[area_id] = json.decode(value)
        print('[ezmemory] loaded area memory for '..area_id)
    end)
end

function ezmemory.save_area_memory(area_id)
    if area_memory[area_id] then
        Async.write_file('./memory/area/'..area_id..'.json', json.encode(area_memory[area_id]))
    end
end

function ezmemory.save_player_memory(safe_secret)
    if player_memory[safe_secret] then
        Async.write_file('./memory/player/'..safe_secret..'.json', json.encode(player_memory[safe_secret]))
    end
end

function ezmemory.get_area_memory(area_id)
    if area_memory[area_id] then
        return area_memory[area_id]
    else
        area_memory[area_id] = {
            hidden_objects = {}
        }
        ezmemory.save_area_memory(area_id)
        return area_memory[area_id]
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

function ezmemory.get_player_name_from_safesecret(safe_secret)
    if player_list[safe_secret] then
        return player_list[safe_secret]
    end
    return "Unknown"
end

function ezmemory.give_player_item(player_id, name, description, amount)
    if not amount then
        amount = 1
    end
    --TODO index items with player_memory.items[item_id]
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    for i=1,amount do
        Net.give_player_item(player_id, name, description)
    end
    if player_memory.items[name] then
        --If the player already has the item, increase the quantity
        player_memory.items[name].quantity = player_memory.items[name].quantity + amount
    else
        --Otherwise create the item
        player_memory.items[name] = {name=name,description=description,quantity=amount}
    end
    print('[ezmemory] gave '..player_id..' '..amount..' '..name..' now they have '..player_memory.items[name].quantity)
    ezmemory.save_player_memory(safe_secret)
end

function ezmemory.remove_player_item(player_id, name, remove_quant)
    print('[ezmemory] removed a '..name..' from '..player_id)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    if player_memory.items[name] then
        --If the player has the item
        for i=1,remove_quant do
            Net.remove_player_item(player_id, name)
        end
        player_memory.items[name].quantity = player_memory.items[name].quantity - remove_quant
        if player_memory.items[name].quantity < 1 then
            --if the quantity drops below 1, remove the item completely
            player_memory.items[name] = nil
            return 0
        end
        ezmemory.save_player_memory(safe_secret)
        return player_memory.items[name].quantity
    end
    return 0
end

function ezmemory.set_player_money(player_id, money)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    Net.set_player_money(player_id, money)
    player_memory.money = money
    ezmemory.save_player_memory(safe_secret)
end

function ezmemory.count_player_item(player_id, item_name)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    if player_memory.items[item_name] then
        return player_memory.items[item_name].quantity
    end
    return false
end

function ezmemory.handle_player_join(player_id)
    --record player to list of players that have joined
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_name = Net.get_player_name(player_id)
    --assumes that player memory has already been read from disk
    local player_memory = ezmemory.get_player_memory(safe_secret)
    update_player_list(safe_secret,player_name)
    --Send player items
    for item_name, item in pairs(player_memory.items) do
        for i=1,item.quantity do
            Net.give_player_item(player_id, item.name, item.description)
        end
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
    --load memory of area
    local area_memory = ezmemory.get_area_memory(area_id)
    for object_id, is_hidden in pairs(area_memory.hidden_objects) do
        Net.exclude_object_for_player(player_id, object_id)
    end
    --load player's memory of area
    local player_area_memory = ezmemory.get_player_area_memory(safe_secret,area_id)
    for object_id, is_hidden in pairs(player_area_memory.hidden_objects) do
        Net.exclude_object_for_player(player_id, object_id)
    end
    print('[ezmemory] hid '..#player_area_memory.hidden_objects..' objects from '..player_name)
end

return ezmemory
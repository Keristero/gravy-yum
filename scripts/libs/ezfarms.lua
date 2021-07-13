local ezfarms = {}

local eznpcs = require('scripts/libs/eznpcs/eznpcs')
local ezmemory = require('scripts/libs/ezmemory')
local table = require('table')
local helpers = require('scripts/libs/helpers')

local players_using_bbs = {}
local player_tools = {}
local farm_area = 'farm'
local area_memory = nil

local delay_till_update = 1

local PlantData = {
    Turnip={price=100},
    Cauliflower={price=150},
    Garlic={price=175},
    Tomato={price=200},
    Chili={price=220},
    Beetroot={price=180},
    Star={price=300},
    Eggplant={price=230},
    Pumpkin={price=250},
    Yam={price=90},
    ["Beetroot 2"]={price=169},
    ["Ancient"]={price=1000},
    ["Sweet Gem"]={price=500},
    Blueberry={price=400}
}

--Key = tool name, value = plant/tool name
local ToolNames = {CyberHoe="CyberHoe",CyberWtrCan="CyberWtrCan"}
for plant_name, plant in pairs(PlantData) do
    ToolNames[plant_name.." seed"] = plant_name
end

local Tiles = {
    Dirt=85,
    Grass=86,
    DirtWet=87
}

--These resources are not actually loaded here, but are currently loaded by entry script anyway.
local sfx = {
    hurt='/server/assets/sfx/hurt.ogg',
    item_get='/server/assets/sfx/item_get.ogg',
    recover='/server/assets/sfx/recover.ogg',
    card_error='/server/assets/sfx/card_error.ogg'
}

--periods before certain things happen to tiles
local Period = {
    EmptyDirtToGrass=600,
    EmptyDirtWetToDirt=60*60,
    PlantedDirtWetToDirt=60*60*12,
}

local farm_loaded = false

local function update_tile(current_time,loc_string)
    local tile_memory = area_memory.tile_states[loc_string]
    local elpased_since_water = current_time-tile_memory.time.watered
    local elapsed_since_tilled = current_time-tile_memory.time.tilled
    local elapsed_since_planted = current_time-tile_memory.time.planted
    local new_gid = tile_memory.gid --dont change it by default
    local something_changed = false
    local plant_bot_id = loc_string.."plant"
    if tile_memory.plant ~= nil then
        if not Net.is_bot(plant_bot_id) then
            print('creating bot '..plant_bot_id)
            local new_bot_data = { 
                name=tile_memory.plant,
                area_id=farm_area,
                texture_path="/server/assets/objects/plants.png",
                animation_path="/server/assets/objects/plants.animation",
                x=tile_memory.x+0.5,
                y=tile_memory.y+0.5,
                z=tile_memory.z,
                solid=false
            }
            Net.create_bot(plant_bot_id, new_bot_data)
            print('setting animation to IDLE_U')
            --Grr, seems i can only use real animation names?
            Net.animate_bot(plant_bot_id, "IDLE_U", true)
        end
    else
        if Net.is_bot(plant_bot_id) then
            Net.remove_bot(plant_bot_id)
        end
    end

    if tile_memory.gid == Tiles.DirtWet then
        if tile_memory.plant then
            if elpased_since_water > Period.PlantedDirtWetToDirt then
                new_gid = Tiles.Dirt
                something_changed = true
            end
        else
            if elpased_since_water > Period.EmptyDirtWetToDirt then
                tile_memory.time.tilled = current_time
                new_gid = Tiles.Dirt
                something_changed = true
            end
        end
    elseif tile_memory.gid == Tiles.Dirt then
        if tile_memory.plant then
        else
            if elapsed_since_tilled > Period.EmptyDirtToGrass then
                new_gid = Tiles.Grass
                something_changed = true
            end
        end
    end
    --TODO might need to do something with something_changed here? where what was I doing...
    Net.set_tile(farm_area, tile_memory.x, tile_memory.y, tile_memory.z, new_gid)
    return something_changed
end

function load_farm()
    print('[ezfarms] farm area memory loaded')
    area_memory = ezmemory.get_area_memory(farm_area)
    --create tile states if it does not exist
    if not area_memory.tile_states then
        area_memory.tile_states = {}
        ezmemory.save_area_memory(farm_area)
    end
    --load tile states for land
    update_all_tiles()
    --after updating tiles, save memory
    ezmemory.save_area_memory(farm_area)
    farm_loaded = true
end

function update_all_tiles()
    local current_time = os.time()
    local something_changed = false
    for loc_string, tile_memory in pairs(area_memory.tile_states) do
        if update_tile(current_time,loc_string) then
            something_changed = true
        end
    end
    return something_changed
end

function ezfarms.handle_player_join(player_id)
    load_farm()
end

function ezfarms.on_tick(delta_time)
    if not farm_loaded then
        return
    end
    if delay_till_update > 0 then
        delay_till_update = delay_till_update - delta_time
    else
        local something_changed = update_all_tiles()
        if something_changed then
            ezmemory.save_area_memory(farm_area)
        end
        delay_till_update = 1
    end
end

function ezfarms.handle_post_selection(player_id, post_id)
    if players_using_bbs[player_id] then
        if players_using_bbs[player_id] == "Buy Seeds" then
            try_buy_seed(player_id,post_id)
        elseif players_using_bbs[player_id] == "Select Tool" then
            player_tools[player_id] = ToolNames[post_id]
            players_using_bbs[player_id] = nil
            Net.message_player(player_id,"You are now holding "..post_id)
            Net.close_bbs(player_id)
        end
    end
end

function ezfarms.handle_board_close(player_id)
    players_using_bbs[player_id] = nil
end

function try_buy_seed(player_id,plant_name)
    local player_cash = Net.get_player_money(player_id)
    local price = PlantData[plant_name].price
    if player_cash >= price then
        ezmemory.set_player_money(player_id,player_cash-price)
        Net.play_sound_for_player(player_id,sfx.item_get)
        ezmemory.give_player_item(player_id, plant_name.." seed", "seed for planting "..plant_name)
    else
        Net.message_player(player_id,"Not enough $")
        Net.play_sound_for_player(player_id,sfx.card_error)
    end
    
end

local seed_stall = {
    name="seed_stall",
    action=function (npc,player_id,dialogue)
        local board_color = { r= 128, g= 255, b= 128 }
        local posts = {}
        for plant_name, data in pairs(PlantData) do
            local seed_name = plant_name.." seed"
            posts[#posts+1] = { id=plant_name, read=true, title=seed_name , author=tostring(data.price) }
        end
        local bbs_name = "Buy Seeds"
        players_using_bbs[player_id] = bbs_name
        Net.open_board(player_id, bbs_name, board_color, posts)
        local next_dialouge_options = {
            wait_for_response=true,
            id=dialogue.custom_properties["Next 1"]
        }
        return next_dialouge_options
    end
}
eznpcs.add_event(seed_stall)


--Farming stuff

function ezfarms.list_player_tools(player_id)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    local player_memory = ezmemory.get_player_memory(safe_secret)
    local tool_counts = {}
    for i, item in ipairs(player_memory.items) do
        for tool_name, tool_key in pairs(ToolNames) do
            if item.name == tool_name then
                if tool_counts[tool_name] then
                    tool_counts[tool_name] = tool_counts[tool_name] + 1
                else
                    tool_counts[tool_name] = 1
                end
            end
        end
    end
    return tool_counts
end

function ezfarms.open_held_item_select(player_id)
    local tool_counts = ezfarms.list_player_tools(player_id)
    local board_color = { r= 165, g= 42, b= 42 }
    local posts = {}
    for tool_name, tool_count in pairs(tool_counts) do
        posts[#posts+1] = { id=tool_name, read=true, title=tool_name , author="x "..tostring(tool_count) }
    end
    local bbs_name = "Select Tool"
    players_using_bbs[player_id] = bbs_name
    Net.open_board(player_id, bbs_name, board_color, posts)
end

local function get_location_string(x,y,z)
    return tostring(x)..','..tostring(y)..','..tostring(z)
end

local function till_tile(tile,x,y,z)
    if tile.gid == Tiles.Grass then
        local tile_loc_string = get_location_string(x,y,z)
        local current_time = os.time()
        area_memory.tile_states[tile_loc_string] = {
            gid=Tiles.Dirt,
            x=x,
            y=y,
            z=z,
            plant=nil,
            time={
                tilled=current_time,
                watered=0,
                planted=0
            }
        }
        update_tile(current_time,tile_loc_string)
        ezmemory.save_area_memory(farm_area)
    end
end

local function water_tile(tile,x,y,z)
    if tile.gid == Tiles.Dirt or tile.gid == Tiles.DirtWet then
        local tile_loc_string = get_location_string(x,y,z)
        local current_time = os.time()
        area_memory.tile_states[tile_loc_string].time.watered = current_time
        area_memory.tile_states[tile_loc_string].gid = Tiles.DirtWet
        update_tile(current_time,tile_loc_string)
        ezmemory.save_area_memory(farm_area)
    end
end

local function plant(tile,x,y,z,player_id,seed)
    if tile.gid == Tiles.Dirt or tile.gid == Tiles.DirtWet then
        local plant_to_plant = player_tools[player_id]
        print('[ezfarms] planting '..plant_to_plant)
        local tile_loc_string = get_location_string(x,y,z)
        local current_time = os.time()
        area_memory.tile_states[tile_loc_string].time.planted = current_time
        area_memory.tile_states[tile_loc_string].plant = plant_to_plant
        update_tile(current_time,tile_loc_string)
        ezmemory.save_area_memory(farm_area)
    end
end

function ezfarms.handle_tile_interaction(player_id, x, y, z, button)
    local x = math.floor(x)
    local y = math.floor(y)
    local z = math.floor(z)
    local area_id = Net.get_player_area(player_id)
    if area_id ~= farm_area then
        --player is not in farm
        return
    end
    if button == 1 then
        ezfarms.open_held_item_select(player_id)
        return
    end
    if not player_tools[player_id] then
        --player has no tool selected
        return
    end
    --the player tool uses the ToolNames mapping, so "apple seed"="apple"
    local player_tool = player_tools[player_id]
    local tile = Net.get_tile(area_id, x, y, z)

    if player_tool == "CyberHoe" then
        till_tile(tile,x,y,z)
    elseif player_tool == "CyberWtrCan" then
        water_tile(tile,x,y,z)
    else
        plant(tile,x,y,z,player_id)
    end
end

return ezfarms
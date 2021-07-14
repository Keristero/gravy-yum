local ezfarms = {}

local eznpcs = require('scripts/libs/eznpcs/eznpcs')
local ezmemory = require('scripts/libs/ezmemory')
local table = require('table')
local helpers = require('scripts/libs/helpers')

local players_using_bbs = {}
local player_tools = {}
local farm_area = 'farm'
local area_memory = nil
local delay_till_update = 1 --wait 1 second between updating all farm tiles
local reference_seed = Net.get_object_by_name(farm_area,"Reference Seed")

local plant_ram = {}--non persisted plant related values, keyed by loc_string

local PlantData = {
    Turnip={price=100,local_gid=0},
    Cauliflower={price=150,local_gid=7},
    Garlic={price=175,local_gid=14},
    Tomato={price=200,local_gid=21},
    Chili={price=220,local_gid=28},
    Beetroot={price=180,local_gid=35},
    Star={price=300,local_gid=42},
    Eggplant={price=230,local_gid=49},
    Pumpkin={price=250,local_gid=56},
    Yam={price=90,local_gid=63},
    ["Beetroot 2"]={price=169,local_gid=70},
    ["Ancient"]={price=1000,local_gid=77},
    ["Sweet Gem"]={price=500,local_gid=84},
    Blueberry={price=400,local_gid=91},
    Dead={local_gid=98}
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

local function calculate_plant_gid(plant_name,growth_stage)
    local first_gid = reference_seed.data.gid
    print('plant name '..plant_name)
    if growth_stage == 0 then
        --if the plant is seeds
        local first_plant_gid = first_gid+PlantData[plant_name].local_gid
        return first_plant_gid + math.random(0,1)
    elseif growth_stage > 0 and growth_stage < 5 then
        --if the plant is growing or grown
        local first_plant_gid = (first_gid+1)+PlantData[plant_name].local_gid
        return first_plant_gid+growth_stage
    else
        --if the plant is dead
        plant_name = "Dead"
        local first_plant_gid = first_gid+PlantData[plant_name].local_gid
        return first_plant_gid + math.random(0,3)
    end
end

local function determine_growth_stage(plant_name,elapsed_since_planted)
    --stage 0 = seeds, stage 1-3 = growing, 4 = grown, 5=dead 
    local plant = PlantData[plant_name]
    local stage_time = 10
    local stages = 4
    local death_time = (stage_time*stages)+60
    local growth_stage = math.min(4,math.floor(elapsed_since_planted/stage_time))
    if elapsed_since_planted > death_time then
        growth_stage = 5
    end
    return growth_stage
end

local function update_tile(current_time,loc_string)
    local tile_memory = area_memory.tile_states[loc_string]
    local elpased_since_water = current_time-tile_memory.time.watered
    local elapsed_since_tilled = current_time-tile_memory.time.tilled
    local elapsed_since_planted = current_time-tile_memory.time.planted
    local new_gid = tile_memory.gid --dont change it by default
    local something_changed = false

    --Create or remove plant object when required
    if tile_memory.plant ~= nil then
        local growth_stage = determine_growth_stage(tile_memory.plant,elapsed_since_planted)
        if not plant_ram[loc_string] then
            --create the plant if it does not exist when it should
            local plant_gid = calculate_plant_gid(tile_memory.plant,growth_stage)
            local plant_tile_data = {
                type = "tile",
                gid=plant_gid,
                flipped_horizontally=false,
                flipped_vertically=false
            }
            local new_plant_data = { 
                name=tile_memory.plant,
                type="cyberplant",
                visible=true,
                x=tile_memory.x+0.8,
                y=tile_memory.y+0.8,
                z=tile_memory.z,
                width=0.5,
                height=1,
                data=plant_tile_data
            }
            local new_plant_id = Net.create_object(farm_area, new_plant_data)
            plant_ram[loc_string] = {
                growth_stage=growth_stage,
                id=new_plant_id
            }
            something_changed = true
        else
            if growth_stage ~= plant_ram[loc_string].growth_stage then
                --if a differenet growth stage has been calculated, update the custom property and gid of the object
                print('[ezfarms] a plant changed growth stage! '..growth_stage..' from '..plant_ram[loc_string].growth_stage)
                local plant_gid = calculate_plant_gid(tile_memory.plant,growth_stage)
                local plant_tile_data = {
                    type = "tile",
                    gid=plant_gid,
                    flipped_horizontally=false,
                    flipped_vertically=false
                }
                plant_ram[loc_string].growth_stage = growth_stage
                Net.set_object_data(farm_area, plant_ram[loc_string].id, plant_tile_data)
            end
        end
    else
        if plant_ram[loc_string] then
            --remove the plant if it exists when it should not
            print('trying to delete plant by id '..plant_ram[loc_string].id)
            Net.remove_object(farm_area, plant_ram[loc_string].id)
            plant_ram[loc_string] = nil
            something_changed = true
        end
    end

    --Change tile between Grass/Dirt/DirtWet when required
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
    print('[ezfarms] farm area loading')
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
            if data.price then
                --If the plant is for sale (has a price)
                local seed_name = plant_name.." seed"
                posts[#posts+1] = { id=plant_name, read=true, title=seed_name , author=tostring(data.price) }
            end
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
            growth=0,
            time={
                tilled=current_time,
                watered=0,
                planted=0,
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

local function plant(tile_loc_string,player_id,plant_to_plant,current_time)
    print('[ezfarms] planting '..plant_to_plant)
    local safe_secret = helpers.get_safe_player_secret(player_id)
    area_memory.tile_states[tile_loc_string].time.planted = current_time
    area_memory.tile_states[tile_loc_string].plant = plant_to_plant
    area_memory.tile_states[tile_loc_string].owner = safe_secret
    update_tile(current_time,tile_loc_string)
    ezmemory.save_area_memory(farm_area)
end

local function harvest(tile_loc_string,player_id,safe_secret,current_time)
    local harvest_count = 1
    Net.message_player(player_id,"Harvested "..harvest_count.." "..area_memory.tile_states[tile_loc_string].plant.."!")
    ezmemory.give_player_item(player_id, area_memory.tile_states[tile_loc_string].plant, "mmm, yummy "..area_memory.tile_states[tile_loc_string].plant)
    area_memory.tile_states[tile_loc_string].plant = nil
    area_memory.tile_states[tile_loc_string].owner = nil
    area_memory.tile_states[tile_loc_string].time.tilled = current_time -- so the dirt does not immediately go back to being grass
    update_tile(current_time,tile_loc_string)
    ezmemory.save_area_memory(farm_area)
end

local function describe_growth_state(growth_stage)
    if growth_stage == 5 then
        return "dead as bro"
    elseif growth_stage == 4 then
        return "ready for harvest!"
    elseif growth_stage == 3 then
        return "almost ripe for picking!"
    elseif growth_stage == 2 then
        return "to be healthy"
    elseif growth_stage == 1 then
        return "to be growing steadily"
    elseif growth_stage == 0 then
        return "like it was just planted"
    end
end

local function try_plant_seed(tile,x,y,z,player_id,seed)
    if tile.gid == Tiles.Dirt or tile.gid == Tiles.DirtWet then
        local safe_secret = helpers.get_safe_player_secret(player_id)
        local plant_to_plant = player_tools[player_id]
        local tile_loc_string = get_location_string(x,y,z)
        local current_time = os.time()
        local prexisting_plant = plant_ram[tile_loc_string]
        if not prexisting_plant or prexisting_plant.growth_stage == 5 then
            plant(tile_loc_string,player_id,plant_to_plant,current_time)
        else
            local existing_plant_name = area_memory.tile_states[tile_loc_string].plant
            if area_memory.tile_states[tile_loc_string].owner == safe_secret then
                if prexisting_plant.growth_stage == 4 then
                    harvest(tile_loc_string,player_id,safe_secret,current_time)
                else
                    Net.message_player(player_id,"the "..existing_plant_name.." looks "..describe_growth_state(prexisting_plant.growth_stage))
                end
            else
                local owner_name = ezmemory.get_player_name_from_safesecret(area_memory.tile_states[tile_loc_string].owner)
                Net.message_player(player_id,owner_name.."'s "..existing_plant_name.." looks "..describe_growth_state(prexisting_plant.growth_stage))
            end
        end
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
        try_plant_seed(tile,x,y,z,player_id)
    end
end

return ezfarms
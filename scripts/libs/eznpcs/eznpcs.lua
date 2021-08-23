local Direction = require("scripts/libs/direction")
local math = require('math')

local eznpcs = {}
local placeholder_to_botid = {}

local npc_asset_folder = '/server/assets/eznpcs/'
local generic_npc_animation_path = npc_asset_folder..'sheet/npc.animation'
local generic_npc_mug_animation_path = npc_asset_folder..'mug/mug.animation'
local npcs = {}
local events = {}
local textbox_responses = {}
local npc_required_properties = {"Direction","Asset Name"}

--Type [string] must be NPC
--NPC custom_properties:
--  Asset Name [string] name of asset in eznpc assets folder, just file name, no extension
--  Animation Name [string] name of animation in eznpc assets folder, not usually required
--  Chat [string] NPC will respond with this string when you interact with them
--  Direction [string] Initial direction this NPC will face
--  Next Waypoint 1 [object] NPC will path to this object
--      Wait Time [int] NPC will wait for this period in seconds when it reaches the waypoint
--      Direction [string] NPC will face this way while waiting

--Dialogue custom_properties
--  Dialogue Type [string]
--      first       responds with Text 1 -> Next 1
--      random      responds with Text x (random) -> Next x (if it exists, otherwise Next 1)
--      question    questions with Text 1 -> 
--          yes = Next 1
--          no = Next 2
--      quiz        select from Text 1, Text 2, Text 3, or Text 4 -> Next 1, Next 2, Next 3, or Next 4
--      prompt      select from Text 1 -> Next 1
--      none        display no text, useful for when you want an event with no text
--  Text 1 (first text option, used differently for different Dialogue Types)
--  Text 2, etc
--  Next 1 (first id of next dialogue, used differently for different dialogue types)
--  Next 2, etc
--  Event Name (npc,player_id)

--TODO load all waypoints / dialogues on server start and delete them from the map to save bandwidth

function DoDialogue(npc,player_id,dialogue,relay_object)
    local dialogue_type = dialogue.custom_properties["Dialogue Type"]
    local event_name = dialogue.custom_properties["Event Name"]
    local message = ""
    local next_dialogue_id = nil
    if event_name then
        next_dialogue_info = events[event_name].action(npc,player_id,dialogue,relay_object)
        if next_dialogue_info then
            if next_dialogue_info.id then
                if not next_dialogue_info.wait_for_response then
                    local area_id = Net.get_player_area(player_id)
                    local dialogue = Net.get_object_by_id(area_id,next_dialogue_info.id)
                    DoDialogue(npc,player_id,dialogue,relay_object)
                    return
                end
                next_dialogue_id = next_dialogue_info.id
            end
        end
    end
    if dialogue_type == nil then
        return
    end
    local mug_texture_path = npc_asset_folder.."mug/"..npc.asset_name..".png"
    local mug_animation_path = npc.mug_animation_path
    local player_pos = Net.get_player_position(player_id)

    local dialogue_texts = ExtractNumberedProperties(dialogue,"Text ")
    local next_dialogues = ExtractNumberedProperties(dialogue,"Next ")

    if dialogue_type == "first" or  dialogue_type == "question" then
        message = dialogue_texts[1]
        local next_id = FirstValueFromTable(next_dialogues)
        next_dialogue_id = next_id
    end

    if dialogue_type == "random" then
        local rnd_text_index = math.random( #dialogue_texts)
        message = dialogue_texts[rnd_text_index]
        next_dialogue_id = next_dialogues[rnd_text_index] or next_dialogues[1]
    end

    Net.set_bot_direction(npc.bot_id, Direction.from_points(npc, player_pos))

    if dialogue_type ~= "none" then
        if dialogue_type == "question" then
            Net.question_player(player_id, message, mug_texture_path, mug_animation_path)
        else
            Net.message_player(player_id, message, mug_texture_path, mug_animation_path)
        end
    end
    textbox_responses[player_id] = {
        npc=npc,
        action=function(response)
            EndConversation(player_id)
            if dialogue_type == "question" then
                local next_index = 2
                if response == 1 then
                    next_index = 1
                end
                next_dialogue_id = next_dialogues[next_index]
            end
            if next_dialogue_id then
                local area_id = Net.get_player_area(player_id)
                local dialogue = Net.get_object_by_id(area_id,next_dialogue_id)
                DoDialogue(npc,player_id,dialogue,relay_object)
            end
        end
    }
end

function ExtractNumberedProperties(object,property_prefix)
    local out_table = {}
    for i=1,10 do
        local text = object.custom_properties[property_prefix..i]
        if text then
            out_table[i] = text
        end
    end
    return out_table
end

function FirstValueFromTable(tbl)
    for i, value in pairs(tbl) do
        return value
    end
    return nil
end

function CreateBotFromObject(area_id,object_id)
    local placeholder_object = Net.get_object_by_id(area_id, object_id)
    local x = placeholder_object.x
    local y = placeholder_object.y
    local z = placeholder_object.z

    for i, prop_name in pairs(npc_required_properties) do
        if not placeholder_object.custom_properties[prop_name] then
            print('[eznpcs] NPC objects require the custom property '..prop_name)
            return false
        end
    end  

    local npc_asset_name = placeholder_object.custom_properties["Asset Name"]
    local npc_animation_name = placeholder_object.custom_properties["Animation Name"] or false
    local npc_mug_animation_name = placeholder_object.custom_properties["Mug Animation Name"] or false
    local direction = placeholder_object.custom_properties.Direction

    local npc = CreateNPC(area_id,npc_asset_name,x,y,z,direction,placeholder_object.name,npc_animation_name,npc_mug_animation_name)
    placeholder_to_botid[tostring(object_id)] = npc.bot_id
    print('[eznpcs] added placeholder mapping '..object_id..' to '..npc.bot_id)

    if placeholder_object.custom_properties["Dialogue Type"] then
        --If the placeholder has Chat text, add behaviour to have it respond to interactions
        npc.first_dialogue = placeholder_object
        local chat_behaviour = ChatBehaviour()
        AddBehaviour(npc,chat_behaviour)
    end

    if placeholder_object.custom_properties["Next Waypoint 1"] then
        --If the placeholder has npc_first_waypoint
        local waypoint_follow_behaviour = WaypointFollowBehaviour(placeholder_object.custom_properties["Next Waypoint 1"])
        AddBehaviour(npc,waypoint_follow_behaviour)
    end
end

function CreateNPC(area_id,asset_name,x,y,z,direction,bot_name,animation_name,mug_animation_name)
    local texture_path = npc_asset_folder.."sheet/"..asset_name..".png"
    local animation_path = generic_npc_animation_path
    local mug_animation_path = generic_npc_mug_animation_path
    local name = bot_name or nil
    --Override animations if they were provided as custom properties
    if animation_name then
        animation_path = npc_asset_folder..'sheet/'..animation_name..".animation"
    end
    if mug_animation_name then
        mug_animation_path = npc_asset_folder..'mug/'..mug_animation_name..".animation"
    end
    --Log final paths
    print('[eznpcs] texture path: '..texture_path)
    print('[eznpcs] animation path: '..animation_path)
    print('[eznpcs] mug animation path: '..mug_animation_path)
    --Create bot
    local npc_data = {
        asset_name=asset_name,
        bot_id=nil, 
        name=name, 
        area_id=area_id, 
        texture_path=texture_path, 
        animation_path=animation_path, 
        mug_animation_path=mug_animation_path,
        x=x, 
        y=y, 
        z=z, 
        direction=direction, 
        solid=true, 
        size=0.2,
        speed=1,
    }
    local lastBotId = Net.create_bot(npc_data)
    npc_data.bot_id = lastBotId
    npcs[lastBotId] = npc_data
    print('[eznpcs] created npc '..lastBotId..' at ('..x..','..y..','..z..')')
    return npc_data
end

function AddBehaviour(npc,behaviour)
    --Behaviours have a type and an action
    --type is the event that triggers them, on_interact or on_tick
    --action is the callback for the logic
    --optionally initialize can exist to init the behaviour when it is first added
    if behaviour.type and behaviour.action then
        npc[behaviour.type] = behaviour
        if behaviour.initialize then
            behaviour.initialize(npc)
        end
        print('[eznpcs] added '..behaviour.type..' behaviour to NPC')
    end
end

--Behaviour factories
function ChatBehaviour()
    behaviour = {
        type='on_interact',
        action=function(npc,player_id,relay_object)
            local dialogue = npc.first_dialogue
            DoDialogue(npc,player_id,dialogue,relay_object)
        end
    }
    return behaviour
end

function EndConversation(player_id)
    textbox_responses[player_id] = nil
end

function GetTableLength(tbl)
    local getN = 0
    for n in pairs(tbl) do 
      getN = getN + 1 
    end
    return getN
end

function WaypointFollowBehaviour(first_waypoint_id)
    behaviour = {
        type='on_tick',
        initialize=function(npc)
            local first_waypoint = Net.get_object_by_id(npc.area_id, first_waypoint_id)
            if first_waypoint then
                npc.next_waypoint = first_waypoint
            else
                print('[eznpcs] invalid Next Waypoint '..first_waypoint_id)
            end
        end,
        action=function(npc,delta_time)
            MoveNPC(npc,delta_time)
        end
    }
    return behaviour
end

function OnActorInteraction(player_id,actor_id,relay_object)
    local npc_id = actor_id
    if npcs[npc_id] then
        local npc = npcs[npc_id]
        if npc.on_interact then
            npc.on_interact.action(npc,player_id,relay_object)
        end
    end
end

function position_overlaps_something(position,area_id)
    --Returns true if a position (with a size) overlaps something important
    local player_ids = Net.list_players(area_id)

    --Check for overlap against players
    for i = 1, #player_ids, 1 do
        local player_pos = Net.get_player_position(player_ids[i])
        if
            math.abs(player_pos.x - position.x) < position.size and
            math.abs(player_pos.y - position.y) < position.size and
            player_pos.z == position.z
        then
            return true
        end
    end

    return false
end

function AnyoneTalkingToNPC(npc_id)
    for player_id, conversation in next, textbox_responses do
        if conversation.npc.bot_id == npc_id then
            return true
        end
    end
    return false
end

function MoveNPC(npc,delta_time)
    if AnyoneTalkingToNPC(npc.bot_id) then
        return
    end
    if npc.wait_time and npc.wait_time > 0 then
        npc.wait_time = npc.wait_time - delta_time
        return
    end

    local area_id = Net.get_bot_area(npc.bot_id)
    local waypoint = npc.next_waypoint

    local distance = math.sqrt((waypoint.x - npc.x) ^ 2 + (waypoint.y - npc.y) ^ 2)
    if distance < npc.size then
        NPCReachedWaypoint(npc,waypoint)
        return
    end
    
    local angle = math.atan(waypoint.y - npc.y, waypoint.x - npc.x)
    local vel_x = math.cos(angle) * npc.speed
    local vel_y = math.sin(angle) * npc.speed

    local new_pos = {x=0,y=0,z=npc.z,size=npc.size}

    new_pos.x = npc.x + vel_x * delta_time
    new_pos.y = npc.y + vel_y * delta_time

    if position_overlaps_something(new_pos,area_id) then
        return
    end

    Net.move_bot(npc.bot_id, new_pos.x, new_pos.y, new_pos.z)
    npc.x = new_pos.x
    npc.y = new_pos.y

end

function NPCReachedWaypoint(npc,waypoint)
    if waypoint.custom_properties['Wait Time'] ~= nil then
        npc.wait_time = tonumber(waypoint.custom_properties['Wait Time'])
        if waypoint.custom_properties['Direction'] ~= nil then
            Net.set_bot_direction(npc.bot_id, waypoint.custom_properties['Direction'])
        end
    end
    local waypoint_type = "first"
    if waypoint.custom_properties["Waypoint Type"] then
        waypoint_type = waypoint.custom_properties["Waypoint Type"]
    end
    --select next waypoint based on Waypoint Type
    local next_waypoints = ExtractNumberedProperties(waypoint,"Next Waypoint ")
    local next_waypoint_id = nil
    if waypoint_type == "first" then
        next_waypoint_id = FirstValueFromTable(next_waypoints)
    end
    if waypoint_type == "random" then
        local next_waypoint_index = math.random(#next_waypoints)
        next_waypoint_id = next_waypoints[next_waypoint_index]
    end
    if next_waypoint_id then
        npc.next_waypoint = Net.get_object_by_id(npc.area_id,next_waypoint_id)
    end
end

function OnTextboxResponse(player_id, response)
    if textbox_responses[player_id] then
        textbox_responses[player_id].action(response)
    end
end

function OnPlayerDisconnect(player_id)
    EndConversation(player_id)
end

function OnPlayerTransfer(player_id)
    EndConversation(player_id)
end

function AddEvent(event_object)
    if event_object.name and event_object.action then
        events[event_object.name] = event_object
    else
        print('[eznpcs] Cant add invalid event, events need a name and action {}')
    end
end

function OnObjectInteract(player_id, object_id)
    local area_id = Net.get_player_area(player_id)
    local relay_object = Net.get_object_by_id(area_id,object_id)
    if relay_object.custom_properties["Interact Relay"] then
        local placeholder_id = relay_object.custom_properties["Interact Relay"]
        local bot_id = placeholder_to_botid[placeholder_id]
        OnActorInteraction(player_id,bot_id,relay_object)
    end
end

function AddNpcsToArea(area_id)
    --Loop over all objects in area, spawning NPCs for each NPC type object.
    local objects = Net.list_objects(area_id)
    for i, object_id in next, objects do
        local object = Net.get_object_by_id(area_id, object_id)
        if object.type == "NPC" then
            CreateBotFromObject(area_id, object_id)
        end
    end
end

function LoadNpcs()
    --for each area, load NPCS
    local areas = Net.list_areas()
    for i, area_id in next, areas do
        --Add npcs to existing areas on startup
        AddNpcsToArea(area_id)
    end
end

--Interface
--all of these must be used by entry script for this to function.
function eznpcs.load_npcs()
    return ( LoadNpcs() )
end
function eznpcs.add_event(event_object)
    return ( AddEvent(event_object) )
end
function eznpcs.create_npc_from_object(area_id,object_id)
    return ( CreateBotFromObject(area_id,object_id) )
end
function eznpcs.handle_actor_interaction(player_id,actor_id)
    return ( OnActorInteraction(player_id,actor_id) )
end
function eznpcs.on_tick(delta_time)
    for bot_id, npc in pairs(npcs) do
        if npc.on_tick then
            npc.on_tick.action(npc,delta_time)
        end
    end
end
function eznpcs.create_npc(area_id,asset_name,x,y,z,direction,bot_name,animation_name,mug_animation_name)
    return ( CreateNPC(area_id,asset_name,x,y,z,direction,bot_name,animation_name,mug_animation_name) )
end

function eznpcs.handle_player_transfer(player_id)
    return ( OnPlayerTransfer(player_id))
end
  
function eznpcs.handle_player_disconnect(player_id)
    return ( OnPlayerDisconnect(player_id))
end

function eznpcs.handle_textbox_response(player_id, response)
    return ( OnTextboxResponse(player_id, response))
end

function eznpcs.handle_object_interaction(player_id, object_id)
    return ( OnObjectInteract(player_id, object_id))
end

return eznpcs
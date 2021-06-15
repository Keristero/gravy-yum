local eznpcs = {}

npc_asset_folder = '/server/assets/shared/ez_npc'
generic_npc_animation_path = npc_asset_folder..'/sheet/npc.animation'
lastBotId = 0
npcs = {}
npc_required_properties = {"Direction","Asset Name"}

--NPC custom object information
--Type [string] must be 
--Chat [string] NPC will respond with this string when you interact with them
--Direction [string] Initial direction this NPC will face
--Next Waypoint [object] NPC will path to this object
--  Wait Time [int] NPC will wait for this period in seconds when it reaches the waypoint

function CreateBotFromObject(area_id,object_id)
    local placeholder_object = Net.get_object_by_id(area_id, object_id)
    local x = placeholder_object.x+1
    local y = placeholder_object.y+1
    local z = placeholder_object.z

    for i, prop_name in pairs(npc_required_properties) do
        if not placeholder_object.custom_properties[prop_name] then
            print('[eznpcs] NPC objects require the custom property '..prop_name)
            return false
        end
    end  

    local npc_asset_name = placeholder_object.custom_properties["Asset Name"]
    local direction = placeholder_object.custom_properties.Direction

    local npc = CreateNPC(area_id,npc_asset_name,x,y,z,direction)

    if placeholder_object.custom_properties["Chat"] then
        --If the placeholder has Chat text, add behaviour to have it respond to interactions
        local chat_behaviour = ChatBehaviour(placeholder_object.custom_properties["Chat"])
        AddBehaviour(npc,chat_behaviour)
    end

    if placeholder_object.custom_properties["Next Waypoint"] then
        --If the placeholder has npc_first_waypoint
        local waypoint_follow_behaviour = WaypointFollowBehaviour(placeholder_object.custom_properties["Next Waypoint"])
        AddBehaviour(npc,waypoint_follow_behaviour)
    end
end

function CreateNPC(area_id,asset_name,x,y,z,direction,is_solid,bot_name)
    lastBotId = lastBotId + 1
    local texture_path = npc_asset_folder.."/sheet/"..asset_name..".png"
    local animation_path = npc_animation_file or generic_npc_animation_path
    print('texture path: '..texture_path)
    print('animation path: '..animation_path)
    name = bot_name or nil
    solid = is_solid or true
    npc_data = {
        asset_name=asset_name,
        bot_id=lastBotId, 
        name=name, 
        area_id=area_id, 
        texture_path=texture_path, 
        animation_path=animation_path, 
        x=x, 
        y=y, 
        z=z, 
        direction=direction, 
        solid=solid, 
        size=0.35,
        speed=0.5
    }
    Net.create_bot(lastBotId, npc_data)
    npcs[lastBotId] = npc_data
    print('[eznpcs] created npc '..lastBotId..' at ('..x..','..y..','..z..')')
    return npcs[lastBotId]
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
function ChatBehaviour(chat_text)
    behaviour = {
        type='on_interact',
        action=function(npc,player_id)
            npc.is_interacting = true
            local mug_texture_path = npc_asset_folder.."/mug/"..npc.asset_name..".png"
            --TODO, add mugshot animation where it exists
            Net.message_player(player_id, chat_text, mug_texture_path)
            npc.is_interacting = false
        end
    }
    return behaviour
end

function WaypointFollowBehaviour(first_waypoint_id)
    behaviour = {
        type='on_tick',
        initialize=function(npc)
            local first_waypoint = Net.get_object_by_id(npc.area_id, first_waypoint_id)
            if first_waypoint then
                npc.next_waypoint = first_waypoint
            else
                print('[eznpcs] invalid first_waypoint_id '..first_waypoint_id)
            end
        end,
        action=function(npc,delta_time)
            MoveNPC(npc,delta_time)
        end
    }
    return behaviour
end

function OnActorInteraction(player_id,actor_id)
    print('interacting with actor'..actor_id)
    local npc_id = tonumber(actor_id)
    if npcs[npc_id] then
        print('interacting with npc!')
        local npc = npcs[npc_id]
        if npc.on_interact then
            npc.on_interact.action(npc,player_id)
        end
    end
end

function OnTick(delta_time)
    for bot_id, npc in pairs(npcs) do
        if npc.on_tick then
            npc.on_tick.action(npc,delta_time)
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

function MoveNPC(npc,delta_time)
    if npc.is_interacting == true then
        return
    end
    if npc.wait_time and npc.wait_time > 0 then
        npc.wait_time = npc.wait_time - delta_time
    end

    local area_id = Net.get_bot_area(npc.bot_id)
    local waypoint = npc.next_waypoint
    
    local angle = math.atan(waypoint.y - npc.y, waypoint.x - npc.x)
    local vel_x = math.cos(angle) * npc.speed
    local vel_y = math.sin(angle) * npc.speed

    local new_pos = {x,y,z=npc.z,size=npc.size}

    new_pos.x = npc.x + vel_x * delta_time
    new_pos.y = npc.y + vel_y * delta_time

    if not position_overlaps_something(new_pos,area_id) then
        Net.move_bot(npc.bot_id, new_pos.x, new_pos.y, new_pos.z)
        npc.x = new_pos.x
        npc.y = new_pos.y
    end

    local distance = math.sqrt((waypoint.x - npc.x) ^ 2 + (waypoint.y - npc.y) ^ 2)
    if distance < npc.size then
        NPCReachedWaypoint(npc,waypoint)
    end
end

function NPCReachedWaypoint(npc,waypoint)
    if waypoint.custom_properties['Wait Time'] ~= nil then
        npc.wait_time = tonumber(waypoint.custom_properties['Wait Time'])
    end
    local next_waypoint = Net.get_object_by_id(npc.area_id,waypoint.custom_properties["Next Waypoint"])
    if next_waypoint then
        npc.next_waypoint = next_waypoint
    end
end

--Interface
--all of these must be used by entry script for this to function.
function eznpcs.create_npc_from_object(area_id,object_id)
    return ( CreateBotFromObject(area_id,object_id) )
end
function eznpcs.on_actor_interaction(player_id,actor_id)
    return ( OnActorInteraction(player_id,actor_id) )
end
function eznpcs.on_tick(delta_time)
    return ( OnTick(delta_time) )
end
function eznpcs.create_npc(area_id,asset_name,x,y,z,direction,is_solid,bot_name)
    return ( CreateNPC(area_id,asset_name,x,y,z,direction,is_solid,bot_name) )
end

return eznpcs
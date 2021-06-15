local eznpcs = require('scripts/libs/eznpcs')

function add_npcs_to_area(area_id)
    local objects = Net.list_objects(area_id)
    for i, object_id in next, objects do
        local object = Net.get_object_by_id(area_id, object_id)
        if object.type == "NPC" then
            eznpcs.create_npc_from_object(area_id, object_id)
        end
    end
end

--Process each area on startup
local areas = Net.list_areas()
for i, area_id in next, areas do
    --Add npcs to existing areas on startup
    add_npcs_to_area(area_id)
end

function handle_actor_interaction(player_id, actor_id)
    --handle interactions with NPCs
    eznpcs.on_actor_interaction(player_id,actor_id)
end

function tick(delta_time)
    --handle on tick behaviours for NPCs
    eznpcs.on_tick(delta_time)
end
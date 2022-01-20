local ezmemory = require('scripts/ezlibs-scripts/ezmemory')

local sfx = {
    item_get='/server/assets/ezlibs-assets/sfx/item_get.ogg'
}

local give_result_awards = function (player_id,encounter_info,stats)
    -- stats = { health: number, score: number, time: number, ran: bool, emotion: number, turns: number, npcs: { id: String, health: number }[] }
    if stats.ran then
        return -- no rewards for wimps
    end
    local reward_monies = (stats.score*50)
    ezmemory.spend_player_money(player_id,-reward_monies) -- spending money backwards gives money
    Net.message_player(player_id,"Got $"..reward_monies.."!")
    Net.play_sound_for_player(player_id,sfx.item_get)
end

local encounter1 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters_bundle.zip",
    weight=10,
    enemies = {
        {name="Mettaur",rank=1},
        {name="Champy",rank=1},
        {name="Chimpy",rank=1},
    },
    positions = {
        {0,0,0,1,0,1},
        {0,0,0,0,1,0},
        {0,0,0,1,0,1}
    },
    obstacles = {
        {name="RockCube"}
    },
    obstacle_positions = {
        {0,0,0,0,1,0},
        {0,0,0,1,0,0},
        {0,0,0,0,0,0}
    },
    player_positions = {
        {0,0,1,0,0,0},
        {0,0,0,0,0,0},
        {0,0,2,0,0,0}
    },
    freedom_mission={
        turn_count=5,
        player_can_flip=true
    },
    background = {
        texture = "bn6_green_area",
        x_velocity= 0,
        y_velocity= 1
    },
    music = "surge_of_power",
    results_callback = give_result_awards
}

return {
    minimum_steps_before_encounter=100,
    encounter_chance_per_step=0.01,
    encounters={encounter1}
}
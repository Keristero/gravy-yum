local shared_rewards_table = {
    {
        min={
            rank=1,
            hp=0.0,
            
        },
        max={
            rank=11,
            hp=1.0,

        }
    }
}

local encounter1 = {
    path="/server/assets/packages/ezencounters_bundle.zip",
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
    rewards = shared_rewards_table
}

local encounter2 = {
    path="/server/assets/packages/ezencounters_bundle.zip",
    weight=50,
    enemies = {
        {name="Mettaur",rank=1},
    },
    positions = {
        {1,1,1,1,1,1},
        {1,0,1,1,1,1},
        {1,1,1,1,1,1}
    },
    rewards = shared_rewards_table
}

return {
    minimum_steps_before_encounter=30,
    encounter_chance_per_step=0.1,
    encounters={encounter1,encounter2}
}
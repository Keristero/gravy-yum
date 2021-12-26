
local encounter1 = {
    path="/server/assets/packages/ezencounters_bundle.zip",
    weight=10,
    enemies = {
        {name="Mettaur",rank=1, nickname="GravyMonster"},
        {name="Champy",rank=1},
        {name="Chimpy",rank=1},
    },
    positions = {
        {0,0,0,1,0,1},
        {0,0,0,0,1,0},
        {0,0,0,1,0,1}
    },
    tiles = {
        {1,1,1,1,1,1},
        {1,1,1,1,1,1},
        {1,1,1,1,1,1}
    }
}

return {
    minimum_steps_before_encounter=50,
    encounter_chance_per_step=0.01,
    encounters={encounter1}
}
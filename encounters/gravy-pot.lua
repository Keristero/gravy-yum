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
    if reward_monies > 0 then
        Net.message_player(player_id,"Got $"..reward_monies.."!")
        Net.play_sound_for_player(player_id,sfx.item_get)
    end
end

local give_result_awards_rare = function (player_id,encounter_info,stats)
    -- stats = { health: number, score: number, time: number, ran: bool, emotion: number, turns: number, npcs: { id: String, health: number }[] }
    if stats.ran then
        return -- no rewards for wimps
    end
    local reward_monies = (stats.score*200)
    ezmemory.spend_player_money(player_id,-reward_monies) -- spending money backwards gives money
    if reward_monies > 0 then
        Net.message_player(player_id,"Got $"..reward_monies.."!")
        Net.play_sound_for_player(player_id,sfx.item_get)
    end
end

local encounter1 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=10,
    enemies = {
        {name="Chimpy",rank=1},
        {name="Cactroll",rank=1},
    },
    positions = {
        {0,0,0,1,0,0},
        {0,0,0,0,2,0},
        {0,0,0,0,0,1}
    },
    tiles = {
        {1,9,1,1,9,1},
        {9,9,9,9,9,9},
        {1,9,1,1,9,1}
    },
    results_callback = give_result_awards
}

local encounter2 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=10,
    enemies = {
        {name="Powie2",rank=1},
        {name="Spikey",rank=2},
    },
    positions = {
        {0,0,0,1,0,0},
        {0,0,0,0,0,2},
        {0,0,0,1,0,0}
    },
    results_callback = give_result_awards
}

local encounter3 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=10,
    enemies = {
        {name="Spikey",rank=2}
    },
    positions = {
        {0,0,0,0,1,0},
        {0,0,0,0,0,1},
        {0,0,0,0,1,0}
    },
    obstacles = {
        {name="Rock"}
    },
    obstacle_positions = {
        {0,0,0,0,0,0},
        {0,0,0,1,0,0},
        {0,0,0,0,0,0}
    },
    tiles = {
        {13,1,1,1,1,13},
        {13,1,1,1,1,13},
        {13,1,1,1,1,13}
    },
    results_callback = give_result_awards
}
local encounter4 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=10,
    enemies = {
        {name="Powie2",rank=1},
        {name="Canodumb",rank=3}
    },
    positions = {
        {0,0,0,0,1,0},
        {0,0,0,0,0,0},
        {0,0,0,2,0,1}
    },
    results_callback = give_result_awards
}

local encounter5 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=10,
    enemies = {
        {name="Cactroll",rank=1},
        {name="Cacter",rank=1}
    },
    positions = {
        {0,0,0,1,0,0},
        {0,0,0,0,2,0},
        {0,0,0,0,0,1}
    },
    tiles = {
        {9,9,9,9,9,9},
        {9,9,9,9,9,9},
        {9,9,9,9,9,9}
    },
    results_callback = give_result_awards
}

local encounter6 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=10,
    enemies = {
        {name="Mettaur",rank=1},
        {name="Gunner",rank=1}
    },
    positions = {
        {0,0,0,1,0,2},
        {0,0,0,0,0,2},
        {0,0,0,0,1,2}
    },
    results_callback = give_result_awards
}

local rare_encounter_1 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=1,
    enemies = {
        {name="Cacter",rank=1},
    },
    positions = {
        {0,0,0,0,0,1},
        {0,0,0,0,0,1},
        {0,0,0,0,0,1}
    },
    tiles = {
        {1,12,12,12,12,1},
        {1,12,12,12,12,1},
        {1,12,12,12,12,1}
    },
    music = {
        path='bn5_boss.mid'
    },
    results_callback = give_result_awards_rare
}

local rare_encounter_2 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=1,
    enemies = {
        {name="Canosmart",rank=1},
    },
    positions = {
        {0,0,0,0,1,0},
        {0,0,0,0,0,1},
        {0,0,0,0,1,0}
    },
    tiles = {
        {1,1,14,14,1,1},
        {1,1,14,14,1,1},
        {1,1,14,14,1,1}
    },
    music = {
        path='bn5_boss.mid'
    },
    results_callback = give_result_awards_rare
}

local rare_encounter_3 = {
    path="/server/assets/ezlibs-assets/ezencounters/ezencounters.zip",
    weight=1,
    enemies = {
        {name="RareChampy",rank=1},
    },
    positions = {
        {0,0,0,0,0,0},
        {0,0,0,0,0,1},
        {0,0,0,0,0,0}
    },
    tiles = {
        {10,10,10,10,10,10},
        {10,1,1,10,10,1},
        {10,10,10,10,10,10}
    },
    music = {
        path='bn5_boss.mid'
    },
    results_callback = give_result_awards_rare
}

return {
    minimum_steps_before_encounter=80,
    encounter_chance_per_step=0.05,
    encounters={encounter1,encounter2,encounter3,encounter4,encounter5,encounter6,rare_encounter_1,rare_encounter_2,rare_encounter_3}
}
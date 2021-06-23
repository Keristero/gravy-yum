local tiles_to_spin = {}
local delay_till_change = 0

function StartSpinningTiles(area_id)
    --Loop over all objects in area, spawning NPCs for each NPC type object.
    local objects = Net.list_objects(area_id)
    for i, object_id in next, objects do
        local object = Net.get_object_by_id(area_id, object_id)
        if object.type == "Spinning Conveyor" then
            local spin = {
                area_id=area_id,
                x=math.floor(object.x),
                y=math.floor(object.y),
                z=math.floor(object.z)
            }
            tiles_to_spin[#tiles_to_spin+1] = spin
        end
    end
    print('[spin] added '..#tiles_to_spin..' spin tiles')
end

function LoadSpinTiles()
    --for each area, load NPCS
    local areas = Net.list_areas()
    for i, area_id in next, areas do
        --Add npcs to existing areas on startup
        StartSpinningTiles(area_id)
    end
end

function SpinTiles()
    for k, location in pairs(tiles_to_spin) do
        local randomint = math.random(0, 1)
        local randomint2 = math.random(0, 1)
        local flip_h = false
        local gid = 64
        if randomint > 0.5 then
            flip_h = true
        end
        if randomint2 > 0.5 then
            gid = 63
        end
        Net.set_tile(location.area_id, location.x, location.y, location.z, gid, flip_h)
    end
end

function tick(delta_time)
    if delay_till_change > 0 then
        delay_till_change = delay_till_change - delta_time
    else
        SpinTiles()
        delay_till_change = 3
    end
end

LoadSpinTiles()
print('[spin] loaded')
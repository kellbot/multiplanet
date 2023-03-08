-- Adapted from https://github.com/Oarcinae/FactorioScenarioMultiplayerSpawn

-- This is the radius, in chunks, that a spawn area is from any other generated
-- chunks. It ensures the spawn area isn't too near generated/explored/existing
-- area. The larger you make this, the further away players will spawn from
-- generated map area (even if it is not visible on the map!).
CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS = 10
CHUNK_SIZE = 32

function createSpawns(surface, count, spacing)

    local points = {}

    -- Get an ODD number from the square of the input count.
    -- Always rounding up so we don't end up with less points that requested.
    local sqrt_count = math.ceil(math.sqrt(count))
    if (sqrt_count % 2 == 0) then
        sqrt_count = sqrt_count + 1
    end

    -- Need to know how much to offset the grid.
    local sqrt_half = math.floor((sqrt_count-1)/2)

    if (sqrt_count < 1) then
        log("createSpawns less than 1!!")
        return
    end

    if (global.spawns[surface.name] == nil) then
        global.spawns[surface.name] = {}
    end

    -- This should give me points centered around 0,0 I think.
    for i=-sqrt_half,sqrt_half,1 do
        for j=-sqrt_half,sqrt_half,1 do
            if (i~=0 or j~=0) then -- EXCEPT don't put 0,0

                local x_pos = (i*spacing)
                x_pos = x_pos - (x_pos % CHUNK_SIZE) + (CHUNK_SIZE/2)
                local y_pos = (j*spacing)
                y_pos = y_pos - (y_pos % CHUNK_SIZE) + (CHUNK_SIZE/2)

                table.insert(points, {x=x_pos,y=y_pos})
                table.insert(global.spawns[surface.name], {x=x_pos,y=y_pos})
            end
        end
    end

    -- Do something with the return value.
    return points
end

function findSpawn(surface, target_distance)
    local best_key = nil
    local best_distance = nil

    for k,v in pairs(global.spawns[surface.name]) do

        -- Check if chunks nearby are not generated.
        local chunk_pos = GetChunkPosFromTilePos(v)
        if IsChunkAreaUngenerated(chunk_pos, CHECK_SPAWN_UNGENERATED_CHUNKS_RADIUS, surface) then

            -- Is this our first valid find?
            if ((best_key == nil) or (best_distance == nil)) then
                best_key = k
                best_distance = math.abs(math.sqrt((v.x^2) + (v.y^2)) - target_distance)

            -- Check if it is closer to target_distance than previous option.
            else
                local new_distance = math.abs(math.sqrt((v.x^2) + (v.y^2)) - target_distance)
                if (new_distance < best_distance) then
                    best_key = k
                    best_distance = new_distance
                end
            end

        -- If it's not a valid spawn anymore, let's remove it.
        else
            log("Removing vanilla spawn due to chunks generated: x=" .. v.x .. ",y=" .. v.y)
            table.remove(global.spawns[surface.name], k)
        end
    end

    local spawn_pos = {x=0,y=0}
    if ((best_key ~= nil) and (global.spawns[surface.name][best_key] ~= nil)) then
        spawn_pos.x = global.spawns[surface.name][best_key].x
        spawn_pos.y = global.spawns[surface.name][best_key].y
        table.remove(global.spawns[surface.name], best_key)
    end
    log("Found unused vanilla spawn: x=" .. spawn_pos.x .. ",y=" .. spawn_pos.y)
    return spawn_pos
end

function GetChunkPosFromTilePos(tile_pos)
    return {x=math.floor(tile_pos.x/32), y=math.floor(tile_pos.y/32)}
end

-- Check for ungenerated chunks around a specific chunk
-- +/- chunkDist in x and y directions
function IsChunkAreaUngenerated(chunkPos, chunkDist, surface)
    for x=-chunkDist, chunkDist do
        for y=-chunkDist, chunkDist do
            local checkPos = {x=chunkPos.x+x,
                             y=chunkPos.y+y}
            if (surface.is_chunk_generated(checkPos)) then
                return false
            end
        end
    end
    return true
end

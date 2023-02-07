function lerp(a, b, t)
	return a + (b - a) * t
end

-- convert miliseconds to seconds
function msToSec(ms)
    return ms / 1000
end

--https://osu.ppy.sh/wiki/en/Client/File_formats/Osu_%28file_format%29
function getHitObject(osuFilePath)
    local object = {}
    local foundHitObjects = true
    local file = io.open(osuFilePath, "r")
    for line in file:lines() do
        -- after [HitObjects] section
        if line == "[HitObjects]" then
            foundHitObjects = true
        end
        if foundHitObjects then
            -- skip empty lines
            if line ~= "" then
                -- skip comments
                if string.sub(line, 1, 2) ~= "//" then
                    -- skip [HitObjects] section
                    if line ~= "[HitObjects]" then
                        -- split line into table
                        local lineTable = split(line, ",")
                        -- add to object table
                        table.insert(object, lineTable)
                    end
                end
            end
        end
    end
    file:close()
    object.x = object.lineTable[1]
    object.y = object.lineTable[2]
    object.time = object.lineTable[3]
    object.type = object.lineTable[4]
    object.hitSound = object.lineTable[5]
    if object.type == 1 then --slider
        object.isSlider = true
        object.objectParams = object.lineTable[6]
        object.repeatCount = object.lineTable[7]
        object.length = object.lineTable[8]
        object.edgeSounds = object.lineTable[9]
        object.edgeSets = object.lineTable[10]
    end

    if object.type == 1 then
        local data = split(object.objectParams, "|") 
    end
end

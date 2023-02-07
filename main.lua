require("helper")

local maps = {}
local songSelectRows = {    
}
local selectedSongIndex = 1
local background = love.graphics.newImage("images/placeholder.jpg")
local fontAllerRg16 = love.graphics.newFont("fonts/Aller/Aller_Rg.ttf", 16)
local fontAllerLt16 = love.graphics.newFont("fonts/Aller/Aller_Lt.ttf", 16)
local curSongSource = nil
local logo = love.graphics.newImage("images/logo.png")


local function GetMetaData(filePath) 
    local file = io.open(filePath, "r")
    local metaData = {}
    -- get title from file matching Title: pattern
    for line in file:lines() do
        if line:match("Title:") then
            metaData.title = line:match("Title:(.*)")
        end
        if line:match("Artist:") then
            metaData.artist = line:match("Artist:(.*)")
        end
        if line:match("Creator:") then
            metaData.creator = line:match("Creator:(.*)")
        end
        if line:match("Version:") then
            metaData.difficulty = line:match("Version:(.*)")
            print(metaData.difficulty)
        end
        if line:match("PreviewTime:") then
            metaData.previewTime = tonumber(line:match("PreviewTime:(.*)"))
        end
        
        
        if line:match("AudioFilename") then
            -- trim 
            metaData.audioFilename = line:match("AudioFilename:(.*)"):gsub("^%s*(.-)%s*$", "%1") 
        end
        -- if after line containing "[Events]", there is a line containing a word ending with .jpg or .png or .jpeg, then that is the background image
        if line:match("%[Events%]") then
            for line in file:lines() do
                if line:match(".*%.jpg") or line:match(".*%.png") or line:match(".*%.jpeg") then
                    --metaData.background = line:match(".*%.jpg") or line:match(".*%.png") or line:match(".*%.jpeg")
                    --use (%b\"\")
                    metaData.background = line:match("%b\"\""):sub(2, -2)
                    break
                end
            end
        end
    end
    return metaData
end



local function getAvaiableMapFolders()
    -- Get all folders in the maps folder
    local folders = love.filesystem.getDirectoryItems("maps")
    -- Create a table to store the folders that contain a .osu file
    local mapFolders = {}
    -- Loop through all folders
    for i, folder in ipairs(folders) do
        -- Get all files in the folder
        local files = love.filesystem.getDirectoryItems("maps/" .. folder)
        -- Loop through all files
        for i, file in ipairs(files) do
            -- Check if the file is a .osu file
            if string.sub(file, -4) == ".osu" then
                -- Add the folder to the mapFolders table
                --print("Found map folder: " .. folder)
                table.insert(mapFolders, folder)
                -- Break the loop
                break
            end
        end
    end
    -- Return the mapFolders table
    return mapFolders
end

function playSongFromPos()
    curSongSource = love.audio.newSource("maps/" .. songSelectRows[selectedSongIndex].mapFolder .. "/" ..songSelectRows[selectedSongIndex].metaData.audioFilename, "stream")
    love.audio.stop()
    love.audio.play(curSongSource)
    
    if songSelectRows[selectedSongIndex].metaData.previewTime == nil or songSelectRows[selectedSongIndex].metaData.previewTime < 0 then
        curSongSource:seek(0)
        --print("seeking to " .. songSelectRows[selectedSongIndex].metaData.previewTime)
    else 
        print("seeking to " .. songSelectRows[selectedSongIndex].metaData.previewTime)
        curSongSource:seek(msToSec(songSelectRows[selectedSongIndex].metaData.previewTime))
    end
end

function love.load()
    local limits = love.graphics.getSystemLimits()
    print("Max texture size: " .. limits.texturesize)

    local nthMap = 0
    local mapFolders = getAvaiableMapFolders()
    for i, folder in ipairs(mapFolders) do
        local files = love.filesystem.getDirectoryItems("maps/" .. folder)
        for i, file in ipairs(files) do
            if string.sub(file, -4) == ".osu" then
                print("Found map: " .. folder .. "/" .. file)
                table.insert(maps, file)
                table.insert(songSelectRows, {
                    mapFolder = folder, 
                    mapFile = file, 
                    y = nthMap * 100,
                    metaData = GetMetaData("maps/" .. folder .. "/" .. file)
                })
                nthMap = nthMap + 1
            end
        end
    end
    
    background = love.graphics.newImage("maps/" .. songSelectRows[selectedSongIndex].mapFolder .. "/" .. songSelectRows[selectedSongIndex].metaData.background)
    playSongFromPos()
end

function love.update(dt)
    updateSongSelect(dt)
    --mainData = love.filesystem.load("main.lua")()
end

function love.draw()
    if background then
        --print("maps/" .. songSelectRows[selectedSongIndex].mapFolder .. "/" .. songSelectRows[selectedSongIndex].metaData.background)
        love.graphics.setColor(1, 1, 1)
        -- draw image with width and height of the screen
        love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight())
        --love.graphics.draw(background, love.graphics.newQuad(0, 0, 1920, 1080, background:getDimensions()))
    end
    DrawSongSelect()
    -- draw bezier curve using drawCurve
    --love.graphics.setLineWidth(100)
    --love.graphics.line(love.math.newBezierCurve({25,25, 100,100, 200,400, 800,300, 800, 100}):render())
    -- draw a circle at the right bottom corner of the screen with %80 of its visible
   --love.graphics.setColor(255 / 255, 255 / 255, 255 / 255, 255 / 255)
    -- draw logo.png to bottom right corner
    --love.graphics.draw(logo, love.graphics.newQuad(love.graphics.getWidth() - 100, love.graphics.getHeight() - logo:getHeight(), logo:getWidth(), logo:getHeight(), logo:getDimensions()))


end

function love.wheelmoved(x, y)
    if y > 0 then
        if songSelectRows[1].y < 10 then
            for i, row in ipairs(songSelectRows) do
                row.y = lerp(row.y, row.y + (10 * y), 0.9)
            end
        end
    elseif y < 0 then
        if songSelectRows[#songSelectRows].y > love.graphics.getHeight() - 100 then
            for i, row in ipairs(songSelectRows) do
                row.y = lerp(row.y, row.y + (10 * y), 0.9)
            end
        end
    end
end

function updateSongSelect(dt)
    -- scroll throught the song select rows and 
    -- check if the user has clicked on one of them
    for k, v in ipairs(songSelectRows) do
        if love.mouse.isDown(1) then
            local x, y = love.mouse.getPosition()
            if y > v.y and y < v.y + 100  and x > love.graphics.getWidth() - 600 then
                print("Clicked on row: " .. k)
                local oldSelectedSong = songSelectRows[selectedSongIndex]
                selectedSongIndex = k
                if songSelectRows[selectedSongIndex].metaData.background then
                    background = love.graphics.newImage("maps/" .. songSelectRows[selectedSongIndex].mapFolder .. "/" .. songSelectRows[selectedSongIndex].metaData.background)
                else 
                    background = love.graphics.newImage("images/placeholder.jpg")
                end
                if oldSelectedSong.metaData.audioFilename ~= songSelectRows[selectedSongIndex].metaData.audioFilename then
                    playSongFromPos()
                end
            end
        end
    end
end

-- input keyboard
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    -- use up and down arrow to scroll through the song select rows
    
    --if key == "up" then
    --    if songSelectRows[1].y < 10 then
    --        for i, row in ipairs(songSelectRows) do
    --            row.y = lerp(row.y, row.y + 10, 0.9)
    --        end
    --    end
    --elseif key == "down" then
    --    if songSelectRows[#songSelectRows].y > love.graphics.getHeight() - 100 then
    --        for i, row in ipairs(songSelectRows) do
    --           row.y = lerp(row.y, row.y - 10, 0.9)
    --        end
    --    end
    --end
    if key == "up" then
        local oldSelectedSong = songSelectRows[selectedSongIndex]
        selectedSongIndex = selectedSongIndex - 1
        if selectedSongIndex < 1 then
            selectedSongIndex = 1
        end
        if songSelectRows[selectedSongIndex].metaData.background then
            background = love.graphics.newImage("maps/" .. songSelectRows[selectedSongIndex].mapFolder .. "/" .. songSelectRows[selectedSongIndex].metaData.background)
        else 
            background = love.graphics.newImage("images/placeholder.jpg")
        end
        if oldSelectedSong.metaData.audioFilename ~= songSelectRows[selectedSongIndex].metaData.audioFilename then
            playSongFromPos()
        end
    elseif key == "down" then
        local oldSelectedSong = songSelectRows[selectedSongIndex]
        selectedSongIndex = selectedSongIndex + 1
        if selectedSongIndex > #songSelectRows then
            selectedSongIndex = #songSelectRows
        end
        if songSelectRows[selectedSongIndex].metaData.background then
            background = love.graphics.newImage("maps/" .. songSelectRows[selectedSongIndex].mapFolder .. "/" .. songSelectRows[selectedSongIndex].metaData.background)
        else 
            background = love.graphics.newImage("images/placeholder.jpg")
        end
        if oldSelectedSong.metaData.audioFilename ~= songSelectRows[selectedSongIndex].metaData.audioFilename then
            playSongFromPos()
        end
    end

    --if key == "return" then
        -- load the map
    --    loadMap("maps/" .. songSelectRows[selectedSongIndex].mapFolder .. "/" .. songSelectRows[selectedSongIndex].mapFile)
    --end

    -- if selected row is out of screen, scroll to that direction
    if songSelectRows[selectedSongIndex].y < 10 then
        for i, row in ipairs(songSelectRows) do
            row.y = lerp(row.y, row.y + 110, 1)
        end
    elseif songSelectRows[selectedSongIndex].y > love.graphics.getHeight() - 100 then
        for i, row in ipairs(songSelectRows) do
            row.y = lerp(row.y, row.y - 110, 1)
        end
    end

    
end

function DrawSongSelect()
    love.graphics.setFont(fontAllerLt16)
    --draw song information
    love.graphics.setColor(10/255, 5/255,  115/255, 200/255)
    love.graphics.rectangle("fill", 5, 5, love.graphics.getWidth() / 2.3, love.graphics.getHeight() / 1.3)
    -- draw background image inside of this box filling 1 / 4 of the box
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background, 15, 15, 0, love.graphics.getWidth() / 2.4 / background:getWidth(), love.graphics.getHeight() / 3 / background:getHeight())
    -- draw song title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Title: "..songSelectRows[selectedSongIndex].metaData.title, 15, love.graphics.getHeight() / 3 + 20)
    -- draw song artist
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Artist: "..songSelectRows[selectedSongIndex].metaData.artist, 15, love.graphics.getHeight() / 3 + 40)
    -- draw song creator
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Creator: "..songSelectRows[selectedSongIndex].metaData.creator, 15, love.graphics.getHeight() / 3 + 60)
    -- draw song difficulty
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Difficulty: "..songSelectRows[selectedSongIndex].metaData.difficulty, 15, love.graphics.getHeight() / 3 + 80)
    -- draw song bpm
    love.graphics.setColor(1, 1, 1)
    --love.graphics.print(songSelectRows[selectedSongIndex].metaData.bpm, 15, love.graphics.getHeight() / 3 + 95)
    if songSelectRows[selectedSongIndex].metaData.previewTime then
        love.graphics.print("Preview Time: "..songSelectRows[selectedSongIndex].metaData.previewTime, 15, love.graphics.getHeight() / 3 + 100)
    end
    
    -- draw a rectangle at bottom
    love.graphics.setColor(10/255, 5/255,  115/255, 200/255)
    love.graphics.rectangle("fill", 5, love.graphics.getHeight() - 100, love.graphics.getWidth() / 2.3, 95)
    -- draw 3 buttons inside this rectangle
    drawButton(10, love.graphics.getHeight() - 100, (love.graphics.getWidth() / 2.3) / 4 - 2, 95, "Sort by Title", function ()  
        -- sort by title
        table.sort(songSelectRows, function (a, b) return a.metaData.title < b.metaData.title end)
    end)
    drawButton(10 + (love.graphics.getWidth() / 2.3) / 4, love.graphics.getHeight() - 100, (love.graphics.getWidth() / 2.3) / 4 - 2, 95, "Sort by Artist", function ()  
        -- sort by artist
        table.sort(songSelectRows, function (a, b) return a.metaData.artist < b.metaData.artist end)
    end)
    drawButton(10 + (love.graphics.getWidth() / 2.3) / 4 * 2, love.graphics.getHeight() - 100, (love.graphics.getWidth() / 2.3) / 4 - 2, 95, "Sort by Difficulty", function ()  
        -- sort by difficulty
        --table.sort(songSelectRows, function (a, b) return a.metaData.difficulty < b.metaData.difficulty end)
    end)
    drawButton(10 + (love.graphics.getWidth() / 2.3) / 4 * 3, love.graphics.getHeight() - 100, (love.graphics.getWidth() / 2.3) / 4 - 2, 95, "Sort by BPM", function ()  
        -- sort by bpm
        --table.sort(songSelectRows, function (a, b) return a.metaData.bpm < b.metaData.bpm end)
    end)
    
    
    for k, v in ipairs(songSelectRows) do
        -- set color to dark blue
        love.graphics.setColor(33/255, 18/255,  115/255, 200/255)
        if k == selectedSongIndex then
            -- set color to light blue
            love.graphics.setColor(33/255, 18/255,  115/255, 255/255)
            love.graphics.rectangle("fill", love.graphics.getWidth() - 600 , v.y, 600, 90, 5, 5)
            -- black
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineStyle("rough")
            love.graphics.setLineWidth(4)
            love.graphics.rectangle("line", love.graphics.getWidth() - 600 , v.y, 600, 90, 5, 5)
        else 

            love.graphics.rectangle("fill", love.graphics.getWidth() - 600 + 50, v.y, 600, 90, 5, 5)
        end
        
        -- draw song names into the rectangle from maps
        --set color to black
        -- set font
        love.graphics.setFont(fontAllerRg16)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(v.metaData.artist.." - "..v.metaData.title.." ["..v.metaData.difficulty.."]", 
        love.graphics.getWidth() - 480, v.y + 20, 600, "left")
        love.graphics.printf("Creator: ".. v.metaData.creator, love.graphics.getWidth() - 480, v.y + 40, 600, "left")
    end
end

function drawButton(_x, _y, _width, _height, _text, onClick)
    local x, y = love.mouse.getPosition()
    local isHovered = x > _x and x < _x + _width and y > _y and y < _y + _height
    local isClicked = isHovered and love.mouse.isDown(1)
    if isClicked then
        onClick()
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", _x, _y, _width, _height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", _x, _y, _width, _height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(_text, _x, _y + _height / 2 - 10, _width, "center")
end
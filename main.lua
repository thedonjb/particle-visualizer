-- main.lua
local devices = {}
local selected = nil
local device = nil
local samples = {}
local sampleCount = 256

local bloomIntensity = 0
local t = 0
local volume = 0

local rotX, rotY, rotZ = 0, 0, 0

local cam = { x = 0, y = 0, z = -700 }
local focalLength = 800

local MIN_CAM_Z = -2000
local MAX_CAM_Z = -200
local ZOOM_STEP = 50

local isDragging = false
local lastMouseX, lastMouseY = 0, 0

local emitters = {
    { color = { 0.9, 0.3, 0.3 } },
    { color = { 0.3, 0.9, 0.4 } },
    { color = { 0.3, 0.4, 0.9 } }
}

local MAX_VOLUME = 0.5

local hoveredIndex = nil
local deviceYStart = 60
local deviceSpacing = 20

-- ===============================
-- Load visualizer modules dynamically
-- ===============================
local visualizers = {}

do
    local ok, module = pcall(require, "modules.burst3d")
    if ok and type(module) == "table"
        and module.update and module.draw and module.reset then
        table.insert(visualizers, module)
        print("Loaded visualizer first: burst3d")
    else
        print("Failed to load burst3d as first visualizer")
    end
end

do
    local files = love.filesystem.getDirectoryItems("modules")
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local name = file:gsub("%.lua$", "")
            if name ~= "burst3d" then
                local ok, module = pcall(require, "modules." .. name)
                if ok and type(module) == "table"
                    and module.update and module.draw and module.reset then
                    table.insert(visualizers, module)
                    print("Loaded visualizer:", name)
                else
                    print("Skipping invalid visualizer:", name)
                end
            end
        end
    end
end

local currentVisualizerIndex = 1
local visualizer = visualizers[currentVisualizerIndex]

-- ===============================
-- LOVE callbacks
-- ===============================
function love.load()
    love.window.setTitle("Audio Particle Visualizer")
    love.window.setMode(1400, 900, { resizable = true, vsync = false })
    devices = love.audio.getRecordingDevices()
end

function love.keypressed(key)
    if key == "c" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        love.event.quit()
        return
    end

    if not device then
        local num = tonumber(key)
        if num and devices[num] then
            selected = num
            device = devices[num]
            device:start(sampleCount, 44100, 16, 1)
        end
    else
        if key == "escape" then
            if device then device:stop() end
            device = nil
            selected = nil
            samples = {}
            visualizer.reset()
        elseif key == "right" then
            currentVisualizerIndex = currentVisualizerIndex % #visualizers + 1
            visualizer = visualizers[currentVisualizerIndex]
            visualizer.reset()
        elseif key == "left" then
            currentVisualizerIndex = (currentVisualizerIndex - 2) % #visualizers + 1
            visualizer = visualizers[currentVisualizerIndex]
            visualizer.reset()
        end
    end
end

function love.mousepressed(x, y, button)
    if visualizer.mousepressed then
        visualizer.mousepressed(x, y, button)
    end

    if not device and button == 1 and hoveredIndex then
        selected = hoveredIndex
        device = devices[selected]
        device:start(sampleCount, 44100, 16, 1)
    elseif device and button == 1 then
        isDragging = true
        lastMouseX, lastMouseY = x, y
    end
end

function love.mousereleased(x, y, button)
    if visualizer.mousereleased then
        visualizer.mousereleased(x, y, button)
    end

    if button == 1 then
        isDragging = false
    end
end

function love.mousemoved(x, y, dx, dy)
    if visualizer.mousemoved then
        visualizer.mousemoved(x, y, dx, dy)
    end
end

function love.wheelmoved(x, y)
    if visualizer.wheelmoved then
        visualizer.wheelmoved(x, y)
    end

    if y > 0 then
        cam.z = math.min(MAX_CAM_Z, cam.z + ZOOM_STEP)
    elseif y < 0 then
        cam.z = math.max(MIN_CAM_Z, cam.z - ZOOM_STEP)
    end
end

function love.update(dt)
    t = t + dt

    if not device then
        hoveredIndex = nil
        local mx, my = love.mouse.getPosition()
        for i, _ in ipairs(devices) do
            local y = deviceYStart + i * deviceSpacing
            local w, h = 400, 18
            if mx >= 40 and mx <= 40 + w and my >= y and my <= y + h then
                hoveredIndex = i
            end
        end
    end

    if device then
        local soundData = device:getData()
        if soundData then
            samples = {}
            for i = 0, math.min(soundData:getSampleCount() - 1, sampleCount - 1) do
                samples[i + 1] = soundData:getSample(i, 1)
            end
        end
    end

    volume = 0
    for i = 1, #samples do
        volume = volume + samples[i] ^ 2
    end
    if #samples > 0 then
        volume = math.sqrt(volume / #samples)
    end
    if volume > MAX_VOLUME then
        volume = MAX_VOLUME
    end

    bloomIntensity = bloomIntensity + (volume * 3 - bloomIntensity) * dt * 8

    if device then
        visualizer.update(dt, volume, emitters, samples, cam)
    end

    if isDragging then
        local mx, my = love.mouse.getPosition()
        local dx, dy = mx - lastMouseX, my - lastMouseY
        rotY = rotY - dx * 0.01
        rotX = rotX + dy * 0.01
        lastMouseX, lastMouseY = mx, my
    end
end

function love.draw()
    love.graphics.clear(0, 0, 0)

    if not device then
        love.graphics.print("Select an input device (click or use number keys):", 20, 20)
        for i, d in ipairs(devices) do
            local label = d:getName()
            if label:find("monitor") then
                label = label .. " [SPEAKER MONITOR]"
            end
            local y = deviceYStart + i * deviceSpacing
            if hoveredIndex == i then
                local text = i .. ". " .. label
                love.graphics.print(text, 40, y)
                local width = love.graphics.getFont():getWidth(text)
                love.graphics.line(40, y + 16, 40 + width, y + 16)
            else
                love.graphics.print(i .. ". " .. label, 40, y)
            end
        end
    else
        -- Visualizer draw
        visualizer.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)

        -- HUD info
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Listening to: " .. devices[selected]:getName() .. " (Esc to reselect)", 20, 20)
        love.graphics.print("Visualizer: " .. tostring(currentVisualizerIndex) .. " / " .. #visualizers .. " (left/right to switch)", 20, 40)
        love.graphics.print(string.format("RMS: %.3f", volume), 20, 60)
        love.graphics.print("Camera Z: " .. cam.z, 20, 80)
    end
end

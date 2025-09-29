local devices = {}
local selected = nil
local device = nil
local samples = {}
local sampleCount = 256

local particles = {}
local bloomIntensity = 0
local t = 0
local volume = 0

local rotX, rotY, rotZ = 0, 0, 0

local cam = { x = 0, y = 0, z = -700 }
local focalLength = 800

local emitters = {
    { color = { 0.9, 0.3, 0.3 } },
    { color = { 0.3, 0.9, 0.4 } },
    { color = { 0.3, 0.4, 0.9 } }
}

local MAX_VOLUME = 0.5
local MAX_PARTICLES = 6000
local LERP_ALPHA = 0.05
local DEBUG_BANDS = false

local hoveredIndex = nil
local deviceYStart = 60
local deviceSpacing = 20

function love.load()
    love.window.setTitle("Audio Particle Visualizer")
    love.window.setMode(1400, 900, { resizable = true, vsync = false })
    devices = love.audio.getRecordingDevices()
end

function love.keypressed(key)
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
            samples, particles = {}, {}
        end
    end
end

function love.mousepressed(x, y, button)
    if not device and button == 1 and hoveredIndex then
        selected = hoveredIndex
        device = devices[selected]
        device:start(sampleCount, 44100, 16, 1)
    end
end

local function project3D(x, y, z)
    local dx, dy, dz = x - cam.x, y - cam.y, z - cam.z
    if dz <= 0.1 then dz = 0.1 end
    local sx = (dx / dz) * focalLength + love.graphics.getWidth() / 2
    local sy = (dy / dz) * focalLength + love.graphics.getHeight() / 2
    return sx, sy, dz
end

local function rotate3D(x, y, z, ax, ay, az)
    local cos, sin = math.cos, math.sin
    local cx, sx = cos(ax), sin(ax)
    local cy, sy = cos(ay), sin(ay)
    local cz, sz = cos(az), sin(az)
    local y1, z1 = y * cx - z * sx, y * sx + z * cx
    y, z = y1, z1
    local x1, z2 = x * cy + z * sy, -x *sy + z * cy
    x, z = x1, z2
    local x2, y2 = x * cz - y * sz, x * sz + y * cz
    return x2, y2, z
end

function love.update(dt)
    t = t + dt

    if not device then
        hoveredIndex = nil
        local mx, my = love.mouse.getPosition()
        for i, _ in ipairs(devices) do
            local y = deviceYStart + i * deviceSpacing
            local w = 400
            local h = 18
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

    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 50)
            for i = 1, count do
                local a1 = math.random() * math.pi * 2
                local a2 = math.random() * math.pi
                local speed = 120 + volume * 900
                local dx = math.cos(a1) * math.sin(a2) * speed
                local dy = math.sin(a1) * math.sin(a2) * speed
                local dz = math.cos(a2) * speed
                table.insert(particles, {
                    x = 0, y = 0, z = 0,
                    dx = dx, dy = dy, dz = dz,
                    life = 1.0,
                    size = 3 + volume * 25,
                    color = emitter.color
                })
            end
        end
    end

    if #particles > MAX_PARTICLES then
        local excess = #particles - MAX_PARTICLES
        for i = 1, excess do
            table.remove(particles, 1)
        end
    end

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.z = p.z + p.dz * dt
        p.life = p.life - dt * 0.6
        p.size = p.size * (1 - dt * 0.8)
        if p.life <= 0 or p.size < 1 then
            table.remove(particles, i)
        end
    end

    rotX = rotX + dt * 0.05
    rotY = rotY + dt * 0.03
    rotZ = rotZ + dt * 0.02
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
        love.graphics.setBlendMode("add")

        local ax, ay, az = rotX, rotY, rotZ

        for _, p in ipairs(particles) do
            local rx, ry, rz = rotate3D(p.x, p.y, p.z, ax, ay, az)
            local sx, sy, dz = project3D(rx, ry, rz)
            local scale = focalLength / dz
            local size = p.size * scale
            local r, g, b = p.color[1], p.color[2], p.color[3]
            for glow = 4, 1, -1 do
                local alpha = (p.life * 0.2 * bloomIntensity) / glow
                love.graphics.setColor(r, g, b, alpha)
                love.graphics.circle("fill", sx, sy, size * glow * 0.35)
            end
        end

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Listening to: " .. devices[selected]:getName() .. " (Esc to reselect)", 20, 20)
        love.graphics.print("Particles: " .. #particles .. " / " .. MAX_PARTICLES, 20, 40)
        love.graphics.print(string.format("RMS: %.3f", volume), 20, 60)
    end
end

local burst3d = {}
local math3d = require("utilities.math3d")
local spawn = require("utilities.spawn")

local particles = {}
local MAX_PARTICLES = 6000

function burst3d.update(dt, volume, emitters)
    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 50)
            for i = 1, count do
                local speed = 120 + volume * 900
                local size = 3 + volume * 25
                table.insert(particles, spawn.scatter(speed, emitter.color, size))
            end
        end
    end

    if #particles > MAX_PARTICLES then
        for i = 1, #particles - MAX_PARTICLES do
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
end

function burst3d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, p in ipairs(particles) do
        local rx, ry, rz = math3d.rotate3D(p.x, p.y, p.z, rotX, rotY, rotZ)
        local sx, sy, dz = math3d.project3D(rx, ry, rz, cam, focalLength)
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
end

function burst3d.reset()
    particles = {}
end

return burst3d

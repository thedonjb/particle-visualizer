-- modules/ringwave3d.lua
local ringwave3d = {}
local math3d = require("utilities.math3d")
local spawn = require("utilities.spawn")

local rings = {}
local MAX_RINGS = 600

function ringwave3d.update(dt, volume, bassEnergy, emitters)
    -- 🔹 Normal rings (based on overall volume, like original wave3d)
    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 5)
            for i = 1, count do
                table.insert(rings, spawn.waveRing(volume, emitter.color))
            end
        end
    end

    -- 🔸 Bass-only rings (accent layer, alternate color)
    if bassEnergy > 0.08 then
        for _, emitter in ipairs(emitters) do
            local bassColor = { 1 - emitter.color[1], 1 - emitter.color[2], 1 - emitter.color[3] } 
            -- invert-ish color for contrast
            table.insert(rings, spawn.waveRing(bassEnergy * 1.2, bassColor))
        end
    end

    -- update all rings
    for i = #rings, 1, -1 do
        local r = rings[i]
        r.radius = r.radius + r.speed * dt
        r.z      = r.z + dt * 40        -- drift in depth
        r.life   = r.life - dt * 0.15   -- slower fade
        r.width  = r.width * (1 - dt * 0.05)

        if r.life <= 0 or r.width < 0.5 then
            table.remove(rings, i)
        end
    end

    if #rings > MAX_RINGS then
        for i = 1, #rings - MAX_RINGS do
            table.remove(rings, 1)
        end
    end
end

function ringwave3d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, r in ipairs(rings) do
        local points = {}
        local steps = 48
        for i = 1, steps do
            local angle = (i / steps) * math.pi * 2
            local x = math.cos(angle) * r.radius
            local y = math.sin(angle) * r.radius
            local z = r.z

            local rx, ry, rz = math3d.rotate3D(x, y, z, rotX, rotY, rotZ)
            local sx, sy, dz = math3d.project3D(rx, ry, rz, cam, focalLength)
            table.insert(points, sx)
            table.insert(points, sy)
        end

        local rCol, gCol, bCol = r.color[1], r.color[2], r.color[3]

        -- glow layering
        for glow = 3, 1, -1 do
            local alpha = (r.life * 0.15 * bloomIntensity) / glow
            love.graphics.setColor(rCol, gCol, bCol, alpha)
            love.graphics.setLineWidth(r.width * glow * 0.5)
            love.graphics.polygon("line", points)
        end
    end

    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function ringwave3d.reset()
    rings = {}
end

return ringwave3d

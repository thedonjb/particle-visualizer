local ripple2d = {}
local math3d = require("utilities.math3d")

local ripples = {}
local MAX_RIPPLES = 150

function ripple2d.update(dt, volume, emitters)
    if volume > 0.03 then
        -- spawn new ripples
        local count = math.floor(volume * 8)
        for i = 1, count do
            table.insert(ripples, {
                x = math.random(love.graphics.getWidth()),
                y = math.random(love.graphics.getHeight()),
                radius = 0,
                maxRadius = 80 + volume * 400,
                speed = 40 + math.random(60),
                alpha = 0.4 + volume * 0.6,
                thickness = 2 + math.random(2)
            })
        end
    end

    -- update ripples
    for i = #ripples, 1, -1 do
        local r = ripples[i]
        r.radius = r.radius + r.speed * dt
        r.alpha = r.alpha - dt * 0.25

        if r.alpha <= 0 or r.radius > r.maxRadius then
            table.remove(ripples, i)
        end
    end

    -- trim to max
    if #ripples > MAX_RIPPLES then
        for i = 1, #ripples - MAX_RIPPLES do
            table.remove(ripples, 1)
        end
    end
end

function ripple2d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, r in ipairs(ripples) do
        local a = r.alpha * bloomIntensity
        love.graphics.setColor(0.2, 0.8, 1.0, a)
        love.graphics.setLineWidth(r.thickness)
        love.graphics.circle("line", r.x, r.y, r.radius)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function ripple2d.reset()
    ripples = {}
end

return ripple2d

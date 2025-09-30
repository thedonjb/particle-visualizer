-- ./modules/galaxy.lua
local galaxy = {}

local stars = {}
local MAX_STARS = 5000

-- Helpers
local function rotate2D(x, y, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    return x * cos - y * sin, x * sin + y * cos
end

function galaxy.update(dt, volume, emitters)
    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 40)
            for i = 1, count do
                local angle = math.random() * math.pi * 2
                local radius = (math.random() ^ 1.5) * 300  -- spread outward
                local speed = 40 + volume * 400
                table.insert(stars, {
                    x = math.cos(angle) * radius,
                    y = math.sin(angle) * radius,
                    angle = angle,
                    radius = radius,
                    spin = (math.random() - 0.5) * 2.5, -- slight spin
                    life = 1.0,
                    size = 2 + volume * 15,
                    color = emitter.color,
                    drift = speed * (0.4 + math.random() * 0.6)
                })
            end
        end
    end

    if #stars > MAX_STARS then
        for i = 1, #stars - MAX_STARS do
            table.remove(stars, 1)
        end
    end

    for i = #stars, 1, -1 do
        local s = stars[i]
        s.angle = s.angle + dt * s.spin * 0.5
        s.radius = s.radius + dt * s.drift * 0.2
        s.x, s.y = rotate2D(s.radius, 0, s.angle)
        s.life = s.life - dt * 0.3
        s.size = s.size * (1 - dt * 0.5)
        if s.life <= 0 or s.size < 0.5 then
            table.remove(stars, i)
        end
    end
end

function galaxy.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, s in ipairs(stars) do
        local r, g, b = s.color[1], s.color[2], s.color[3]
        for glow = 3, 1, -1 do
            local alpha = (s.life * 0.25 * bloomIntensity) / glow
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.circle("fill", s.x + love.graphics.getWidth() / 2,
                                          s.y + love.graphics.getHeight() / 2,
                                          s.size * glow * 0.5)
        end
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function galaxy.reset()
    stars = {}
end

return galaxy

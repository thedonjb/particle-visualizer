-- ./modules/galaxy3d.lua
local galaxy3d = {}

local stars = {}
local MAX_STARS = 5000

-- 3D helpers (reuse burst.lua’s logic if desired)
local function rotate3D(x, y, z, ax, ay, az)
    local cos, sin = math.cos, math.sin
    local cx, sx = cos(ax), sin(ax)
    local cy, sy = cos(ay), sin(ay)
    local cz, sz = cos(az), sin(az)

    local y1, z1 = y * cx - z * sx, y * sx + z * cx
    y, z = y1, z1

    local x1, z2 = x * cy + z * sy, -x * sy + z * cy
    x, z = x1, z2

    local x2, y2 = x * cz - y * sz, x * sz + y * cz
    return x2, y2, z
end

local function project3D(x, y, z, cam, focalLength)
    local dx, dy, dz = x - cam.x, y - cam.y, z - cam.z
    if dz <= 0.1 then dz = 0.1 end
    local sx = (dx / dz) * focalLength + love.graphics.getWidth() / 2
    local sy = (dy / dz) * focalLength + love.graphics.getHeight() / 2
    return sx, sy, dz
end

-- Update
function galaxy3d.update(dt, volume, emitters)
    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 40)
            for i = 1, count do
                local angle = math.random() * math.pi * 2
                local radius = (math.random() ^ 1.5) * 300
                local speed = 40 + volume * 400
                table.insert(stars, {
                    x = math.cos(angle) * radius,
                    y = math.sin(angle) * radius,
                    z = 0, -- keep everything on a flat plane
                    angle = angle,
                    radius = radius,
                    spin = (math.random() - 0.5) * 2.5,
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
        s.x = math.cos(s.angle) * s.radius
        s.y = math.sin(s.angle) * s.radius
        s.life = s.life - dt * 0.3
        s.size = s.size * (1 - dt * 0.5)
        if s.life <= 0 or s.size < 0.5 then
            table.remove(stars, i)
        end
    end
end

-- Draw
function galaxy3d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, s in ipairs(stars) do
        -- Rotate + project star
        local rx, ry, rz = rotate3D(s.x, s.y, s.z, rotX, rotY, rotZ)
        local sx, sy, dz = project3D(rx, ry, rz, cam, focalLength)

        local scale = focalLength / dz
        local size = s.size * scale
        local r, g, b = s.color[1], s.color[2], s.color[3]

        for glow = 3, 1, -1 do
            local alpha = (s.life * 0.25 * bloomIntensity) / glow
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.circle("fill", sx, sy, size * glow * 0.5)
        end
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function galaxy3d.reset()
    stars = {}
end

return galaxy3d

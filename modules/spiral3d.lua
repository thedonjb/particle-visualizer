-- ./modules/spiral3d.lua
local spiral3d = {}

local arms = {}
local MAX_ARMS = 3000

-- 3D helpers (reuse burst.lua style)
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

-- Random scatter direction
local function randomScatter()
    local a1 = math.random() * math.pi * 2
    local a2 = math.random() * math.pi
    return math.cos(a1) * math.sin(a2),
           math.sin(a1) * math.sin(a2),
           math.cos(a2)
end

-- Update
function spiral3d.update(dt, volume, emitters)
    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 35)
            for i = 1, count do
                local angle = math.random() * math.pi * 2
                local dx, dy, dz = randomScatter()
                local speed = 60 + volume * 400
                table.insert(arms, {
                    x = 0, y = 0, z = 0,
                    dx = dx * speed * 0.3,
                    dy = dy * speed * 0.3,
                    dz = dz * speed * 0.3,
                    angle = angle,
                    radius = 5,
                    spin = (math.random() - 0.5) * 2,
                    drift = speed,
                    life = 1.0,
                    size = 2 + volume * 12,
                    color = emitter.color
                })
            end
        end
    end

    if #arms > MAX_ARMS then
        for i = 1, #arms - MAX_ARMS do
            table.remove(arms, 1)
        end
    end

    for i = #arms, 1, -1 do
        local a = arms[i]
        -- Spiral + scatter
        a.angle = a.angle + dt * a.spin
        a.radius = a.radius + dt * a.drift * 0.2
        a.x = a.x + a.dx * dt + math.cos(a.angle) * a.radius * 0.05
        a.y = a.y + a.dy * dt + math.sin(a.angle) * a.radius * 0.05
        a.z = a.z + a.dz * dt

        a.life = a.life - dt * 0.35
        a.size = a.size * (1 - dt * 0.45)

        if a.life <= 0 or a.size < 0.5 then
            table.remove(arms, i)
        end
    end
end

-- Draw
function spiral3d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, a in ipairs(arms) do
        local rx, ry, rz = rotate3D(a.x, a.y, a.z, rotX, rotY, rotZ)
        local sx, sy, dz = project3D(rx, ry, rz, cam, focalLength)

        local scale = focalLength / dz
        local size = a.size * scale
        local r, g, b = a.color[1], a.color[2], a.color[3]

        for glow = 3, 1, -1 do
            local alpha = (a.life * 0.2 * bloomIntensity) / glow
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.circle("fill", sx, sy, size * glow * 0.5)
        end
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function spiral3d.reset()
    arms = {}
end

return spiral3d

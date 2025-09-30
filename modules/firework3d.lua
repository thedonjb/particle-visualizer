-- ./modules/firework3d.lua
local firework3d = {}

local trails = {}
local MAX_TRAILS = 1200

-- 3D helpers (same as burst.lua)
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

-- Helpers
local function randomDir3D()
    local a1 = math.random() * math.pi * 2
    local a2 = math.random() * math.pi
    return math.cos(a1) * math.sin(a2),
           math.sin(a1) * math.sin(a2),
           math.cos(a2)
end

function firework3d.update(dt, volume, emitters)
    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 15)
            for i = 1, count do
                local dx, dy, dz = randomDir3D()
                local speed = 60 + volume * 400
                table.insert(trails, {
                    x = 0, y = 0, z = 0,
                    dx = dx * speed,
                    dy = dy * speed,
                    dz = dz * speed,
                    life = 1.0,
                    size = 2 + volume * 10,
                    color = emitter.color,
                    history = {}
                })
            end
        end
    end

    if #trails > MAX_TRAILS then
        for i = 1, #trails - MAX_TRAILS do
            table.remove(trails, 1)
        end
    end

    for i = #trails, 1, -1 do
        local t = trails[i]
        t.x = t.x + t.dx * dt
        t.y = t.y + t.dy * dt
        t.z = t.z + t.dz * dt

        table.insert(t.history, 1, {x = t.x, y = t.y, z = t.z})
        if #t.history > 20 then
            table.remove(t.history)
        end

        t.life = t.life - dt * 0.3
        t.size = t.size * (1 - dt * 0.25)
        if t.life <= 0 or t.size < 0.5 then
            table.remove(trails, i)
        end
    end
end

function firework3d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, t in ipairs(trails) do
        local r, g, b = t.color[1], t.color[2], t.color[3]
        for i = 1, #t.history - 1 do
            local p1 = t.history[i]
            local p2 = t.history[i + 1]

            -- Rotate and project history points
            local rx1, ry1, rz1 = rotate3D(p1.x, p1.y, p1.z, rotX, rotY, rotZ)
            local sx1, sy1, dz1 = project3D(rx1, ry1, rz1, cam, focalLength)

            local rx2, ry2, rz2 = rotate3D(p2.x, p2.y, p2.z, rotX, rotY, rotZ)
            local sx2, sy2, dz2 = project3D(rx2, ry2, rz2, cam, focalLength)

            local alpha = (t.life * 0.25 * bloomIntensity) * (1 - i / #t.history)
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.setLineWidth(t.size * (1 - i / #t.history))
            love.graphics.line(sx1, sy1, sx2, sy2)
        end
    end

    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function firework3d.reset()
    trails = {}
end

return firework3d

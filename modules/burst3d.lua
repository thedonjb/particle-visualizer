-- ./modules/burst3d.lua
local burst3d = {}

local particles = {}
local MAX_PARTICLES = 6000

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

function burst3d.update(dt, volume, emitters)
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
        local rx, ry, rz = rotate3D(p.x, p.y, p.z, rotX, rotY, rotZ)
        local sx, sy, dz = project3D(rx, ry, rz, cam, focalLength)
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

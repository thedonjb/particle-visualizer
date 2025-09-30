-- ./modules/wave3d.lua
local wave3d = {}

local rings = {}
local MAX_RINGS = 600

-- 3D helpers
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

-- Spawn expanding rings
function wave3d.update(dt, volume, emitters)
    if volume > 0.02 then
        for _, emitter in ipairs(emitters) do
            local count = math.floor(volume * 5)
            for i = 1, count do
                table.insert(rings, {
                    radius = 0,
                    speed = 40 + volume * 300,
                    life = 1.0,
                    width = 6 + volume * 18,
                    color = emitter.color,
                    z = 0
                })
            end
        end
    end

    if #rings > MAX_RINGS then
        for i = 1, #rings - MAX_RINGS do
            table.remove(rings, 1)
        end
    end

    for i = #rings, 1, -1 do
        local r = rings[i]
        r.radius = r.radius + r.speed * dt
        r.z = r.z + dt * 40 -- drift in z
        r.life = r.life - dt * 0.25
        r.width = r.width * (1 - dt * 0.1)
        if r.life <= 0 or r.width < 0.5 then
            table.remove(rings, i)
        end
    end
end

-- Draw rings as closed loops
function wave3d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")

    for _, r in ipairs(rings) do
        local points = {}
        local steps = 48
        for i = 1, steps do
            local angle = (i / steps) * math.pi * 2
            local x = math.cos(angle) * r.radius
            local y = math.sin(angle) * r.radius
            local z = r.z

            local rx, ry, rz = rotate3D(x, y, z, rotX, rotY, rotZ)
            local sx, sy, dz = project3D(rx, ry, rz, cam, focalLength)
            table.insert(points, sx)
            table.insert(points, sy)
        end

        local red, green, blue = r.color[1], r.color[2], r.color[3]
        for glow = 3, 1, -1 do
            local alpha = (r.life * 0.15 * bloomIntensity) / glow
            love.graphics.setColor(red, green, blue, alpha)
            love.graphics.setLineWidth(r.width * glow * 0.5)
            love.graphics.polygon("line", points) -- closed loop
        end
    end

    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function wave3d.reset()
    rings = {}
end

return wave3d

local math3d = {}

function math3d.rotate3D(x, y, z, ax, ay, az)
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

function math3d.project3D(x, y, z, cam, focalLength)
    local dx, dy, dz = x - cam.x, y - cam.y, z - cam.z
    if dz <= 0.1 then dz = 0.1 end
    local sx = (dx / dz) * focalLength + love.graphics.getWidth() / 2
    local sy = (dy / dz) * focalLength + love.graphics.getHeight() / 2
    return sx, sy, dz
end

function math3d.lerp(a, b, t)
    return a + (b - a) * t
end

return math3d

local spawn = {}

function spawn.ring(radius, z, color, density, size)
    local ring = {}
    for i = 1, density do
        local angle = (i / density) * math.pi * 2
        table.insert(ring, {
            x = math.cos(angle) * radius,
            y = math.sin(angle) * radius,
            z = z or 0,
            angle = angle,
            size = size or 4,
            color = color,
            alpha = 0
        })
    end
    return ring
end

function spawn.waveRing(volume, color)
    return {
        radius = 0,
        speed = 40 + volume * 300,
        life = 1.0,
        width = 6 + volume * 18,
        color = color,
        z = 0
    }
end

function spawn.star(radius, z, color, angle, spin, size)
    return {
        x = math.cos(angle) * radius,
        y = math.sin(angle) * radius,
        z = z or 0,
        angle = angle,
        radius = radius,
        spin = spin or 0,
        life = 1.0,
        size = size or 2,
        color = color,
        drift = 0,
    }
end

function spawn.scatter(speed, color, size)
    local a1 = math.random() * math.pi * 2
    local a2 = math.random() * math.pi
    local dx = math.cos(a1) * math.sin(a2)
    local dy = math.sin(a1) * math.sin(a2)
    local dz = math.cos(a2)

    return {
        x = 0, y = 0, z = 0,
        dx = dx * speed,
        dy = dy * speed,
        dz = dz * speed,
        life = 1.0,
        size = size or 2,
        color = color,
    }
end

function spawn.circlePoints(radius, steps, z, size, color)
    local points = {}
    for i = 1, steps do
        local angle = (i / steps) * math.pi * 2
        table.insert(points, {
            x = math.cos(angle) * radius,
            y = math.sin(angle) * radius,
            z = z or 0,
            angle = angle,
            size = size or 2,
            color = color,
        })
    end
    return points
end

return spawn

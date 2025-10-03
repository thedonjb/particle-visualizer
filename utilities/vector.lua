local vector = {}

function vector.randomScatter()
    local a1 = math.random() * math.pi * 2
    local a2 = math.random() * math.pi
    return math.cos(a1) * math.sin(a2),
           math.sin(a1) * math.sin(a2),
           math.cos(a2)
end

function vector.new(x, y, z)
    return { x = x or 0, y = y or 0, z = z or 0 }
end

function vector.add(a, b)
    return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end

function vector.sub(a, b)
    return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
end

function vector.scale(a, s)
    return { x = a.x * s, y = a.y * s, z = a.z * s }
end

function vector.dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function vector.cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x
    }
end

function vector.length(a)
    return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

function vector.normalize(a)
    local len = vector.length(a)
    if len == 0 then return { x = 0, y = 0, z = 0 } end
    return { x = a.x / len, y = a.y / len, z = a.z / len }
end

function vector.lerp(a, b, t)
    return {
        x = a.x + (b.x - a.x) * t,
        y = a.y + (b.y - a.y) * t,
        z = a.z + (b.z - a.z) * t
    }
end

function vector.distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

return vector

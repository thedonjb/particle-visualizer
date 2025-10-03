local cube3d = {}
local matrix = require("utilities.matrix")
local vector = require("utilities.vector")

local bassScale = 1.0
local rotX, rotY, rotZ = 0, 0, 0
local glowStrength = 0
local baseCount = 80

local vertices = {
    { -1, -1, -1 },
    { 1,  -1, -1 },
    { 1,  1,  -1 },
    { -1, 1,  -1 },
    { -1, -1, 1 },
    { 1,  -1, 1 },
    { 1,  1,  1 },
    { -1, 1,  1 },
}

-- edges
local edges = {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 }, -- back
    { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 }, -- front
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }  -- connect
}

-- faces with normals
local faces = {
    { normal = { 0, 0, -1 }, verts = { 1, 2, 3, 4 } }, -- back
    { normal = { 0, 0, 1 },  verts = { 5, 6, 7, 8 } }, -- front
    { normal = { 0, -1, 0 }, verts = { 1, 2, 6, 5 } }, -- bottom
    { normal = { 0, 1, 0 },  verts = { 4, 3, 7, 8 } }, -- top
    { normal = { -1, 0, 0 }, verts = { 1, 4, 8, 5 } }, -- left
    { normal = { 1, 0, 0 },  verts = { 2, 3, 7, 6 } }, -- right
}

local particles = {}
local MAX_PARTICLES = 4000

function cube3d.update(dt, volume, bassEnergy, emitters)
    local target = 80 + bassEnergy * 200
    bassScale = bassScale + (target - bassScale) * dt * 5

    rotX = (rotX + dt * 0.8) % (math.pi * 2)
    rotY = (rotY + dt * 1.0) % (math.pi * 2)
    rotZ = (rotZ + dt * 1.2) % (math.pi * 2)

    glowStrength = glowStrength + ((1.0 + bassEnergy * 4) - glowStrength) * dt * 6

    if bassEnergy > 0.1 then
        local count = math.floor(baseCount * bassEnergy * 6)

        local model = matrix.identity()
        model = matrix.multiply(matrix.scale(bassScale, bassScale, bassScale), model)
        model = matrix.multiply(matrix.rotateX(rotX), model)
        model = matrix.multiply(matrix.rotateY(rotY), model)
        model = matrix.multiply(matrix.rotateZ(rotZ), model)

        for _, face in ipairs(faces) do
            local nx, ny, nz = matrix.transformDirection(model, face.normal[1], face.normal[2], face.normal[3])

            for i = 1, count do
                local u, v = math.random(), math.random()
                if u + v > 1 then
                    u, v = 1 - u, 1 - v
                end

                local v1, v2, v3
                if math.random() < 0.5 then
                    v1 = vertices[face.verts[1]]
                    v2 = vertices[face.verts[2]]
                    v3 = vertices[face.verts[3]]
                else
                    v1 = vertices[face.verts[1]]
                    v2 = vertices[face.verts[3]]
                    v3 = vertices[face.verts[4]]
                end

                local px = v1[1] + u * (v2[1] - v1[1]) + v * (v3[1] - v1[1])
                local py = v1[2] + u * (v2[2] - v1[2]) + v * (v3[2] - v1[2])
                local pz = v1[3] + u * (v2[3] - v1[3]) + v * (v3[3] - v1[3])

                local wx, wy, wz = matrix.transformPoint(model, px, py, pz)

                local spreadAngle = (math.random() - 0.5) * math.pi
                local ax, ay, az = vector.randomScatter()

                local cosA, sinA = math.cos(spreadAngle), math.sin(spreadAngle)
                local dot = nx * ax + ny * ay + nz * az
                local rx = ax * dot * (1 - cosA) + nx * cosA + (-az * ny + ay * nz) * sinA
                local ry = ay * dot * (1 - cosA) + ny * cosA + (az * nx - ax * nz) * sinA
                local rz = az * dot * (1 - cosA) + nz * cosA + (-ay * nx + ax * ny) * sinA

                local len = math.sqrt(rx * rx + ry * ry + rz * rz)
                rx, ry, rz = rx / len, ry / len, rz / len

                local speed = 120 + bassEnergy * 500
                table.insert(particles, {
                    x = wx,
                    y = wy,
                    z = wz,
                    dx = rx * speed,
                    dy = ry * speed,
                    dz = rz * speed,
                    life = 1.0,
                    size = 2 + bassEnergy * 6,
                    color = { 0.3 + bassEnergy, 0.8, 1.0 - bassEnergy * 0.5 }
                })
            end
        end
    end

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.z = p.z + p.dz * dt
        p.life = p.life - dt * 0.8
        p.size = p.size * (1 - dt * 0.3)
        if p.life <= 0 or p.size < 0.5 then
            table.remove(particles, i)
        end
    end

    if #particles > MAX_PARTICLES then
        for i = 1, #particles - MAX_PARTICLES do
            table.remove(particles, 1)
        end
    end
end

function cube3d.draw(_, _, _, cam, focalLength, bloomIntensity)
    local projected = {}

    for i, v in ipairs(vertices) do
        local model = matrix.identity()
        model = matrix.multiply(matrix.scale(bassScale, bassScale, bassScale), model)
        model = matrix.multiply(matrix.rotateX(rotX), model)
        model = matrix.multiply(matrix.rotateY(rotY), model)
        model = matrix.multiply(matrix.rotateZ(rotZ), model)

        local x, y, z = matrix.transformPoint(model, v[1], v[2], v[3])
        x, y, z = x - cam.x, y - cam.y, z - cam.z
        if z < 1 then z = 1 end
        local sx = (x / z) * focalLength + love.graphics.getWidth() / 2
        local sy = (y / z) * focalLength + love.graphics.getHeight() / 2
        projected[i] = { sx, sy }
    end

    love.graphics.setBlendMode("add")
    local r, g, b = 0.2, 0.8, 1.0
    for glow = 4, 1, -1 do
        local alpha = (0.25 * bloomIntensity * glowStrength) / glow
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.setLineWidth(1 + glow * 3 * glowStrength)
        for _, e in ipairs(edges) do
            local a, b = projected[e[1]], projected[e[2]]
            love.graphics.line(a[1], a[2], b[1], b[2])
        end
    end

    for _, p in ipairs(particles) do
        local rx, ry, rz = p.x - cam.x, p.y - cam.y, p.z - cam.z
        if rz < 1 then rz = 1 end
        local sx = (rx / rz) * focalLength + love.graphics.getWidth() / 2
        local sy = (ry / rz) * focalLength + love.graphics.getHeight() / 2
        local scale = focalLength / rz
        local size = p.size * scale
        local cr, cg, cb = p.color[1], p.color[2], p.color[3]
        for glow = 3, 1, -1 do
            local alpha = (p.life * 0.25 * bloomIntensity) / glow
            love.graphics.setColor(cr, cg, cb, alpha)
            love.graphics.circle("fill", sx, sy, size * glow * 0.4)
        end
    end

    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
end

function cube3d.reset()
    bassScale = 80
    glowStrength = 1.0
    rotX, rotY, rotZ = 0, 0, 0
    particles = {}
end

return cube3d

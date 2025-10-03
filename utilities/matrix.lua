local matrix = {}

function matrix.identity()
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }
end

function matrix.multiply(a, b)
    local out = {}
    for row = 0, 3 do
        for col = 0, 3 do
            local sum = 0
            for k = 0, 3 do
                sum = sum + a[row*4 + k + 1] * b[k*4 + col + 1]
            end
            out[row*4 + col + 1] = sum
        end
    end
    return out
end

function matrix.transformPoint(m, x, y, z)
    local tx = m[1] * x + m[2] * y + m[3] * z + m[4]
    local ty = m[5] * x + m[6] * y + m[7] * z + m[8]
    local tz = m[9] * x + m[10] * y + m[11] * z + m[12]
    return tx, ty, tz
end

function matrix.transformDirection(m, x, y, z)
    local tx = m[1] * x + m[2] * y + m[3] * z
    local ty = m[5] * x + m[6] * y + m[7] * z
    local tz = m[9] * x + m[10] * y + m[11] * z
    return tx, ty, tz
end

function matrix.translate(x, y, z)
    return {
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1
    }
end

function matrix.scale(x, y, z)
    return {
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1
    }
end

function matrix.rotateX(a)
    local c, s = math.cos(a), math.sin(a)
    return {
        1, 0, 0, 0,
        0, c, -s, 0,
        0, s,  c, 0,
        0, 0, 0, 1
    }
end

function matrix.rotateY(a)
    local c, s = math.cos(a), math.sin(a)
    return {
         c, 0, s, 0,
         0, 1, 0, 0,
        -s, 0, c, 0,
         0, 0, 0, 1
    }
end

function matrix.rotateZ(a)
    local c, s = math.cos(a), math.sin(a)
    return {
        c, -s, 0, 0,
        s,  c, 0, 0,
        0,  0, 1, 0,
        0,  0, 0, 1
    }
end

function matrix.perspective(fov, aspect, near, far)
    local f = 1 / math.tan(fov / 2)
    return {
        f/aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (far+near)/(near-far), (2*far*near)/(near-far),
        0, 0, -1, 0
    }
end

function matrix.ortho(left, right, bottom, top, near, far)
    return {
        2/(right-left), 0, 0, -(right+left)/(right-left),
        0, 2/(top-bottom), 0, -(top+bottom)/(top-bottom),
        0, 0, -2/(far-near), -(far+near)/(far-near),
        0, 0, 0, 1
    }
end

return matrix

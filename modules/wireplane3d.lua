local wireplane3d = {}
local math3d = require("utilities.math3d")

local grid = {}
local GRID_W, GRID_H = 40, 30
local SPACING = 40
local state = { amp = 0 }

function wireplane3d.update(dt, volume, emitters, samples, cam)
    local targetAmp = volume * 250
    state.amp = math3d.lerp(state.amp, targetAmp, dt * 5)

    if #grid == 0 then
        for gx = -GRID_W/2, GRID_W/2 do
            grid[gx] = {}
            for gy = -GRID_H/2, GRID_H/2 do
                grid[gx][gy] = { x = gx * SPACING, y = gy * SPACING, z = 0 }
            end
        end
    end

    for gx = -GRID_W/2, GRID_W/2 do
        for gy = -GRID_H/2, GRID_H/2 do
            local p = grid[gx][gy]
            local wave = math.sin(gx * 0.3 + love.timer.getTime() * 2)
                       + math.cos(gy * 0.3 + love.timer.getTime() * 2)
            local targetZ = wave * state.amp
            p.z = math3d.lerp(p.z, targetZ, dt * 4)
        end
    end
end

function wireplane3d.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(0.3, 0.9, 1.0, 0.6 * bloomIntensity)

    for gx = -GRID_W/2, GRID_W/2 - 1 do
        for gy = -GRID_H/2, GRID_H/2 - 1 do
            local p1 = grid[gx][gy]
            local p2 = grid[gx+1][gy]
            local p3 = grid[gx][gy+1]

            local rx1, ry1, rz1 = math3d.rotate3D(p1.x, p1.y, p1.z, rotX, rotY, rotZ)
            local rx2, ry2, rz2 = math3d.rotate3D(p2.x, p2.y, p2.z, rotX, rotY, rotZ)
            local rx3, ry3, rz3 = math3d.rotate3D(p3.x, p3.y, p3.z, rotX, rotY, rotZ)

            local sx1, sy1 = math3d.project3D(rx1, ry1, rz1, cam, focalLength)
            local sx2, sy2 = math3d.project3D(rx2, ry2, rz2, cam, focalLength)
            local sx3, sy3 = math3d.project3D(rx3, ry3, rz3, cam, focalLength)

            love.graphics.line(sx1, sy1, sx2, sy2)
            love.graphics.line(sx1, sy1, sx3, sy3)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function wireplane3d.reset()
    grid = {}
end

return wireplane3d

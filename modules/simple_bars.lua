local math3d = require("utilities.math3d")

local simple_bars = {}

local bars = {}
local numBars = 64
local barSpacing = 6
local maxHeight = 300

local lerpSpeed = 10

function simple_bars.reset()
    bars = {}
    for i = 1, numBars do
        bars[i] = 0
    end
end

function simple_bars.update(dt, volume, emitters, samples, cam)
    if #samples > 0 then
        local binSize = math.floor(#samples / numBars)
        for i = 1, numBars do
            local sum = 0
            for j = 1, binSize do
                local idx = (i - 1) * binSize + j
                if idx <= #samples then
                    sum = sum + math.abs(samples[idx])
                end
            end

            local avg = sum / binSize
            local targetHeight = avg * maxHeight * 2

            bars[i] = math3d.lerp(bars[i], targetHeight, dt * lerpSpeed)
        end
    else
        for i = 1, numBars do
            bars[i] = math3d.lerp(bars[i], 0, dt * lerpSpeed)
        end
    end
end

function simple_bars.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    local screenW, screenH = love.graphics.getDimensions()
    local centerX = screenW / 2
    local baseY = screenH - 100

    love.graphics.setColor(0.2 + bloomIntensity, 0.6, 1.0, 1.0)

    for i, h in ipairs(bars) do
        local x = centerX + (i - numBars / 2) * barSpacing
        love.graphics.rectangle("fill", x, baseY - h, barSpacing - 2, h)
    end
end

return simple_bars

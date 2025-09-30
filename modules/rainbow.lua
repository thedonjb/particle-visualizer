local spectrum = {}
spectrum.name = "Rainbow Spectrum (Linear)"

local bars = {}
local numBars = 48
local t = 0

local FFT_SIZE = 256
local fftBuffer = {}

local smoothedHeights = {}
local LERP_SPEED = 14
local PEAK_CAP = 0.7

-- HSV → RGB
local function hsvToRgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local r = v * (1 - (1 - f) * s)
    local mod = i % 6
    if mod == 0 then return v, r, p
    elseif mod == 1 then return q, v, p
    elseif mod == 2 then return p, v, r
    elseif mod == 3 then return p, q, v
    elseif mod == 4 then return r, p, v
    else return v, p, q end
end

-- FFT
local function fft(x)
    local N = #x
    if N <= 1 then return x end
    local even, odd = {}, {}
    for i = 1, N, 2 do table.insert(even, x[i]) end
    for i = 2, N, 2 do table.insert(odd,  x[i]) end
    even, odd = fft(even), fft(odd)

    local result = {}
    for k = 0, (N / 2) - 1 do
        local angle = -2 * math.pi * k / N
        local twiddle = { math.cos(angle), math.sin(angle) }
        local oddPart = {
            odd[k+1][1] * twiddle[1] - odd[k+1][2] * twiddle[2],
            odd[k+1][1] * twiddle[2] + odd[k+1][2] * twiddle[1]
        }
        result[k+1] = { even[k+1][1] + oddPart[1], even[k+1][2] + oddPart[2] }
        result[k+1+N/2] = { even[k+1][1] - oddPart[1], even[k+1][2] - oddPart[2] }
    end
    return result
end

-- Build linear bin ranges
local function buildLinearBins(totalBins, numBars)
    local bins = {}
    local binsPerBar = totalBins / numBars
    for i = 1, numBars do
        local startBin = math.floor((i - 1) * binsPerBar) + 1
        local endBin   = math.floor(i * binsPerBar)
        if startBin > totalBins then startBin = totalBins end
        if endBin > totalBins then endBin = totalBins end
        if endBin < startBin then endBin = startBin end
        table.insert(bins, {startBin, endBin})
    end
    return bins
end

local linearBins = buildLinearBins(FFT_SIZE / 2, numBars)

function spectrum.update(dt, volume, emitters, samples)
    t = t + dt
    bars = {}

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local barSpacing = 4
    local barWidth = (width / numBars) - barSpacing
    local maxHeight = height * PEAK_CAP

    -- Prepare FFT buffer
    fftBuffer = {}
    for i = 1, FFT_SIZE do
        local sample = samples and samples[i] or 0
        fftBuffer[i] = { sample, 0 }
    end

    local freqDomain = fft(fftBuffer)

    -- Bars from linear bins
    for i, range in ipairs(linearBins) do
        local sum, count = 0, 0
        for j = range[1], range[2] do
            if freqDomain[j] then
                local re, im = freqDomain[j][1], freqDomain[j][2]
                sum = sum + math.sqrt(re*re + im*im)
                count = count + 1
            end
        end
        local magnitude = (count > 0) and (sum / count) or 0

        -- Normalize & cap
        local rawHeight = math.min(maxHeight, magnitude * 250)

        -- Smooth (lerp)
        local prev = smoothedHeights[i] or 0
        local h = prev + (rawHeight - prev) * math.min(1, dt * LERP_SPEED)
        smoothedHeights[i] = h

        -- Rainbow hue
        local hue = (i / numBars + t * 0.12) % 1.0
        local r, g, b = hsvToRgb(hue, 1.0, 1.0)

        table.insert(bars, {
            x = (i - 1) * (barWidth + barSpacing),
            y = height - h,
            w = barWidth,
            h = h,
            color = {r, g, b}
        })
    end
end

function spectrum.draw(rotX, rotY, rotZ, cam, focalLength, bloomIntensity)
    love.graphics.setBlendMode("add")
    for glow = 10, 1, -1 do
        local alpha = (0.05 * bloomIntensity) / glow
        for _, bar in ipairs(bars) do
            love.graphics.setColor(bar.color[1], bar.color[2], bar.color[3], alpha)
            love.graphics.rectangle("fill",
                bar.x - glow, bar.y - glow,
                bar.w + glow * 2, bar.h + glow * 2,
                bar.w * 0.4, bar.w * 0.4
            )
        end
    end

    love.graphics.setBlendMode("alpha")
    for _, bar in ipairs(bars) do
        love.graphics.setColor(bar.color[1], bar.color[2], bar.color[3], 0.95)
        love.graphics.rectangle("fill",
            bar.x, bar.y, bar.w, bar.h,
            bar.w * 0.4, bar.w * 0.4
        )
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function spectrum.reset()
    bars = {}
    fftBuffer = {}
    smoothedHeights = {}
    t = 0
end

return spectrum

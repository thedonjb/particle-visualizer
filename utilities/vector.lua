local vector = {}

function vector.randomScatter()
    local a1 = math.random() * math.pi * 2
    local a2 = math.random() * math.pi
    return math.cos(a1) * math.sin(a2),
           math.sin(a1) * math.sin(a2),
           math.cos(a2)
end

return vector

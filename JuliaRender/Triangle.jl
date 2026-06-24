


mutable struct Triangle

    Points::Vector{Vec4}
    #text coords later here
    Color::UInt32
    
end

function BarycentricWeights(p::Vec2, a::Vec2, b::Vec2, c::Vec2)::Vec3
    denom = ((b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y))

    if denom == 0.0f0
        return Vec3(-1.0f0, -1.0f0, -1.0f0)  
    end

    alpha::Float32 = ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) / denom
    beta::Float32 = ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / denom
    gamma::Float32 = 1.0f0 - alpha - beta

    return Vec3(alpha, beta, gamma)
end
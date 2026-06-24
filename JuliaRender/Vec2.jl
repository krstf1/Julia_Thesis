struct Vec2
    x::Float32
    y::Float32
end

Vec2(x::Real, y::Real) = Vec2(Float32(x), Float32(y))

Base.:+(a::Vec2, b::Vec2) = (a.x + b.x, a.y + b.Y)
Base.:-(a::Vec2, b::Vec2) = (a.x - b.x, a.y - b.y)

Base.:*(a::Vec2, b::Real) = (a.x * b, a.y * b)
Base.:/(a::Vec2, b::Real) = (a.x / b, a.y / b)

function NewVec2(a::Vec2, b::Vec2)

    return Vec2(a, b)

end

function Vec2Len(a::Vec2)
    return sqrt(a.x* a.x + a.y * a.y)
end

function Vec2Dot(a::Vec2, b::Vec2)

    return (a.x* b.x + a.y * b.y)
    
end

function Vec2Normalize(a::Vec2)

    len = sqrt(a.x * a.x + a.y * a.y)
    
    return (a.x/len, a.y/len)

end

function MakeVec2FromVec4(x::Real, y::Real, z::Real, w::Real)
    
    return Vec2(x, y)

end


function MakeVec2FromVec3(x::Real, y::Real, z::Real)

    return Vec2(x, y)

end
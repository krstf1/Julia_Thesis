struct Vec3
    x::Float32
    y::Float32
    z::Float32
end

Vec3(x::Real, y::Real, z::Real) = Vec3(Float32(x), Float32(y), Float32(z))

Base.:+(a::Vec3, b::Vec3) = Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
Base.:-(a::Vec3, b::Vec3) = Vec3(a.x - b.x, a.y - b.y, a.z - b.z)

Base.:*(a::Vec3, b::Real) = Vec3(a.x * b, a.y * b, a.z * b)
Base.:*(a::Real, b::Vec3) = Vec3(a * b.x, a * b.y, a * b.z)
Base.:/(a::Vec3, b::Real) = Vec3(a.x / b, a.y / b, a.z / b)

function NewVec3(x::Real, y::Real, z::Real)

    return Vec3(x,y,z)

end

function Vec3Dot(a::Vec3, b::Vec3)::Float32
    return Float32(a.x * b.x + a.y * b.y + a.z * b.z)
end

function Cross(a::Vec3, b::Vec3)::Vec3
    return Vec3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
end
function Vec3Len(a::Vec3)
    return sqrt(Vec3Dot(a, a))
end

function Normalize(v::Vec3)
    len = Vec3Len(v)
    if len == 0
        return Vec3(0, 0, 0)
    end
    return v / len
end

function Vec3Normal(v0::Vec3, v1::Vec3, v2::Vec3)::Vec3
    edge1 = v1 - v0
    edge2 = v2 - v0

    return Normalize(Cross(edge1, edge2))
end


function MakeVec3FromVec4(x::Real, y::Real, z::Real, w::Real)

    return Vec3(x, y, z)
    
end
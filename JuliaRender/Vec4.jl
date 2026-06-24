struct Vec4
    x::Float32
    y::Float32
    z::Float32
    w::Float32
end


Vec4(x::Real, y::Real, z::Real, w::Real) = Vec4(Float32(x), Float32(y), Float32(z), Float32(w))

function MakeVec4FromVec3(x::Real, y::Real, z::Real)

    return Vec4(x, y, z, 1)
    
end


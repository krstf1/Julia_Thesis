using MiniFB
using LinearAlgebra


function MakeIdentity()
    return Matrix{Float32}(I, 4, 4)
end


function RotateX(angle::Float32)
    s = sin(angle)
    c = cos(angle)
    return Float32[
        1 0 0 0 
        0 c -s 0
        0 s c 0 
        0 0 0 1
    ]
end

function RotateY(angle::Float32)
    s = sin(angle)
    c = cos(angle)
    return Float32[
        c 0 s 0
        0 1 0 0
        -s 0 c 0
        0 0 0 1 
    ]
end

function RotateZ(angle::Float32)::Matrix{Float32}
    s = sin(angle)
    c = cos(angle)
    return Float32[
        c -s 0 0 
        s c 0 0
        0 0 1 0
        0 0 0 1
    ]
end

function MakeScale(sx::Real, sy::Real, sz::Real)::Matrix{Float32}
    return Float32[
        sx 0 0 0
        0 sy 0 0
        0 0 sz 0
        0 0 0 1
    ]
end

function MakeTranslation(tx::Real, ty::Real, tz::Real)::Matrix{Float32}
    return Float32[
        1 0 0 tx
        0 1 0 ty
        0 0 1 tz
        0 0 0 1
    ]
end

function MakePerspective(
    fov::Float32,
    aspect::Float32,
    znear::Float32,
    zfar::Float32
)::Matrix{Float32}

    m = zeros(Float32, 4, 4)

    f = 1.0f0 / tan(fov / 2.0f0)

    m[1, 1] = f / aspect
    m[2, 2] = f
    m[3, 3] = zfar / (zfar - znear)
    m[3, 4] = (-zfar * znear) / (zfar - znear)
    m[4, 3] = 1.0f0

    return m
end


function MulMat4Vec4(m::Matrix{Float32}, v::Vec4)::Vec4
    return Vec4(
        m[1, 1] * v.x + m[1, 2] * v.y + m[1, 3] * v.z + m[1, 4] * v.w,
        m[2, 1] * v.x + m[2, 2] * v.y + m[2, 3] * v.z + m[2, 4] * v.w,
        m[3, 1] * v.x + m[3, 2] * v.y + m[3, 3] * v.z + m[3, 4] * v.w,
        m[4, 1] * v.x + m[4, 2] * v.y + m[4, 3] * v.z + m[4, 4] * v.w
    )
end


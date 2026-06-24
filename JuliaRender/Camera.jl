



mutable struct Cam
    CamPos::Vec3
    CamTurnDegree::Float32  
end

function LookAtItem(eye::Vec3, target::Vec3, up::Vec3)::Matrix{Float32}

    z = target - eye
    z = Normalize(z)
    x = Cross(up, z)
    x = Normalize(x)
    y = Cross(z, x)

    viewMatrix = Float32[
        x.x x.y x.z -Vec3Dot(x, eye)
        y.x y.y y.z -Vec3Dot(y, eye)
        z.x z.y z.z -Vec3Dot(z, eye)
        0.0f0 0.0f0 0.0f0 1.0f0
    ]

    return viewMatrix
end
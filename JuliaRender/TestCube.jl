using MiniFB
include("Vec3.jl")

struct Tex2
    u::Float32
    v::Float32
end

mutable struct Face
    a::Int
    b::Int
    c::Int

    a_uv::Tex2
    b_uv::Tex2
    c_uv::Tex2
end

mutable struct Mesh
    Faces::Vector{Face}
    Vertices::Vector{Vec3}
    Scale::Vec3
    Rotation::Vec3
    Translation::Vec3
end



const CUBE_VERTICES = Vec3[
    Vec3(-1.0f0, -1.0f0, -1.0f0),
    Vec3(-1.0f0, 1.0f0, -1.0f0),
    Vec3(1.0f0, 1.0f0, -1.0f0),
    Vec3(1.0f0, -1.0f0, -1.0f0),
    Vec3(1.0f0, 1.0f0, 1.0f0),
    Vec3(1.0f0, -1.0f0, 1.0f0),
    Vec3(-1.0f0, 1.0f0, 1.0f0),
    Vec3(-1.0f0, -1.0f0, 1.0f0)
]





const CUBE_FACES = Face[
    # near/back depending on your camera convention, z = -1
    Face(1, 2, 3, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),
    Face(1, 3, 4, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),

    # z = 1
    Face(4, 3, 5, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),
    Face(4, 5, 6, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),

    # x = -1
    Face(6, 5, 7, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),
    Face(6, 7, 8, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),

    # x = 1
    Face(8, 7, 2, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),
    Face(8, 2, 1, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),

    # y = -1
    Face(2, 7, 5, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),
    Face(2, 5, 3, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),

    # y = 1
    Face(6, 8, 1, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0)),
    Face(6, 1, 4, Tex2(0.0f0, 0.0f0), Tex2(1.0f0, 0.0f0), Tex2(1.0f0, 1.0f0))
]





function CreateCube()

    return Mesh(
        copy(CUBE_FACES),
        copy(CUBE_VERTICES),
        Vec3(1.0f0, 1.0f0, 1.0f0),
        Vec3(0.0f0, 0.0f0, 0.0f0),
        Vec3(0.0f0, 0.0f0, 5.0f0)

    )


end
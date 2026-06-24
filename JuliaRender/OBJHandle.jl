
function ParseOBJFaceToken(token::AbstractString)
    parts = split(token, "/")

    vi = parse(Int, parts[1])

    ti = 0
    ni = 0

    if length(parts) >= 2 && parts[2] != ""
        ti = parse(Int, parts[2])
    end

    if length(parts) >= 3 && parts[3] != ""
        ni = parse(Int, parts[3])
    end

    return vi, ti, ni
end


function GetUV(texCoords::Vector{Tex2}, index::Int)::Tex2
    if index <= 0
        return Tex2(0.0f0, 0.0f0)
    end

    return texCoords[index]
end


function LoadMeshFromOBJ(filename::String)::Mesh
    vertices = Vec3[]
    faces = Face[]
    texCoords = Tex2[]

    for line in eachline(filename)
        line = strip(line)

        if isempty(line) || startswith(line, "#")
            continue
        end

        parts = split(line)

        if parts[1] == "v"
            x = parse(Float32, parts[2])
            y = parse(Float32, parts[3])
            z = parse(Float32, parts[4])
            push!(vertices, Vec3(x, y, z))

        elseif parts[1] == "vt"
            u = parse(Float32, parts[2])
            v = parse(Float32, parts[3])
            push!(texCoords, Tex2(u, v))

        elseif parts[1] == "f"
            faceTokens = parts[2:end]
            parsed = [ParseOBJFaceToken(token) for token in faceTokens]

            for i in 2:length(parsed)-1
                vi1, ti1, ni1 = parsed[1]
                vi2, ti2, ni2 = parsed[i]
                vi3, ti3, ni3 = parsed[i+1]
                face = Face(
                    vi1,
                    vi2,
                    vi3,
                    GetUV(texCoords, ti1),
                    GetUV(texCoords, ti2),
                    GetUV(texCoords, ti3)
                )
                push!(faces, face)
            end
        end
    end

    return Mesh(
        faces,
        vertices,
        Vec3(1.0f0, 1.0f0, 1.0f0),
        Vec3(0.0f0, 0.0f0, 0.0f0),
        Vec3(0.0f0, 0.0f0, 5.0f0)
    )
end
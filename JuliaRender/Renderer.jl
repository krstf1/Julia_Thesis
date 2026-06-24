using MiniFB
const FOV_FACTOR = 600.0f0


mutable struct AppState
    window
    width::Int
    height::Int
    bIsRunning::Bool
    ColorBuffer::Vector{UInt32}
    zBuffer::Vector{Float32}
    Mesh::Mesh
    Camera::Cam
    PrevFrameTime::Float64
    Texture::Texture
    LightDir::Vec3
    FrameCount::Int
    CurrentFPS::Float32
    FpsTimer::Float64
end


function get_screen_size()
    width = ccall((:GetSystemMetrics, "user32"), Int32, (Int32,), 0)
    height = ccall((:GetSystemMetrics, "user32"), Int32, (Int32,), 1)

    return Int(width), Int(height)
end



function InitWin()
    width, height = get_screen_size()

    cube::Mesh = LoadMeshFromOBJ("assets/vrije.obj")
    texture::Texture = LoadTextureFromPNG("assets/vrije.png")
    
    Camera = Cam(
        #Vec3(0.0f0, 0.0f0, 1.0f0),   # CamDir
        Vec3(0.0f0, 0.0f0, -60.0f0),  # CamPos
        #Vec3(0.0f0, 0.0f0, 0.0f0),    # CamForwardVelocity
        0.0f0                         # CamTurnDegree
    )

    println("Screen size: ", width, " x ", height)

    window = mfb_open_ex(
        "Julia Fullscreen Test",
        width,
        height,
        MiniFB.WF_FULLSCREEN
    )

    mfb_set_target_fps(1000)


    ColorBuffer = zeros(UInt32, width * height)
    zBuffer = fill(Inf32, width * height)

    return AppState(
        window,
        width,
        height,
        true,
        ColorBuffer,
        zBuffer,
        cube,
        Camera,
        time(),
        texture,
        Vec3(0,0,1),
        0,          # FrameCount
        0.0f0,      # CurrentFPS
        time()      # FpsTimer

    )
end




function DrawPixel!(app::AppState, x::Int, y::Int, color::UInt32)
    if x < 0 || x >= app.width || y < 0 || y >= app.height
        return
    end

    index = y * app.width + x + 1
    app.ColorBuffer[index] = color

end



function DrawRect!(app::AppState, x::Int, y::Int, w::Int, h::Int, color::UInt32)

    for py in y:y+h-1

        for px in x:x+w-1
        
            DrawPixel!(app, px, py, color)
        
        end
    end
end



function DrawLine!(app::AppState, x0::Int, y0::Int, x1::Int, y1::Int, Color::UInt32)

    deltaX::Int = x1 - x0
    deltaY::Int = y1 - y0

    SideLen::Int = abs(deltaX) > abs(deltaY) ? abs(deltaX) : abs(deltaY)

    XInc::Float32 = deltaX / Float32(SideLen)
    YInc::Float32 = deltaY / Float32(SideLen)

    CurrX::Float32 = Float32(x0)
    CurrY::Float32 = Float32(y0)

    for i in 0:SideLen
        DrawPixel!(app, Int(round(CurrX)), Int(round(CurrY)), Color)
        CurrX+=XInc
        CurrY+=YInc
    
    end
end


function ProjectVertexVec3(v::Vec3, app::AppState)
    z = v.z

    if z <= 0.0001f0
        return 0, 0
    end

    screen_x = round(Int, app.width / 2 + (v.x * FOV_FACTOR) / z)
    screen_y = round(Int, app.height / 2 - (v.y * FOV_FACTOR) / z)

    return screen_x, screen_y
end


function ProjectVertexForWireframe(
    v::Vec4,
    projectionMat::Matrix{Float32},
    app::AppState
)::Tuple{Int,Int}

    projected = ProjectVertexVec4(v, projectionMat, app)

    screen_x = round(Int, projected.x)
    screen_y = round(Int, projected.y)

    return screen_x, screen_y
end


function ProjectVertexVec4(
    v::Vec4,
    projectionMat::Matrix{Float32},
    app::AppState
)::Vec4

    clip = MulMat4Vec4(projectionMat, v)

    if abs(clip.w) <= 0.0001f0
        return Vec4(0.0f0, 0.0f0, clip.z, clip.w)
    end

    
    ndc_x = clip.x / clip.w
    ndc_y = clip.y / clip.w
    ndc_z = clip.z / clip.w

    # Viewport transform: NDC -> screen pixels
    
    screen_x = (ndc_x + 1.0f0) * 0.5f0 * Float32(app.width)
    screen_y = (1.0f0 - ndc_y) * 0.5f0 * Float32(app.height)

    return Vec4(screen_x, screen_y, ndc_z, clip.w)
end

function SwapCoords(vertices::Vector{Vec4}, FaceUVs::Vector{Tex2})::Tuple{Vector{Vec4}, Vector{Tex2}}


    @assert length(vertices) == 3

    sorted = copy(vertices)
    SortedUVs = copy(FaceUVs)


    if sorted[1].y > sorted[2].y
        sorted[1], sorted[2] = sorted[2], sorted[1]
        SortedUVs[1], SortedUVs[2] = SortedUVs[2], SortedUVs[1]
    end

    if sorted[2].y > sorted[3].y
        sorted[2], sorted[3] = sorted[3], sorted[2]
        SortedUVs[2], SortedUVs[3] = SortedUVs[3], SortedUVs[2]
    end

    if sorted[1].y > sorted[2].y
        sorted[1], sorted[2] = sorted[2], sorted[1]
        SortedUVs[1], SortedUVs[2] = SortedUVs[2], SortedUVs[1]
    end

    return sorted, SortedUVs
end



function DrawMeshWireframe!(
    app::AppState,
    vertices::Vector{Vec4},
    color::UInt32,
    projectionMat::Matrix{Float32}
)

    @assert length(vertices) == 3

    x1, y1 = ProjectVertexForWireframe(vertices[1], projectionMat, app)
    x2, y2 = ProjectVertexForWireframe(vertices[2], projectionMat, app)
    x3, y3 = ProjectVertexForWireframe(vertices[3], projectionMat, app)

    DrawLine!(app, x1, y1, x2, y2, color)
    DrawLine!(app, x2, y2, x3, y3, color)
    DrawLine!(app, x3, y3, x1, y1, color)
end



function DrawMeshFilled(
    app::AppState,
    vertices::Vector{Vec4},
    FaceUVs::Vector{Tex2},
    color::UInt32,
    projectionMat::Matrix{Float32}
)
    @assert length(vertices) == 3

    ScreenVertices = Vec4[
        ProjectVertexVec4(vertices[1], projectionMat, app),
        ProjectVertexVec4(vertices[2], projectionMat, app),
        ProjectVertexVec4(vertices[3], projectionMat, app)
    ]
    SwappedCoords, SwappedUVs = SwapCoords(ScreenVertices, FaceUVs)

    vec0 = SwappedCoords[1] 
    vec1 = SwappedCoords[2]  
    vec2 = SwappedCoords[3]  

    uv0 = SwappedUVs[1]
    uv1 = SwappedUVs[2]
    uv2 = SwappedUVs[3]

    x0 = vec0.x
    y0 = vec0.y

    x1 = vec1.x
    y1 = vec1.y

    x2 = vec2.x
    y2 = vec2.y


    if y1 - y0 != 0.0f0

        invSlope1 = (x1 - x0) / (y1 - y0)
        invSlope2 = (x2 - x0) / (y2 - y0)

        yStart = ceil(Int, y0)
        yEnd = floor(Int, y1)

        for y in yStart:yEnd
            fy = Float32(y)

            xStart = x0 + (fy - y0) * invSlope1
            xEnd = x0 + (fy - y0) * invSlope2

            if xEnd < xStart
                xStart, xEnd = xEnd, xStart
            end

            ixStart = ceil(Int, xStart)

            ixEnd = floor(Int, xEnd)

            for x in ixStart:ixEnd

                DrawColoredPixel(x, y, vec0, vec1, vec2, uv0, uv1, uv2, color, app)

            end
        end
    end


    if y2 - y1 != 0.0f0
        invSlope1 = (x2 - x1) / (y2 - y1)
        invSlope2 = (x2 - x0) / (y2 - y0)

        yStart = ceil(Int, y1)
        yEnd = floor(Int, y2)

        for y in yStart:yEnd
            fy = Float32(y)

            xStart = x1 + (fy - y1) * invSlope1
            xEnd = x0 + (fy - y0) * invSlope2

            if xEnd < xStart
                xStart, xEnd = xEnd, xStart
            end

            ixStart = ceil(Int, xStart)
            ixEnd = floor(Int, xEnd)

            for x in ixStart:ixEnd

                DrawColoredPixel(x, y, vec0, vec1, vec2, uv0, uv1, uv2, color, app)

            end
        end
    end
end




function IsCulled(vertices::Vector{Vec3})::Bool
    v0 = vertices[1]
    v1 = vertices[2]
    v2 = vertices[3]

    edge1 = v1 - v0
    edge2 = v2 - v0

    normal = Normalize(Cross(edge1, edge2))

    cameraToTriangle = Normalize(v0 - Vec3(0.0f0, 0.0f0, 0.0f0))
    dotProd = Vec3Dot(normal, cameraToTriangle)

    return dotProd >= 0.0f0
end



function ClearColorBuffer!(app::AppState, color::UInt32)

    ScreenSize::Int = app.width * app.height

    for y = 0:app.height-1

        for x = 0:app.width-1
        
        app.ColorBuffer[y*app.width + x + 1] = color
        
        end
    end
    
end




function ClearZBuffer(app::AppState)
    fill!(app.zBuffer, Inf32)
end



function LerpColorARGB(colorA::UInt32, colorB::UInt32, t::Float32)::UInt32
    t = clamp(t, 0.0f0, 1.0f0)

    a1 = (colorA >> 24) & 0xff
    r1 = (colorA >> 16) & 0xff
    g1 = (colorA >> 8) & 0xff
    b1 = colorA & 0xff

    a2 = (colorB >> 24) & 0xff
    r2 = (colorB >> 16) & 0xff
    g2 = (colorB >> 8) & 0xff
    b2 = colorB & 0xff

    a = UInt32(round(Int, Float32(a1) + (Float32(a2) - Float32(a1)) * t))
    r = UInt32(round(Int, Float32(r1) + (Float32(r2) - Float32(r1)) * t))
    g = UInt32(round(Int, Float32(g1) + (Float32(g2) - Float32(g1)) * t))
    b = UInt32(round(Int, Float32(b1) + (Float32(b2) - Float32(b1)) * t))

    return (a << 24) | (r << 16) | (g << 8) | b
end



function ApplyFog(color::UInt32, distance::Float32)::UInt32
    fogAmount = (distance - FOG_START) / (FOG_END - FOG_START)
    fogAmount = clamp(fogAmount, 0.0f0, 1.0f0)

    return LerpColorARGB(color, FOG_COLOR, fogAmount)
end



function DrawColoredPixel(x::Int, y::Int, a::Vec4, b::Vec4, c::Vec4, auv::Tex2, buv::Tex2, cuv::Tex2, color::UInt32, app::AppState)

    if x < 0 || x >= app.width || y < 0 || y >= app.height
        return
    end

    au::Float32 = auv.u
    av::Float32 = auv.v

    bu::Float32 = buv.u
    bv::Float32 = buv.v

    cu::Float32 = cuv.u
    cv::Float32 = cuv.v

    av = 1 - av
    bv = 1 - bv
    cv = 1 - cv
    
    Vec2Point::Vec2 = Vec2(Float32(x), Float32(y))
    PointA::Vec2 = MakeVec2FromVec4(a.x, a.y, a.z, a.w)
    PointB::Vec2 = MakeVec2FromVec4(b.x, b.y, b.z, b.w)
    PointC::Vec2 = MakeVec2FromVec4(c.x, c.y, c.z, c.w)
    Weights::Vec3 = BarycentricWeights(Vec2Point, PointA, PointB, PointC)

    InterpolatedU::Float32 = (au / a.w) * Weights.x + (bu / b.w) * Weights.y + (cu / c.w) * Weights.z
    InterpolatedV::Float32 = (av / a.w) * Weights.x + (bv / b.w) * Weights.y + (cv / c.w) * Weights.z
    IntepolatedReversedW::Float32 = (1 / a.w) * Weights.x + (1 / b.w) * Weights.y + (1 / c.w) * Weights.z

    InterpolatedU /= IntepolatedReversedW
    InterpolatedV /= IntepolatedReversedW


    #Depth = 1.0f0 - IntepolatedReversedW
    
    #distance::Float32 = 1.0f0 / IntepolatedReversedW

    Depth::Float32 = 1.0f0 / IntepolatedReversedW
    distance::Float32 = Depth

    Index = app.width * y + x + 1

    if Depth < app.zBuffer[Index]

        baseColor::UInt32 = color

        if CurrDisplayState == TEXTURE || CurrDisplayState == TEXTURE_WIREFRAME

            baseColor = SampleTexture(app.Texture, InterpolatedU, InterpolatedV)
        end

        DrawPixel!(app, x, y, baseColor)
        app.zBuffer[Index] = Depth
        
    end

#inner if


    #texX = abs(trunc(Int, InterpolatedU * app.Texture.width)) % app.Texture.width
    #texY = abs(trunc(Int, InterpolatedV * app.Texture.height)) % app.Texture.height

    #TIndex = app.Texture.width * texY + texX + 1


    #baseColor = app.Texture.pixels[TIndex]

end



function SampleTexture(texture::Texture, u::Float32, v::Float32)::UInt32
    u = clamp(u, 0.0f0, 1.0f0)
    v = clamp(v, 0.0f0, 1.0f0)

    texX = floor(Int, u * Float32(texture.width - 1))
    texY = floor(Int, v * Float32(texture.height - 1))

    index = texY * texture.width + texX + 1
    return texture.pixels[index]
end


function TransformOneFace(VerticesToTransform::Vector{Vec4}, app::AppState)::Vector{Vec4}

    M::Matrix{Float32} = MakeIdentity()

    ScaleMat::Matrix{Float32} = MakeScale(app.Mesh.Scale.x, app.Mesh.Scale.y, app.Mesh.Scale.z)
    RotationMatX::Matrix{Float32} = RotateX(app.Mesh.Rotation.x)
    RotationMatY::Matrix{Float32} = RotateY(app.Mesh.Rotation.y)
    RotationMatZ::Matrix{Float32} = RotateZ(app.Mesh.Rotation.z)
    TranslateMat::Matrix{Float32} = MakeTranslation(app.Mesh.Translation.x, app.Mesh.Translation.y, app.Mesh.Translation.z)


    M = ScaleMat * M
    M = RotationMatX * M
    M = RotationMatY * M
    M = RotationMatZ * M
    M = TranslateMat * M

    transformed = Vector{Vec4}(undef, 3)

    transformed[1] = MulMat4Vec4(M, VerticesToTransform[1])
    transformed[2] = MulMat4Vec4(M, VerticesToTransform[2])
    transformed[3] = MulMat4Vec4(M, VerticesToTransform[3])


    return transformed

end




function RotateXVec(v::Vec3, angle::Vec3)
    c = cos(angle.x)
    s = sin(angle.x)

    return Vec3(
        v.x,
        Float32(v.y * c - v.z * s),
        Float32(v.y * s + v.z * c)
    )
end





function DrawDigit7Seg!(
    app::AppState,
    digit::Int,
    x::Int,
    y::Int,
    scale::Int,
    color::UInt32
)
    t = 2 * scale
    w = 12 * scale
    h = 20 * scale
    half = h ÷ 2

    # segments:
    #   A
    # F   B
    #   G
    # E   C
    #   D

    segments = Dict(
        0 => (true, true, true, true, true, true, false),
        1 => (false, true, true, false, false, false, false),
        2 => (true, true, false, true, true, false, true),
        3 => (true, true, true, true, false, false, true),
        4 => (false, true, true, false, false, true, true),
        5 => (true, false, true, true, false, true, true),
        6 => (true, false, true, true, true, true, true),
        7 => (true, true, true, false, false, false, false),
        8 => (true, true, true, true, true, true, true),
        9 => (true, true, true, true, false, true, true)
    )

    A, B, C, D, E, F, G = segments[digit]

    if A
        DrawRect!(app, x + t, y, w - 2t, t, color)
    end

    if B
        DrawRect!(app, x + w - t, y + t, t, half - t, color)
    end

    if C
        DrawRect!(app, x + w - t, y + half, t, half - t, color)
    end

    if D
        DrawRect!(app, x + t, y + h - t, w - 2t, t, color)
    end

    if E
        DrawRect!(app, x, y + half, t, half - t, color)
    end

    if F
        DrawRect!(app, x, y + t, t, half - t, color)
    end

    if G
        DrawRect!(app, x + t, y + half - t ÷ 2, w - 2t, t, color)
    end
end



function DrawNumber7Seg!(
    app::AppState,
    value::Int,
    x::Int,
    y::Int,
    scale::Int,
    color::UInt32
)
    text = string(value)

    cursorX = x
    spacing = 15 * scale

    for ch in text
        digit = parse(Int, string(ch))
        DrawDigit7Seg!(app, digit, cursorX, y, scale, color)
        cursorX += spacing
    end
end



function DrawFPSOverlay!(app::AppState)
    fps = round(Int, app.CurrentFPS)

    # black background box
    DrawRect!(app, 10, 10, 110, 40, 0xFF000000)

    # green FPS number
    DrawNumber7Seg!(app, fps, 20, 18, 1, 0xFF00FF00)
end
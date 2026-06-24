using MiniFB
include("Vec4.jl")
include("Vec2.jl")
include("Triangle.jl")
include("TestCube.jl")
include("Vec3.jl")
include("Window.jl")
include("Texture.jl")
include("Camera.jl")
include("Renderer.jl")
include("Light.jl")
include("Matrix.jl")
include("OBJHandle.jl")
include("DisplayState.jl")

const FPS = 120
const FRAME_TARGET_TIME = 1.0 / FPS

const FOG_COLOR = UInt32(0xff808080)
const FOG_START = 8.0f0
const FOG_END = 25.0f0

ShouldCull = false
Fog = false

function WaitForNextFrame!(app::AppState)
    elapsed = time() - app.PrevFrameTime
    timeToWait = FRAME_TARGET_TIME - elapsed
    if timeToWait > 0.0 && timeToWait <= FRAME_TARGET_TIME
        sleep(timeToWait)
    end
    app.PrevFrameTime = time()
end



function key_down(window, key)
    keyBuffer = mfb_get_key_buffer(window)

    return unsafe_load(keyBuffer, Int(key) + 1) != 0
end


function HandleInput!(app::AppState, deltaTime::Float32)
    
    
    
    global CurrDisplayState
    global ShouldCull
    global Fog


    if key_down(app.window, MiniFB.KB_KEY_ESCAPE)
        app.bIsRunning = false
    end


    # Display modes
    if key_down(app.window, MiniFB.KB_KEY_1)
        CurrDisplayState = WIREFRAME
    end

    if key_down(app.window, MiniFB.KB_KEY_2)
        CurrDisplayState = FILLED
    end

    if key_down(app.window, MiniFB.KB_KEY_3)
        CurrDisplayState = FILLED_WIREFRAME
    end

    if key_down(app.window, MiniFB.KB_KEY_4)
        CurrDisplayState = TEXTURE
    end

    if key_down(app.window, MiniFB.KB_KEY_5)
        CurrDisplayState = TEXTURE_WIREFRAME
    end

    # Culling on/off
    if key_down(app.window, MiniFB.KB_KEY_Y)
        ShouldCull = true
    end

    if key_down(app.window, MiniFB.KB_KEY_N)
        ShouldCull = false
    end

    if key_down(app.window, MiniFB.KB_KEY_F)

        Fog = true
    
    end

    if key_down(app.window, MiniFB.KB_KEY_G)

        Fog = false

    end

    moveSpeed = 5.0f0
    turnSpeed = 2.0f0

    forward = GetCameraDirection(app)

    if key_down(app.window, MiniFB.KB_KEY_W)
        app.Camera.CamPos = app.Camera.CamPos + forward * (moveSpeed * deltaTime)
    end

    if key_down(app.window, MiniFB.KB_KEY_S)
        app.Camera.CamPos = app.Camera.CamPos - forward * (moveSpeed * deltaTime)
    end

    if key_down(app.window, MiniFB.KB_KEY_UP)
        app.Camera.CamPos = Vec3(
            app.Camera.CamPos.x,
            app.Camera.CamPos.y + moveSpeed * deltaTime,
            app.Camera.CamPos.z
        )
    end

    if key_down(app.window, MiniFB.KB_KEY_DOWN)
        app.Camera.CamPos = Vec3(
            app.Camera.CamPos.x,
            app.Camera.CamPos.y - moveSpeed * deltaTime,
            app.Camera.CamPos.z
        )
    end

    if key_down(app.window, MiniFB.KB_KEY_RIGHT)
        app.Camera.CamTurnDegree += turnSpeed * deltaTime
    end

    if key_down(app.window, MiniFB.KB_KEY_LEFT)
        app.Camera.CamTurnDegree -= turnSpeed * deltaTime
    end
end



function GetCameraDirection(app::AppState)::Vec3
    return Normalize(Vec3(
        sin(app.Camera.CamTurnDegree),
        0.0f0,
        cos(app.Camera.CamTurnDegree)
    ))
end


function ApplyFogToWholeScreen!(app::AppState)
    for y in 0:app.height-1
        for x in 0:app.width-1
            index = y * app.width + x + 1

            if app.zBuffer[index] == Inf32
                app.ColorBuffer[index] = FOG_COLOR
            else
                depth = app.zBuffer[index]
                app.ColorBuffer[index] = ApplyFog(app.ColorBuffer[index], depth)
            end
        end
    end
end

function Update!(app)

    ClearColorBuffer!(app, 0x00000000)
    ClearZBuffer(app)

    app.Mesh.Rotation = Vec3(
        app.Mesh.Rotation.x, #+ 0.02f0,
        app.Mesh.Rotation.y + 0.015f0,
        app.Mesh.Rotation.z
    )

    NumFaces::Int = length(app.Mesh.Faces)


    culledCount = 0
    drawnCount = 0


    LookTarget::Vec3 = Vec3(0,0,1)

    CamRot = RotateY(app.Camera.CamTurnDegree)

    temp = MulMat4Vec4(CamRot, MakeVec4FromVec3(LookTarget.x, LookTarget.y, LookTarget.z))

    #app.Camera.CamDir = MakeVec3FromVec4(temp.x, temp.y, temp.z, temp.w)

    camdir = GetCameraDirection(app)

    LookTarget = app.Camera.CamPos + camdir # app.Camera.CamDir

    Up::Vec3 = Vec3(0, 1, 0)

    ViewMat = LookAtItem(app.Camera.CamPos, LookTarget, Up)

    aspect = Float32(app.width) / Float32(app.height)

    ProjectionMat = MakePerspective(
        Float32(pi / 3),
        aspect,
        0.1f0,
        100.0f0
    )


    for i in 1:NumFaces

        CurrFace::Face = app.Mesh.Faces[i]

        v1 = app.Mesh.Vertices[CurrFace.a]
        v2 = app.Mesh.Vertices[CurrFace.b]
        v3 = app.Mesh.Vertices[CurrFace.c]

        FaceVectors = Vec4[
            MakeVec4FromVec3(v1.x, v1.y, v1.z),
            MakeVec4FromVec3(v2.x, v2.y, v2.z),
            MakeVec4FromVec3(v3.x, v3.y, v3.z)
        ]

        FaceUVs = Tex2[

            CurrFace.a_uv,
            CurrFace.b_uv,
            CurrFace.c_uv

        ]

        TransformedVertices = TransformOneFace(FaceVectors, app)
        TransformedVertices[1] = MulMat4Vec4(ViewMat, TransformedVertices[1])
        TransformedVertices[2] = MulMat4Vec4(ViewMat, TransformedVertices[2])
        TransformedVertices[3] = MulMat4Vec4(ViewMat, TransformedVertices[3])
        TransformedVerticesForCull = Vector{Vec3}(undef, 3)

        TransformedVerticesForCull[1] = MakeVec3FromVec4(TransformedVertices[1].x, TransformedVertices[1].y, TransformedVertices[1].z, TransformedVertices[1].w)
        TransformedVerticesForCull[2] = MakeVec3FromVec4(TransformedVertices[2].x, TransformedVertices[2].y, TransformedVertices[2].z, TransformedVertices[2].w)
        TransformedVerticesForCull[3] = MakeVec3FromVec4(TransformedVertices[3].x, TransformedVertices[3].y, TransformedVertices[3].z, TransformedVertices[3].w)



        if (ShouldCull == true)


            if IsCulled(TransformedVerticesForCull)

                culledCount += 1

                continue

            end

        end


        drawnCount += 1


        CalculatedLightColor::UInt32 = CalculateColor(TransformedVerticesForCull, app.LightDir, 0x00FFFFFF)

        #Calc Fog in draw colored pixels

        if (CurrDisplayState == FILLED || CurrDisplayState == TEXTURE || CurrDisplayState == FILLED_WIREFRAME || CurrDisplayState == TEXTURE_WIREFRAME)

            DrawMeshFilled(app, TransformedVertices, FaceUVs, CalculatedLightColor, ProjectionMat)
        end

        if (CurrDisplayState == WIREFRAME || CurrDisplayState == FILLED_WIREFRAME || CurrDisplayState == TEXTURE_WIREFRAME)

            DrawMeshWireframe!(app, TransformedVertices, 0x0000DD00, ProjectionMat)
        end
    
    end
    

    if (Fog)
    
        ApplyFogToWholeScreen!(app) #if turned off, the clear color buffer takes over with black each frame

    end

    DrawFPSOverlay!(app)

    #println("drawn = ", drawnCount, " culled = ", culledCount)

end



function Render!(app)
    state = mfb_update(app.window, app.ColorBuffer)
    if state != MiniFB.STATE_OK
        app.bIsRunning = false
    end
end



function UpdateFPS!(app::AppState)
    app.FrameCount += 1
    elapsed = time() - app.FpsTimer
    if elapsed >= 1.0
        app.CurrentFPS = Float32(app.FrameCount / elapsed)
        app.FrameCount = 0
        app.FpsTimer = time()
    end
end



    function main()

        app = InitWin()
        lastTime = time()

        while app.bIsRunning
            
            WaitForNextFrame!(app)

            currentTime = time()
            deltaTime = Float32(currentTime - lastTime)
            lastTime = currentTime

            HandleInput!(app, deltaTime)
            Update!(app)
            

            Render!(app)

            UpdateFPS!(app)
        end
    end


main()
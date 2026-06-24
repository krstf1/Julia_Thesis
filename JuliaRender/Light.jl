



function CalcLightIntensity(Vertices::Vector{Vec3}, LocalLight::Vec3)::Float32
    
    NormalVec::Vec3 = Vec3Normal(Vertices[1], Vertices[2], Vertices[3])
    NormalizedVec::Vec3 = Normalize(NormalVec)
    NormalizedLightRay::Vec3 = Normalize(LocalLight)
    DotProd::Float32 = - Vec3Dot(NormalizedLightRay, NormalizedVec)

    if (DotProd < 0) DotProd = 0 end
    if (DotProd > 1) DotProd = 1 end

    return DotProd
end



function ApplyLight(originalColor::UInt32, percentageFactor::Float32)::UInt32
    a = originalColor & 0xff000000
    r = (originalColor >> 16) & 0xff
    g = (originalColor >> 8) & 0xff
    b = originalColor & 0xff

    r = UInt32(clamp(round(Int, Float32(r) * percentageFactor), 0, 255))
    g = UInt32(clamp(round(Int, Float32(g) * percentageFactor), 0, 255))
    b = UInt32(clamp(round(Int, Float32(b) * percentageFactor), 0, 255))

    return a | (r << 16) | (g << 8) | b
end

function CalculateColor(vertices::Vector{Vec3}, LocalLight::Vec3, OriginalColor::UInt32)::UInt32

    Dot::Float32 = CalcLightIntensity(vertices, LocalLight)
    res::UInt32 = ApplyLight(OriginalColor, Dot)
    
    return res

end
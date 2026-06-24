using FileIO
using PNGFiles
using ColorTypes

struct Texture
    width::Int
    height::Int
    pixels::Vector{UInt32}
end

function PackRGBA(r::UInt8, g::UInt8, b::UInt8, a::UInt8)::UInt32
    return (UInt32(a) << 24) |
           (UInt32(r) << 16) |
           (UInt32(g) << 8) |
           UInt32(b)
end

function LoadTextureFromPNG(filename::String)::Texture
    img = load(filename)
    height, width = size(img)
    pixels = Vector{UInt32}(undef, width * height)

    for y in 1:height
        for x in 1:width
            c = RGBA{Float32}(img[y, x])

            r = round(UInt8, clamp(c.r, 0.0f0, 1.0f0) * 255.0f0)
            g = round(UInt8, clamp(c.g, 0.0f0, 1.0f0) * 255.0f0)
            b = round(UInt8, clamp(c.b, 0.0f0, 1.0f0) * 255.0f0)
            a = round(UInt8, clamp(c.alpha, 0.0f0, 1.0f0) * 255.0f0)

            index = (y - 1) * width + x
            pixels[index] = PackRGBA(r, g, b, a)
        end
    end
    return Texture(width, height, pixels)
end
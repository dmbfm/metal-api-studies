#include <metal_stdlib>

using namespace metal;

struct Vertex {
    float2 position [[ attribute(0) ]];
    float2 uv [[ attribute(1) ]];
};

struct FragmentData {
    float4 position [[ position ]];
    float2 uv;
};


vertex 
FragmentData vertex_shader(Vertex in [[ stage_in ]], constant uint2 *viewport_size [[ buffer(1) ]]) {
    FragmentData out;

    float2 pixel_coords = in.position;
    float2 viewport = float2(*viewport_size);
    float2 clip_coords = pixel_coords / (viewport/2) - 1;
    clip_coords.y *= -1;

    out.position = float4(clip_coords.x, clip_coords.y, 0, 1);
    out.uv = in.uv;

    return out;
}

fragment
float4 fragment_shader(FragmentData in [[ stage_in ]], texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler s (mag_filter::nearest, min_filter::nearest);

    return texture.sample(s, in.uv);
    /* return float4(1, 0, 0, 1); */
}


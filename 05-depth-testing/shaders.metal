#include <metal_stdlib>

using namespace metal;

struct Vertex {
    float3 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
};

struct FragmentData {
    float4 position [[ position ]];
    float4 color;
};

vertex FragmentData
vertex_shader(Vertex in [[ stage_in ]], constant uint2 &viewport_size [[ buffer(1) ]]) {
    FragmentData out;

    out.position = float4(0, 0, 0, 1);

    float2 screen_pixel_pos = in.position.xy;
    float2 viewport = float2(viewport_size);

    float2 top_down_position = (screen_pixel_pos / (viewport / 2.0)) - 1.0;
    out.position.x = top_down_position.x;
    out.position.y = -top_down_position.y;
    out.position.z = in.position.z;
    out.color = in.color;

    return out;
}

fragment float4
fragment_shader(FragmentData in [[ stage_in ]]) {
    return in.color;
}

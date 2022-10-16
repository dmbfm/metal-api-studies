#include <metal_stdlib>

using namespace metal;

struct Vertex {
    float2 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
};

struct FragmentData {
    float4 position [[ position ]];
    float4 color;
};

vertex FragmentData
vertex_shader(Vertex in [[ stage_in ]], constant uint2 &viewport_size [[ buffer(1) ]]) {
    FragmentData out;

    float2 vp = float2(viewport_size);
    out.position = float4(0, 0, 0, 1);
    out.position.xy = in.position / (vp / 2.0) - 1;
    out.color = in.color;

    return out;
}

fragment float4
fragment_shader(FragmentData in [[ stage_in ]]) {
    return in.color;
}

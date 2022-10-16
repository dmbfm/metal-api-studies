#include <metal_stdlib>
#include <simd/simd.h>


using namespace metal;

struct VertexPC {
    float3 pos [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexPT {
    float3 pos [[attribute(0)]];
    float2 texcoord [[attribute(1)]];
};

struct VertexOutPC {
    float4 pos [[position]];
    float4 color;
};

struct VertexOutPT {
    float4 pos [[position]];
    float2 texcoord;
};

vertex VertexOutPC
basic_vertex(VertexPC in [[ stage_in ]]) {
    VertexOutPC out;
    
    out.pos = float4(in.pos, 1.0);
    out.color = in.color;
    
    return out;
}

fragment float4 basic_fragment(VertexOutPC in [[ stage_in ]]) {
    return in.color;
}


vertex VertexOutPT
texture_vertex_shader(VertexPT in [[ stage_in ]]) {
    VertexOutPT out;

    out.pos = float4(in.pos, 1.0);
    out.texcoord = in.texcoord;

    return out;
}

fragment float4
texture_fragment_shader(VertexOutPT in [[ stage_in ]], texture2d<float> texture [[texture(0)]]) {
    sampler s;

    float4 color = texture.sample(s, in.texcoord);

    return color;
}



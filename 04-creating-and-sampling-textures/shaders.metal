#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct VertexP2T2 {
    float2 position [[attribute(0)]];
    float2 texcoord [[attribute(1)]];
};

struct Vertexp2T2Out {
    float4 position [[ position ]];
    float2 texcoord;
};

vertex Vertexp2T2Out
vertex_shader(VertexP2T2 in [[ stage_in ]],
              constant vector_uint2 *viewportSizePtr [[ buffer(1) ]]) {
    Vertexp2T2Out out;

    float2 viewportSize = float2(*viewportSizePtr);

    out.position = float4(0, 0, 0, 1);
    out.position.xy = in.position.xy / (viewportSize / 2);
    out.texcoord = in.texcoord;

    return out;
}


fragment float4 
fragment_shader(Vertexp2T2Out in [[ stage_in ]], 
                texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler s (mag_filter::linear, min_filter::linear);

    float4 col = texture.sample(s, in.texcoord);

    return col;
}

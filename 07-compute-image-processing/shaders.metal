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

vertex FragmentData
vertex_shader(Vertex in [[ stage_in ]], constant uint2 &viewport_size [[ buffer(1) ]]) {
    FragmentData out;

    float2 pixel_pos = in.position.xy;
    float2 viewport = float2(viewport_size);

    float2 clip_pos = pixel_pos / (viewport/2);

    out.position = float4(clip_pos, 0, 1);
    out.uv = in.uv;

    return out;
}

fragment float4
fragment_shader(FragmentData in [[ stage_in ]], texture2d<half> texture [[ texture(0) ]]) {
    constexpr sampler s (mag_filter::linear, min_filter::linear);

    half4 col = texture.sample(s, in.uv);
    return float4(col);
}

// Compute kernels
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

kernel void
grayscale_kernel(texture2d<half, access::read> in_texture [[ texture(0) ]], 
                 texture2d<half, access::write> out_texture [[ texture(1) ]],
                 uint2 gid [[ thread_position_in_grid ]], constant float *bias [[ buffer(0) ]] ) {
                 
    half4 input_color = in_texture.read(gid);
    half gray = dot(input_color.rgb, kRec709Luma + half3((half)*bias, (half)*bias, (half)*bias));
    out_texture.write(half4(gray, gray, gray, 1.0), gid);
}

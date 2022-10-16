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

struct UniformData {
    float4x4 view_matrix;
    float4x4 proj_matrix;
};

vertex 
FragmentData vertex_shader(Vertex in [[ stage_in ]], constant UniformData *u [[ buffer(1) ]]) {
    FragmentData out;

    //out.position = float4(in.position, 1.0);
    out.position = u->proj_matrix * u->view_matrix * float4(in.position, 1.0);
    out.color = in.color;

    return out;
}

fragment
float4 fragment_shader(FragmentData in [[ stage_in ]]) {
    return in.color;
}


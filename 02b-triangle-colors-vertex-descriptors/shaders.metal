

struct VertexIn {
    float3 pos [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

vertex VertexOut
basic_vertex(VertexIn in [[ stage_in ]]) {
    VertexOut out;
    out.pos = float4(in.pos, 1.0);
    out.color = in.color;
    return out;
}


fragment float4 basic_fragment(VertexOut in [[ stage_in ]]) {
    return in.color;
}

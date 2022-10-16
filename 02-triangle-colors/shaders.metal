struct VertexOut {
    float4 pos [[position]];
    float4 color;
};

vertex VertexOut
basic_vertex(const device packed_float3* vertex_array [[buffer(0)]],
             const device packed_float4* vertex_colors [[buffer(1)]],
             unsigned int vertex_id [[ vertex_id ]]) {
    VertexOut out;
    out.pos = float4(vertex_array[vertex_id], 1.0);
    out.color = vertex_colors[vertex_id];
    return out;
}


fragment float4 basic_fragment(VertexOut in [[ stage_in ]]) {
    return in.color;
}

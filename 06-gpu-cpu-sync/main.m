#include <stdio.h>
#include <stdint.h>
#include <math.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#define APP_IMPLEMENTATION
#include "../common/app.h"

#define PI 3.14159265359

enum {
    NumTriangles = 50,
    NumInFlightFrames = 3,
};

static const float TriangleSize = 50;
static const unsigned int viewport[2] = { 800, 600 };
static const float colors[6][4] = {
    { 1.0, 0.0, 0.0, 1.0 },  // Red
    { 0.0, 1.0, 0.0, 1.0 },  // Green
    { 0.0, 0.0, 1.0, 1.0 },  // Blue
    { 1.0, 0.0, 1.0, 1.0 },  // Magenta
    { 0.0, 1.0, 1.0, 1.0 },  // Cyan
    { 1.0, 1.0, 0.0, 1.0 },  // Yellow
};

typedef struct {
    dispatch_semaphore_t semaphore;
    int current_buffer;
    
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> render_pipeline_state;
    id<MTLBuffer> vertex_buffers[NumInFlightFrames];
    id<MTLBuffer> uniform_buffer;
    float triangle_positions[2 * NumTriangles];
    double time;
} State;

static State state;

typedef struct {
    float position[2];
    float color[4];
} Vertex;

void exit_with_error(NSError *error) {
    NSLog(@"%@\n", error);
    exit(1);
}

void triangle_at(float x, float y, float r, float g, float b, Vertex *ptr) {
    ptr[0] = (Vertex){ {x, y}, { r, g, b, 1} };
    ptr[1] = (Vertex){ {x + TriangleSize, y}, {r, g, b, 1} };
    ptr[2] = (Vertex){ { x + 0.5 * TriangleSize, y + 0.8860 * TriangleSize }, { r, g, b, 1}};
}

void update_triangles() {
    const float amplitude = 80.0;
    for (int i = 0; i < NumTriangles; i++) {
        float x =  ((730.0/NumTriangles) * i);
        state.triangle_positions[2 * i] = x;
        state.triangle_positions[2 * i + 1] = (600.0/2 - amplitude/2 - ((float)TriangleSize/2)) +  amplitude * ( 1 + sin(x/300 * state.time));
    }

    Vertex *vertices = [state.vertex_buffers[state.current_buffer] contents];

    for (int i = 0; i < NumTriangles; i++) {
        const float *color = colors[i % 6];
        triangle_at(state.triangle_positions[2 * i], state.triangle_positions[2*i +1], color[0], color[1], color[2], &vertices[3*i]);
    }
}

void init() {
    NSError *error;

    state.semaphore = dispatch_semaphore_create(NumInFlightFrames);
    
    state.command_queue = [app.device newCommandQueue];

    id<MTLLibrary> library = [app.device newLibraryWithFile:@"MyLibrary.metallib" error:&error];
    if (!library) {
        exit_with_error(error);
    }

    id<MTLFunction> vertex_function = [library newFunctionWithName:@"vertex_shader"];
    id<MTLFunction> fragment_function = [library newFunctionWithName:@"fragment_shader"];

    MTLVertexDescriptor *vertex_descriptor = [[MTLVertexDescriptor alloc] init];
    vertex_descriptor.attributes[0].format = MTLVertexFormatFloat2;
    vertex_descriptor.attributes[0].offset = 0;
    vertex_descriptor.attributes[0].bufferIndex = 0;
    vertex_descriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertex_descriptor.attributes[1].offset = 2 * sizeof(float);
    vertex_descriptor.attributes[1].bufferIndex = 0;
    vertex_descriptor.layouts[0].stride = sizeof(Vertex);
    vertex_descriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    MTLRenderPipelineDescriptor *render_pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    render_pipeline_desc.label = @"main render pipeline";
    render_pipeline_desc.vertexFunction = vertex_function;
    render_pipeline_desc.fragmentFunction = fragment_function;
    render_pipeline_desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    render_pipeline_desc.vertexDescriptor = vertex_descriptor;
    render_pipeline_desc.vertexBuffers[0].mutability = MTLMutabilityImmutable;

    state.render_pipeline_state = [app.device newRenderPipelineStateWithDescriptor:render_pipeline_desc error:&error];
    if (!state.render_pipeline_state) {
        exit_with_error(error);
    }

    for (int i = 0; i < NumInFlightFrames; i++) {
        state.vertex_buffers[i] = [app.device newBufferWithLength:NumTriangles * 3 * sizeof(Vertex) options:MTLResourceCPUCacheModeDefaultCache];
    }
    state.uniform_buffer = [app.device newBufferWithBytes:&viewport length:sizeof(viewport) options:MTLResourceCPUCacheModeDefaultCache];

    [vertex_descriptor release];
    [fragment_function release];
    [vertex_function release];
    [library release];
    [render_pipeline_desc release];
}

void frame() {
    dispatch_semaphore_wait(state.semaphore, DISPATCH_TIME_FOREVER);
    
    state.time += 0.01;
    state.current_buffer = (state.current_buffer + 1) % NumInFlightFrames;
    update_triangles();
    
    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];
    MTLRenderPassDescriptor *render_pass_desc = app.view.currentRenderPassDescriptor;

    id<MTLRenderCommandEncoder> render_command_encoder = [command_buffer renderCommandEncoderWithDescriptor:render_pass_desc];
    [render_command_encoder setRenderPipelineState:state.render_pipeline_state];
    [render_command_encoder setVertexBuffer:state.vertex_buffers[state.current_buffer] offset:0 atIndex:0];
    [render_command_encoder setVertexBuffer:state.uniform_buffer offset:0 atIndex:1];
    [render_command_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:(3*NumTriangles)];
    [render_command_encoder endEncoding];
    
    [command_buffer presentDrawable:app.view.currentDrawable];

    __block dispatch_semaphore_t sem = state.semaphore;
    [command_buffer addCompletedHandler:^(id<MTLCommandBuffer> buffer){
        dispatch_semaphore_signal(sem);
    }];
    
    [command_buffer commit];
}

void deinit(){
    [state.render_pipeline_state release];
    [state.command_queue release];
}

int main(int argc, char **argv) {
    AppDesc desc = { "06-gpu-cpu-sync", init, frame, deinit};
    app_init(desc);
}



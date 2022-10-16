#include <stdio.h>
#include <stdint.h>
#include <math.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#define APP_IMPLEMENTATION
#include "../common/app.h"

typedef struct {
    float leftVertexDepth;
    float topVertexDepth;    
    float rightVertexDepth;   
    
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> render_pipeline_state;
    id<MTLBuffer> quad_buffer;
    id<MTLBuffer> tri_buffer;
    id<MTLBuffer> uniform_buffer;
    id<MTLDepthStencilState> depth_state;
} State;

static State state;

typedef struct {
    float position[3];
    float color[4];
} Vertex;

static int viewport_size[2] = { 800, 600 };

static const Vertex quad_vertices[6] = {
    { {     100,     100, 0.5 }, { 0.5, 0.5, 0.5, 1 } },
    { {     100, 600-100, 0.5 }, { 0.5, 0.5, 0.5, 1 } },
    { { 800-100, 600-100, 0.5 }, { 0.5, 0.5, 0.5, 1 } },

    { {     100,     100, 0.5 }, { 0.5, 0.5, 0.5, 1 } },
    { { 800-100, 600-100, 0.5 }, { 0.5, 0.5, 0.5, 1 } },
    { { 800-100,     100, 0.5 }, { 0.5, 0.5, 0.5, 1 } },
};


void init() {
    NSError *error;
    state.command_queue = [app.device newCommandQueue];

    id<MTLLibrary> library = [app.device newLibraryWithFile:@"MyLibrary.metallib" error:&error];
    if (!library) {
        NSLog(@"%@\n", error);
        exit(1);
    }

    id<MTLFunction> vertex_function = [library newFunctionWithName:@"vertex_shader"];
    if (!vertex_function) {
        NSLog(@"error: vertex function not found!");
        exit(1);
    }
    
    id<MTLFunction> fragment_function = [library newFunctionWithName:@"fragment_shader"];
    if (!vertex_function) {
        NSLog(@"error: fragment function not found!");
        exit(1);
    }

    MTLVertexDescriptor *vertex_descriptor = [[MTLVertexDescriptor alloc] init];
    vertex_descriptor.attributes[0].offset = 0;
    vertex_descriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertex_descriptor.attributes[0].bufferIndex = 0;
    vertex_descriptor.attributes[1].offset = 3 * sizeof(float);
    vertex_descriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertex_descriptor.attributes[1].bufferIndex = 0;
    vertex_descriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    vertex_descriptor.layouts[0].stride = sizeof(Vertex);


    MTLRenderPipelineDescriptor *pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipeline_descriptor.label = @"default";
    pipeline_descriptor.vertexFunction = vertex_function;
    pipeline_descriptor.fragmentFunction = fragment_function;
    pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipeline_descriptor.vertexDescriptor = vertex_descriptor;

    state.render_pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_descriptor error:&error];
    if (!state.render_pipeline_state) {
         NSLog(@"%@\n", error);
         exit(1);
    }

    state.quad_buffer = [app.device newBufferWithBytes:quad_vertices length:sizeof(quad_vertices) options:MTLResourceCPUCacheModeDefaultCache];
    state.tri_buffer = [app.device newBufferWithLength:3 * sizeof(Vertex) options:MTLResourceCPUCacheModeDefaultCache | MTLResourceStorageModeShared];
    state.uniform_buffer = [app.device newBufferWithBytes:&viewport_size length:sizeof(viewport_size) options:MTLResourceCPUCacheModeDefaultCache];

    MTLDepthStencilDescriptor *depth_descriptor = [[MTLDepthStencilDescriptor alloc] init];
    depth_descriptor.depthCompareFunction = MTLCompareFunctionLessEqual;
    depth_descriptor.depthWriteEnabled = true;
    state.depth_state = [app.device newDepthStencilStateWithDescriptor:depth_descriptor];

    state.leftVertexDepth = 0.5;
    state.rightVertexDepth = 0.5;
    state.topVertexDepth = 0.5;
    
    [depth_descriptor release];
    [pipeline_descriptor release];
    [vertex_descriptor release];
    [vertex_function release];
    [fragment_function release];
    [library release];
}

float t = 0;
void frame() {
    app.view.clearColor = MTLClearColorMake(0, 0, 0, 1);

    t += 0.01;

    float s = sin(t);
    float c = cos(t);
    
    state.topVertexDepth = s * 0.25;
    state.leftVertexDepth = c * 0.25;
    state.rightVertexDepth = s * c * 0.25 * 0.25;
    
    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];

    MTLRenderPassDescriptor *render_pass_descriptor = app.view.currentRenderPassDescriptor;
    if (render_pass_descriptor != nil) {
        id<MTLRenderCommandEncoder> render_command_encoder = [command_buffer renderCommandEncoderWithDescriptor:render_pass_descriptor];

        [render_command_encoder setRenderPipelineState:state.render_pipeline_state];
        [render_command_encoder setDepthStencilState:state.depth_state];
        [render_command_encoder setVertexBuffer:state.quad_buffer offset:0 atIndex:0];
        [render_command_encoder setVertexBuffer:state.uniform_buffer offset:0 atIndex:1];
        [render_command_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        const Vertex tri_vertices[3] = {
            { {        200, 600 - 200, state.leftVertexDepth  }, { 1, 1, 1, 1 } },
            { {  800 / 2.0,       200, state.topVertexDepth   }, { 1, 1, 1, 1 } },
            { {  800 - 200, 600 - 200, state.rightVertexDepth }, { 1, 1, 1, 1 } }  
        };

        memcpy(state.tri_buffer.contents, tri_vertices, sizeof(tri_vertices));
        [render_command_encoder setVertexBuffer:state.tri_buffer offset:0 atIndex:0];
        [render_command_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

        [render_command_encoder endEncoding];
        [command_buffer presentDrawable:app.view.currentDrawable];
    }

    [command_buffer commit];
}

void deinit(){
    [state.uniform_buffer release];
    [state.tri_buffer release];
    [state.quad_buffer release];
    [state.render_pipeline_state release];
    [state.command_queue release];
}

int main(int argc, char **argv) {
    AppDesc desc = { "05-depth-testing", init, frame, deinit};
    app_init(desc);
}



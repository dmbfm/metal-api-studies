#include <stdio.h>
#include <stdint.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#define APP_IMPLEMENTATION
#include "../common/app.h"

typedef struct {
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> pipeline_state;
    id<MTLBuffer> vertex_buffer;
} State;

static State state;

static float vertex_data[9] = {
     0.0,  1.0, 0.0,
    -1.0, -1.0, 0.0,
     1.0, -1.0, 0.0
} ;

void init() {
    NSLog(@"initzz!");

    // Create command queue
    state.command_queue = [app_get_device() newCommandQueue];

    
    // Load library
    NSURL *url = [NSURL fileURLWithPath:@"MyLibrary.metallib"];
    NSError *error;
    id<MTLLibrary> library = [app.device newLibraryWithURL:url error:&error];

    if (library == nil) {
        NSLog(@"Error: %@", error);
        exit(1);
    }

    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"basic_vertex"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"basic_fragment"];

    // Create Render Pipeline Descriptor
    MTLRenderPipelineDescriptor *pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    pipeline_desc.vertexFunction = vertexFunc;
    pipeline_desc.fragmentFunction = fragmentFunc;
    pipeline_desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    // Create Render Pipeline State Object
    state.pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_desc error:nil];
    
    state.vertex_buffer = [app.device newBufferWithBytes:vertex_data length:sizeof(vertex_data) options:MTLResourceCPUCacheModeDefaultCache]; 

    [vertexFunc release];
    [fragmentFunc release];
    [pipeline_desc release];
}

void frame() {
    id<CAMetalDrawable> drawable =  [app.view currentDrawable];

    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];
    
    MTLRenderPassDescriptor *pass_desc = [MTLRenderPassDescriptor renderPassDescriptor];
    pass_desc.colorAttachments[0].texture = drawable.texture;
    pass_desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass_desc.colorAttachments[0].clearColor = MTLClearColorMake(254.0 / 255.0, 245.0 / 255.0, 225.0 / 255.0, 1);
    
    id<MTLRenderCommandEncoder> render_encoder = [command_buffer renderCommandEncoderWithDescriptor:pass_desc];
    [render_encoder setCullMode:MTLCullModeNone];
    // Set the command enconder to use our shader....
    [render_encoder setRenderPipelineState:state.pipeline_state];
    // Set our vertex buffer
    [render_encoder setVertexBuffer:state.vertex_buffer offset:0 atIndex:0];
    // Set the command encoder to draw a triangle
    [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

    [render_encoder endEncoding];
    [command_buffer presentDrawable:drawable];
    [command_buffer commit];
}

void deinit() {
    [state.command_queue release];
}

int main(int argc, char **argv) {
    printf("metal-01-hello-triangle\n");

    NSString *s = [[NSString alloc] initWithUTF8String:"hello"];
    [s release];
    [s release];
    
    AppDesc desc = (AppDesc) {
            .title = "metal-01-triangle",
            .init_fn = init,
            .deinit_fn = deinit,
            .frame_fn = frame,
    };

    app_init(desc);
}

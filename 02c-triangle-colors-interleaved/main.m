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

typedef struct {
    float position[3];
    float color[4];
} Vertex;

#define col(x) (((float)(x))/255.0f)

static Vertex vertex_data[3] = {
    {{ 0,  1, 0}, {col(235), col(114), col(113), 1,}},
    {{-1, -1, 0}, {col(229), col(155), col(95),  1,}},
    {{ 1, -1, 0}, {col(252), col(218), col(150), 1 }},
};

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

    // Create vertex descriptor
    MTLVertexDescriptor *vertex_desc = [MTLVertexDescriptor vertexDescriptor];

    // attribute indices must match the ones in the shader
    vertex_desc.attributes[0].format = MTLVertexFormatFloat3;
    vertex_desc.attributes[0].offset = 0;
    vertex_desc.attributes[0].bufferIndex = 0;
    vertex_desc.attributes[1].format = MTLVertexFormatFloat4;
    vertex_desc.attributes[1].offset = 3 * sizeof(float);
    vertex_desc.attributes[1].bufferIndex = 0;

    // Layouts index == buffer number
    vertex_desc.layouts[0].stride = sizeof(Vertex);
    vertex_desc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    // Set the descriptor in the pipeline desc.
    pipeline_desc.vertexDescriptor = vertex_desc;

    // Create Render Pipeline State Object
    state.pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_desc error:&error];

    if (!state.pipeline_state) {
        NSLog(@"%@", error);
        exit(1);
    }
    
    state.vertex_buffer = [app.device newBufferWithBytes:vertex_data length:sizeof(vertex_data) options:MTLResourceCPUCacheModeDefaultCache]; 
    /* state.color_buffer = [app.device newBufferWithBytes:vertex_colors length:sizeof(vertex_colors) options:MTLResourceCPUCacheModeDefaultCache];  */

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
    /* [render_encoder setVertexBuffer:state.color_buffer offset:0 atIndex:1]; */

    
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

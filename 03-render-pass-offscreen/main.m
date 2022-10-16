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
    id<MTLBuffer> triangle_buffer;
    id<MTLBuffer> quad_buffer;
    id<MTLTexture> render_texture;
    MTLRenderPassDescriptor *render_to_texture_pass_desc;
    id<MTLRenderPipelineState> screen_pipeline_state;
    id<MTLRenderPipelineState> render_to_texture_pipeline_state;
} State;

static State state;

typedef struct {
    float position[3];
    float color[4];
} VertexPC;

typedef struct {
    float position[3];
    float texcoord[2];
} VertexPT;

#define col(x) (((float)(x))/255.0f)

static VertexPC triangle_vertices[3] = {
    {{ 0.5, -0.5, 0}, {col(235), col(114), col(113), 1,}},
    {{-0.5, -0.5, 0}, {col(229), col(155), col(95),  1,}},
    {{   0,  0.5, 0}, {col(252), col(218), col(150), 1 }},
};

static VertexPT quad_vertices[6] = {
    {{ 0.5, -0.5, 0}, {1, 1}},
    {{-0.5, -0.5, 0}, {0, 1}},
    {{-0.5,  0.5, 0}, {0, 0}},
   
    {{ 0.5, -0.5, 0}, {1, 1}},
    {{-0.5,  0.5, 0}, {0, 0}},
    {{ 0.5,  0.5, 0}, {1, 0}},
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
    
    id<MTLFunction> textureVertexFunc = [library newFunctionWithName:@"texture_vertex_shader"];
    id<MTLFunction> textureFragmentFunc = [library newFunctionWithName:@"texture_fragment_shader"];

    // Create render texture
    MTLTextureDescriptor *tex_desc = [MTLTextureDescriptor new];
    tex_desc.textureType = MTLTextureType2D;
    tex_desc.width = 512;
    tex_desc.height = 512;
    tex_desc.pixelFormat = MTLPixelFormatBGRA8Unorm;
    tex_desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

    // Crate buffers
    state.triangle_buffer = [app.device newBufferWithBytes:triangle_vertices length:sizeof(triangle_vertices) options:MTLResourceOptionCPUCacheModeDefault];
    state.quad_buffer = [app.device newBufferWithBytes:quad_vertices length:sizeof(quad_vertices) options:MTLResourceOptionCPUCacheModeDefault];
     
    state.render_texture = [app.device newTextureWithDescriptor:tex_desc];

    if (!state.render_texture) {
        printf("Failed to create render texture!\n");
        exit(1);
    }

    // Create pass render-to-texture pass descriptor
    state.render_to_texture_pass_desc = [MTLRenderPassDescriptor new];
    state.render_to_texture_pass_desc.colorAttachments[0].texture = state.render_texture;
    state.render_to_texture_pass_desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    state.render_to_texture_pass_desc.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
    state.render_to_texture_pass_desc.colorAttachments[0].storeAction = MTLStoreActionStore;
    

    // Create Render Pipeline Descriptor
    MTLRenderPipelineDescriptor *pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    pipeline_desc.label = @"Draw to screen pipeline";
    pipeline_desc.vertexFunction = textureVertexFunc;
    pipeline_desc.fragmentFunction = textureFragmentFunc;
    pipeline_desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    // Create vertex descriptor
    MTLVertexDescriptor *vertex_desc = [MTLVertexDescriptor vertexDescriptor];
    // attribute indices must match the ones in the shader
    vertex_desc.attributes[0].format = MTLVertexFormatFloat3;
    vertex_desc.attributes[0].offset = 0;
    vertex_desc.attributes[0].bufferIndex = 0;
    vertex_desc.attributes[1].format = MTLVertexFormatFloat2;
    vertex_desc.attributes[1].offset = 3 * sizeof(float);
    vertex_desc.attributes[1].bufferIndex = 0;
    // Layouts index == buffer number
    vertex_desc.layouts[0].stride = sizeof(VertexPT);
    vertex_desc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    // Set the descriptor in the pipeline desc.
    pipeline_desc.vertexDescriptor = vertex_desc;
    // Crate Pipeline State Object for screen rendering
    state.screen_pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_desc error:&error];
    if (!state.screen_pipeline_state) {
        NSLog(@"%@", error);
        exit(1);
    }


    pipeline_desc.label = @"Draw to texture pipeline";
    pipeline_desc.vertexFunction = vertexFunc;
    pipeline_desc.fragmentFunction = fragmentFunc;
    vertex_desc.attributes[1].format = MTLVertexFormatFloat4;
    vertex_desc.layouts[0].stride = sizeof(VertexPC);
    pipeline_desc.vertexDescriptor = vertex_desc;
    state.render_to_texture_pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_desc error:&error];
    if (!state.render_to_texture_pipeline_state) {
         NSLog(@"%@", error);
         exit(1);
    }
    
    [vertexFunc release];
    [fragmentFunc release];
    [textureFragmentFunc release];
    [textureVertexFunc release];
    [pipeline_desc release];
    [tex_desc release];
    [library release];
}

void frame() {
    id<CAMetalDrawable> drawable =  [app.view currentDrawable];

    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];
    
    MTLRenderPassDescriptor *screen_pass_desc = [MTLRenderPassDescriptor renderPassDescriptor];
    screen_pass_desc.colorAttachments[0].texture = drawable.texture;
    screen_pass_desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    screen_pass_desc.colorAttachments[0].clearColor = MTLClearColorMake(254.0 / 255.0, 245.0 / 255.0, 225.0 / 255.0, 1);
    
    id<MTLRenderCommandEncoder> render_encoder = [command_buffer renderCommandEncoderWithDescriptor:state.render_to_texture_pass_desc];
    render_encoder.label = @"Offscreen pass";
    [render_encoder setCullMode:MTLCullModeNone];
    [render_encoder setRenderPipelineState:state.render_to_texture_pipeline_state];
    [render_encoder setVertexBuffer:state.triangle_buffer offset:0 atIndex:0];
    [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [render_encoder endEncoding];
    
    render_encoder = [command_buffer renderCommandEncoderWithDescriptor:screen_pass_desc];
    render_encoder.label = @"Screen pass";
    [render_encoder setCullMode:MTLCullModeNone];
    [render_encoder setRenderPipelineState:state.screen_pipeline_state];
    [render_encoder setVertexBuffer:state.quad_buffer offset:0 atIndex:0];
    [render_encoder setFragmentTexture:state.render_texture atIndex:0];
    [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [render_encoder endEncoding];
    
    [command_buffer presentDrawable:drawable];
    [command_buffer commit];
}

void deinit() {
    [state.command_queue release];
    [state.screen_pipeline_state release];
    [state.render_to_texture_pipeline_state release];
    [state.quad_buffer release];
    [state.triangle_buffer release];
    [state.render_texture release];
    [state.render_to_texture_pass_desc release];
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

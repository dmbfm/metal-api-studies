#include <stdio.h>
#include <stdint.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#define APP_IMPLEMENTATION
#include "../common/app.h"


#define STB_IMAGE_IMPLEMENTATION
#include "../common/stb_image.h"

typedef struct {
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> pipeline_state;
    id<MTLBuffer> vertex_buffer;
    id<MTLBuffer> uniform_buffer;
    id<MTLTexture> texture;
    vector_uint2 viewportSize;
} State;

static State state;

typedef struct {
    float pos[2];
    float texcoord[2];
} VertexP2T2;

static VertexP2T2 vertex_data[6] = {
      { {  250,  -250 },  { 1.f, 1.f } },
      { { -250,  -250 },  { 0.f, 1.f } },
      { { -250,   250 },  { 0.f, 0.f } },

      { {  250,  -250 },  { 1.f, 1.f } },
      { { -250,   250 },  { 0.f, 0.f } },
      { {  250,   250 },  { 1.f, 0.f } },
};

// Load a texture using stb_image
id<MTLTexture> load_texture(const char *path) {

    int width, height, n;
    unsigned char *data = stbi_load(path, &width, &height, &n, 4);
    
    MTLTextureDescriptor *texture_desc = [[MTLTextureDescriptor alloc]init];

    NSLog(@"texture: %d, %d, %d", width, height, n);

    texture_desc.width = width;
    texture_desc.height = height;
    texture_desc.pixelFormat = MTLPixelFormatRGBA8Unorm;

    id<MTLTexture> texture = [app.device newTextureWithDescriptor:texture_desc];

    MTLRegion region = {0};
    region.origin = (MTLOrigin) { 0, 0, 0 };
    region.size = (MTLSize) { .width= width, .height = height, .depth = 1 };

    NSUInteger bytesPerRow = 4 * width;
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:data bytesPerRow:bytesPerRow];
    
    [texture_desc release];

    return texture;
}

void init() {
    NSLog(@"initzz!");

    // Create command queue
    state.command_queue = [app_get_device() newCommandQueue];

    state.viewportSize.x = 800;
    state.viewportSize.y = 600;
    
    // Load library
    NSURL *url = [NSURL fileURLWithPath:@"MyLibrary.metallib"];
    NSError *error;
    id<MTLLibrary> library = [app.device newLibraryWithURL:url error:&error];

    if (library == nil) {
        NSLog(@"Error: %@", error);
        exit(1);
    }

    state.texture = load_texture("./Image.tga");
    /* state.texture = load_texture("./img.png"); */

    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_shader"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_shader"];

    MTLVertexDescriptor *vertex_desc = [MTLVertexDescriptor vertexDescriptor];
    vertex_desc.attributes[0].format = MTLVertexFormatFloat2;
    vertex_desc.attributes[0].offset = 0;
    vertex_desc.attributes[0].bufferIndex = 0;
    vertex_desc.attributes[1].format = MTLVertexFormatFloat2;
    vertex_desc.attributes[1].offset = 2 * sizeof(float);
    vertex_desc.attributes[1].bufferIndex = 0;
    vertex_desc.layouts[0].stride = sizeof(VertexP2T2);
    vertex_desc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex; 


    // Create Render Pipeline Descriptor
    MTLRenderPipelineDescriptor *pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    pipeline_desc.vertexFunction = vertexFunc;
    pipeline_desc.fragmentFunction = fragmentFunc;
    pipeline_desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipeline_desc.vertexDescriptor = vertex_desc;

    // Create Render Pipeline State Object
    state.pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_desc error:&error];
    if (!state.pipeline_state) {
        NSLog(@"%@\n", error);
        exit(1);
    }
    
    state.vertex_buffer = [app.device newBufferWithBytes:vertex_data length:sizeof(vertex_data) options:MTLResourceCPUCacheModeDefaultCache]; 
    state.uniform_buffer = [app.device newBufferWithBytes:&state.viewportSize length:sizeof(state.viewportSize) options:MTLResourceOptionCPUCacheModeDefault];

    [vertexFunc release];
    [fragmentFunc release];
    [pipeline_desc release];
    [library release];
}

void frame() {
    id<CAMetalDrawable> drawable =  [app.view currentDrawable];

    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];
    
    MTLRenderPassDescriptor *pass_desc = [MTLRenderPassDescriptor renderPassDescriptor];
    pass_desc.colorAttachments[0].texture = drawable.texture;
    pass_desc.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass_desc.colorAttachments[0].clearColor = MTLClearColorMake(254.0 / 255.0, 245.0 / 255.0, 225.0 / 255.0, 1);
    
    id<MTLRenderCommandEncoder> render_encoder = [command_buffer renderCommandEncoderWithDescriptor:pass_desc];
    /* [render_encoder setCullMode:MTLCullModeNone]; */
    // Set the command enconder to use our shader....
    [render_encoder setRenderPipelineState:state.pipeline_state];
    // Set our vertex buffer
    [render_encoder setVertexBuffer:state.vertex_buffer offset:0 atIndex:0];
    [render_encoder setVertexBuffer:state.uniform_buffer offset:0 atIndex:1];
    [render_encoder setFragmentTexture:state.texture atIndex:0];
    // Set the command encoder to draw a triangle
    [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    [render_encoder endEncoding];
    [command_buffer presentDrawable:drawable];
    [command_buffer commit];
}

void deinit() {
    [state.command_queue release];
    [state.texture release];
    [state.vertex_buffer release];
    [state.uniform_buffer release];
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

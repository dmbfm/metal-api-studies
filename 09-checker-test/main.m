#include <bsm/audit.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#define APP_IMPLEMENTATION
#include "../common/app.h"

#define STB_IMAGE_IMPLEMENTATION
#define UTILS_H_IMPLEMENTATION
#include "../common/utils.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../common/stb_image_write.h"

#define PI 3.14159265359

typedef struct {
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> render_pipeline_state;
    id<MTLTexture> checker_texture;
    id<MTLBuffer> vertex_buffer;
} State;

static State state;

#define WIDTH 100
#define HEIGHT 100

static uint32_t viewport[2] = {WIDTH, HEIGHT};

typedef struct {
    float position[2];
    float uv[2];
} Vertex;

static Vertex quad_vertices[6] = {
     { {      0,      0 }, { 0, 0 } },
     { {  WIDTH,      0 }, { 1, 0 } },
     { {  WIDTH, HEIGHT }, { 1, 1 } },

     { {  WIDTH, HEIGHT }, { 1, 1 } },
     { {  0,     HEIGHT }, { 0, 1 } },
     { {  0,          0 }, { 0, 0 } },
};

void init() {
    NSError *error;
    state.command_queue = [app.device newCommandQueue];
   
    id<MTLLibrary> library = [app.device newLibraryWithFile:@"MyLibrary.metallib" error:&error];
    if (!library) {
        exitWith(error);
    }

    id<MTLFunction> vertex_function = [library newFunctionWithName:@"vertex_shader"];
    if (!vertex_function) {
        exitWith(@"Vertex function not found!");
    }

    id<MTLFunction> fragment_function = [library newFunctionWithName:@"fragment_shader"];
    if (!fragment_function) {
        exitWith(@"Fragment function not found!");
    }

    MTLVertexDescriptor *vertex_desc = [[MTLVertexDescriptor alloc] init];
    vertex_desc.attributes[0].bufferIndex = 0;
    vertex_desc.attributes[0].offset = 0;
    vertex_desc.attributes[0].format = MTLVertexFormatFloat2;
    vertex_desc.attributes[1].bufferIndex = 0;
    vertex_desc.attributes[1].offset = 2 * sizeof(float);
    vertex_desc.attributes[1].format = MTLVertexFormatFloat2;
    vertex_desc.layouts[0].stride = sizeof(Vertex);
    vertex_desc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    MTLRenderPipelineDescriptor *pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    pipeline_desc.vertexFunction = vertex_function;
    pipeline_desc.fragmentFunction = fragment_function;
    pipeline_desc.vertexDescriptor = vertex_desc;
    pipeline_desc.colorAttachments[0].pixelFormat = app.view.colorPixelFormat;

    state.render_pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_desc error:&error];
    if (!state.render_pipeline_state) {
        exitWith(error);
    }

    state.vertex_buffer = [app.device newBufferWithBytes:quad_vertices 
                                                  length:sizeof(quad_vertices) 
                                                 options:MTLResourceOptionCPUCacheModeDefault];
    
    MTLTextureDescriptor *texture_desc = [[MTLTextureDescriptor alloc] init];
    texture_desc.pixelFormat = MTLPixelFormatRGBA8Unorm;
    texture_desc.width = 10;
    texture_desc.height = 10;
    texture_desc.textureType = MTLTextureType2D;
    state.checker_texture = [app.device newTextureWithDescriptor:texture_desc];
    if (!state.checker_texture) {
        exitWith(@"texture");
    }

    uint8_t *pixels = (uint8_t *) malloc(10 * 10 * 4);

    for (int x = 0; x < 10; x++) {
        for (int y = 0; y < 10; y++) {

            int offset = y % 2;
            int idx = y * 10 + x;

            uint8_t col = (x + offset) % 2 == 0 ? 255 : 0; 

            pixels[4 * idx] = col;
            pixels[4 * idx + 1] = col;
            pixels[4 * idx + 2] = col;
            pixels[4 * idx + 3] = 255;
            
        }
    }

    MTLRegion region = MTLRegionMake2D(0, 0, 10, 10);

    [state.checker_texture replaceRegion:region mipmapLevel:0 withBytes:pixels bytesPerRow:4*10];

    free(pixels);

    [library release];
    [vertex_function release];
    [fragment_function release];
    [pipeline_desc release];
    [vertex_desc release];
    [texture_desc release];
    
}

void event(AppEvent *event) {
    switch (event->type) {
        case AppEventMouseDown:
        case AppEventMouseDragged:
            NSLog(@"%f, %f", event->x/((float)WIDTH/10), event->y/((float)HEIGHT/10));
            break;
        default: break;
    }
}

/* void event(AppEvent *event) { */
/* } */

void frame() {
    /* [NSCursor hide]; */
    /* printf("."); */
    app.view.clearColor = MTLClearColorMake(1, 0, 0, 1);
    
    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];
    
    id<MTLRenderCommandEncoder> render_encoder = [command_buffer renderCommandEncoderWithDescriptor:app.view.currentRenderPassDescriptor];
    [render_encoder setRenderPipelineState:state.render_pipeline_state];
    [render_encoder setCullMode:MTLCullModeNone];
    [render_encoder setVertexBuffer:state.vertex_buffer offset:0 atIndex:0];
    [render_encoder setVertexBytes:viewport length:sizeof(viewport) atIndex:1];
    [render_encoder setFragmentTexture:state.checker_texture atIndex:0];
    [render_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [render_encoder endEncoding];

    [command_buffer presentDrawable:app.view.currentDrawable];
    [command_buffer commit];
}

void deinit() {
    [state.command_queue release];
    [state.render_pipeline_state release];
}

int main(int argc, char **argv) {
    AppDesc desc = { "Checker Test", init, frame, deinit, event, WIDTH, HEIGHT };
    app_init(desc);
}



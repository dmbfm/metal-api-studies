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
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t a;
} PixelBGRA8;

typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
} PixelRGBA8;

typedef struct {
    float x;
    float y;
} Vec2;

typedef struct {
    float x;
    float y;
    float w;
    float h;
} Rectangle;

Rectangle rectangle_from_points(Vec2 a, Vec2 b) {
    Rectangle result = { 0 };

    float xmin = fminf(a.x, b.x);
    float ymin = fminf(a.y, b.y);
    float xmax = fmaxf(a.x, b.x);
    float ymax = fmaxf(a.y, b.y);

    result.x = xmin;
    result.y = ymin;
    result.w  = xmax - xmin;
    result.h  = ymax - ymin;

    return result;
}

typedef struct {
    id<MTLBuffer> vertex_buffer;
    id<MTLBuffer> outline_buffer;
    id<MTLBuffer> read_buffer;
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> render_pipeline_state;
    Vec2 start;
    Vec2 end;
    Vec2 current;
    bool draw_outline;
    bool read_pixels_this_frame;
} State;

static State state;

static uint32_t viewport[2] = {800, 600};

typedef struct {
    float position[2];
    float color[4];
} Vertex;

#define image_half_width 225
#define image_half_height 300
#define WIDTH 800
#define HEIGHT 600

static Vertex quad_vertices[6] = {
     { {      0,      0 }, { 1, 0, 0, 1 } },
     { {  WIDTH,      0 }, { 0, 1, 0, 1 } },
     { {  WIDTH, HEIGHT }, { 0, 0, 1, 1 } },

     { {  WIDTH, HEIGHT }, { 0, 0, 1, 1 } },
     { {  0,     HEIGHT }, { 1, 1, 1, 1 } },
     { {  0,          0 }, { 1, 0, 0, 1 } },
};

void exitWith(id obj) {
    NSLog(@"%@\n", obj);
    exit(1);
}

void init() {
    app.view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    app.view.framebufferOnly = NO;
    NSError *error;
    state.command_queue = [app.device newCommandQueue];
    if (!state.command_queue) {
        exitWith(@"Failed to create command queue!");
    }

    id<MTLLibrary> library = [app.device newLibraryWithFile:@"./MyLibrary.metallib" error:&error];
    if (!library) {
        exitWith(error);
    }

    id<MTLFunction> vertex_func = [library newFunctionWithName:@"vertex_shader"];
    if (!vertex_func) {
        exitWith(@"vertex_func");
    }
    
    id<MTLFunction> fragment_func = [library newFunctionWithName:@"fragment_shader"];
    if (!fragment_func) {
        exitWith(@"fragment_func");
    }

    MTLVertexDescriptor *vertex_desc = [[MTLVertexDescriptor alloc] init];
    vertex_desc.attributes[0].bufferIndex = 0;
    vertex_desc.attributes[0].offset = 0;
    vertex_desc.attributes[0].format = MTLVertexFormatFloat2;
    vertex_desc.attributes[1].bufferIndex = 0;
    vertex_desc.attributes[1].offset = 2 * sizeof(float);
    vertex_desc.attributes[1].format = MTLVertexFormatFloat4;
    vertex_desc.layouts[0].stride = sizeof(Vertex);
    vertex_desc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    MTLRenderPipelineDescriptor *render_pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    render_pipeline_desc.vertexFunction = vertex_func;
    render_pipeline_desc.fragmentFunction = fragment_func;
    render_pipeline_desc.colorAttachments[0].pixelFormat = app.view.colorPixelFormat;
    render_pipeline_desc.vertexDescriptor = vertex_desc;

    state.render_pipeline_state = [app.device newRenderPipelineStateWithDescriptor:render_pipeline_desc error:&error];
    if (!state.render_pipeline_state) {
        exitWith(error);
    }

    state.vertex_buffer = [app.device newBufferWithBytes:quad_vertices length:sizeof(quad_vertices) options:MTLResourceOptionCPUCacheModeDefault];
    state.outline_buffer = [app.device newBufferWithLength:5 * sizeof(Vertex) options:MTLResourceOptionCPUCacheModeDefault];

    [vertex_func release];
    [fragment_func release];
    [vertex_desc release];
    [render_pipeline_desc release];
    [library release];
}

void event(AppEvent *event) {
    
    printf("Event: %d\n", event->type);

    switch (event->type) {
        case AppEventMouseDown:
            {
                state.start = (Vec2) { event->x, HEIGHT - event->y - 1 };
                state.end = state.start;
                state.current = state.start;
                state.draw_outline = true;
            } break;

        case AppEventMouseDragged:
            {
                state.current = (Vec2) { event->x, HEIGHT - event->y -1 };
                state.draw_outline = true;
            }break;

        case AppEventMouseUp:
            {
                state.end = (Vec2) { event->x, HEIGHT - event->y -1 };
                state.current = state.end;
                state.draw_outline = false;

                if (state.end.x != state.start.x && state.end.y != state.start.y) {
                    state.read_pixels_this_frame = true;
                }
                
            } break;

        default:
            break;
    }
}

void frame() {
    app.view.clearColor = MTLClearColorMake(1, 1, 1, 1);
    
    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];
    id<MTLRenderCommandEncoder> render_command_encoder = [command_buffer renderCommandEncoderWithDescriptor:app.view.currentRenderPassDescriptor];
    
    [render_command_encoder setRenderPipelineState:state.render_pipeline_state];
    [render_command_encoder setVertexBuffer:state.vertex_buffer offset:0 atIndex:0];
    [render_command_encoder setVertexBytes:viewport length:sizeof(viewport) atIndex:1];
    [render_command_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    Rectangle r = rectangle_from_points(state.start, state.current);
    
    if (state.draw_outline) {
        float x = r.x;
        float y = r.y;
        float w = r.w;
        float h = r.h;
        
        const Vertex outline_vertices[6] = {
            { {   x,   y },  { 1, 1, 1, 1 } }, // Lower-left corner.
            { {   x, y+h },  { 1, 1, 1, 1 } }, // Upper-left corner.
            { { x+w, y+h },  { 1, 1, 1, 1 } }, // Upper-right corner.
            { { x+w,   y },  { 1, 1, 1, 1 } }, // Lower-right corner.
            { {   x,   y },  { 1, 1, 1, 1 } }, // Lower-left corner (to complete the line strip).
        };
        
        memcpy(state.outline_buffer.contents, outline_vertices, sizeof(outline_vertices));
        
        [render_command_encoder setVertexBuffer:state.outline_buffer offset:0 atIndex:0];
        [render_command_encoder drawPrimitives:MTLPrimitiveTypeLineStrip vertexStart:0 vertexCount:5];
    }
    
    [render_command_encoder endEncoding];

    if (state.read_pixels_this_frame) {
        
        state.read_pixels_this_frame = false;
        
        id<MTLTexture> texture_to_read = app.view.currentDrawable.texture;

        assert(texture_to_read.pixelFormat == MTLPixelFormatBGRA8Unorm);

        /* int w = r.w; */
        /* int h = r.h; */
        /* int x = r.x; */
        /* int y = r.y; */
        
        MTLOrigin origin = MTLOriginMake(0, 0, 0);
        /* MTLOrigin origin = MTLOriginMake(x, y, 0); */
        /* MTLSize read_size = MTLSizeMake(w, h, 1); */
        /* int width = app.view.currentDrawable.texture.width; */
        /* int height = app.view.currentDrawable.texture.width; */
        

        int x = 0, y = 0, w = texture_to_read.width, h = texture_to_read.height;
        
        MTLSize read_size = MTLSizeMake(w, h, 1);
        NSUInteger bytes_per_pixel = 4;
        NSUInteger bytes_per_row = w * bytes_per_pixel;
        NSUInteger bytes_per_image = h * bytes_per_row;

        printf("%u,%u,%u,%u -- %u, %u, %u\n", x, y, w, h, (uint) bytes_per_pixel,(uint) bytes_per_row, (uint)bytes_per_image);
        
        state.read_buffer = [app.device newBufferWithLength:bytes_per_image options:MTLResourceStorageModeShared];
        if (!state.read_buffer) {
            exitWith(@"read_buffer");
        }

        id<MTLBlitCommandEncoder> blit_encoder = [command_buffer blitCommandEncoder];
        [blit_encoder copyFromTexture:texture_to_read 
                          sourceSlice:0 
                          sourceLevel:0 
                         sourceOrigin:origin 
                           sourceSize:read_size 
                             toBuffer:state.read_buffer 
                    destinationOffset:0 
               destinationBytesPerRow:bytes_per_row 
             destinationBytesPerImage:bytes_per_image];

        [blit_encoder endEncoding];
        [command_buffer commit];
        [command_buffer waitUntilCompleted];

        uint8_t *pixels = (uint8_t *)malloc(state.read_buffer.length);
        memcpy(pixels, state.read_buffer.contents, state.read_buffer.length);
        /* PixelRGBA8 *converted = (PixelRGBA8 *)malloc(bytes_per_image); */
        uint8_t *converted = (uint8_t *)malloc(state.read_buffer.length);


        for (int i = 0; i < w * h; i++) {
            converted[4*i ] = pixels[4*i+2];
            converted[4*i+1] = pixels[4*i+1];
            converted[4*i+2] = pixels[4*i];
            converted[4*i+3] = pixels[4*i+3];
        }

        /* for (int i = 0; i < 4 * r.h * r.w; i++) converted */
        
        stbi_write_bmp("out.bmp", w, h, 4, converted);
        free(converted);
        free(pixels);
        [state.read_buffer release];
        
    } else {
        [command_buffer presentDrawable:app.view.currentDrawable];
        [command_buffer commit];
    }
}

void deinit() {
    [state.command_queue release];
    [state.vertex_buffer release];
    [state.outline_buffer release];
}

int main(int argc, char **argv) {
    AppDesc desc = { "07-compute-image-processing", init, frame, deinit, event };
    app_init(desc);
}



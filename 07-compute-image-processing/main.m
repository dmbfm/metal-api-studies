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

#define PI 3.14159265359

typedef struct {
    id<MTLTexture> input_texture;
    id<MTLTexture> output_texture;
    id<MTLBuffer> vertex_buffer;
    id<MTLBuffer> uniform_buffer;
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> render_pipeline_state;
    id<MTLComputePipelineState> compute_pipeline_state;
    MTLSize threadgroup_size;
    MTLSize threadgroup_count;
} State;

static State state;

static uint32_t viewport[2] = {800, 600};

typedef struct {
    float position[2];
    float uv[2];
} Vertex;

#define image_half_width 225
#define image_half_height 300

static Vertex quad_vertices[6] = {
    { {  image_half_width,  -image_half_height },  { 1.f, 1.f } },
    { { -image_half_width,  -image_half_height },  { 0.f, 1.f } },
    { { -image_half_width,   image_half_height },  { 0.f, 0.f } },

    { {  image_half_width,  -image_half_height },  { 1.f, 1.f } },
    { { -image_half_width,   image_half_height },  { 0.f, 0.f } },
    { {  image_half_width,   image_half_height },  { 1.f, 0.f } },
};

void exitWith(id obj) {
    NSLog(@"%@\n", obj);
    exit(1);
}

void init() {
    NSError *error;

    app.view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

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

    id<MTLFunction> kernel_function = [library newFunctionWithName:@"grayscale_kernel"];
    if (!kernel_function) {
        exitWith(@"Kernel function not found!");
    }

    MTLTextureDescriptor *texture_desc = [[MTLTextureDescriptor alloc] init];
    texture_desc.usage = MTLTextureUsageShaderRead;
    
    state.input_texture = load_texture(app.device, texture_desc, "./out.png");
    if (!state.input_texture) {
        exitWith(@"failed to load texture!");
    }

    texture_desc.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    state.output_texture = [app.device newTextureWithDescriptor:texture_desc];

    /* state.input_texture.usage = MTLTextureUsageShaderRead; */

    state.vertex_buffer = [app.device newBufferWithBytes:&quad_vertices length:sizeof(quad_vertices) options:MTLResourceOptionCPUCacheModeDefault];
    state.uniform_buffer = [app.device newBufferWithBytes:&viewport length:sizeof(viewport) options:MTLResourceOptionCPUCacheModeDefault];

    MTLVertexDescriptor *vertex_desc = [[MTLVertexDescriptor alloc] init];
    vertex_desc.attributes[0].bufferIndex = 0;
    vertex_desc.attributes[0].offset = 0;
    vertex_desc.attributes[0].format = MTLVertexFormatFloat2;
    vertex_desc.attributes[1].bufferIndex = 0;
    vertex_desc.attributes[1].offset = 2 * sizeof(float);
    vertex_desc.attributes[1].format = MTLVertexFormatFloat2;
    vertex_desc.layouts[0].stride = sizeof(Vertex);
    vertex_desc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    MTLRenderPipelineDescriptor *render_pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    render_pipeline_desc.fragmentFunction = fragment_function;
    render_pipeline_desc.vertexFunction = vertex_function;
    render_pipeline_desc.vertexDescriptor = vertex_desc;
    render_pipeline_desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    state.render_pipeline_state = [app.device newRenderPipelineStateWithDescriptor:render_pipeline_desc error:&error];
    if (!state.render_pipeline_state) {
        exitWith(error);
    }


    state.compute_pipeline_state = [app.device newComputePipelineStateWithFunction:kernel_function error:&error];
    if (!state.compute_pipeline_state) {
        exitWith(@"compute_pipeline_state");
    }

    state.command_queue = [app.device newCommandQueue];

    // Each group is 16x16 threads (256)
    state.threadgroup_size = MTLSizeMake(16, 16, 1);

    state.threadgroup_count.width = (state.input_texture.width + state.threadgroup_size.width - 1) / state.threadgroup_size.width;
    state.threadgroup_count.height = (state.input_texture.height + state.threadgroup_size.height - 1) / state.threadgroup_size.height;
    state.threadgroup_count.depth = 1;
    
    [texture_desc release];
    [vertex_desc release];
    [render_pipeline_desc release];
    [vertex_function release];
    [fragment_function release];
    [kernel_function release];
    [library release];
}

double t = 0;
float bias = 0;

void frame() {
    t += 0.01;
    bias = (float) (0.5 * sin(t));
    
    app.view.clearColor = MTLClearColorMake(0, 0, 0, 1);

    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];

    // Issue compute commands
    id<MTLComputeCommandEncoder> compute_command_encoder = [command_buffer computeCommandEncoder];
    [compute_command_encoder setComputePipelineState:state.compute_pipeline_state];
    [compute_command_encoder setTexture:state.input_texture atIndex:0];
    [compute_command_encoder setTexture:state.output_texture atIndex:1];
    [compute_command_encoder setBytes:&bias length:sizeof(float) atIndex:0];
    /* [compute_command_encoder setBytes:] */
    [compute_command_encoder dispatchThreadgroups:state.threadgroup_count threadsPerThreadgroup:state.threadgroup_size];
    [compute_command_encoder endEncoding];
    
    MTLRenderPassDescriptor *render_pass_descriptor = [app.view currentRenderPassDescriptor];

    id<MTLRenderCommandEncoder> render_command_encoder = [command_buffer renderCommandEncoderWithDescriptor:render_pass_descriptor];
    /* [render_command_encoder setViewport:(MTLViewport){0, 0, viewport[0], viewport[1], 0, 1}]; */
    [render_command_encoder setRenderPipelineState:state.render_pipeline_state];
    [render_command_encoder setVertexBuffer:state.vertex_buffer offset:0 atIndex:0];
    [render_command_encoder setVertexBuffer:state.uniform_buffer offset:0 atIndex:1];
    [render_command_encoder setFragmentTexture:state.output_texture atIndex:0];
    [render_command_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    [render_command_encoder endEncoding];

    [command_buffer presentDrawable:app.view.currentDrawable];
    [command_buffer commit];
}

void deinit() {
    [state.compute_pipeline_state release];
    [state.render_pipeline_state release];
    [state.command_queue release];
    [state.uniform_buffer release];
    [state.vertex_buffer release];
    [state.input_texture release];
    [state.output_texture release];
    [state.input_texture release];
}

typedef struct {
    size_t count;
    size_t capacity;
    int *free;
    size_t num_free;
} IndexPool;

void index_pool_init(IndexPool *pool, size_t capacity) {
    pool->count = 0;
    pool->capacity = capacity;
    pool->free = (int*) malloc(capacity * sizeof(int));
    pool->num_free = 0;
}

int index_pool_get(IndexPool *pool) {
    if (pool->num_free > 0) {
        return pool->free[--(pool->num_free)];
    }
    else if (pool->count >= pool->capacity) {
        return -1;
    } else {
        return pool->count++;
    }
}

void index_pool_return(IndexPool *pool, int index) {
    
}

int main(int argc, char **argv) {
    AppDesc desc = { "07-compute-image-processing", init, frame, deinit};
    app_init(desc);
}



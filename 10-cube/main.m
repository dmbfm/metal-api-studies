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

/* #define MATH_IMPL */
/* #include "../common/math.h" */

#define DFTK_IMPLEMENTATION
#include "../common/dftk/dftk.h"

#define PI 3.14159265359
#define DEG2RAD(x) (PI*((float)(x))/180)

#define WIDTH 800
#define HEIGHT 600

typedef struct {
    id<MTLCommandQueue> command_queue;
    id<MTLRenderPipelineState> pipeline_state;
    id<MTLBuffer> vertex_buffer;
    id<MTLBuffer> index_buffer;
    id<MTLBuffer> uniform_buffer;
    id<MTLDepthStencilState> depth_stencil_state;
    df_orbit_camera_t camera;
} State;

static State state;

typedef struct {
    float position[3];
    float color[4];
} Vertex;

typedef struct {
    df_matrix_4x4_t view_matrix;
    df_matrix_4x4_t proj_matrix;
} UniformData;


typedef uint16_t Index;

const Vertex triangle_vertices[3] = {
    { {   0,   0, 0}, {1, 0, 0, 1} },
    { { 0.5,   0, 0}, {0, 1, 0, 1} },
    { {   0, 0.5, 0}, {0, 0, 1, 1} },
};

void build_cube_vertices(Vertex **vertices, Index **indices, float size) {
    *vertices = (Vertex *) malloc(8 * sizeof(Vertex));
    *indices = (Index *) malloc(36 * sizeof(Vertex));

    Vertex vs[8] = {
        
        { { -size, -size, -size }, { 0, 0, 0, 1} },
        { { -size, -size,  size }, { 0, 1, 0, 1} },
        { {  size, -size,  size }, { 0, 1, 1, 1} },
        { {  size, -size, -size }, { 0, 0, 1, 1} },
        
        { { -size,  size, -size }, { 1, 0, 0, 1} },
        { { -size,  size,  size }, { 1, 1, 0, 1} },
        { {  size,  size,  size }, { 1, 1, 1, 1} },
        { {  size,  size, -size }, { 1, 0, 1, 1} },
    };

    Index idxs[36] = {
        // Bottom
        0, 1, 2,
        0, 2, 3,
        // Top
        4, 6, 5,
        4, 7, 6,
        // 0347
        0, 7, 4,
        0, 3, 7,
        // 0145
        1, 0, 4,
        1, 4, 5,
        //1256
        2, 1, 5,
        2, 5, 6,
        // 2376
        3, 2, 6,
        3, 6, 7,
    };

    memcpy(*vertices, vs, sizeof(vs));
    memcpy(*indices, idxs, sizeof(idxs));
}

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
    vertex_desc.attributes[0].format = MTLVertexFormatFloat3;
    vertex_desc.attributes[0].offset = 0;
    vertex_desc.attributes[1].bufferIndex = 0;
    vertex_desc.attributes[1].format = MTLVertexFormatFloat4;
    vertex_desc.attributes[1].offset = 3 * sizeof(float);
    vertex_desc.layouts[0].stride = sizeof(Vertex);
    vertex_desc.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    MTLRenderPipelineDescriptor *pipeline_desc = [[MTLRenderPipelineDescriptor alloc] init];
    pipeline_desc.vertexFunction = vertex_function;
    pipeline_desc.fragmentFunction = fragment_function;
    pipeline_desc.colorAttachments[0].pixelFormat = app.view.colorPixelFormat;
    pipeline_desc.depthAttachmentPixelFormat = app.view.depthStencilPixelFormat;
    pipeline_desc.stencilAttachmentPixelFormat = app.view.depthStencilPixelFormat;
    pipeline_desc.sampleCount = app.view.sampleCount;
    /* pipeline_desc.depthAttachmentPixelFormat = app.view.depthStencilPixelFormat; */
    /* pipeline_desc.stencilAttachmentPixelFormat = app.view.depthStencilPixelFormat; */
    
    pipeline_desc.vertexDescriptor = vertex_desc;

    state.pipeline_state = [app.device newRenderPipelineStateWithDescriptor:pipeline_desc error:&error];
    if (!state.pipeline_state) {
        exitWith(error);
    }


    MTLDepthStencilDescriptor *depth_desc = [[MTLDepthStencilDescriptor alloc] init];
    depth_desc.depthCompareFunction = MTLCompareFunctionLessEqual;
    depth_desc.depthWriteEnabled = true;
    state.depth_stencil_state = [app.device newDepthStencilStateWithDescriptor:depth_desc];
    
    Vertex *vertices;
    Index *indices;
    build_cube_vertices(&vertices, &indices, 0.5);

    state.vertex_buffer = [app.device newBufferWithBytes:vertices 
                                                  length:(8*sizeof(Vertex)) 
                                                 options:MTLResourceOptionCPUCacheModeDefault];

    state.index_buffer = [app.device newBufferWithBytes:indices 
                                                  length:(36*sizeof(Index)) 
                                                 options:MTLResourceOptionCPUCacheModeDefault];

    state.uniform_buffer = [app.device newBufferWithLength:sizeof(UniformData) options:MTLResourceOptionCPUCacheModeDefault];

    free(vertices);
    free(indices);

    [library release];
    [vertex_function release];
    [fragment_function release];
    [vertex_desc release];
    [pipeline_desc release];
    [depth_desc release];

    state.camera = (df_orbit_camera_t) {
        .camera = { .fov = DEG2RAD(55), .near = 0.1, .far = 100, .aspect = (float)WIDTH/HEIGHT },
        .target = {{ 0, 0, 0 }},
        .radius = 4,
        .polar_angle = DEG2RAD(45),
        .azimuth_angle = DEG2RAD(45),
        .polar_min = DEG2RAD(15),
        .polar_max = DEG2RAD(120),
        .radius_min = 1.8,
        .radius_max = 10,
    };
}

void event(AppEvent *event) {
    switch (event->type) {
        case AppEventMouseDragged:
            df_orbit_camera_inc_polar(&state.camera, -0.008 * event->dy);
            df_orbit_camera_inc_azimuthal(&state.camera, -0.008 * event->dx);
            break;

        case AppEventScrollWheel:
            df_orbit_camera_inc_radius(&state.camera, 0.08 * event->dy);
            /* state.camera.radius += event->dy; */
            break;
        default:
            break;
    }
}


void update() {

    UniformData u = {};
    df_orbit_camera_update(&state.camera);
    df_orbit_camera_view_mat(&state.camera, &u.view_matrix);
    df_orbit_camera_projection_mat(&state.camera, &u.proj_matrix);

    memcpy(state.uniform_buffer.contents, &u, sizeof(UniformData));
}

void frame() {
    app.view.clearColor = MTLClearColorMake(0.12, 0.12, 0.12, 1);
    app.view.clearDepth = 1;

    update();

    id<MTLCommandBuffer> command_buffer = [state.command_queue commandBuffer];
    id<MTLRenderCommandEncoder> render_encoder = [command_buffer renderCommandEncoderWithDescriptor:app.view.currentRenderPassDescriptor];
    [render_encoder setRenderPipelineState:state.pipeline_state];
    [render_encoder setDepthStencilState:state.depth_stencil_state];
    [render_encoder setCullMode:MTLCullModeBack];
    [render_encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [render_encoder setVertexBuffer:state.vertex_buffer offset:0 atIndex:0];
    [render_encoder setVertexBuffer:state.uniform_buffer offset:0 atIndex:1];
    [render_encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle 
                               indexCount:36 
                                indexType:MTLIndexTypeUInt16  
                              indexBuffer:state.index_buffer 
                        indexBufferOffset: 0];
    [render_encoder endEncoding];

    [command_buffer presentDrawable:app.view.currentDrawable];
    [command_buffer commit];
}

void deinit() {
    [state.command_queue release];
    [state.pipeline_state release];
    [state.vertex_buffer release];
    [state.index_buffer release];
    [state.depth_stencil_state release];
}

int main(int argc, char *argv[]) {
    AppDesc desc = { "10-cube", init, frame, deinit, event, WIDTH, HEIGHT, 4 };
    app_init(desc);

    return 0;
} 


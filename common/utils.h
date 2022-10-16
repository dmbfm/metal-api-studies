#if !defined(UTILS_H)
#define UTILS_H

#import <Metal/Metal.h>
#include "./stb_image.h"

id<MTLTexture> load_texture(id<MTLDevice> device, MTLTextureDescriptor *texture_desc, const char *path);
void exitWith(id obj);

#if defined(UTILS_H_IMPLEMENTATION)

void exitWith(id obj) {
    NSLog(@"%@\n", obj);
    exit(1);
}

// Load a texture using stb_image
id<MTLTexture> load_texture(id<MTLDevice> device, MTLTextureDescriptor *texture_desc, const char *path) {

    int width, height, n;
    unsigned char *data = stbi_load(path, &width, &height, &n, 4);
    
    bool owns_texture_desc = false;
    if (!texture_desc) {
        texture_desc = [[MTLTextureDescriptor alloc]init];
        owns_texture_desc = true;
    }
        

    NSLog(@"texture: %d, %d, %d", width, height, n);

    texture_desc.width = width;
    texture_desc.height = height;
    texture_desc.pixelFormat = MTLPixelFormatRGBA8Unorm;
    texture_desc.textureType = MTLTextureType2D;

    id<MTLTexture> texture = [device newTextureWithDescriptor:texture_desc];

    MTLRegion region = {0};
    region.origin = (MTLOrigin) { 0, 0, 0 };
    region.size = (MTLSize) { .width = (unsigned int) width, .height = (unsigned int) height, .depth = 1 };

    NSUInteger bytesPerRow = 4 * width;
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:data bytesPerRow:bytesPerRow];

    if (owns_texture_desc) {
        [texture_desc release];
    }
    
    return texture;
}
#endif


#endif

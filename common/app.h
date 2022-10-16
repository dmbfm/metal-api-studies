// TODO:
// - Add tracking area to detect mouse exited (see: https://stackoverflow.com/questions/4639379/how-to-use-nstrackingarea)
// - Add mouse move events
#if !defined(APP_H)
#define APP_H

#include <stdio.h>
#include <stdint.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface WindowDelegate : NSObject<NSWindowDelegate>
@end

@interface AppDelegate : NSObject<NSApplicationDelegate>
@end

@interface MetalView : MTKView
- (void)mouseDragged:(NSEvent *)event;
- (void)mouseUp:(NSEvent *)event;
- (void)mouseDown:(NSEvent *)event;
- (void)mouseExited:(NSEvent *)event;
- (void)scrollWheel:(NSEvent *)event;
@end


typedef enum {
    AppEventMouseDragged,
    AppEventMouseUp,
    AppEventMouseDown,
    AppEventMouseExited,
    AppEventScrollWheel,
} AppEventType;

typedef struct {
    AppEventType type;
    float dx;
    float dy;
    float x;
    float y;
} AppEvent;

typedef struct {
    const char *title;
    void (*init_fn)();
    void (*frame_fn)();
    void (*deinit_fn)();
    void (*event_fn)(AppEvent *e);
    int width;
    int height;
    int sampleCount;
} AppDesc;

typedef struct {
    AppDesc desc;
    NSWindow *win;
    MetalView *view;
    WindowDelegate *win_dlg;
    AppDelegate *app_dlg;
    size_t frame;
    id<MTLDevice> device;
    AppEvent event;
} App;

static App app;

/* #if defined(APP_IMPLEMENTATION) */
#if 1

void _app_init() {
    if (app.desc.init_fn != 0) {
        app.desc.init_fn();
    }
}

void app_frame() {
    if (app.frame == 0) {
        _app_init();
    }

    
    if (app.desc.frame_fn != 0) {
        app.desc.frame_fn();
    }

    app.frame++;
}

void app_deinit() {
    if (app.desc.deinit_fn != 0) {
        app.desc.deinit_fn();
    }

    [app.app_dlg release];
    [app.view release];
    [app.win_dlg release];
};


void app_init(AppDesc desc) {
    /* AppDesc desc = (AppDesc) { .title = "metal-01-triangle"}; */
    app.desc = desc;

    app.app_dlg = [[AppDelegate alloc] init];
    
    [NSApplication sharedApplication];
    [NSApp setDelegate:app.app_dlg];
    [NSApp run];
}

id<MTLDevice> app_get_device() {
    return app.device;
}


MetalView *app_get_view() {
    return app.view;
}

@implementation WindowDelegate
- (BOOL)windowShouldClose:(NSWindow *) sender {
    return YES;
}
@end

@implementation MetalView 
- (void)drawRect:(NSRect) dirtyRect {
    app_frame();
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint pos = [event locationInWindow];

    if (app.desc.event_fn) {
        app.event = (AppEvent) { 
            .type = AppEventMouseDragged, 
            .dx = (float) event.deltaX,  
            .dy = (float) event.deltaY,
            .x = (float) pos.x,
            .y = (float) pos.y,
        };
        app.desc.event_fn(&app.event);
    }
}

- (void)mouseUp:(NSEvent *)event {
    NSPoint pos = [event locationInWindow];

    if (app.desc.event_fn) {
        app.event = (AppEvent) { 
            .type = AppEventMouseUp, 
            .dx = (float) event.deltaX,  
            .dy = (float) event.deltaY,
            .x = (float) pos.x,
            .y = (float) pos.y,
        };
        app.desc.event_fn(&app.event);
    }
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint pos = [event locationInWindow];

    if (app.desc.event_fn) {
        app.event = (AppEvent) { 
            .type = AppEventMouseDown, 
            .dx = (float) event.deltaX,  
            .dy = (float) event.deltaY,
            .x = (float) pos.x,
            .y = (float) pos.y,
        };
        app.desc.event_fn(&app.event);
    }
}

- (void)mouseExited:(NSEvent *)event {
    NSPoint pos = [event locationInWindow];

    if (app.desc.event_fn) {
        app.event = (AppEvent) { 
            .type = AppEventMouseExited, 
            .dx = (float) event.deltaX,  
            .dy = (float) event.deltaY,
            .x = (float) pos.x,
            .y = (float) pos.y,
        };
        app.desc.event_fn(&app.event);
    }
}

- (void) scrollWheel:(NSEvent *)event {
    NSPoint pos = [event locationInWindow];

    if (app.desc.event_fn) {
        app.event = (AppEvent) { 
            .type = AppEventScrollWheel, 
            .dx = (float) event.deltaX,  
            .dy = (float) event.deltaY,
            .x = (float) pos.x,
            .y = (float) pos.y,
        };
        app.desc.event_fn(&app.event);
    }
}
@end

@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"applicationDidFinishLaunching!");

    int width = app.desc.width <= 0 ? 800 : app.desc.width;
    int height = app.desc.width <= 0 ? 600 : app.desc.height;
    
    NSRect frame = NSMakeRect(0, 0, width, height);
    NSWindowStyleMask style = 
        NSWindowStyleMaskTitled | 
        NSWindowStyleMaskClosable | 
        NSWindowStyleMaskResizable;
    
    app.win = [[NSWindow alloc] initWithContentRect:frame 
                                          styleMask:style 
                                            backing:NSBackingStoreBuffered 
                                              defer:NO];
    


    app.win_dlg = [[WindowDelegate alloc] init];
    app.view = [[MetalView alloc] init];
    app.device = MTLCreateSystemDefaultDevice();
    app.view.device = app.device;
    /* app.view.framebufferOnly = true; */
    app.view.preferredFramesPerSecond = 60;
    app.view.sampleCount = app.desc.sampleCount <= 0 ? 1 : app.desc.sampleCount;
    app.view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    app.view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    app.view.autoResizeDrawable = false;

    /* [app.win setBackgroundColor:[NSColor blueColor]]; */
    [app.win setDelegate:app.win_dlg];
    [app.win setContentView:app.view];
    [app.win makeFirstResponder:app.view];
    [app.win setTitle:[NSString stringWithUTF8String:app.desc.title]];
    [app.win center];
    
    NSApp.activationPolicy = NSApplicationActivationPolicyRegular;
    [NSApp activateIgnoringOtherApps:YES];
    [app.win makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) sender {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *) notification {
    app_deinit();
}
@end

#endif

#endif

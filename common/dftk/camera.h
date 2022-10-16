#if !defined(DFTK_CAMERA_H)
#define DFTK_CAMERA_H

#include "math.h"

typedef enum {
    DFCameraProjectionPerspective,
    DFCameraProjectionOrtho,
} df_camera_projection_type;

// A look at camera 
typedef struct {
    df_vec3_t position;                        // The camera's position
    df_vec3_t target;                          // The camera's view target
    df_vec3_t up;                              // Which way is up :)
    float fov;                                 // The horizontal FOV angle
    float aspect;                              // The screen's aspect ration
    float near;                                // The near clipping plane distance
    float far;                                 // The far clipping plane distance
    df_camera_projection_type projection_type; // The camera's projection type
} df_camera_t;

// An orbital camera controller
typedef struct {
    df_camera_t camera;    // The internal-usage camera
    df_vec3_t target;      // The camera's target
    float radius;          // The orbital distance from the camera to the target
    float polar_angle;     // The angle between the target-camera vector and the y axis    
    float azimuth_angle;   // The azimuthal angle
    float polar_min;       // Tha minimum value for the polar angle
    float polar_max;       // The maximum value for the polar angle
    float radius_min;      // The minimum orbital distance
    float radius_max;      // The maximum orbital distance
} df_orbit_camera_t; 

void df_camera_projection_mat(df_camera_t *camera, df_matrix_4x4_t *out);
void df_camera_view_mat(df_camera_t *camera, df_matrix_4x4_t *out);
void df_camera_full_mat(df_camera_t *camera, df_matrix_4x4_t *out);
void df_orbit_camera_inc_polar(df_orbit_camera_t *oc, float inc);
void df_orbit_camera_inc_radius(df_orbit_camera_t *oc, float inc);
void df_orbit_camera_inc_azimuthal(df_orbit_camera_t *oc, float inc);
void df_orbit_camera_update(df_orbit_camera_t *oc);
void df_orbit_camera_projection_mat(df_orbit_camera_t *oc, df_matrix_4x4_t *out);
void df_orbit_camera_view_mat(df_orbit_camera_t *oc, df_matrix_4x4_t *out);
void df_orbit_camera_full_mat(df_orbit_camera_t *oc, df_matrix_4x4_t *out);

#endif

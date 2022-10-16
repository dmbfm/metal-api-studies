#if !defined(DFTK_CAMERA_H)
#define DFTK_CAMERA_H

#include "math.h"

typedef enum {
    DFCameraProjectionPerspective,
    DFCameraProjectionOrtho,
} df_camera_projection_type;

typedef struct {
    // The camera's position
    df_vec3_t position;          
    // The camera's view target
    df_vec3_t target;
    // Which way is up :)
    df_vec3_t up;
    // The horizontal FOV angle
    float fov;
    // The screen's aspect ration
    float aspect;
    // The near clipping plane distance
    float near;
    // The far clipping plane distance
    float far;
    // The camera's projection type
    df_camera_projection_type projection_type;
} df_camera_t;

// An orbital camera controller
typedef struct {
    // The internal-usage camera
    df_camera_t camera;
    // The camera's target
    df_vec3_t target;
    // The orbital distance from the camera to the target
    float radius;
    // The polar angle; that is, the angle between vector from 
    // the object to the camera and the y axis 
    float polar_angle;      
    // The azimuthal angle
    float azimuth_angle;
    // Tha minimum value for the polar angle
    float polar_min;
    // The maximum value for the polar angle
    float polar_max;
    // The minimum orbital distance
    float radius_min;
    // The maximum orbital distance
    float radius_max;
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

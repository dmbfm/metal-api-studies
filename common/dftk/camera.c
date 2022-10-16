#include <math.h>
#include "math.h"
#include "camera.h"

void df_camera_projection_mat(df_camera_t *camera, df_matrix_4x4_t *out) {
    df_matrix_4x4_perspective_with_fov(out, 
                                       camera->near, 
                                       camera->far, 
                                       camera->aspect, 
                                       camera->fov);
}

void df_camera_view_mat(df_camera_t *camera, df_matrix_4x4_t *out) {
    df_matrix_4x4_look_at(out, camera->position, camera->target, camera->up);
}

void df_camera_full_mat(df_camera_t *camera, df_matrix_4x4_t *out) {
    df_matrix_4x4_t p, v;
    df_camera_projection_mat(camera, &p);
    df_camera_view_mat(camera, &v);
    df_matrix_4x4_mul(&p, &v, out);
}

void df_orbit_camera_inc_polar(df_orbit_camera_t *oc, float inc) {
    oc->polar_angle += inc;
    if (oc->polar_angle > oc->polar_max) oc->polar_angle = oc->polar_max;
    if (oc->polar_angle < oc->polar_min) oc->polar_angle = oc->polar_min;
}

void df_orbit_camera_inc_radius(df_orbit_camera_t *oc, float inc) {
    oc->radius += inc;

    if (oc->radius < oc->radius_min) oc->radius = oc->radius_min;
    if (oc->radius > oc->radius_max) oc->radius = oc->radius_max;
}

void df_orbit_camera_inc_azimuthal(df_orbit_camera_t *oc, float inc) {
    oc->azimuth_angle += inc;
}

void df_orbit_camera_update(df_orbit_camera_t *oc) {
    if (oc->polar_angle > oc->polar_max) oc->polar_angle = oc->polar_max;
    if (oc->polar_angle < oc->polar_min) oc->polar_angle = oc->polar_min;
    
    float a = DFTK_PI/2 - oc->polar_angle;
    oc->camera.up = df_vec3_create(-sin(a) * cos(oc->azimuth_angle), cos(a), -sin(a) * sin(oc->azimuth_angle));
    oc->camera.position.y = oc->target.y + oc->radius * cos(oc->polar_angle);
    oc->camera.position.x = oc->target.x + oc->radius * sin(oc->polar_angle) * cos(oc->azimuth_angle);
    oc->camera.position.z = oc->target.z + oc->radius * sin(oc->polar_angle) * sin(oc->azimuth_angle);
}

void df_orbit_camera_projection_mat(df_orbit_camera_t *oc, df_matrix_4x4_t *out) {
    df_camera_projection_mat(&oc->camera, out);
}

void df_orbit_camera_view_mat(df_orbit_camera_t *oc, df_matrix_4x4_t *out) {
    df_camera_view_mat(&oc->camera, out);
}

void df_orbit_camera_full_mat(df_orbit_camera_t *oc, df_matrix_4x4_t *out) {
    df_camera_full_mat(&oc->camera, out);
}

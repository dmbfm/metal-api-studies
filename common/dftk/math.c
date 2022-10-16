#include <math.h>
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

#include "math.h"

df_vec3_t df_vec3_create(float x, float y, float z) {
    df_vec3_t v;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

df_vec3_t df_vec3_add(df_vec3_t v, df_vec3_t w) {
    df_vec3_t r;
    r.x = v.x + w.x;
    r.y = v.y + w.y;
    r.z = v.z + w.z;
    return r;
}

df_vec3_t df_vec3_sub(df_vec3_t v, df_vec3_t w) {
    df_vec3_t r;
    r.x = v.x - w.x;
    r.y = v.y - w.y;
    r.z = v.z - w.z;
    return r;
}

bool df_vec3_eql(df_vec3_t v, df_vec3_t w) {
    const float eps = 0.00001; 

    for (int i = 0; i < 3; i++) {
        float d = fabs(v.data[i] - w.data[i]);
        if (d > eps) return false;
    }
    return true;
}

float df_vec3_dot(df_vec3_t v, df_vec3_t w) {
    return v.x * w.x + v.y * w.y + v.z * w.z;
}

float df_vec3_len(df_vec3_t v) {
    return sqrtf(df_vec3_dot(v, v));
}

df_vec3_t df_vec3_mul(df_vec3_t v, float a) {
    df_vec3_t r;
    r.x = v.x * a;
    r.y = v.y * a;
    r.z = v.z * a;
    return r;
}

df_vec3_t df_vec3_normalize(df_vec3_t v) {
    return df_vec3_mul(v, 1.0 / df_vec3_len(v));
}

df_vec3_t df_vec3_cross(df_vec3_t v, df_vec3_t w) {
    df_vec3_t r;
    r.x  = v.y * w.z - v.z * w.y;
    r.y  = v.z * w.x - v.x * w.z;
    r.z  = v.x * w.y - v.y * w.x;
    return r;
}

void df_matrix_4x4_identity(df_matrix_4x4_t *m) {
    df_matrix_4x4_zeroes(m);
    m->data[0][0] = 1;
    m->data[1][1] = 1;
    m->data[2][2] = 1;
    m->data[3][3] = 1;
}

bool df_matrix_4x4_eq(const df_matrix_4x4_t *m1, const df_matrix_4x4_t *m2) {
    float eps = 0.00001;

    const float *x1 = &m1->data[0][0];
    const float *x2 = &m2->data[0][0];

    for (int i = 0; i < 16; i++) {
        if (fabs(x1[i] - x2[i]) > eps) {
            return false;
        }
    }

    return true;
}

void df_matrix_4x4_mul(const df_matrix_4x4_t *m1, const df_matrix_4x4_t *m2, df_matrix_4x4_t *out) {
    assert(out != m1);
    assert(out != m2);
    
    // [col][line]
    out->data[0][0] = m1->data[0][0] * m2->data[0][0] + m1->data[1][0] * m2->data[0][1] + m1->data[2][0] * m2->data[0][2] + m1->data[3][0] * m2->data[0][3];
    out->data[1][0] = m1->data[0][0] * m2->data[1][0] + m1->data[1][0] * m2->data[1][1] + m1->data[2][0] * m2->data[1][2] + m1->data[3][0] * m2->data[1][3];
    out->data[2][0] = m1->data[0][0] * m2->data[2][0] + m1->data[1][0] * m2->data[2][1] + m1->data[2][0] * m2->data[2][2] + m1->data[3][0] * m2->data[2][3];
    out->data[3][0] = m1->data[0][0] * m2->data[3][0] + m1->data[1][0] * m2->data[3][1] + m1->data[2][0] * m2->data[3][2] + m1->data[3][0] * m2->data[3][3];

    out->data[0][1] = m1->data[0][1] * m2->data[0][0] + m1->data[1][1] * m2->data[0][1] + m1->data[2][1] * m2->data[0][2] + m1->data[3][1] * m2->data[0][3];
    out->data[1][1] = m1->data[0][1] * m2->data[1][0] + m1->data[1][1] * m2->data[1][1] + m1->data[2][1] * m2->data[1][2] + m1->data[3][1] * m2->data[1][3];
    out->data[2][1] = m1->data[0][1] * m2->data[2][0] + m1->data[1][1] * m2->data[2][1] + m1->data[2][1] * m2->data[2][2] + m1->data[3][1] * m2->data[2][3];
    out->data[3][1] = m1->data[0][1] * m2->data[3][0] + m1->data[1][1] * m2->data[3][1] + m1->data[2][1] * m2->data[3][2] + m1->data[3][1] * m2->data[3][3];

    out->data[0][2] = m1->data[0][2] * m2->data[0][0] + m1->data[1][2] * m2->data[0][1] + m1->data[2][2] * m2->data[0][2] + m1->data[3][2] * m2->data[0][3];
    out->data[1][2] = m1->data[0][2] * m2->data[1][0] + m1->data[1][2] * m2->data[1][1] + m1->data[2][2] * m2->data[1][2] + m1->data[3][2] * m2->data[1][3];
    out->data[2][2] = m1->data[0][2] * m2->data[2][0] + m1->data[1][2] * m2->data[2][1] + m1->data[2][2] * m2->data[2][2] + m1->data[3][2] * m2->data[2][3];
    out->data[3][2] = m1->data[0][2] * m2->data[3][0] + m1->data[1][2] * m2->data[3][1] + m1->data[2][2] * m2->data[3][2] + m1->data[3][2] * m2->data[3][3];

    out->data[0][3] = m1->data[0][3] * m2->data[0][0] + m1->data[1][3] * m2->data[0][1] + m1->data[2][3] * m2->data[0][2] + m1->data[3][3] * m2->data[0][3];
    out->data[1][3] = m1->data[0][3] * m2->data[1][0] + m1->data[1][3] * m2->data[1][1] + m1->data[2][3] * m2->data[1][2] + m1->data[3][3] * m2->data[1][3];
    out->data[2][3] = m1->data[0][3] * m2->data[2][0] + m1->data[1][3] * m2->data[2][1] + m1->data[2][3] * m2->data[2][2] + m1->data[3][3] * m2->data[2][3];
    out->data[3][3] = m1->data[0][3] * m2->data[3][0] + m1->data[1][3] * m2->data[3][1] + m1->data[2][3] * m2->data[3][2] + m1->data[3][3] * m2->data[3][3];
}

void df_matrix_4x4_random(df_matrix_4x4_t *m) {
    float *x = &(m->data[0][0]);
    for (int i = 0; i < 16; i++) {
        x[i] = (float) rand();
    }
}

void df_matrix_4x4_translation(df_matrix_4x4_t *m, float tx, float ty, float tz) {
    df_matrix_4x4_identity(m);
    m->data[3][0] = tx;
    m->data[3][1] = ty;
    m->data[3][2] = tz;
}

void df_matrix_4x4_look_at(df_matrix_4x4_t *mat, df_vec3_t camera_pos, df_vec3_t look_at_point, df_vec3_t up) {
    df_matrix_4x4_t t, m;

    df_matrix_4x4_translation(&t, -camera_pos.x, -camera_pos.y, -camera_pos.z);
    
    df_vec3_t e3 = df_vec3_normalize(df_vec3_sub(look_at_point, camera_pos));
    df_vec3_t up_norm = df_vec3_normalize(up);
    df_vec3_t e1 = df_vec3_cross(up_norm, e3);
    df_vec3_t e2 = df_vec3_cross(e3, e1);

    df_matrix_4x4_identity(&m);
    m.data[0][0] = e1.x;
    m.data[0][1] = e2.x;
    m.data[0][2] = e3.x;
    m.data[1][0] = e1.y;
    m.data[1][1] = e2.y;
    m.data[1][2] = e3.y;
    m.data[2][0] = e1.z;
    m.data[2][1] = e2.z;
    m.data[2][2] = e3.z;

    df_matrix_4x4_mul(&m, &t, mat);
}

void df_matrix_4x4_zeroes(df_matrix_4x4_t *m) {
    float *x = &m->data[0][0];
    for (int i = 0; i < 16;i++) x[i] = 0;
}

void df_matrix_4x4_perspective(df_matrix_4x4_t *m, float n, float f, float w, float h) {
    df_matrix_4x4_zeroes(m);
    m->data[0][0] = (2*n)/w;
    m->data[1][1] = (2*n)/h;
    m->data[2][2] = f/(f-n);
    m->data[2][3] = 1;
    m->data[3][2] = (f*n)/(n-f);
}

void df_matrix_4x4_perspective_with_fov(df_matrix_4x4_t *m, float n, float f, float aspect, float fov) {
    float w = (n * tanf(fov))/2;
    float h = w / aspect;
    df_matrix_4x4_perspective(m, n, f, w, h);
}

void df_matrix_4x4_print(df_matrix_4x4_t *m) {
    printf("[\n");
    printf("%f, %f, %f, %f\n", m->data[0][0], m->data[1][0], m->data[2][0],  m->data[3][0]);
    printf("%f, %f, %f, %f\n", m->data[0][1], m->data[1][1], m->data[2][1],  m->data[3][1]);
    printf("%f, %f, %f, %f\n", m->data[0][2], m->data[1][2], m->data[2][2],  m->data[3][2]);
    printf("%f, %f, %f, %f\n", m->data[0][3], m->data[1][3], m->data[2][3],  m->data[3][3]);
    printf("]\n");
}



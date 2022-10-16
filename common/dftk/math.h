#if !defined(DFTK_MATH_H)
#define DFTK_MATH_H

#include <stdbool.h>


#define DFTK_PI 3.14159265359

typedef union {
    float data[3];
    struct {
        float x;
        float y;
        float z;
    };
} df_vec3_t;

typedef struct {
    // m[i][j] -> i = col, j = row
    float data[4][4];
} df_matrix_4x4_t;

df_vec3_t df_vec3_create(float x, float y, float z);
df_vec3_t df_vec3_add(df_vec3_t v, df_vec3_t w);
df_vec3_t df_vec3_sub(df_vec3_t v, df_vec3_t w);
float df_vec3_dot(df_vec3_t v, df_vec3_t w);
float df_vec3_len(df_vec3_t v);
df_vec3_t df_vec3_mul(df_vec3_t v, float a);
df_vec3_t df_vec3_normalize(df_vec3_t v);
df_vec3_t df_vec3_cross(df_vec3_t v, df_vec3_t w);
bool df_vec3_eql(df_vec3_t v, df_vec3_t w);


void df_matrix_4x4_identity(df_matrix_4x4_t *m);
bool df_matrix_4x4_eq(const df_matrix_4x4_t *m1, const df_matrix_4x4_t *m2);
void df_matrix_4x4_mul(const df_matrix_4x4_t *m1, const df_matrix_4x4_t *m2, df_matrix_4x4_t *out);
void df_matrix_4x4_random(df_matrix_4x4_t *m);
void df_matrix_4x4_translation(df_matrix_4x4_t *m, float tx, float ty, float tz);
void df_matrix_4x4_look_at(df_matrix_4x4_t *mat, df_vec3_t camera_pos, df_vec3_t look_at_point, df_vec3_t up);
void df_matrix_4x4_zeroes(df_matrix_4x4_t *m);
void df_matrix_4x4_perspective(df_matrix_4x4_t *m, float n, float f, float w, float h);
void df_matrix_4x4_perspective_with_fov(df_matrix_4x4_t *m, float n, float f, float aspect, float fov);
void df_matrix_4x4_print(df_matrix_4x4_t *m);

#endif

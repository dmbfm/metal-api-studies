#if !defined(MATH_H)
#define MATH_H

typedef union {
    float data[3];
    struct {
        float x;
        float y;
        float z;
    };
} Vec3;

Vec3 vec3_create(float x, float y, float z);
Vec3 vec3_add(Vec3 v, Vec3 w);
Vec3 vec3_sub(Vec3 v, Vec3 w);
float vec3_dot(Vec3 v, Vec3 w);
float vec3_len(Vec3 v);
Vec3 vec3_mul(Vec3 v, float a);
Vec3 vec3_normalize(Vec3 v);
Vec3 vec3_cross(Vec3 v, Vec3 w);
bool vec3_eql(Vec3 v, Vec3 w);

typedef struct {
    // m[i][j] -> i = col, j = row
    float data[4][4];
} Matrix4x4;

void matrix_4x4_identity(Matrix4x4 *m);
bool matrix_4x4_eq(const Matrix4x4 *m1, const Matrix4x4 *m2);
void matrix_4x4_mul(const Matrix4x4 *m1, const Matrix4x4 *m2, Matrix4x4 *out);
void matrix_4x4_random(Matrix4x4 *m);
void matrix_4x4_translation(Matrix4x4 *m, float tx, float ty, float tz);
void matrix_4x4_look_at(Matrix4x4 *mat, Vec3 camera_pos, Vec3 look_at_point, Vec3 up);
void matrix_4x4_zeroes(Matrix4x4 *m);
void matrix_4x4_perspective(Matrix4x4 *m, float n, float f, float w, float h);
void matrix_4x4_perspective_with_fov(Matrix4x4 *m, float n, float f, float aspect, float fov);
void matrix_4x4_print(Matrix4x4 *m);

#ifdef TEST
void math_h_test();
#endif

// #define MATH_IMPL 1
#ifdef MATH_IMPL

#include <math.h>
#include <stdio.h>
#include <assert.h>

Vec3 vec3_create(float x, float y, float z) {
    Vec3 v;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

Vec3 vec3_add(Vec3 v, Vec3 w) {
    Vec3 r;
    r.x = v.x + w.x;
    r.y = v.y + w.y;
    r.z = v.z + w.z;
    return r;
}

Vec3 vec3_sub(Vec3 v, Vec3 w) {
    Vec3 r;
    r.x = v.x - w.x;
    r.y = v.y - w.y;
    r.z = v.z - w.z;
    return r;
}

bool vec3_eql(Vec3 v, Vec3 w) {
    const float eps = 0.00001; 

    for (int i = 0; i < 3; i++) {
        float d = fabs(v.data[i] - w.data[i]);
        if (d > eps) return false;
    }
    return true;
}

float vec3_dot(Vec3 v, Vec3 w) {
    return v.x * w.x + v.y * w.y + v.z * w.z;
}

float vec3_len(Vec3 v) {
    return sqrtf(vec3_dot(v, v));
}

Vec3 vec3_mul(Vec3 v, float a) {
    Vec3 r;
    r.x = v.x * a;
    r.y = v.y * a;
    r.z = v.z * a;
    return r;
}

Vec3 vec3_normalize(Vec3 v) {
    return vec3_mul(v, 1.0 / vec3_len(v));
}

Vec3 vec3_cross(Vec3 v, Vec3 w) {
    Vec3 r;
    r.x  = v.y * w.z - v.z * w.y;
    r.y  = v.z * w.x - v.x * w.z;
    r.z  = v.x * w.y - v.y * w.x;
    return r;
}

void matrix_4x4_identity(Matrix4x4 *m) {
    matrix_4x4_zeroes(m);
    m->data[0][0] = 1;
    m->data[1][1] = 1;
    m->data[2][2] = 1;
    m->data[3][3] = 1;
}

bool matrix_4x4_eq(const Matrix4x4 *m1, const Matrix4x4 *m2) {
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

void matrix_4x4_mul(const Matrix4x4 *m1, const Matrix4x4 *m2, Matrix4x4 *out) {
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

void matrix_4x4_random(Matrix4x4 *m) {
    float *x = &(m->data[0][0]);
    for (int i = 0; i < 16; i++) {
        x[i] = (float) rand();
    }
}

void matrix_4x4_translation(Matrix4x4 *m, float tx, float ty, float tz) {
    matrix_4x4_identity(m);
    m->data[3][0] = tx;
    m->data[3][1] = ty;
    m->data[3][2] = tz;
}

void matrix_4x4_look_at(Matrix4x4 *mat, Vec3 camera_pos, Vec3 look_at_point, Vec3 up) {
    Matrix4x4 t, m;

    matrix_4x4_translation(&t, -camera_pos.x, -camera_pos.y, -camera_pos.z);
    
    Vec3 e3 = vec3_normalize(vec3_sub(look_at_point, camera_pos));
    Vec3 up_norm = vec3_normalize(up);
    Vec3 e1 = vec3_cross(up_norm, e3);
    Vec3 e2 = vec3_cross(e3, e1);

    matrix_4x4_identity(&m);
    m.data[0][0] = e1.x;
    m.data[0][1] = e2.x;
    m.data[0][2] = e3.x;
    m.data[1][0] = e1.y;
    m.data[1][1] = e2.y;
    m.data[1][2] = e3.y;
    m.data[2][0] = e1.z;
    m.data[2][1] = e2.z;
    m.data[2][2] = e3.z;

    matrix_4x4_mul(&m, &t, mat);
}

void matrix_4x4_zeroes(Matrix4x4 *m) {
    float *x = &m->data[0][0];
    for (int i = 0; i < 16;i++) x[i] = 0;
}

void matrix_4x4_perspective(Matrix4x4 *m, float n, float f, float w, float h) {
    matrix_4x4_zeroes(m);
    m->data[0][0] = (2*n)/w;
    m->data[1][1] = (2*n)/h;
    m->data[2][2] = f/(f-n);
    m->data[2][3] = 1;
    m->data[3][2] = (f*n)/(n-f);
}

void matrix_4x4_perspective_with_fov(Matrix4x4 *m, float n, float f, float aspect, float fov) {
    float w = (n * tanf(fov))/2;
    float h = w / aspect;
    matrix_4x4_perspective(m, n, f, w, h);
}

void matrix_4x4_print(Matrix4x4 *m) {
    
    printf("[\n");
    printf("%f, %f, %f, %f\n", m->data[0][0], m->data[1][0], m->data[2][0],  m->data[3][0]);
    printf("%f, %f, %f, %f\n", m->data[0][1], m->data[1][1], m->data[2][1],  m->data[3][1]);
    printf("%f, %f, %f, %f\n", m->data[0][2], m->data[1][2], m->data[2][2],  m->data[3][2]);
    printf("%f, %f, %f, %f\n", m->data[0][3], m->data[1][3], m->data[2][3],  m->data[3][3]);
    printf("]\n");
}

#endif // MATH_IMPL
       

#ifdef TEST

#include <assert.h>

bool approx_eql(double x, double y, double eps) {
    return (fabs(x - y) < eps);
}

void math_h_test() {
    {
        Vec3 u = {{ 0, 0, 0 }};
        Vec3 v = {{ 0, 0, 0 }};
        Vec3 w = {{ 1, 0, 0 }};

        assert(vec3_eql(u, v));
        assert(!vec3_eql(u, w));

        u = vec3_create(1, 2, 3);
        v = vec3_create(4, 5, 6);
        w = vec3_create(5, 7, 9);

        assert(vec3_eql(vec3_add(u, v), w));
        
        w = vec3_create(3, 3, 3);
        assert(vec3_eql(vec3_sub(v, u), w));

        assert(vec3_dot(u, v) == 32);

        assert(approx_eql(vec3_len(u), 3.741657, 0.00001));

        w = vec3_create(2, 4, 6);
        assert(vec3_eql(vec3_mul(u, 2), w));
        assert(approx_eql(vec3_len(vec3_normalize(v)), 1, 0.00001));

        Vec3 i = vec3_create(1, 0, 0);
        Vec3 j = vec3_create(0, 1, 0);
        Vec3 k = vec3_create(0, 0, 1);

        assert(vec3_eql(i, vec3_cross(j, k)));
        assert(vec3_eql(k, vec3_cross(i, j)));
        assert(vec3_eql(j, vec3_cross(k, i)));
    }
    {
        
    }
    

    printf("math.h: passed!\n");
}
#endif
    



#endif

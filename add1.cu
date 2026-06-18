#include <cmath>
#include <algorithm>
#include <array>
#include <cstdio>
#include <iterator>
#include "error.cuh"

constexpr double EPSILON = 1.0e-15;
constexpr double a = 1.23;
constexpr double b = 2.34;
constexpr double z = 3.57;
constexpr int N = 1024;
void __global__ add(double *dst, const double *x, const double *y);
void __device__ add_device(const double *x, const double *y);
void check(std::array<double, N> &data);
void check(const double *data, int len);

int main(void) {
    printf("test kernel function add\n");
    // std::array<double, N> h_a {}; // 使用std::array，数据存放在stack中，
    // std::array<double, N> h_b {}; // 若用new，则存放在堆中；若是数据量大，使用new。
    // std::array<double, N> h_z {};
    double *h_a = new double[N];
    double *h_b = new double[N];
    double *h_z = new double[N];
    std::fill(h_a, h_a + N, a);
    std::fill(h_b, h_b + N, b);
    
    double *d_x, *d_y, *d_z;
    constexpr int M = sizeof(double) * N;
    CHECK(cudaMalloc((void**)&d_x, M));
    CHECK(cudaMalloc((void**)&d_y, M));
    CHECK(cudaMalloc((void**)&d_z, M));
    CHECK(cudaMemcpy(d_x, h_a, M, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_y, h_b, M, cudaMemcpyHostToDevice));

    constexpr int block_size = 128;
    constexpr int grid_size = N / 128;

    add<<<grid_size, block_size>>>(d_z, d_x, d_y);

    // cudaMemcpy(h_z.data(), d_z, M, cudaMemcpyDeviceToHost);
    // CHECK(cudaMemcpy(h_z, d_z, M, cudaMemcpyHostToDevice)); // 方向错误了，不提示，不在执行check函数，使用宏函数检测出问题原因
    CHECK(cudaMemcpy(h_z, d_z, M, cudaMemcpyDeviceToHost));
    // check(h_z);
    check(h_z, N);
    
    CHECK(cudaFree(d_x));
    CHECK(cudaFree(d_y));
    CHECK(cudaFree(d_z));

    delete [] h_a;
    delete [] h_b;
    delete [] h_z;
    return 0;
}

void check(std::array<double, N> &data) {
    bool has_error = false;
    for (auto& item : data) {
        if (fabs(item-z)>EPSILON) {
            has_error = true;
        }
    }
    has_error ? printf("Has error\n") : printf("No error\n");
}

void check(const double *data, int len) {
    bool has_error = false;
    for (int i = 0; i < len; ++i) {
        if (fabs(data[i]-z) > EPSILON) {
            has_error = true;
        }
    }
    has_error ? printf("Has error\n") : printf("No error\n");
}

// 为数据相加定义一个设备函数，仅仅是练手
double __device__ add_device(const double x, const double y) {
    return x + y;
}

void __global__ add(double *dst, const double *x, const double *y) {
    const int tid = threadIdx.x + blockIdx.x * blockDim.x;

    if (tid < N) {
        // dst[tid] = x[tid] + y[tid];
        dst[tid] = add_device(x[tid], y[tid]);
        printf("thread id %d: %lf   thread-id:%d, block-id:%d\n", tid, dst[tid], threadIdx.x, blockIdx.x);
    }
}
#include <cmath>
#include <algorithm>
#include <array>
#include <cstdio>

constexpr double EPSILON = 1.0e-15;
constexpr double a = 1.23;
constexpr double b = 2.34;
constexpr double z = 3.57;
constexpr int N = 1024;
void __global__ add(double *dst, const double *x, const double *y);
void __device__ add_device(const double *x, const double *y);
void check(std::array<double, N> &data);

int main(void) {
    printf("test kernel function add\n");
    std::array<double, N> h_a {}; // 使用std::array，数据存放在stack中，
    std::array<double, N> h_b {}; // 若用new，则存放在堆中；若是数据量大，使用new。
    std::array<double, N> h_z {};
    std::fill(h_a.begin(), h_a.end(), a);
    std::fill(h_b.begin(), h_b.end(), b);
    
    double *d_x, *d_y, *d_z;
    const int M = sizeof(double) * N;
    cudaMalloc((void**)&d_x, M);
    cudaMalloc((void**)&d_y, M);
    cudaMalloc((void**)&d_z, M);
    cudaMemcpy(d_x, h_a.data(), M, cudaMemcpyHostToDevice);
    cudaMemcpy(d_y, h_b.data(), M, cudaMemcpyHostToDevice);

    constexpr int block_size = 128;
    constexpr int grid_size = N / 128;

    add<<<grid_size, block_size>>>(d_z, d_x, d_y);

    // cudaMemcpy(h_z.data(), d_z, M, cudaMemcpyDeviceToHost);
    cudaMemcpy(h_z.data(), d_z, M, cudaMemcpyHostToDevice); // 方向错误了，不提示，不在执行check函数
    check(h_z);
    
    cudaFree(d_x);
    cudaFree(d_y);
    cudaFree(d_z);
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
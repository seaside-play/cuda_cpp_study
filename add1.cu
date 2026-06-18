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
void check(std::array<double, N> &data);

int main(void) {
    printf("test kernel function add\n");
    std::array<double, N> h_a {};
    std::array<double, N> h_b {};
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

    cudaMemcpy(h_z.data(), d_z, M, cudaMemcpyDeviceToHost);

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

void __global__ add(double *dst, const double *x, const double *y) {
    const int tid = threadIdx.x + blockIdx.x * blockDim.x;

    dst[tid] = x[tid] + y[tid];
    printf("thread id %d: %lf\n", tid, dst[tid]);
}
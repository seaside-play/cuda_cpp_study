#include <cmath>
#include <algorithm>
#include <array>
#include <cstdio>
#include <iterator>
#include "base.cuh"

constexpr real a = 1.23;
constexpr real b = 2.34;
constexpr real z = 3.57;
constexpr int N = 1e7;
void __global__ add(real *dst, const real *x, const real *y);
void __device__ add_device(const real *x, const real *y);
void check(std::array<real, N> &data);
void check(const real *data, int len);

int main(void) {
    printf("test kernel function add\n");
    // std::array<real, N> h_a {}; // 使用std::array，数据存放在stack中，
    // std::array<real, N> h_b {}; // 若用new，则存放在堆中；若是数据量大，使用new。
    // std::array<real, N> h_z {};
    real *h_a = new real[N];
    real *h_b = new real[N];
    real *h_z = new real[N];
    std::fill(h_a, h_a + N, a);
    std::fill(h_b, h_b + N, b);
    
    real *d_x, *d_y, *d_z;
    constexpr int M = sizeof(real) * N;
    CHECK(cudaMalloc((void**)&d_x, M));
    CHECK(cudaMalloc((void**)&d_y, M));
    CHECK(cudaMalloc((void**)&d_z, M));
    CHECK(cudaMemcpy(d_x, h_a, M, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_y, h_b, M, cudaMemcpyHostToDevice));

    constexpr int block_size = 128;
    constexpr int grid_size = (N + block_size - 1)/ 128;
    
    {
        EventTimer event_timer;   
        add<<<grid_size, block_size>>>(d_z, d_x, d_y);
    }
    

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

void check(std::array<real, N> &data) {
    bool has_error = false;
    for (auto& item : data) {
        if (fabs(item-z)>EPSILON) {
            has_error = true;
        }
    }
    has_error ? printf("Has error\n") : printf("No error\n");
}

void check(const real *data, int len) {
    bool has_error = false;
    for (int i = 0; i < len; ++i) {
        if (fabs(data[i]-z) > EPSILON) {
            has_error = true;
        }
    }
    has_error ? printf("Has error\n") : printf("No error\n");
}

// 为数据相加定义一个设备函数，仅仅是练手
real __device__ add_device(const real x, const real y) {
    return x + y;
}

void __global__ add(real *dst, const real *x, const real *y) {
    const int tid = threadIdx.x + blockIdx.x * blockDim.x;

    // 取消该if语句，使用computer-sanitizer 检测cubin目标文件，就可以详细看到出错的地方。
    // 如：Address 0x7e2ccae02008 is out of bounds，表示越界访问显存了！！！
    if (tid < N) { 
        // dst[tid] = x[tid] + y[tid];
        dst[tid] = add_device(x[tid], y[tid]);
        // printf("thread id %d: %lf   thread-id:%d, block-id:%d\n", tid, dst[tid], threadIdx.x, blockIdx.x);
    }
}
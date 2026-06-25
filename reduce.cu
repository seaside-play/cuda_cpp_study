#include "include/reduce.cuh"
#include <algorithm>
#include <numeric>
#include <iostream>

namespace test {
    
real Reduce::ReduceInCPU(const real *x, const int len) { 
    FUNC();
    EventTimer event_timer;
    real sum = 0.0;
    for (int i = 0; i < len; ++i) {
        sum += x[i];
    }
    return sum;
}

real Reduce::ReduceInGlobalMemory(real *x, const int len) {
    FUNC();
 
    real *d_x;
    int byte_count = sizeof(real) * len;
    CHECK(cudaMalloc(&d_x, byte_count));
    CHECK(cudaMemcpy(d_x, x, byte_count, cudaMemcpyHostToDevice));

    int grid_size = len / 128; // 前提：len是128的整数倍
    {
        EventTimer event_timer;
        reduce_in_global_memory<<<grid_size, 128>>>(d_x, len);
        CHECK(cudaDeviceSynchronize());
    }
    
    CHECK(cudaMemcpy(x, d_x, byte_count, cudaMemcpyDeviceToHost));

    CHECK(cudaFree(d_x));

    real sum = 0.0;
    for (int i = 0; i < grid_size; ++i) {
        sum += x[128 * i];
    }

    return sum;
}

real Reduce::ReduceInSharedMemory(const real *x, const int len) {
    FUNC();
    real *d_x, *d_y;
    int d_x_byte_count = sizeof(real) * len;
    const int block_size = 128;
    const int grid_size = (len+ block_size - 1) / block_size;
    int d_y_byte_count = sizeof(real) * grid_size;

    CHECK(cudaMalloc(&d_x, d_x_byte_count));
    CHECK(cudaMalloc(&d_y, d_y_byte_count));

    CHECK(cudaMemcpy(d_x, x, d_x_byte_count, cudaMemcpyHostToDevice));
 
    {
        EventTimer event_timer;
        // reduce_in_shared_memory<<<grid_size, block_size>>>(d_x, d_y, len);
        // 使用动态共享内存
        reduce_in_shared_memory<<<grid_size, block_size, block_size * sizeof(real)>>>(d_x, d_y, len);
        CHECK(cudaDeviceSynchronize());
    }

    real *h_y = new real[grid_size];
    std::fill(h_y, h_y + grid_size, 0.0f);

    CHECK(cudaMemcpy(h_y, d_y, d_y_byte_count, cudaMemcpyDeviceToHost));
    
    real sum = std::accumulate(h_y, h_y + grid_size, 0.0f);

    delete [] h_y;
    CHECK(cudaFree(d_x));
    CHECK(cudaFree(d_y));

    return sum;
}

} // namespace test
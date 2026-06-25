#include "include/reduce.cuh"
#include <iostream>

namespace test {
    
real Reduce::ReduceInCPU(const real *x, const int len) {
    std::cout << __func__ << ": " << std::endl;
    EventTimer event_timer;
    real sum = 0.0;
    for (int i = 0; i < len; ++i) {
        sum += x[i];
    }
    return sum;
}

real Reduce::ReduceInGlobalMemory(real *x, const int len) {
    std::cout << __func__ << ": " << std::endl;
 
    real *d_x;
    int byte_count = sizeof(real) * len;
    CHECK(cudaMalloc(&d_x, byte_count));
    CHECK(cudaMemcpy(d_x, x, byte_count, cudaMemcpyHostToDevice));

    int grid_size = len / 128; // 前提：len是128的整数倍
    {
        EventTimer event_timer;
        reduce_in_global_memory<<<grid_size, 128>>>(d_x, len);
    }
    
    CHECK(cudaDeviceSynchronize());
    CHECK(cudaMemcpy(x, d_x, byte_count, cudaMemcpyDeviceToHost));

    CHECK(cudaFree(d_x));

    real sum = 0.0;
    for (int i = 0; i < grid_size; ++i) {
        sum += x[128 * i];
    }

    return sum;
}

real Reduce::ReduceInSharedMemory(const real *x, const int len) {
    return 0.0;
}


} // namespace test
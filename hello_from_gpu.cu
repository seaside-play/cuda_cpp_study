#include <cstdio>

// 该核函数可以很好的理解线程组织结构
__global__ void hello_from_gpu() {
    int tid = threadIdx.x + threadIdx.y * blockDim.x + threadIdx.z * blockDim.x * blockDim.y;
    int bid = blockIdx.x + blockIdx.y * gridDim.x + blockIdx.z * gridDim.x * gridDim.y;
    printf("Hello World, tid is %d, from thread (%d, %d, %d) in block %d\n", 
           tid, threadIdx.x, threadIdx.y, threadIdx.z, bid);
}

int main() {
    // hello_from_gpu<<<2, 4>>>();
    // 指定二维的线程块
    dim3 block_size(2, 4);
    hello_from_gpu<<<2, block_size>>>();
    cudaDeviceSynchronize();
    return 0;
}
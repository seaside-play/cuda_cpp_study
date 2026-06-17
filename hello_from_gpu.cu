#include <cstdio>

__global__ void hello_from_gpu() {
    printf("Hello World, from thread %d in block %d\n", threadIdx.x, blockIdx.x);
}

int main() {
    hello_from_gpu<<<2, 4>>>();
    cudaDeviceSynchronize();
    return 0;
}
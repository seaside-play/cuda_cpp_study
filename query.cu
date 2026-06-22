#include "error.cuh"
#include <cstdio>

int main(int argc, char* argv[]) {
    int device_id = 0;
    if (argc > 1) {
        device_id = std::atoi(argv[1]);
    }
    CHECK(cudaSetDevice(device_id));

    cudaDeviceProp device_prop;
    CHECK(cudaGetDeviceProperties(&device_prop, device_id));

    printf("Device id: %d\n", device_id);
    printf("Device name: %s\n", device_prop.name);
    printf("Device compute capability: %d.%d\n", device_prop.major, device_prop.minor);
    printf("Amount of global memory: %g GB\n", device_prop.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
    printf("Amount of constant memory: %g KB\n", device_prop.totalConstMem / 1024.0);
    printf("Maximum grid size: %d  %d  %d\n", device_prop.maxGridSize[0], device_prop.maxGridSize[1], device_prop.maxGridSize[2]);
    printf("Maximum block size: %d  %d  %d\n", device_prop.maxThreadsDim[0], device_prop.maxThreadsDim[1], device_prop.maxThreadsDim[2]);
    printf("Number of SMs: %d\n", device_prop.multiProcessorCount);
    printf("Maximum number of shared memory per block: %g KB\n", device_prop.sharedMemPerBlock / 1024.0);
    printf("---\n");
    printf("Maximum number of registers per block: %g KB\n", device_prop.regsPerBlock / 1024.0);
    printf("Maximum number of registers per SM: %g KB\n", device_prop.regsPerMultiprocessor / 1024.0);

    printf("---\n");
    printf("Maximum number of threads per block: %d\n", device_prop.maxThreadsPerBlock);
    printf("Maximum number of threads per SM: %d\n", device_prop.maxThreadsPerMultiProcessor);
    return 0;
}
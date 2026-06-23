#include "include/base.cuh"

namespace test {

__global__ void matrix_copy(real *B, const real *A, const MatDim2D &mat_dim_2d) {
    // printf("enter matrix_copy\n");
    const int x = blockDim.x * blockIdx.x + threadIdx.x; // 先确定在哪个block块的x坐标上的位置，再确定在block块中的哪个x位置的线程
    const int y = blockDim.y * blockIdx.y + threadIdx.y; // 然后确定在哪个block块的y坐标上的位置，再确定在block块中的哪个y位置的线程
    int index = y * mat_dim_2d.rows + x; // 顺序合并访问模式
    printf("index: %d, x:%d y:%d\n", index, x, y);
    if (x < mat_dim_2d.cols && y < mat_dim_2d.rows) {
        B[index] = A[index];
    }
}

} // namespace test
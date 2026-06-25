#include "include/base.cuh"

namespace test {

__global__ void matrix_copy(real *B, const real *A, const MatDim2D mat_dim_2d) {
    // printf("enter matrix_copy\n");
    const int x = blockDim.x * blockIdx.x + threadIdx.x; // 先确定在哪个block块的x坐标上的位置，再确定在block块中的哪个x位置的线程
    const int y = blockDim.y * blockIdx.y + threadIdx.y; // 然后确定在哪个block块的y坐标上的位置，再确定在block块中的哪个y位置的线程
    int index = y * mat_dim_2d.cols + x; // 顺序合并访问模式
    // printf("index: %d, x:%d y:%d\n", index, x, y);
    if (x < mat_dim_2d.cols && y < mat_dim_2d.rows) {
        B[index] = A[index];
    }
}

// 实现矩阵转置
__global__ void matrix_transpose1(real *B, const real *A, const MatDim2D mat_dim_2d) {
    const int x = blockDim.x * blockIdx.x + threadIdx.x;
    const int y = blockDim.y * blockIdx.y + threadIdx.y;
    // printf("%d:%d\n", x, y);
    int index_src = y * mat_dim_2d.cols + x;
    int index_des = x * mat_dim_2d.rows + y;
    if (x < mat_dim_2d.cols && y < mat_dim_2d.rows) {
        B[index_des] = A[index_src];
    }
}

__global__ void matrix_transpose2(real *B, const real *A, const MatDim2D mat_dim_2d) {
    const int x = blockDim.x * blockIdx.x + threadIdx.x;
    const int y = blockDim.y * blockIdx.y + threadIdx.y;
    int index_src = x * mat_dim_2d.rows + y;
    int index_des = y * mat_dim_2d.cols + x;
    if (x < mat_dim_2d.cols && y < mat_dim_2d.rows) {
        B[index_des] = A[index_src];
    }
}

__global__ void matrix_transpose3(real *B, const real *A, const MatDim2D mat_dim_2d) {
    const int x = blockDim.x * blockIdx.x + threadIdx.x;
    const int y = blockDim.y * blockIdx.y + threadIdx.y;
    int index_src = x * mat_dim_2d.rows + y;
    int index_des = y * mat_dim_2d.cols + x;
    if (x < mat_dim_2d.cols && y < mat_dim_2d.rows) {
        B[index_des] = __ldg(&A[index_src]);
    }
}

__global__ void reduce_in_global_memory(real *d_x, const int len) {
    int tid = threadIdx.x;
    real *x = d_x + blockDim.x * blockIdx.x;
    for (int offset = blockDim.x >> 1; offset > 0; offset >>= 1) {
        if (tid < offset) {
            x[tid] += x[tid + offset];
            __syncthreads();
        }
    }
}

__global__ void reduce_in_shared_memory(real *x, real *y, const int len) {


}


} // namespace test
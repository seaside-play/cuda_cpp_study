#ifndef KERNELS_H_
#define KERNELS_H_
#include "base.cuh"

namespace test {

// 注意：这里mat_dim_2d使用引用，将出现an illegal memory access was encountered
__global__ void matrix_copy(real *B, const real *A, const MatDim2D mat_dim_2d);

// 实现矩阵转置
__global__ void matrix_transpose1(real *B, const real *A, const MatDim2D mat_dim_2d);
__global__ void matrix_transpose2(real *B, const real *A, const MatDim2D mat_dim_2d);
__global__ void matrix_transpose3(real *B, const real *A, const MatDim2D mat_dim_2d);

// 归约数组
__global__ void reduce_in_global_memory(real *x, const int len);
__global__ void reduce_in_shared_memory(real *x, real *y, const int len);

} // namespace test
#endif // KERNELS_H_
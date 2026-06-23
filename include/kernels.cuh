#ifndef KERNELS_H_
#define KERNELS_H_
#include "base.cuh"

namespace test {

// 注意：这里mat_dim_2d使用引用，将出现an illegal memory access was encountered
__global__ void matrix_copy(real *B, const real *A, const MatDim2D mat_dim_2d);

} // namespace test
#endif // KERNELS_H_
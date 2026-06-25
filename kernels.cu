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
        }
        __syncthreads();
    }
}

__global__ void reduce_in_shared_memory(real *d_x, real *y, int len) {
    int tid = threadIdx.x;
    int bid = blockIdx.x;
    int i = blockDim.x * blockIdx.x + tid;
    //__shared__ real s_data[blockDim.x]; // 这样就可以完全和线程块的长度一致,但是数组需要常量数定义啊，所以不能使用
    // __shared__ real s_data[128]; // 此处为静态共享内存，也可以使用动态共享内存，这样通用性就更强大
    extern __shared__ real s_data[]; // 我的理解是，编译器会根据执行配置的参数来判断共享内存，并且进行底层参数的指定，
                                     // 使用extern标识说明使用动态共享内存
    s_data[tid] = (i < len) ? d_x[i] : 0.0f;
    __syncthreads(); // 全部线程块中的所有线程，都实现了数据的赋值工作。

    for (int offset = blockDim.x >> 1; offset > 0; offset >>= 1) {
        if (tid < offset) {
            s_data[tid] += s_data[tid + offset];
        }
        __syncthreads();
    }

    if (0 == tid) {
        y[bid] = s_data[0]; // 将共享内存中的结果赋值到全局内存中，gpu内存之间的赋值，可以直接操作。
    }

}


} // namespace test
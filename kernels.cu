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

/**********************************************************************
 * 功能：使用静态共享内存进行矩阵转置
 *      将全局内存中的数据先放入静态共享内存中，转置时，直接从共享内存中读取数据
 * 作者：Chris
 * 时间：2026.06.25
 * 参数：real *B         存放矩阵转置后的结果
 *      const real *A   存放原始矩阵数据
 *      const MatDim2D mat_dim_2d 指明2维矩阵的维度，行数和列数
*********************************************************************** */
__global__ void matrix_transpose1_by_shared_memory(real *B, const real *A, const MatDim2D mat_dim_2d) {
    __shared__ real s_data[TILE_DIM][TILE_DIM]; // 因为是静态共享内存，只能用全局变量或const变量
    int bx = blockIdx.x * blockDim.x;
    int by = blockIdx.y * blockDim.y;

    int x = bx + threadIdx.x;
    int y = by + threadIdx.y;
    if (x < mat_dim_2d.cols && y < mat_dim_2d.rows) {
        s_data[threadIdx.y][threadIdx.x] = A[y*mat_dim_2d.cols+x]; // 用心体会这里的书写方式
    }
    __syncthreads(); // 数据初始化时，需要实现线程块内所有线程束的同步功能
    int x1 = y; // 转置时，对原始的x和y进行对调, 即便进行了对调，
    int y1 = x; 
    // B的维度与A的维度，刚好相反
    // MatDim2D mat_transpose{mat_dim_2d.cols, mat_dim_2d.rows};
    // 这里仍然保持的原始A的二维数组的规则，但是偏移值却不在是cols，而是rows
    if (x1 < mat_dim_2d.cols && y1 < mat_dim_2d.rows) { // 即便进行了（x,y）对调，但二维数组的范围值，仍然没有变化；
        // 如何理解：B[x1 * mat_dim_2d.rows + y1] 我们注意到这个的y1，就是x，是连续的数据，那么这样就保证了B是连续的，
        // 但是不再以cols为单位进行偏移，而是以rows进行偏移，仅仅rows个数据进行邻接赋值。
        // 如何理解：s_data[threadIdx.x][threadIdx.y]，首先s_data的结构没有变化，就是普通的(x,y)啊
        B[x1 * mat_dim_2d.rows + y1] = s_data[threadIdx.x][threadIdx.y]; // 共享内存已是缓存了，不用考虑合并，要考虑B的合并访问
        // printf("x1:y1(%d:%d) threadIdx.x:threadIdx.y(%d:%d)\n", x1,y1, threadIdx.x, threadIdx.y);
                                                                         
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
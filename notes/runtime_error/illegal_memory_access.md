an illegal memory access was encountered — CUDA 非法访存完整排查方案
一、报错本质
GPU kernel 运行时，线程访问了不在当前线程合法显存范围的地址：
越界读 / 写、空指针、主机指针直接传给 GPU、对齐错误、共享内存越界、数组索引溢出。
这个错误是异步运行时错误，只同步后 cudaDeviceSynchronize() / cudaEventSynchronize 才能捕获。

出错代码：

    __global__ void matrix_copy(real *B, const real *A, const MatDim2D &mat_dim_2d);

出错原因：
GPU 不支持主机引用
MatDim2D & 是主机侧引用，你直接传给 __global__ 核函数，GPU 拿到的是主机内存地址，读取结构体时直接越界报错。

CUDA 规则：
__global__ 形参不能传引用 &，只能传值；
设备函数 __device__ 才允许设备内存引用；
主机结构体对象用引用传入核函数 = 非法设备访存。
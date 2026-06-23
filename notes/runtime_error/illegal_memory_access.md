an illegal memory access was encountered — CUDA 非法访存完整排查方案
一、报错本质
GPU kernel 运行时，线程访问了不在当前线程合法显存范围的地址：
越界读 / 写、空指针、主机指针直接传给 GPU、对齐错误、共享内存越界、数组索引溢出。
这个错误是异步运行时错误，只同步后 cudaDeviceSynchronize() / cudaEventSynchronize 才能捕获。
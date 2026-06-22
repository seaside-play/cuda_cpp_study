nvcc -arch=sm_61 -o add1.exe add1.cu
nvcc -o add1.exe add1.cu

// 使用最快定位工具（工业标准）
nvcc -arch=sm_61 -lineinfo -o add1.exe add1.cu
compute-sanitizer ./add1.exe > saniter_add1.txt


nvcc -O3 -I./include main.cu -DUSE_DP -o add1.exe  # -I./include：把当前目录下的 include 加入头文件搜索路径

核心参数：-D 定义宏，-U 取消宏

nvcc -O3 -arch=sm_61 -I./include add1.cu -o add1.exe            ：单精度耗时 3.42173 ms
nvcc -O3 -arch=sm_61 -I./include add1.cu -DUSE_DP -o add1.exe   ：双精度耗时 6.79302 ms


实现Nsight分析运行后终端输出每个 Kernel 的耗时、SM 占用、带宽、占用率等指标。
chris@x:~/workspace/cuda_cpp_study$ nvcc -arch=sm_61 -g --ptxas-options=-v -I./include add1.cu -o add1.exe
ptxas info    : 0 bytes gmem
ptxas info    : Compiling entry function '_Z3addPfPKfS1_' for 'sm_61'
ptxas info    : Function properties for _Z3addPfPKfS1_
    0 bytes stack frame, 0 bytes spill stores, 0 bytes spill loads
ptxas info    : Used 8 registers, 344 bytes cmem[0], 4 bytes cmem[2]


ncu ./add1.exe分析每个 Kernel 的耗时、SM 占用、带宽、占用率等指标。
chris@x:~/workspace/cuda_cpp_study$ ncu add1.exe
test kernel function add
==PROF== Connected to process 13124 (/home/chris/workspace/cuda_cpp_study/add1.exe)
==ERROR== ERR_NVGPUCTRPERM - The user does not have permission to access NVIDIA GPU Performance Counters on the target device 0. For instructions on enabling permissions and to get more information see https://developer.nvidia.com/ERR_NVGPUCTRPERM
Elapsed 4.34544 ms.
No error
==PROF== Disconnected from process 13124
==WARNING== No kernels were profiled.


标准CUDA调优工作流程：
1. nsys profile -o trace ./main
   nsys-ui trace.nsys-rep
看时间轴，找到耗时Top1，Top2的kernel名称，记录下来
2. ncu --kernel-regex "add_kernel" -set full ./main
分析占用率，访存，阻塞原因，修改代码（调Block尺寸，合并内存，优化共享内容）
3. 修改代码后，重复1，2步，对比优化收益
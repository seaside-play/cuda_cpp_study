一句话流程：先用 nsys 找哪个环节慢，再用 ncu 深挖单个 Kernel 为什么慢，二者互补、不能互相替代。
# 一、核心定位对比
1. Nsight Systems（命令：nsys /nsys-ui）系统级宏观工具
视角：全程序时间线，CPU + GPU 全局调度
解决问题：时间都耗在哪？CPU 与 GPU 配合是否有浪费？
粒度：API、线程、流、内存拷贝、Kernel 执行段（粗粒度）
采集开销极低，适合完整跑一遍程序做全局扫描
不看 Kernel 内部硬件细节
2. Nsight Compute（命令：ncu /ncu-ui）内核微观工具
视角：单 CUDA Kernel 内部 SM 硬件细节
解决问题：这个 Kernel 为什么跑不快？资源利用率低的根源？
粒度：warp、寄存器、共享内存、L1/L2/DRAM 带宽、指令阻塞
采集开销大，只能单独分析少数热点 Kernel
只针对 CUDA 计算内核，不关心 CPU、memcpy、同步流程
# 二、详细功能对照表
表格
对比项	    Nsight Systems (nsys)	                             Nsight Compute (ncu)
分析层级	全应用系统级、CPU-GPU 协同	                            单个 CUDA Kernel 硬件微架构
可视化形式	长条时间轴 Timeline	                                   指标表格、屋顶图 Roofline、源码行指标
能看到什么	1. CPU 所有线程、函数耗时2. cudaMemcpy H2D/D2H 耗时3. CUDA Stream、Kernel 启动时序4. 同步等待（cudaSync）GPU 空白闲置5. cuBLAS/cuDNN/TensorRT 库调用6. 多 GPU、进程调度、IO	

            1. SM 占用率 Occupancy（替代 xls 计算器）2. 每线程寄存器、每 Block 共享内存限制3. L1/L2/DRAM 带宽、缓存命中率4. Warp 分化、分支阻塞、同步等待5. 计算 / 访存瓶颈判定（Roofline）6. 逐行源码硬件开销
典型报错限制  所有显卡通用（包括 GTX10 Pascal），无硬件计数器封锁问题	 Pascal（GTX10）完全不支持；RTX20/30/40 需要放开 GPU 性能计数器权限
采集速度	快，完整程序一次跑完	                                 慢，会重复执行 Kernel 采集硬件 PMU
适用阶段	第一步全局扫描、定位热点	                              第二步深度调优选中的慢 Kernel

# 三、各自能排查的典型问题
Nsight Systems 专属排查场景
GPU 大部分时间空白闲置：CPU 预处理太慢、同步太多
cudaMemcpy 拷贝占总耗时 20% 以上：数据传输瓶颈
大量微小 Kernel 频繁启动，Launch 开销大于计算本身
Stream 串行执行，没有重叠计算与拷贝
CPU 多线程调度、锁、文件 IO 拖慢整体流程
多 GPU 任务负载不均衡

Nsight Compute 专属排查场景（CUDA 内核调优核心）
SM 占用率过低（<60%）：寄存器 / 共享内存限制 Block 并行数量
DRAM 带宽打满、计算单元空闲：访存瓶颈（内存受限）
DRAM 带宽很低，FP32 指令跑不满：计算瓶颈
大量 warp stall、分支 if-else 分化严重
非合并全局内存访问，L1 缓存命中率极低
动态共享内存分配不合理，限制并发 Block

# 四、标准 CUDA 调优工作流（先 nsys 后 ncu）
Nsight Systems 全局扫描
bash
运行
        nsys profile -o trace ./add1.exe
        nsys-ui trace.nsys-rep
看时间轴，找到耗时 Top1、Top2 的 Kernel 名称，记录下来。
Nsight Compute 针对性深度剖析该 Kernel
bash
运行
        # 只分析刚才找到的add_kernel
        ncu --kernel-regex "add_kernel" --set full ./add1.exe
        分析占用率、访存、阻塞原因，修改代码（调 Block 尺寸、合并访存、优化共享内存）。
修改代码后重复 1、2 步对比优化收益。
# 五、针对你 GTX10 Pascal 笔记本的特殊限制
Nsight Systems（nsys）完全可用，无任何限制，正常采集全流程时序；
Nsight Compute（ncu）不支持 GTX10 Pascal，会提示 Profiling is not supported on device 0；
折中方案：用 nsys nvprof 查看基础 Kernel 指标，配合在线 Occupancy 计算器手动算理论占用率。
# 六、两条极简示例命令
Nsight Systems 采集全局 trace
bash
运行
    nsys profile -t cuda,nvtx ./your_cuda_program
Nsight Compute 采集单个 Kernel 完整硬件指标（RTX20/30/40 显卡可用）
bash
运行
    ncu --set full --kernel-regex ".*kernel_name.*" ./your_cuda_program
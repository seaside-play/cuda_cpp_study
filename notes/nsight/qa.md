# 1 没有开权限

test kernel function add
==PROF== Connected to process 13384 (/home/chris/workspace/cuda_cpp_study/add1.exe)
==ERROR== ERR_NVGPUCTRPERM - The user does not have permission to access NVIDIA GPU Performance Counters on the target device 0. For instructions on enabling permissions and to get more information see https://developer.nvidia.com/ERR_NVGPUCTRPERM
Elapsed 3.88765 ms.
No error
==PROF== Disconnected from process 13384
==WARNING== No kernels were profiled.


报错 ERR_NVGPUCTRPERM 完整解决（两个权限都要开：Linux perf + NVIDIA GPU 剖析权限）
你现在的报错不是 perf_event_paranoid，是NVIDIA 驱动单独限制了普通用户读取 GPU 硬件计数器，分两步修复，缺一不可。
一、报错原因
NVIDIA 驱动默认：只有 root 用户才能采集 GPU 性能计数器，普通用户运行 ncu 直接拒绝读取 SM、带宽、占用率等硬件指标，最后提示 No kernels were profiled。
二、修复步骤（Ubuntu 22.04）
步骤 1：修改 NVIDIA 驱动参数，放开普通用户剖析权限
创建驱动配置文件
bash
运行
sudo tee /etc/modprobe.d/nvidia-profiling.conf <<EOF
options nvidia NVreg_RestrictProfilingToAdminUsers=0
EOF

更新启动镜像，重启生效
bash
运行
sudo update-initramfs -u
sudo reboot

步骤 2：保持内核 perf 权限为 0（之前那条命令）
临时生效（重启失效）
bash
运行
sudo sh -c 'echo 0 > /proc/sys/kernel/perf_event_paranoid'

永久生效（开发机推荐）
bash
运行
echo "kernel.perf_event_paranoid=0" | sudo tee /etc/sysctl.d/99-perf.conf
sudo sysctl -p

三、临时绕过方案（不想重启电脑）
直接用 sudo 运行 ncu，root 自带全部权限，无需改驱动配置：
bash
运行
sudo ncu ./add1.exe

缺点：sudo 环境变量、CUDA 路径可能不一致，优先用上面永久方案。
四、验证权限是否生效
重启后执行，无报错即正常：
bash
运行
ncu --section LaunchStats ./add1.exe

补充说明两个权限区别（避免混淆）
perf_event_paranoid：Linux 系统 CPU 侧性能计数器权限
NVreg_RestrictProfilingToAdminUsers=0：NVIDIA GPU 硬件计数器权限
你的报错 ERR_NVGPUCTRPERM 只和第二条驱动参数相关。
常见踩坑
只改 perf_event_paranoid 不修改 nvidia modprobe → 依旧报 ERR_NVGPUCTRPERM
写入 modprobe 后没执行 update-initramfs + 重启 → 参数不加载
WSL2 环境：部分旧驱动不支持普通用户剖析，只能 sudo 运行 ncu


chris@x:~/workspace/cuda_cpp_study$ sudo /usr/local/cuda-12.4/bin/ncu ./add1.exe
test kernel function add
==PROF== Connected to process 4613 (/home/chris/workspace/cuda_cpp_study/add1.exe)
==ERROR== Profiling is not supported on device 0. To find out supported GPUs refer --list-chips option.
Elapsed 4.18365 ms.
No error
==PROF== Disconnected from process 4613
==WARNING== No kernels were profiled.


chris@x:~/workspace/cuda_cpp_study$ ncu --list-chips
ad102, ad103, ad104, ad106, ad107, ga100, ga102, ga103, ga104, ga106, ga107, ga10b, gh100, gv100, gv11b, tu102, tu104, tu106, tu116, tu117
说明：
ad102/ad103/ad104/ad106/ad107 → Ada Lovelace（RTX40系列）
ga100/ga102/ga103/ga104/ga106/ga107/ga10b → Ampere（RTX30/A100）
gh100 → Hopper（H100）
gv100/gv11b → Volta（V100）
tu102/tu104/tu106/tu116/tu117 → Turing（RTX20/GTX16）

关键规则
Nsight Compute 从发布起就彻底不支持 Pascal 架构 GP10x（GTX10 全系：1050/1060/1070/1080）
你的列表里完全没有 GP100/GP102/GP104/GP106/GP108，说明：
你的显卡是 GTX10 系列 Pascal，直接触发报错：
Profiling is not supported on device 0
权限全开、驱动升级都没用，硬件架构不兼容 ncu

## 1.1 两套替代方案（GTX10 只能用这两个）
### 1.1.1 方案 1：Nsight Systems（nsys，必可用，推荐）
只能看宏观时序、kernel 耗时、显存拷贝、调用栈，看不到 SM 占用 / 寄存器 / 访存细分指标，但能定位慢 Kernel。
bash
运行
        # 采集trace
        nsys profile -o trace ./add1.exe
        # 图形界面打开
        nsys-ui trace.nsys-rep


### 1.1.2 方案 2：nvprof（传统内核指标工具，Pascal 专用）
CUDA12 虽然移除了独立 nvprof 命令，但可以套在 nsys 里用，拿到寄存器、共享内存、SM 占用率、各类 metrics：
bash
        运行
        # 完整指标采集
        nsys nvprof --metrics all ./add1.exe
        # 只看占用率相关指标
        nsys nvprof --metrics sm_efficiency,achieved_occupancy ./add1.exe
        
### 1.1.3 方案 3：纯理论占用率计算（替代旧 cuda_occupancy_calculator.xls）
在线计算器，手动填入算力、block 大小、寄存器、共享内存，算理论占用率：
https://xmartlabs.github.io/cuda-calculator/
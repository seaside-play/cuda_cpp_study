Ubuntu 默认禁用 perf 事件计数器，否则提示Profiling disabled，为什么?

# 一、先讲这条命令到底做了什么
bash
运行
sudo sh -c 'echo 0 > /proc/sys/kernel/perf_event_paranoid'
/proc/sys/kernel/perf_event_paranoid 是内核运行时参数文件，控制普通用户访问 CPU/GPU 硬件性能计数器（PMU） 的权限等级；
默认 Ubuntu22.04 该值是 1；
命令把它临时改成 0，放开普通用户读取硬件性能事件的权限；
Nsight Compute（ncu）底层依赖 Linux perf_events 子系统读取硬件计数器采集 `SM 占用、寄存器、访存指标`，参数不够低就会报错：Profiling disabled。
# 二、Ubuntu 默认值 = 1，为什么要限制、禁用完整 perf 计数器？
1. 核心原因 1：侧信道信息泄露攻击（最关键）
硬件性能计数器会暴露极细粒度执行特征：每条指令周期、缓存命中 / 缺失、分支跳转、内存访问时序。
恶意普通用户可以：
- 利用计数器时序差异，窃取密码、密钥、内存敏感数据（Spectre/Meltdown 类侧信道漏洞）；
- 监听其他进程内核态执行轨迹，绕过权限隔离偷看系统 / 其他用户隐私；
- 监控内核函数调用、内核符号，挖掘内核漏洞用于本地提权。
如果默认开放全部计数器，普通非 root 用户就能大面积窥探系统机密，安全风险极高。
2. 核心原因 2：perf_events 是高危内核攻击面
perf_event_open 是逻辑极复杂的系统调用，历史上爆出大量本地提权 CVE 漏洞。
发行商（Ubuntu）默认抬高限制等级，缩小非特权用户能触发的内核代码路径，减少漏洞利用入口。
3. 核心原因 3：防止资源耗尽 DoS
无限制采样硬件计数器会频繁触发 CPU 中断，大量占用 CPU、内存；普通用户恶意持续采样可拖慢整机。paranoid 等级限制普通用户采样范围、采样频率。
4. 核心原因 4：区分 “普通监控” 和 “底层硬件剖析”
值 = 1（Ubuntu 默认）的规则：
- 普通用户只能采集纯用户态轻量软件事件（进程运行时间等）；
- 禁止读取原始硬件 PMU 计数器、内核态事件、系统全局采样；
- 而 Nsight Compute 需要读取 GPU 协同的底层硬件性能事件（SM 调度、warp、L2 缓存、DRAM 带宽），刚好被 1 等级拦截，直接判定 Profiling disabled。

# 三、perf_event_paranoid 各数值权限对照表（看懂为什么 0 才能跑 ncu）
表格
值	权限说明	                                    是否能跑 Nsight Compute
-1	完全放开，所有用户任意采样内核 + 硬件计数器	         可以，不推荐生产
0	普通用户可读硬件 PMU；内核级跟踪仅 root 可用        ✅ 刚好满足 ncu 需求（开发常用）
1（Ubuntu 默认）	普通用户禁止硬件 / 内核原始计数器    ❌ 报 Profiling disabled
2	仅 root/CAP_PERFMON 才能使用 perf 所有接口	      ❌
3	普通用户完全无法调用 perf_event_open	          ❌

# 四、为什么改到 0 就能解决 Nsight Compute 报错？
ncu 采集 GPU 指标时，会同时依赖两套计数器：
1. NVIDIA GPU 硬件性能计数器（SM、warp、共享内存、带宽）；
2. Linux 内核 perf_events 框架做进程调度、时间戳同步、硬件采样调度；
当 paranoid=1：内核拦截普通用户发起的硬件性能事件采集请求，ncu 拿不到底层硬件采样数据，直接抛出 Profiling disabled。
改成 0 后，内核允许普通用户读取硬件 PMU 数据，剖析流程正常运行。
# 五、重要安全提醒
echo 0 只是临时生效，重启 Ubuntu 后变回默认 1；
生产服务器不要长期设为 0，仅本地开发机调试 CUDA 时临时 / 永久开启；
配套 NVIDIA 驱动还有一层限制，需同步配置：
bash
运行
# 放开GPU剖析权限
echo "options nvidia NVreg_RestrictProfilingToAdminUsers=0" | sudo tee /etc/modprobe.d/nvidia-prof.conf
sudo update-initramfs -u && reboot
永久修改内核参数（开发机）：
bash
运行
echo "kernel.perf_event_paranoid=0" | sudo tee /etc/sysctl.d/99-perf.conf
sudo sysctl -p
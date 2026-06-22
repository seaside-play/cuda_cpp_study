Ubuntu22.04 Nsight Compute 完整使用教程
# 一、先分清定位
Nsight Compute（ncu）：Kernel 内核级分析，看 SM 占用、寄存器、共享内存、访存瓶颈、占用率（替代旧 xls 计算器）
Nsight Systems：进程 / API 宏观时间线，先找慢 Kernel，再用 ncu 深挖原因
# 二、安装（Ubuntu22.04）
CUDA 自带（已装 cuda toolkit）
路径示例：/usr/local/cuda-12.4/bin/ncu、/usr/local/cuda-12.4/bin/ncu-ui
验证安装
ncu --version      # 命令行采集工具
ncu-ui            # 图形界面
权限修复（必做，否则采集失败）
Ubuntu 默认禁用 perf 事件计数器，否则提示Profiling disabled
bash
运行
        # 临时生效（重启失效）
        sudo sh -c 'echo 0 > /proc/sys/kernel/perf_event_paranoid'
        # perf_event_paranoid是内核运行时参数文件，控制普通用户访问 CPU/GPU 硬件性能计数器（PMU） 的权限等级；
        # 永久生效
        sudo nano /etc/sysctl.conf
        # 添加一行
        kernel.perf_event_paranoid = 0
        # 重载
        sudo sysctl -p

sudo sh -c 'echo 0 > /proc/sys/kernel/perf_event_paranoid'
/proc/sys/kernel/perf_event_paranoid 是内核运行时参数文件，控制普通用户访问 CPU/GPU 硬件性能计数器（PMU） 的权限等级；
默认 Ubuntu22.04 该值是 1；
命令把它临时改成 0，放开普通用户读取硬件性能事件的权限；
Nsight Compute（ncu）底层依赖 Linux perf_events 子系统读取硬件计数器采集 SM 占用、寄存器、访存指标，参数不够低就会报错：Profiling disabled。

# 三、两种使用模式：命令行 ncu、图形界面 ncu-ui
模式 1：命令行 ncu（批量 / 自动化 / 服务器无 GUI 首选）
1. 基础语法
bash
运行
ncu [参数] 可执行文件 [程序参数]
2. 最简示例（采集所有 kernel 基础指标）
bash
运行
        # 编译cuda程序必须加-g调试符号，源码行才能对应指标
        nvcc -g --ptxas-options=-v test.cu -o test
        # 采集分析
        ncu ./test
运行后终端输出每个 Kernel 的耗时、SM 占用、带宽、占用率等指标。
3. 保存报告到文件（.ncu-rep，可图形界面打开细看）
bash
运行
        # -o 指定输出报告
        ncu -o profile_report ./test
        # 采集完成自动打开图形界面查看
        ncu -o profile_report --open-in-ui ./test
4. 高频实用参数
① 只分析指定 kernel（过滤无关内核）
bash
运行
        # 精确匹配内核名
        ncu --kernel vector_add ./test
        # 正则匹配含matmul的所有kernel
        ncu --kernel-regex ".*matmul.*" ./test
② 完整深度指标（自动计算 SM 占用率、屋顶图、访存 / 计算瓶颈）
bash
运行
        # full模式，包含SpeedOfLight（自动瓶颈诊断，替代xls占用率表格）
        ncu --set full -o full_report ./test
③ 只采集占用率相关指标（对应你之前的 cuda_occupancy_calculator）
bash
运行
        # 只看SM、warp、寄存器、共享内存、占用率
        ncu --section LaunchStats --section SchedulerStatistics ./test
④ 限制采集次数（程序跑很多轮时只抓第一轮 kernel）
bash
运行
        ncu --launch-count 1 ./test
⑤ 屏蔽冗余输出、只看关键汇总
bash
运行
        ncu --quiet --set basic ./test
5. 常用 section 分析模块（按需组合，减少采集耗时）
SpeedOfLight：自动瓶颈诊断（最核心，直接告诉你是内存 / 计算限制）
LaunchStats：Block 尺寸、寄存器、smem、SM 占用率 Occupancy
MemoryWorkloadAnalysis：全局内存 / L1/L2 缓存带宽、访存延迟
ComputeWorkloadAnalysis：算术指令吞吐量、warp 分支分化
SchedulerStatistics：warp 调度、活跃 warp 数量
示例：只分析占用率 + 内存瓶颈
bash
运行
    ncu --section LaunchStats --section MemoryWorkloadAnalysis -o mem_occ ./test
模式 2：图形界面 ncu-ui（本地 Ubuntu 可视化调优，最直观）
1. 启动 GUI
bash
运行
ncu-ui


Nsight Compute欢迎页
2. 新建分析任务步骤
首页点 Start Activity → Profile


Launch配置面板
Target Platform：Linux (x86_64)，Connection 选localhost
Launch 标签页填写：
Application Executable：你的 cuda 可执行文件路径
Working Directory：程序运行目录
Command Line Arguments：程序传入参数（无则空）
Activity 面板设置：
Output File：填保存的.ncu-rep路径
Target Processes：All
Graph Profiling：Node（完整指标）
右下角点 Launch，程序自动运行并采集数据
3. 已有报告打开查看
bash
运行
# 终端直接打开报告
ncu-ui profile_report.ncu-rep
# 或GUI内 File → Open
4. 报告核心页面（重点看占用率、瓶颈）
1）Summary 总览页（第一眼必看）
Kernel 总耗时、Grid/Block 尺寸
Multiprocessor Occupancy：SM 占用率（替代 xls 表格）
DRAM/L2/L1 带宽利用率、计算 / 内存屋顶图 Roofline
Speed Of Light Insight：工具自动给出瓶颈结论（如：低占用由寄存器限制）
2）Launch Stats（占用率详情，对应 xls 计算器）
自动算出：
Registers per Thread、每 Block 共享内存大小
单 SM 最大活跃 Block、活跃 Warp、理论 / 实际占用率
直接标出限制因素：寄存器 / 共享内存 / Warp 数量上限
3）Source 源码页
每行代码对应硬件指标：哪一行访存延迟高、分支分化、指令耗时，逐行定位热点。
4）Memory 内存分析页
全局内存读写吞吐量、缓存命中率、非合并访存次数（优化重点）。
四、和 cuda_occupancy_calculator.xls 对比优势
xls 需要手动填寄存器、smem；ncu自动读取编译后的真实值，无人工填错误差
xls 只算理论占用率；ncu 给出运行时真实占用率，区分理论上限与实际调度损耗
直接关联访存、分支、缓存瓶颈，不只看占用率一个指标
支持任意新 GPU 架构（Ada/Blackwell），旧 xls 不再更新新算力
五、典型实战流程（CUDA Kernel 调优标准步骤）
先用 Nsight Systems 定位耗时最长的 Kernel
编译程序加-g --ptxas-options=-v获取寄存器日志
ncu 采集完整报告：
bash
运行
ncu --set full -o kernel_report ./app
ncu-ui 打开报告：
Summary 看占用率，低于 60% 说明资源没打满
Launch Stats 查看是寄存器还是共享内存限制并行 Block
Memory 页看是否带宽瓶颈、访存是否合并
Source 页定位热点循环、分支分化代码
调整 Block 尺寸、优化 smem / 寄存器、重排访存，重新采集对比优化效果
六、Ubuntu 常见报错解决
perf_event_paranoid 权限不足
执行前文sysctl永久修改 0
ncu-ui 界面黑屏 / 缺少 xcb 依赖
bash
运行
sudo apt install libxcb-xinput0 libxcb-randr0 libxcb-shape0
采集不到指标、报告为空
编译必须加-g调试符号
确认显卡驱动版本≥535，CUDA 与 Nsight Compute 版本匹配
提示无法 attach 进程
关闭显卡节能、程序用前台运行，不要后台 nohup 执行
七、极简速查命令
bash
运行
# 1. 快速采集基础指标，终端直接看占用率
ncu --section LaunchStats ./test

# 2. 完整深度分析，保存报告并自动打开GUI
ncu --set full --open-in-ui -o result ./test

# 3. 只分析指定kernel，减少采集时间
ncu --kernel matmul_kernel --set basic ./test
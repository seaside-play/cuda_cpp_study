nvcc -arch=sm_61 -o add1.exe add1.cu
nvcc -o add1.exe add1.cu

// 使用最快定位工具（工业标准）
nvcc -arch=sm_61 -lineinfo -o add1.exe add1.cu
compute-sanitizer ./add1.exe > saniter_add1.txt


nvcc -I./include main.cu -o app  # -I./include：把当前目录下的 include 加入头文件搜索路径

核心参数：-D 定义宏，-U 取消宏
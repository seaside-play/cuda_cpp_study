nvcc -arch=sm_61 -o add1.exe add1.cu
nvcc -o add1.exe add1.cu

// 使用最快定位工具（工业标准）
nvcc -arch=sm_61 -lineinfo -o add1.exe add1.cu
compute-sanitizer ./add1.exe > saniter_add1.txt

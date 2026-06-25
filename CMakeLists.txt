cmake_minimum_required(VERSION 3.22)
project(MyCUDATest LANGUAGES CXX CUDA)

# 为整个项目设置 CUDA C++ 和标准 C++ 标准为 17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_ARCHITECTURES 61)

include_directories(${PROJECT_SOURCE_DIR})

# 自定义开关
option(USE_DP "Enable debug log output" OFF)
# 根据开关，向编译器传递宏定义
if(USE_DP)
    add_compile_definitions(USE_DP)
endif()

# find_package(CUDAToolkit REQUIRED)
# 不用find_package(CUDAToolkit)
find_package(CUDA REQUIRED)
include_directories(${CUDA_INCLUDE_DIRS})

# 强制要求使用该标准，如果不可用则报错
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 源码分组：cpp + cu
# set(SRC_CPP
# )
set(SRC_CU
    main.cu
    utils.cu
    kernels.cu
    matrix_copy.cu
    reduce.cu
 
    # test_cublas.cu
)

# add_executable(app global_memory_merge.cu)
# add_executable(matrix matrix.cu)
add_executable(query query.cu)
target_include_directories(query PRIVATE ${CMAKE_SOURCE_DIR}/include)
target_link_libraries(query PRIVATE
    ${CUDA_LIBRARIES}
    # ${CUDA_cublas_LIBRARY}
)


function(set_cuda_debug_options target)
    target_compile_options(${target} PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:-g>
        $<$<COMPILE_LANGUAGE:CUDA>:-O3>
        $<$<COMPILE_LANGUAGE:CUDA>:--ptxas-options=-v>
    )
endfunction()

#  nvcc -g --ptxas-options=-v -I./include add1.cu -o add1.exe
add_executable(main ${SRC_CU})
# target_link_libraries(main PRIVATE CUDAToolkit::cublas)
target_include_directories(main PRIVATE ${CMAKE_SOURCE_DIR}/include)

# 3. 调用函数，传入目标名 add1
set_cuda_debug_options(main)

# 去掉 CUDAToolkit::cublas
target_link_libraries(main PRIVATE
    ${CUDA_LIBRARIES}
    ${CUDA_cublas_LIBRARY}
)
# target_link_libraries(main cudart)
# add_executable(test_stl test_stl.cpp)

# set_target_properties(app PROPERTIES
#     CUDA_ARCHITECTURES "61"
# )
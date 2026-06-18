//#pragma once
#ifndef ERROR_CU_H_
#define ERROR_CU_H_
#include <cstdio>

#define CHECK(call) \
do { \
    const cudaError_t error_code = call; \
    if (error_code != cudaSuccess) { \
        printf("CUDA Error:\n"); \
        printf("File: %s\n", __FILE__); \
        printf("LINE: %d\n", __LINE__); \
        printf("Error Code: %d\n", error_code); \
        printf("Error Text: %s\n", cudaGetErrorString(error_code)); \
        exit(1); \
    }   \
} while(0)

#endif // ERROR_CU_H_
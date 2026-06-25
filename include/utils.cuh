#ifndef UTILS_H_
#define UTILS_H_

#include <iostream>
#include <string>
#include "base.cuh"

#define FUNC() \
    std::cout << __func__ << "----------------------------------" << std::endl;
namespace test {
    void PrintMatrixData(const real *A, const MatDim2D& mat_dim_2d, const std::string &description /*= ""*/);

}

#endif //UTILS_H_
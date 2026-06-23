#ifndef UTILS_H_
#define UTILS_H_

#include <string>
#include "base.cuh"

namespace test {
    void PrintMatrixData(const real *A, const MatDim2D& mat_dim_2d, const std::string &description /*= ""*/);

}

#endif //UTILS_H_
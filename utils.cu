#include "include/base.cuh"
#include <iostream>

namespace test {
     void PrintMatrixData(const real *A, const MatDim2D& mat_dim_2d, const std::string &description = "") {
        std::cout << (description.empty() ? "Matrix data is:\n" : description + ":\n");
        for (auto i = 0; i < mat_dim_2d.rows; ++i) {
            for (auto j = 0; j < mat_dim_2d.cols; ++j) {
                printf("%7.f", A[i*mat_dim_2d.cols + j]);
                // std::cout << A[i*mat_dim_2d.cols + j] << " ";
            }
            std::cout << "\n";
        }
        std::cout << std::endl;
     }

}
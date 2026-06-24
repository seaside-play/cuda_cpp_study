#ifndef MATRIX_COPY_H_
#define MATRIX_COPY_H_

#include "include/base.cuh"

namespace test {
class MatrixCopy {
public:
    MatrixCopy(int matrix_dim);
    MatrixCopy(int matrix_dim_row, int matrix_dim_col);
    bool TranslateInDevice(real *B, real *A, TranslateType translate_type);
    bool CopyInHost(real *B, real *A);
    

private:
    MatDim2D mat_dim_2d_;
    const int array_length_;
    const int total_bytes_;
};

}

#endif // MATRIX_COPY_H_
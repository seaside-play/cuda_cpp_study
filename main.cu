#include "include/base.cuh"
#include "include/matrix_copy.cuh"
#include <algorithm>

__global__ void copy(real *B, const real *A, const int n);

void print_matrix(const real *matrix, const int n);


int main(int argc, char* argv[]) {
    if (argc != 3) {
        printf("usage: %s Rows and Cols\n", argv[0]);
        exit(1);
    }
    size_t rows = atoi(argv[1]);
    size_t cols = atoi(argv[2]);
    size_t len = rows * cols;
    real *A = new real[len];
    real *B = new real[len];
    for (size_t i = 0; i < len; ++i) {
        A[i] = i;
        B[i] = 0;
    }

    test::MatrixCopy matrix_copy(rows, cols);
    matrix_copy.CopyInDevice(B, A);
    matrix_copy.CopyInHost(B, A);

    delete []A;
    delete []B;

    return 0;
}
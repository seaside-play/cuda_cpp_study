#include "include/base.cuh"
#include "include/matrix_copy.cuh"
#include <algorithm>

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
    real *C = new real[len];
    for (size_t i = 0; i < len; ++i) {
        A[i] = i;
        B[i] = 0;
        C[i] = 0;
    }

    test::MatrixCopy matrix_copy(rows, cols);
    std::vector<test::TranslateType> translate_types {//test::TranslateType::COPY, 
                                                      test::TranslateType::TRANSPOSE1, 
                                                    //   test::TranslateType::TRANSPOSE2, 
                                                    //   test::TranslateType::TRANSPOSE3
                                                    };
    for (auto item : translate_types) {
        matrix_copy.TranslateInDevice(B, A, item);
    }

    // matrix_copy.CopyInHost(C, A);

    delete []A;
    delete []B;
    delete []C;

    return 0;
}
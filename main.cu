#include "include/base.cuh"
#include "include/matrix_copy.cuh"
#include "include/reduce.cuh"
#include <algorithm>
#include <iostream>


void TestMatrixOperate(int argc, char* argv);
void TestArrayReduce();

int main(int argc, char* argv[]) {
    // TestMatrixOperate(argc, argv);
    TestArrayReduce();
    return 0;
}

void TestMatrixOperate(int argc, char* argv[]) {
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
    // std::for_each(translate_types.cbegin(), translate_types.cend(), [&matrix_copy, &B, &A](test::TranslateType item) {
    //     matrix_copy.TranslateInDevice(B, A, item);
    // });
    for (auto item : translate_types) {
        matrix_copy.TranslateInDevice(B, A, item);
    }

    // matrix_copy.CopyInHost(C, A);

    delete []A;
    delete []B;
    delete []C;
}

void TestArrayReduce() {
    test::Reduce reduce;
    constexpr size_t kCount = 1e8;
    std::cout << "kCount " << kCount << std::endl;
    real *data = new real[kCount];
    for (int i = 0; i < kCount; ++i) {
        data[i] = 1.23;
    }
    auto ret = reduce.ReduceInCPU(data, kCount);
    std::cout << "Result is " << ret << " in cpu." << std::endl;
    auto ret2 = reduce.ReduceInGlobalMemory(data, kCount);
    std::cout << "Result is " << ret2 << " in gpu global memory." << std::endl;

    delete [] data;
}
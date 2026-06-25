#include "include/base.cuh"
#include "include/matrix.cuh"
#include "include/reduce.cuh"
#include <algorithm>
#include <iostream>


void TestMatrixOperate(int argc, char* argv[]);
void TestArrayReduce();

int main(int argc, char* argv[]) {
    TestMatrixOperate(argc, argv);
    // TestArrayReduce();
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

    test::Matrix matrix(rows, cols);
    std::vector<test::TranslateType> translate_types {//test::TranslateType::COPY, 
                                                    //   test::TranslateType::TRANSPOSE1, 
                                                      test::TranslateType::TRASNSPOSE1_SHARED, 
                                                    //   test::TranslateType::TRANSPOSE2, 
                                                    //   test::TranslateType::TRANSPOSE3
                                                    };
    // std::for_each(translate_types.cbegin(), translate_types.cend(), [&matrix, &B, &A](test::TranslateType item) {
    //     matrix.TranslateInDevice(B, A, item);
    // });
    for (auto item : translate_types) {
        matrix.TranslateInDevice(B, A, item);
    }

    // matrix.CopyInHost(C, A);

    delete []A;
    delete []B;
    delete []C;
}

void TestArrayReduce() {
    test::Reduce reduce;
    constexpr size_t kCount = 1e7;
    std::cout << "kCount " << kCount << std::endl;
    real *data = new real[kCount];
    for (int i = 0; i < kCount; ++i) {
        data[i] = 1.23;
    }

    auto ret = reduce.ReduceInCPU(data, kCount);
    std::cout << "Result is " << ret << " in cpu." << std::endl;

    // 使用gpu共享内存进行reduce处理，不会改变数据内存
    auto ret3 = reduce.ReduceInSharedMemory(data, kCount);
    std::cout << "Result is " << ret3 << " in gpu shared memory." << std::endl;

    // 使用gpu全局内存进行reduce处理，会改变数据内存
    auto ret2 = reduce.ReduceInGlobalMemory(data, kCount);
    std::cout << "Result is " << ret2 << " in gpu global memory." << std::endl;

    delete [] data;
}
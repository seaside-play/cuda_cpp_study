#include "include/matrix_copy.cuh"

namespace {
  constexpr size_t kTileDim {32};
}

namespace test {

MatrixCopy::MatrixCopy(int matrix_dim) : MatrixCopy(matrix_dim, matrix_dim) {}

MatrixCopy::MatrixCopy(int matrix_dim_row, int matrix_dim_col)
    : mat_dim_2d_(matrix_dim_row, matrix_dim_col),
      array_length_(matrix_dim_row * matrix_dim_col),
      total_bytes_(array_length_ * sizeof(real)) {}

bool MatrixCopy::TranslateInDevice(real *B, real *A, TranslateType translate_type) {
  // test::PrintMatrixData(A, mat_dim_2d_, "矩阵A的内容");
  real *d_A, *d_B;
  CHECK(cudaMalloc(&d_A, total_bytes_));
  CHECK(cudaMalloc(&d_B, total_bytes_));
  CHECK(cudaMemcpy(d_A, A, total_bytes_, cudaMemcpyHostToDevice));

  dim3 block_size(kTileDim, kTileDim); // 每一个网格中有一片矩阵，最好是32*32，因为刚好是1024个线程，确保线程块的线程数是满饱和的。
  // 可以想象一下有一个二维的坐标系中，有一个二维的网格在其中，（x,y）
  int grid_x = (mat_dim_2d_.cols + block_size.x - 1) / kTileDim;
  int grid_y = grid_x;
  dim3 grid_size(grid_x, grid_y);
  {
    EventTimer event_timer;
    switch (translate_type) {
      case TranslateType::COPY:{
        test::matrix_copy<<<grid_size, block_size>>>(d_B, d_A, mat_dim_2d_);
        break;
      }
      case TranslateType::TRANSPOSE1: {
        test::matrix_transpose1<<<grid_size, block_size>>>(d_B, d_A, mat_dim_2d_);
        break;
      }
      case TranslateType::TRANSPOSE2: {
        test::matrix_transpose2<<<grid_size, block_size>>>(d_B, d_A, mat_dim_2d_);
        break;
      }
      case TranslateType::TRANSPOSE3: {
        test::matrix_transpose3<<<grid_size, block_size>>>(d_B, d_A, mat_dim_2d_);
        break;
      }
      default:{
        break;
      }
    }
  }
  
  // CHECK(cudaGetLastError()); // 仅 cudaGetLastError() 能抓到：启动期错误（主机侧同步错误）
  // 只有显存分配、同步拷贝、NULL 流操作、设备同步函数才会触发跨流隐式同步。
  CHECK(cudaDeviceSynchronize()); // 因为核函数执行是异步的，主机发出调用核函数之后，立即执行后面的语句，不会等待核函数执行完成

  CHECK(cudaMemcpy(B, d_B, total_bytes_, cudaMemcpyDeviceToHost));
  switch (translate_type) {
    case TranslateType::COPY: {
      test::PrintMatrixData(B, mat_dim_2d_, "矩阵B的内容 by device");
      break;
    }
    case TranslateType::TRANSPOSE1:
    case TranslateType::TRANSPOSE2: {
      MatDim2D mat_dim_2d_transporse(mat_dim_2d_.cols, mat_dim_2d_.rows);
      test::PrintMatrixData(B, mat_dim_2d_transporse, "转置矩阵内容 by device");
      break;
    }
    default: {
      break;
    }
  }
  
  return true;
}

bool MatrixCopy::CopyInHost(real *B, real *A) {
  {
    EventTimer event_timer;
    for (auto i = 0; i < mat_dim_2d_.rows; ++i) {
      for (auto j = 0; j < mat_dim_2d_.cols; ++j) {
        B[i*mat_dim_2d_.cols + j] = A[i*mat_dim_2d_.cols + j];
      }
    }
  }
  
  PrintMatrixData(B, mat_dim_2d_, "矩阵B的内容 by host");

  return true;
}

} // namespace test
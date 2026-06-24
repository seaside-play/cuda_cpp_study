#ifndef BASE_TYPES_H_
#define BASE_TYPES_H_

namespace test {
struct MatDim2D {
    MatDim2D(int row, int col) : rows(row), cols(col) {}
    MatDim2D() = default;
    int rows {0};
    int cols {0};
};

const int TILE_DIM {32};

enum class TranslateType { COPY, TRANSPOSE1, TRANSPOSE2, TRANSPOSE3 };

}

#endif // BASE_TYPES_H_

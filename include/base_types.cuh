#ifndef BASE_TYPES_H_
#define BASE_TYPES_H_

namespace test {
struct MatDim2D {
    MatDim2D(std::size_t row, std::size_t col) : rows(row), cols(col) {}
    MatDim2D() = default;
    std::size_t rows {0};
    std::size_t cols {0};
};

const int TILE_DIM {32};

}

#endif // BASE_TYPES_H_

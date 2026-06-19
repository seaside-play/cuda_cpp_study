#ifndef FLOAT_TYPE_H_
#define FLOAT_TYPE_H_

#ifdef USE_DP
    typedef double real;
    constexpr real EPSILON { 1.0e-15 };
#else
    typedef float real;
    constexpr real EPSILON { 1.0e-6f };
#endif

#endif // FLOAT_TYPE_H_
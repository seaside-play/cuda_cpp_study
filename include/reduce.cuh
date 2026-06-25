#ifndef REDUCE_H_
#define REDUCE_H_

#include "include/base.cuh"

namespace test {

class Reduce {
 public:
  real ReduceInCPU(const real *x, const int len);
  real ReduceInGlobalMemory(real *x, const int len);
  real ReduceInSharedMemory(const real *x, const int len);
  real ReduceInSharedMemoryWithAtomic(const real *x, const int len);
  

}; // class Reduce

} // namespace test

#endif // REDUCE_H_


#ifndef EVENT_TIMER_H_
#define EVENT_TIMER_H_

#include <cstdio>
#include <cuda_runtime.h>

class EventTimer {
public:
    EventTimer() {
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start);
        cudaEventQuery(start);
    }
    ~EventTimer() {
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        float elapsed_time;
        cudaEventElapsedTime(&elapsed_time, start, stop);
        printf("Elapsed %g ms.\n", elapsed_time);
        cudaEventDestroy(start);
        cudaEventDestroy(stop);
    }
private:
    cudaEvent_t start;
    cudaEvent_t stop;

};

#endif // EVENT_TIMER_H_
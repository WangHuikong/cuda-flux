#include <cstdio>
#include <cstdlib>
#include <cuda.h>
#include <cuda_runtime.h>

#ifndef CHECK_CUDA
#define CHECK_CUDA(call)                                                      \
    do {                                                                      \
        cudaError_t err__ = (call);                                           \
        if (err__ != cudaSuccess) {                                           \
            fprintf(stderr, "CUDA Error %s (code %d), line %d\n",           \
                    cudaGetErrorString(err__), err__, __LINE__);             \
            exit(EXIT_FAILURE);                                               \
        }                                                                     \
    } while (0)
#endif

// Inline PTX helpers ----------------------------------------------------------
__device__ __forceinline__ float ld_ca(const float *addr) {
    float ret;
    asm volatile("ld.global.ca.f32 %0, [%1];" : "=f"(ret) : "l"(addr));
    return ret;
}

__device__ __forceinline__ float ld_cg(const float *addr) {
    float ret;
    asm volatile("ld.global.cg.f32 %0, [%1];" : "=f"(ret) : "l"(addr));
    return ret;
}

// Kernel that stresses L1 (cache at all levels)
__global__ void l1_kernel(const float * __restrict__ in, float * __restrict__ out,
                          size_t elems_per_thread, unsigned stride) {
    const size_t base = (blockIdx.x * blockDim.x + threadIdx.x) * stride;
    float sum = 0.f;
    #pragma unroll 4
    for (size_t i = 0; i < elems_per_thread; ++i) {
        sum += ld_ca(&in[base + i * stride]);
    }
    out[blockIdx.x * blockDim.x + threadIdx.x] = sum; // avoid dead-code removal
}

// Kernel that bypasses L1 and uses L2 only
__global__ void l2_kernel(const float * __restrict__ in, float * __restrict__ out,
                          size_t elems_per_thread, unsigned stride) {
    const size_t base = (blockIdx.x * blockDim.x + threadIdx.x) * stride;
    float sum = 0.f;
    #pragma unroll 4
    for (size_t i = 0; i < elems_per_thread; ++i) {
        sum += ld_cg(&in[base + i * stride]);
    }
    out[blockIdx.x * blockDim.x + threadIdx.x] = sum;
}

float giga_bytes_per_sec(size_t bytes, float msec) {
    return static_cast<float>(bytes) / (1e6f * msec); // 1e9B/s = 1GB/s
}

int main(int argc, char **argv) {
    // Settings --------------------------------------------------------------
    const int block_size = 256;
    const int grid_size  = 208; // Enough to fully occupy 108 SMs on A100

    // L1 benchmark parameters ----------------------------------------------
    const size_t l1_dataset_bytes = 256 * 1024; // 256 KiB < L1 per SM aggregate
    const size_t l1_total_elems   = l1_dataset_bytes / sizeof(float);

    // L2 benchmark parameters ----------------------------------------------
    const size_t l2_dataset_bytes = 8 * 1024 * 1024; // 8 MiB < 40MiB L2
    const size_t l2_total_elems   = l2_dataset_bytes / sizeof(float);

    const int repetitions = 200; // number of kernel repetitions to average

    // Allocate device buffers ------------------------------------------------
    float *d_in, *d_out;
    CHECK_CUDA(cudaMalloc(&d_in, l2_dataset_bytes));
    CHECK_CUDA(cudaMalloc(&d_out, grid_size * block_size * sizeof(float)));

    // Init
    CHECK_CUDA(cudaMemset(d_in, 0, l2_dataset_bytes));

    cudaEvent_t start, stop;
    CHECK_CUDA(cudaEventCreate(&start));
    CHECK_CUDA(cudaEventCreate(&stop));

    // ---------------- L1 Benchmark -----------------
    {
        size_t elems_per_thread = l1_total_elems / (grid_size * block_size);
        unsigned stride = 1; // contiguous

        // Warm-up run
        l1_kernel<<<grid_size, block_size>>>(d_in, d_out, elems_per_thread, stride);
        CHECK_CUDA(cudaDeviceSynchronize());

        CHECK_CUDA(cudaEventRecord(start));
        for (int r = 0; r < repetitions; ++r) {
            l1_kernel<<<grid_size, block_size>>>(d_in, d_out, elems_per_thread, stride);
        }
        CHECK_CUDA(cudaEventRecord(stop));
        CHECK_CUDA(cudaEventSynchronize(stop));

        float msec = 0.f;
        CHECK_CUDA(cudaEventElapsedTime(&msec, start, stop));

        size_t bytes_transferred = static_cast<size_t>(repetitions) * l1_dataset_bytes;
        printf("[L1] Bytes: %zu, Time: %.3f ms, Bandwidth: %.2f GB/s\n",
               bytes_transferred, msec, giga_bytes_per_sec(bytes_transferred, msec));
    }

    // ---------------- L2 Benchmark -----------------
    {
        size_t elems_per_thread = l2_total_elems / (grid_size * block_size);
        unsigned stride = 1;

        // Warm-up
        l2_kernel<<<grid_size, block_size>>>(d_in, d_out, elems_per_thread, stride);
        CHECK_CUDA(cudaDeviceSynchronize());

        CHECK_CUDA(cudaEventRecord(start));
        for (int r = 0; r < repetitions; ++r) {
            l2_kernel<<<grid_size, block_size>>>(d_in, d_out, elems_per_thread, stride);
        }
        CHECK_CUDA(cudaEventRecord(stop));
        CHECK_CUDA(cudaEventSynchronize(stop));

        float msec = 0.f;
        CHECK_CUDA(cudaEventElapsedTime(&msec, start, stop));

        size_t bytes_transferred = static_cast<size_t>(repetitions) * l2_dataset_bytes;
        printf("[L2] Bytes: %zu, Time: %.3f ms, Bandwidth: %.2f GB/s\n",
               bytes_transferred, msec, giga_bytes_per_sec(bytes_transferred, msec));
    }

    CHECK_CUDA(cudaFree(d_in));
    CHECK_CUDA(cudaFree(d_out));

    CHECK_CUDA(cudaEventDestroy(start));
    CHECK_CUDA(cudaEventDestroy(stop));

    return 0;
}
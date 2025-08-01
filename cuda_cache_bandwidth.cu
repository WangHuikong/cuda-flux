#include <cuda_runtime.h>
#include <cuda.h>
#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cstring>

// 错误检查宏
#define CUDA_CHECK(call) \
    do { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            std::cerr << "CUDA error at " << __FILE__ << ":" << __LINE__ << " - " \
                      << cudaGetErrorString(err) << std::endl; \
            exit(1); \
        } \
    } while(0)

// 常量定义
const int BLOCK_SIZE = 256;
const int GRID_SIZE = 1024;
const int ITERATIONS = 1000;
const size_t BUFFER_SIZE = 1024 * 1024 * 1024; // 1GB

// L1 Cache测试内核 - 使用共享内存
__global__ void l1_cache_test(float* data, int size, int iterations) {
    __shared__ float shared_data[BLOCK_SIZE];
    
    int tid = threadIdx.x;
    int gid = blockIdx.x * blockDim.x + threadIdx.x;
    
    for (int iter = 0; iter < iterations; iter++) {
        // 从全局内存加载到共享内存
        if (gid < size) {
            shared_data[tid] = data[gid];
        }
        __syncthreads();
        
        // 在共享内存中进行计算
        float sum = 0.0f;
        for (int i = 0; i < BLOCK_SIZE; i++) {
            sum += shared_data[i];
        }
        
        // 写回全局内存
        if (gid < size) {
            data[gid] = sum;
        }
        __syncthreads();
    }
}

// L2 Cache测试内核 - 使用全局内存访问模式
__global__ void l2_cache_test(float* data, int size, int iterations) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    
    for (int iter = 0; iter < iterations; iter++) {
        // 使用跨步访问模式来测试L2 Cache
        int stride = 64; // 64字节跨步，适合L2 Cache行大小
        int offset = tid * stride / sizeof(float);
        
        if (offset < size) {
            float val = data[offset];
            // 简单的计算
            val = val * 2.0f + 1.0f;
            data[offset] = val;
        }
    }
}

// 内存带宽测试内核
__global__ void memory_bandwidth_test(float* data, int size, int iterations) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    
    for (int iter = 0; iter < iterations; iter++) {
        // 顺序访问模式，最大化内存带宽
        int offset = tid;
        while (offset < size) {
            float val = data[offset];
            val = val * 2.0f + 1.0f;
            data[offset] = val;
            offset += blockDim.x * gridDim.x;
        }
    }
}

// 获取GPU信息
void print_gpu_info() {
    cudaDeviceProp prop;
    int device;
    CUDA_CHECK(cudaGetDevice(&device));
    CUDA_CHECK(cudaGetDeviceProperties(&prop, device));
    
    std::cout << "=== GPU Information ===" << std::endl;
    std::cout << "Device: " << prop.name << std::endl;
    std::cout << "Compute Capability: " << prop.major << "." << prop.minor << std::endl;
    std::cout << "Global Memory: " << prop.totalGlobalMem / (1024*1024*1024) << " GB" << std::endl;
    std::cout << "Shared Memory per Block: " << prop.sharedMemPerBlock / 1024 << " KB" << std::endl;
    std::cout << "L2 Cache Size: " << prop.l2CacheSize / 1024 << " KB" << std::endl;
    std::cout << "Max Threads per Block: " << prop.maxThreadsPerBlock << std::endl;
    std::cout << "Max Blocks per SM: " << prop.maxBlocksPerMultiProcessor << std::endl;
    std::cout << "Number of SMs: " << prop.multiProcessorCount << std::endl;
    std::cout << "========================\n" << std::endl;
}

// 测量带宽
double measure_bandwidth(float* d_data, size_t data_size, int iterations, 
                        void (*kernel)(float*, int, int), const char* test_name) {
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    
    // 预热
    kernel<<<GRID_SIZE, BLOCK_SIZE>>>(d_data, data_size / sizeof(float), 10);
    CUDA_CHECK(cudaDeviceSynchronize());
    
    // 开始计时
    CUDA_CHECK(cudaEventRecord(start));
    
    // 执行内核
    kernel<<<GRID_SIZE, BLOCK_SIZE>>>(d_data, data_size / sizeof(float), iterations);
    
    // 结束计时
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));
    
    float milliseconds = 0;
    CUDA_CHECK(cudaEventElapsedTime(&milliseconds, start, stop));
    
    // 计算带宽 (GB/s)
    double total_bytes = (double)data_size * iterations * 2; // 读写操作
    double bandwidth = (total_bytes / (milliseconds / 1000.0)) / (1024*1024*1024);
    
    std::cout << std::fixed << std::setprecision(2);
    std::cout << test_name << ":" << std::endl;
    std::cout << "  Time: " << milliseconds << " ms" << std::endl;
    std::cout << "  Bandwidth: " << bandwidth << " GB/s" << std::endl;
    std::cout << "  Total Data: " << total_bytes / (1024*1024*1024) << " GB" << std::endl;
    std::cout << std::endl;
    
    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    
    return bandwidth;
}

// 测试L1 Cache性能
void test_l1_cache(float* d_data, size_t data_size) {
    std::cout << "=== L1 Cache Bandwidth Test ===" << std::endl;
    
    // 使用较小的数据块来测试L1 Cache
    size_t l1_data_size = 64 * 1024; // 64KB，适合L1 Cache
    int l1_iterations = ITERATIONS * 10; // 增加迭代次数以获得更准确的测量
    
    measure_bandwidth(d_data, l1_data_size, l1_iterations, l1_cache_test, "L1 Cache Test");
}

// 测试L2 Cache性能
void test_l2_cache(float* d_data, size_t data_size) {
    std::cout << "=== L2 Cache Bandwidth Test ===" << std::endl;
    
    // 使用较大的数据块来测试L2 Cache
    size_t l2_data_size = 8 * 1024 * 1024; // 8MB，适合L2 Cache
    int l2_iterations = ITERATIONS;
    
    measure_bandwidth(d_data, l2_data_size, l2_iterations, l2_cache_test, "L2 Cache Test");
}

// 测试全局内存带宽
void test_memory_bandwidth(float* d_data, size_t data_size) {
    std::cout << "=== Global Memory Bandwidth Test ===" << std::endl;
    
    size_t mem_data_size = data_size;
    int mem_iterations = ITERATIONS / 10; // 减少迭代次数，因为数据量大
    
    measure_bandwidth(d_data, mem_data_size, mem_iterations, memory_bandwidth_test, "Global Memory Test");
}

int main() {
    std::cout << "CUDA Cache Bandwidth Measurement for A100 GPU" << std::endl;
    std::cout << "=============================================" << std::endl;
    
    // 打印GPU信息
    print_gpu_info();
    
    // 分配GPU内存
    float* d_data;
    CUDA_CHECK(cudaMalloc(&d_data, BUFFER_SIZE));
    
    // 初始化数据
    std::vector<float> h_data(BUFFER_SIZE / sizeof(float), 1.0f);
    CUDA_CHECK(cudaMemcpy(d_data, h_data.data(), BUFFER_SIZE, cudaMemcpyHostToDevice));
    
    // 执行各种测试
    test_l1_cache(d_data, BUFFER_SIZE);
    test_l2_cache(d_data, BUFFER_SIZE);
    test_memory_bandwidth(d_data, BUFFER_SIZE);
    
    // 清理
    CUDA_CHECK(cudaFree(d_data));
    
    std::cout << "=== Test Summary ===" << std::endl;
    std::cout << "L1 Cache测试使用共享内存和较小的数据块" << std::endl;
    std::cout << "L2 Cache测试使用全局内存的跨步访问模式" << std::endl;
    std::cout << "Global Memory测试使用顺序访问模式" << std::endl;
    std::cout << "所有测试都包含读写操作以获得完整的带宽测量" << std::endl;
    
    return 0;
}
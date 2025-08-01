#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <iostream>
#include <chrono>
#include <vector>
#include <cstdlib>
#include <cstring>

// CUDA错误检查宏
#define CUDA_CHECK(call) \
    do { \
        cudaError_t error = call; \
        if (error != cudaSuccess) { \
            std::cerr << "CUDA error at " << __FILE__ << ":" << __LINE__ << " - " << cudaGetErrorString(error) << std::endl; \
            exit(1); \
        } \
    } while(0)

// L1 Cache带宽测试内核 - 使用共享内存
__global__ void l1_cache_bandwidth_test(float* data, int iterations, int data_size) {
    extern __shared__ float shared_data[];
    
    int tid = threadIdx.x;
    int bid = blockIdx.x;
    int global_tid = bid * blockDim.x + tid;
    
    // 将数据加载到共享内存
    if (tid < data_size && global_tid < data_size) {
        shared_data[tid] = data[global_tid];
    }
    __syncthreads();
    
    float sum = 0.0f;
    
    // 执行多次读取操作以测量L1 Cache带宽
    for (int i = 0; i < iterations; i++) {
        int idx = (tid + i) % data_size;
        if (idx < blockDim.x) {
            sum += shared_data[idx];
        }
    }
    
    // 防止编译器优化掉计算
    if (global_tid < data_size) {
        data[global_tid] = sum;
    }
}

// L2 Cache带宽测试内核 - 使用全局内存访问
__global__ void l2_cache_bandwidth_test(float* data, int iterations, int data_size) {
    int tid = threadIdx.x;
    int bid = blockIdx.x;
    int global_tid = bid * blockDim.x + tid;
    
    if (global_tid >= data_size) return;
    
    float sum = 0.0f;
    
    // 执行多次读取操作，访问模式设计为利用L2 Cache
    for (int i = 0; i < iterations; i++) {
        // 使用stride访问模式来测试L2 Cache
        int idx = (global_tid + i * 1024) % data_size;
        sum += data[idx];
    }
    
    // 防止编译器优化
    data[global_tid] = sum;
}

// 写带宽测试内核
__global__ void write_bandwidth_test(float* data, int iterations, int data_size) {
    int tid = threadIdx.x;
    int bid = blockIdx.x;
    int global_tid = bid * blockDim.x + tid;
    
    if (global_tid >= data_size) return;
    
    float value = global_tid * 1.0f;
    
    // 执行多次写入操作
    for (int i = 0; i < iterations; i++) {
        int idx = (global_tid + i * 512) % data_size;
        data[idx] = value + i;
    }
}

// 获取GPU设备信息
void printDeviceInfo() {
    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    
    std::cout << "=== GPU Device Information ===" << std::endl;
    std::cout << "Device Name: " << prop.name << std::endl;
    std::cout << "Compute Capability: " << prop.major << "." << prop.minor << std::endl;
    std::cout << "Global Memory: " << prop.totalGlobalMem / (1024*1024) << " MB" << std::endl;
    std::cout << "Shared Memory per Block: " << prop.sharedMemPerBlock / 1024 << " KB" << std::endl;
    std::cout << "L2 Cache Size: " << prop.l2CacheSize / 1024 << " KB" << std::endl;
    std::cout << "Memory Clock Rate: " << prop.memoryClockRate / 1000 << " MHz" << std::endl;
    std::cout << "Memory Bus Width: " << prop.memoryBusWidth << " bits" << std::endl;
    std::cout << "Peak Memory Bandwidth: " << 2.0 * prop.memoryClockRate * (prop.memoryBusWidth / 8) / 1.0e6 << " GB/s" << std::endl;
    std::cout << "Multiprocessors: " << prop.multiProcessorCount << std::endl;
    std::cout << "===============================" << std::endl << std::endl;
}

// 测量L1 Cache带宽
double measureL1CacheBandwidth() {
    std::cout << "=== L1 Cache Bandwidth Test ===" << std::endl;
    
    const int data_size = 32 * 1024; // 32KB，适合L1 Cache大小
    const int iterations = 1000;
    const int block_size = 256;
    const int grid_size = (data_size + block_size - 1) / block_size;
    
    // 分配内存
    float* d_data;
    CUDA_CHECK(cudaMalloc(&d_data, data_size * sizeof(float)));
    
    // 初始化数据
    std::vector<float> h_data(data_size);
    for (int i = 0; i < data_size; i++) {
        h_data[i] = static_cast<float>(i);
    }
    CUDA_CHECK(cudaMemcpy(d_data, h_data.data(), data_size * sizeof(float), cudaMemcpyHostToDevice));
    
    // 预热
    l1_cache_bandwidth_test<<<grid_size, block_size, block_size * sizeof(float)>>>(d_data, 10, data_size);
    CUDA_CHECK(cudaDeviceSynchronize());
    
    // 开始计时
    auto start = std::chrono::high_resolution_clock::now();
    
    // 执行测试
    l1_cache_bandwidth_test<<<grid_size, block_size, block_size * sizeof(float)>>>(d_data, iterations, data_size);
    CUDA_CHECK(cudaDeviceSynchronize());
    
    // 结束计时
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    double time_ms = duration.count() / 1000.0;
    
    // 计算带宽 (GB/s)
    double bytes_transferred = (double)data_size * iterations * sizeof(float) * grid_size;
    double bandwidth_gb_s = (bytes_transferred / (time_ms / 1000.0)) / (1024*1024*1024);
    
    std::cout << "Data Size: " << data_size * sizeof(float) / 1024 << " KB" << std::endl;
    std::cout << "Iterations: " << iterations << std::endl;
    std::cout << "Time: " << time_ms << " ms" << std::endl;
    std::cout << "L1 Cache Bandwidth: " << bandwidth_gb_s << " GB/s" << std::endl;
    std::cout << "================================" << std::endl << std::endl;
    
    CUDA_CHECK(cudaFree(d_data));
    return bandwidth_gb_s;
}

// 测量L2 Cache带宽
double measureL2CacheBandwidth() {
    std::cout << "=== L2 Cache Bandwidth Test ===" << std::endl;
    
    const int data_size = 4 * 1024 * 1024; // 4MB，超过L1但适合L2 Cache
    const int iterations = 100;
    const int block_size = 256;
    const int grid_size = (data_size + block_size - 1) / block_size;
    
    // 分配内存
    float* d_data;
    CUDA_CHECK(cudaMalloc(&d_data, data_size * sizeof(float)));
    
    // 初始化数据
    std::vector<float> h_data(data_size);
    for (int i = 0; i < data_size; i++) {
        h_data[i] = static_cast<float>(i);
    }
    CUDA_CHECK(cudaMemcpy(d_data, h_data.data(), data_size * sizeof(float), cudaMemcpyHostToDevice));
    
    // 预热
    l2_cache_bandwidth_test<<<grid_size, block_size>>>(d_data, 10, data_size);
    CUDA_CHECK(cudaDeviceSynchronize());
    
    // 开始计时
    auto start = std::chrono::high_resolution_clock::now();
    
    // 执行测试
    l2_cache_bandwidth_test<<<grid_size, block_size>>>(d_data, iterations, data_size);
    CUDA_CHECK(cudaDeviceSynchronize());
    
    // 结束计时
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    double time_ms = duration.count() / 1000.0;
    
    // 计算带宽 (GB/s)
    double bytes_transferred = (double)data_size * iterations * sizeof(float);
    double bandwidth_gb_s = (bytes_transferred / (time_ms / 1000.0)) / (1024*1024*1024);
    
    std::cout << "Data Size: " << data_size * sizeof(float) / (1024*1024) << " MB" << std::endl;
    std::cout << "Iterations: " << iterations << std::endl;
    std::cout << "Time: " << time_ms << " ms" << std::endl;
    std::cout << "L2 Cache Bandwidth: " << bandwidth_gb_s << " GB/s" << std::endl;
    std::cout << "================================" << std::endl << std::endl;
    
    CUDA_CHECK(cudaFree(d_data));
    return bandwidth_gb_s;
}

// 测量写带宽
double measureWriteBandwidth() {
    std::cout << "=== Write Bandwidth Test ===" << std::endl;
    
    const int data_size = 2 * 1024 * 1024; // 2MB
    const int iterations = 100;
    const int block_size = 256;
    const int grid_size = (data_size + block_size - 1) / block_size;
    
    // 分配内存
    float* d_data;
    CUDA_CHECK(cudaMalloc(&d_data, data_size * sizeof(float)));
    
    // 预热
    write_bandwidth_test<<<grid_size, block_size>>>(d_data, 10, data_size);
    CUDA_CHECK(cudaDeviceSynchronize());
    
    // 开始计时
    auto start = std::chrono::high_resolution_clock::now();
    
    // 执行测试
    write_bandwidth_test<<<grid_size, block_size>>>(d_data, iterations, data_size);
    CUDA_CHECK(cudaDeviceSynchronize());
    
    // 结束计时
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    double time_ms = duration.count() / 1000.0;
    
    // 计算带宽 (GB/s)
    double bytes_transferred = (double)data_size * iterations * sizeof(float);
    double bandwidth_gb_s = (bytes_transferred / (time_ms / 1000.0)) / (1024*1024*1024);
    
    std::cout << "Data Size: " << data_size * sizeof(float) / (1024*1024) << " MB" << std::endl;
    std::cout << "Iterations: " << iterations << std::endl;
    std::cout << "Time: " << time_ms << " ms" << std::endl;
    std::cout << "Write Bandwidth: " << bandwidth_gb_s << " GB/s" << std::endl;
    std::cout << "=============================" << std::endl << std::endl;
    
    CUDA_CHECK(cudaFree(d_data));
    return bandwidth_gb_s;
}

int main() {
    std::cout << "CUDA Cache Bandwidth Benchmark for A100 GPU" << std::endl;
    std::cout << "=============================================" << std::endl << std::endl;
    
    // 检查CUDA设备
    int device_count;
    CUDA_CHECK(cudaGetDeviceCount(&device_count));
    
    if (device_count == 0) {
        std::cerr << "No CUDA devices found!" << std::endl;
        return 1;
    }
    
    // 设置GPU设备
    CUDA_CHECK(cudaSetDevice(0));
    
    // 打印设备信息
    printDeviceInfo();
    
    // 执行带宽测试
    double l1_bandwidth = measureL1CacheBandwidth();
    double l2_bandwidth = measureL2CacheBandwidth();
    double write_bandwidth = measureWriteBandwidth();
    
    // 总结结果
    std::cout << "=== Summary ===" << std::endl;
    std::cout << "L1 Cache Bandwidth: " << l1_bandwidth << " GB/s" << std::endl;
    std::cout << "L2 Cache Bandwidth: " << l2_bandwidth << " GB/s" << std::endl;
    std::cout << "Write Bandwidth: " << write_bandwidth << " GB/s" << std::endl;
    std::cout << "===============" << std::endl;
    
    return 0;
}
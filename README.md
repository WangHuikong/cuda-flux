# CUDA Cache Bandwidth Measurement for A100 GPU

这个项目包含两个CUDA程序，用于测量A100 GPU的L1和L2 Cache带宽，以及全局内存带宽。

## 程序版本

### 1. 基础版本 (`cuda_cache_bandwidth.cu`)
- 基本的L1和L2 Cache带宽测试
- 简单的内存访问模式
- 适合快速测试和验证

### 2. 高级版本 (`advanced_cache_test.cu`)
- 包含Cache行大小自动检测
- 多次测量取平均值，提高精度
- 更详细的内存访问模式分析
- 标准差计算

## 功能特性

- **L1 Cache测试**: 使用共享内存和较小的数据块来测量L1 Cache性能
- **L2 Cache测试**: 使用全局内存的跨步访问模式来测量L2 Cache性能
- **全局内存测试**: 使用顺序访问模式来测量全局内存带宽
- **Cache行大小检测**: 自动检测最优Cache行大小
- **GPU信息显示**: 自动检测并显示GPU的详细规格信息
- **统计精度**: 多次测量取平均值和标准差

## 编译要求

- CUDA Toolkit 11.0或更高版本
- 支持CUDA的GPU（推荐A100或类似架构）
- GCC或Clang编译器

## 快速开始

### 1. 编译所有程序
```bash
make all
```

### 2. 运行基础测试
```bash
make run
```

### 3. 运行高级测试
```bash
make run-advanced
```

### 4. 验证编译
```bash
./test_compile.sh
```

## 详细使用说明

### 编译选项

```bash
# 编译基础版本
make cuda_cache_bandwidth

# 编译高级版本
make advanced_cache_test

# 编译所有版本
make all

# 清理编译文件
make clean
```

### 运行选项

```bash
# 运行基础版本
./cuda_cache_bandwidth

# 运行高级版本
./advanced_cache_test

# 使用make运行
make run           # 基础版本
make run-advanced  # 高级版本
```

## 程序说明

### L1 Cache测试
- **基础版本**: 使用64KB数据块，共享内存访问
- **高级版本**: 优化了循环展开和内存访问模式
- **数据大小**: 64KB（适合L1 Cache）
- **访问模式**: 块内顺序访问

### L2 Cache测试
- **基础版本**: 使用8MB数据块，64字节跨步
- **高级版本**: 动态跨步大小，基于Cache行检测
- **数据大小**: 8MB（适合L2 Cache）
- **访问模式**: 跨步访问

### 全局内存测试
- **基础版本**: 使用1GB数据块，顺序访问
- **高级版本**: 优化了内存访问模式
- **数据大小**: 1GB
- **访问模式**: 顺序访问，最大化带宽

### Cache行大小检测（仅高级版本）
- 测试多种跨步大小：16, 32, 64, 128, 256, 512, 1024字节
- 自动选择带宽最高的跨步大小
- 提供详细的带宽对比

## 输出说明

### 基础版本输出
```
=== GPU Information ===
Device: NVIDIA A100-SXM4-40GB
Compute Capability: 8.0
Global Memory: 40 GB
L2 Cache Size: 40960 KB
...

=== L1 Cache Bandwidth Test ===
L1 Cache Test:
  Time: 12.34 ms
  Bandwidth: 1234.56 GB/s
  Total Data: 1.23 GB

=== L2 Cache Bandwidth Test ===
L2 Cache Test:
  Time: 45.67 ms
  Bandwidth: 567.89 GB/s
  Total Data: 4.56 GB
```

### 高级版本输出
```
=== Cache Line Size Detection ===
  Stride 16 bytes: 123.45 GB/s
  Stride 32 bytes: 234.56 GB/s
  Stride 64 bytes: 345.67 GB/s
  ...
  Optimal cache line size: 64 bytes

=== L1 Cache Bandwidth Test ===
L1 Cache Test:
  Average Time: 12.34 ms
  Std Dev: 0.12 ms
  Bandwidth: 1234.56 GB/s
  Total Data: 1.23 GB
```

## 预期结果

对于A100 GPU，预期结果大致如下：

| 测试类型 | 基础版本 | 高级版本 |
|---------|---------|---------|
| L1 Cache带宽 | 1000-1500 GB/s | 1200-1800 GB/s |
| L2 Cache带宽 | 400-800 GB/s | 500-1000 GB/s |
| 全局内存带宽 | 1200-1800 GB/s | 1400-2000 GB/s |
| Cache行大小 | N/A | 64-128 bytes |

注意：实际结果可能因GPU配置、驱动程序版本和系统负载而异。

## 技术细节

### 内存访问模式

1. **L1 Cache测试**:
   - 使用共享内存作为L1 Cache的代理
   - 数据块大小: 64KB
   - 访问模式: 块内顺序访问

2. **L2 Cache测试**:
   - 使用全局内存的跨步访问
   - 数据块大小: 8MB
   - 跨步大小: 动态检测（高级版本）

3. **全局内存测试**:
   - 使用顺序访问模式
   - 数据块大小: 1GB
   - 最大化内存带宽

### 带宽计算

带宽计算公式：
```
带宽 = (总字节数 × 迭代次数 × 2) / (时间 × 1024³)
```

其中：
- 总字节数：测试的数据大小
- 迭代次数：重复测试的次数
- ×2：包含读写操作
- 时间：以秒为单位

### 精度改进（高级版本）

1. **多次测量**: 每个测试运行5次取平均值
2. **标准差计算**: 提供测量精度指标
3. **预热**: 在正式测量前进行预热
4. **Cache行检测**: 自动优化访问模式

## 故障排除

### 常见问题

1. **编译错误**: 确保CUDA Toolkit已正确安装
2. **运行时错误**: 检查GPU是否支持CUDA
3. **内存不足**: 减少BUFFER_SIZE常量值
4. **精度问题**: 使用高级版本获得更准确的测量

### 性能优化建议

1. 确保GPU处于最佳性能模式
2. 关闭其他GPU应用程序
3. 使用最新的CUDA驱动程序
4. 在专用测试环境中运行
5. 使用高级版本获得更准确的测量

## 扩展功能

可以添加以下功能来增强程序：

1. **多GPU支持**: 测试多个GPU的Cache性能
2. **不同数据类型**: 测试不同数据类型的带宽
3. **图形化输出**: 生成性能图表
4. **配置文件**: 支持自定义测试参数
5. **结果导出**: 将结果保存为CSV格式

## 文件结构

```
.
├── cuda_cache_bandwidth.cu    # 基础版本程序
├── advanced_cache_test.cu     # 高级版本程序
├── Makefile                   # 编译配置
├── test_compile.sh           # 编译测试脚本
├── README.md                 # 项目说明
└── README_cache_bandwidth.md # 详细技术说明
```

## 许可证

本程序遵循MIT许可证。
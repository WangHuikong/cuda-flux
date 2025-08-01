# AXI4 Master Agent

这是一个完整的AXI4 master agent实现，使用SystemVerilog编写。该agent提供了完整的AXI4协议支持，包括读写事务、突发传输、协议检查等功能。

## 目录结构

```
axi4_master_agent/
├── inc/                    # 接口和类型定义
│   ├── axi4_if.sv         # AXI4接口定义
│   └── axi4_transaction.sv # AXI4事务类型定义
├── rtl/                    # RTL实现
│   ├── axi4_master_agent.sv # 主agent类
│   └── axi4_sequences.sv   # 预定义序列
├── tb/                     # 测试文件
│   └── axi4_master_test.sv # 测试示例
└── README.md              # 本文档
```

## 功能特性

### 1. 完整的AXI4协议支持
- 支持所有AXI4信号和通道
- 支持突发传输（INCR、FIXED、WRAP）
- 支持不同的数据宽度和地址宽度
- 支持ID和用户信号

### 2. 组件化设计
- **Driver**: 负责驱动AXI4信号
- **Monitor**: 负责监控和收集事务信息
- **Sequencer**: 负责生成和发送事务
- **Agent**: 统一管理所有组件

### 3. 预定义序列
- 单次读写序列
- 突发读写序列
- 随机序列
- 内存测试序列

### 4. 事务类型
- 写地址事务（axi4_write_addr_t）
- 写数据事务（axi4_write_data_t）
- 写响应事务（axi4_write_resp_t）
- 读地址事务（axi4_read_addr_t）
- 读数据事务（axi4_read_data_t）

## 使用方法

### 1. 基本使用

```systemverilog
// 创建agent实例
axi4_master_agent #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(64),
    .ID_WIDTH(4),
    .USER_WIDTH(1)
) master_agent;

// 初始化
master_agent = new(axi4_if_inst.master);

// 启动agent
master_agent.start();

// 创建事务
axi4_transaction_t trans = new();
trans.trans_type = AXI4_WRITE;
// ... 配置事务参数

// 发送事务
master_agent.send_transaction(trans);

// 等待完成
master_agent.wait_for_completion();

// 获取响应
master_agent.get_response(trans);
```

### 2. 使用预定义序列

```systemverilog
// 单次写序列
axi4_single_write_sequence write_seq;
write_seq = new(master_agent.req_mbx);
write_seq.addr = 32'h1000_0000;
write_seq.data = 64'h1234_5678_9ABC_DEF0;
write_seq.id = 4'h1;
write_seq.body();

// 突发读序列
axi4_burst_read_sequence read_seq;
read_seq = new(master_agent.req_mbx);
read_seq.addr = 32'h2000_0000;
read_seq.length = 8;
read_seq.id = 4'h2;
read_seq.body();
```

### 3. 配置参数

```systemverilog
// 配置agent
master_agent.config.min_delay = 0;
master_agent.config.max_delay = 10;
master_agent.config.enable_checks = 1;
master_agent.config.enable_coverage = 1;
```

## 事务类型说明

### 写事务
1. **写地址通道**: 发送地址、长度、突发类型等信息
2. **写数据通道**: 发送数据、字节使能、最后标志等
3. **写响应通道**: 接收响应状态

### 读事务
1. **读地址通道**: 发送地址、长度、突发类型等信息
2. **读数据通道**: 接收数据、响应状态、最后标志等

## 突发类型

- **AXI4_FIXED**: 固定地址突发
- **AXI4_INCR**: 递增地址突发
- **AXI4_WRAP**: 回环地址突发

## 响应类型

- **AXI4_OKAY**: 正常响应
- **AXI4_EXOKAY**: 独占访问成功
- **AXI4_SLVERR**: 从设备错误
- **AXI4_DECERR**: 解码错误

## 运行测试

```bash
# 使用ModelSim/QuestaSim
vlog -sv axi4_master_agent/inc/*.sv
vlog -sv axi4_master_agent/rtl/*.sv
vlog -sv axi4_master_agent/tb/*.sv
vsim -c axi4_master_test -do "run -all; quit"

# 使用VCS
vcs -full64 -sverilog axi4_master_agent/inc/*.sv axi4_master_agent/rtl/*.sv axi4_master_agent/tb/*.sv
./simv
```

## 扩展功能

### 1. 添加协议检查
```systemverilog
// 在monitor中添加协议检查
task check_protocol();
    // 检查地址对齐
    if (awvalid && awready) begin
        assert(awaddr % (1 << awsize) == 0) else
            $error("Address not aligned to size");
    end
    
    // 检查突发长度
    if (awvalid && awready) begin
        assert(awlen <= 255) else
            $error("Burst length exceeds maximum");
    end
endtask
```

### 2. 添加覆盖率收集
```systemverilog
// 定义覆盖率组
covergroup axi4_coverage @(posedge aclk);
    awaddr_cp: coverpoint awaddr {
        bins low = {[0:32'h3FFF_FFFF]};
        bins high = {[32'h4000_0000:32'hFFFF_FFFF]};
    }
    
    awburst_cp: coverpoint awburst {
        bins fixed = {AXI4_FIXED};
        bins incr = {AXI4_INCR};
        bins wrap = {AXI4_WRAP};
    }
    
    awlen_cp: coverpoint awlen {
        bins single = {0};
        bins burst = {[1:255]};
    }
endgroup
```

### 3. 添加性能监控
```systemverilog
// 监控事务延迟
class performance_monitor;
    time start_time;
    time end_time;
    
    task start_transaction();
        start_time = $time;
    endtask
    
    task end_transaction();
        end_time = $time;
        $display("Transaction latency: %0t", end_time - start_time);
    endtask
endclass
```

## 注意事项

1. **时钟域**: 所有信号都在同一个时钟域内
2. **复位**: 确保在复位期间所有信号都处于有效状态
3. **握手**: 严格按照AXI4握手协议进行信号驱动
4. **对齐**: 地址必须按照数据大小对齐
5. **突发长度**: AXI4的突发长度是传输次数减1

## 故障排除

### 常见问题

1. **握手死锁**: 检查valid和ready信号的时序
2. **地址对齐错误**: 确保地址按照数据大小对齐
3. **突发长度错误**: 检查突发长度计算
4. **响应超时**: 检查从设备是否正确响应

### 调试技巧

1. 使用波形查看器观察信号时序
2. 添加详细的打印语句
3. 使用断言检查协议违规
4. 监控事务完成状态

## 版本历史

- v1.0: 初始版本，支持基本AXI4功能
- v1.1: 添加预定义序列
- v1.2: 改进错误处理和调试功能

## 许可证

本项目采用MIT许可证，详见LICENSE文件。
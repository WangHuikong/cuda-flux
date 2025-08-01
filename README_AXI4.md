# AXI4 Master Agent

这是一个完整的AXI4 master agent实现，使用SystemVerilog和UVM编写。该agent提供了完整的AXI4协议支持，包括读写操作、突发传输、协议检查等功能。

## 文件结构

```
├── axi4_interface.sv          # AXI4接口定义
├── axi4_config.sv             # AXI4配置类
├── axi4_transaction.sv        # AXI4事务类
├── axi4_master_agent.sv       # AXI4 master agent主文件
├── axi4_master_driver.sv      # AXI4 master driver
├── axi4_master_monitor.sv     # AXI4 master monitor
├── axi4_master_sequencer.sv   # AXI4 master sequencer
├── axi4_sequences.sv          # AXI4测试序列
├── axi4_test_env.sv           # AXI4测试环境
├── axi4_test.sv               # AXI4测试用例
├── axi4_slave.sv              # AXI4 slave模块（用于测试）
├── axi4_tb.sv                 # AXI4测试台
└── README_AXI4.md            # 本文档
```

## 功能特性

### 1. 完整的AXI4协议支持
- 支持所有AXI4信号和通道
- 支持读写操作
- 支持突发传输（FIXED、INCR、WRAP）
- 支持不同的传输大小（1-64字节）
- 支持ID和用户信号

### 2. 可配置参数
- 地址宽度（默认32位）
- 数据宽度（默认64位）
- ID宽度（默认4位）
- 用户信号宽度（默认1位）
- 时序参数
- 突发长度范围
- 响应概率

### 3. UVM组件
- **Agent**: 管理driver、monitor和sequencer
- **Driver**: 驱动AXI4信号
- **Monitor**: 监控AXI4活动
- **Sequencer**: 管理序列执行
- **Scoreboard**: 协议检查
- **Coverage**: 功能覆盖率收集

### 4. 测试序列
- 随机序列
- 写操作序列
- 读操作序列
- 混合序列
- 突发序列

## 使用方法

### 1. 基本设置

```systemverilog
// 创建配置对象
axi4_config config_obj = axi4_config::type_id::create("config");
config_obj.set_addr_width(32);
config_obj.set_data_width(64);
config_obj.set_id_width(4);

// 设置配置到config database
uvm_config_db#(axi4_config)::set(this, "*", "config", config_obj);
uvm_config_db#(virtual axi4_interface)::set(this, "*", "vif", vif);
```

### 2. 创建Agent

```systemverilog
// 在test environment中创建agent
master_agent = axi4_master_agent::type_id::create("master_agent", this);
```

### 3. 运行测试序列

```systemverilog
// 创建并运行序列
axi4_write_sequence write_seq = axi4_write_sequence::type_id::create("write_seq");
write_seq.num_writes = 10;
write_seq.start(master_agent.sequencer);
```

## 配置选项

### 接口参数
```systemverilog
config_obj.set_addr_width(32);      // 地址宽度
config_obj.set_data_width(64);      // 数据宽度
config_obj.set_id_width(4);         // ID宽度
config_obj.set_user_width(1);       // 用户信号宽度
```

### 时序参数
```systemverilog
config_obj.set_timing(0, 5);        // 最小/最大延迟
```

### 突发参数
```systemverilog
config_obj.set_burst_length(1, 16); // 突发长度范围
```

### 响应概率
```systemverilog
config_obj.set_response_probabilities(
    95.0, 3.0, 2.0,  // 写响应：OKAY, SLVERR, DECERR
    95.0, 3.0, 2.0   // 读响应：OKAY, SLVERR, DECERR
);
```

### Ready信号概率
```systemverilog
config_obj.set_ready_probabilities(90.0, 90.0, 90.0, 90.0, 90.0);
// AWREADY, WREADY, BREADY, ARREADY, RREADY
```

## 测试用例

### 1. 基本测试
```systemverilog
class axi4_basic_test extends axi4_test;
    task run_test_sequences();
        axi4_random_sequence random_seq = axi4_random_sequence::type_id::create("random_seq");
        random_seq.num_transactions = 20;
        random_seq.start(test_env.master_agent.sequencer);
    endtask
endclass
```

### 2. 写操作测试
```systemverilog
class axi4_write_test extends axi4_test;
    task run_test_sequences();
        axi4_write_sequence write_seq = axi4_write_sequence::type_id::create("write_seq");
        write_seq.num_writes = 10;
        write_seq.start_addr = 32'h1000_0000;
        write_seq.start(test_env.master_agent.sequencer);
    endtask
endclass
```

### 3. 读操作测试
```systemverilog
class axi4_read_test extends axi4_test;
    task run_test_sequences();
        axi4_read_sequence read_seq = axi4_read_sequence::type_id::create("read_seq");
        read_seq.num_reads = 10;
        read_seq.start_addr = 32'h1000_0000;
        read_seq.start(test_env.master_agent.sequencer);
    endtask
endclass
```

## 协议检查

Agent包含以下协议检查：

1. **地址对齐检查**: 确保地址与传输大小对齐
2. **突发长度检查**: 确保突发长度在有效范围内
3. **突发大小检查**: 确保突发大小不超过最大值
4. **响应代码检查**: 确保响应代码有效

## 覆盖率

Agent提供以下覆盖率：

1. **事务类型覆盖率**: 读写操作
2. **地址覆盖率**: 低、中、高地址范围
3. **突发长度覆盖率**: 单次、小、中、大突发
4. **突发大小覆盖率**: 字节到64字节传输
5. **突发类型覆盖率**: FIXED、INCR、WRAP
6. **响应覆盖率**: OKAY、EXOKAY、SLVERR、DECERR
7. **交叉覆盖率**: 各种参数组合

## 编译和运行

### 使用ModelSim/QuestaSim
```bash
# 编译
vlog -sv axi4_interface.sv
vlog -sv axi4_config.sv
vlog -sv axi4_transaction.sv
vlog -sv axi4_master_driver.sv
vlog -sv axi4_master_monitor.sv
vlog -sv axi4_master_sequencer.sv
vlog -sv axi4_master_agent.sv
vlog -sv axi4_sequences.sv
vlog -sv axi4_test_env.sv
vlog -sv axi4_test.sv
vlog -sv axi4_slave.sv
vlog -sv axi4_tb.sv

# 运行
vsim -c axi4_tb -do "run -all; quit"
```

### 使用VCS
```bash
# 编译
vcs -full64 -sverilog axi4_interface.sv axi4_config.sv axi4_transaction.sv \
    axi4_master_driver.sv axi4_master_monitor.sv axi4_master_sequencer.sv \
    axi4_master_agent.sv axi4_sequences.sv axi4_test_env.sv axi4_test.sv \
    axi4_slave.sv axi4_tb.sv

# 运行
./simv
```

## 扩展功能

### 1. 添加新的序列
```systemverilog
class axi4_custom_sequence extends axi4_base_sequence;
    task body();
        // 自定义序列实现
    endtask
endclass
```

### 2. 添加新的检查
```systemverilog
function void check_custom_protocol(axi4_transaction trans);
    // 自定义协议检查
endfunction
```

### 3. 添加新的覆盖率
```systemverilog
covergroup custom_cov;
    // 自定义覆盖率定义
endgroup
```

## 注意事项

1. **时钟域**: 确保所有信号在正确的时钟域中
2. **复位**: 确保复位信号正确初始化所有信号
3. **时序**: 注意AXI4协议的时序要求
4. **约束**: 根据实际需求调整随机约束
5. **覆盖率**: 定期检查覆盖率报告

## 故障排除

### 常见问题

1. **编译错误**: 检查SystemVerilog和UVM库路径
2. **运行时错误**: 检查虚拟接口连接
3. **协议违规**: 检查约束设置
4. **覆盖率低**: 调整序列参数

### 调试技巧

1. 使用UVM_INFO增加调试信息
2. 检查波形文件
3. 验证约束设置
4. 检查覆盖率报告

## 版本历史

- v1.0: 初始版本，基本AXI4功能
- v1.1: 添加覆盖率收集
- v1.2: 改进协议检查
- v1.3: 添加更多测试序列

## 许可证

本项目采用MIT许可证。详见LICENSE文件。

## 贡献

欢迎提交问题报告和功能请求。请确保代码符合项目的编码规范。
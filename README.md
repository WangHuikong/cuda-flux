# AXI4 Master Agent

这是一个完整的SystemVerilog AXI4 Master Agent实现，基于UVM验证方法学构建。该Agent可以用于验证AXI4从设备或作为AXI4主设备的行为模型。

## 文件结构

```
├── axi4_interface.sv          # AXI4接口定义
├── axi4_transaction.sv        # AXI4事务类定义
├── axi4_master_driver.sv      # AXI4主设备驱动器
├── axi4_master_monitor.sv     # AXI4主设备监视器
├── axi4_master_sequencer.sv   # AXI4主设备序列器和序列
├── axi4_master_agent.sv       # AXI4主设备代理和配置类
├── axi4_master_tb.sv          # 示例测试台
└── README.md                  # 使用说明
```

## 主要特性

### AXI4接口支持
- 完整的AXI4信号定义
- 可配置的地址宽度、数据宽度、ID宽度和用户信号宽度
- 支持主设备、从设备和监视器模式端口

### 事务类特性
- 支持读写事务类型
- 完整的AXI4属性支持（burst类型、大小、长度等）
- 智能约束确保AXI4协议合规性
- 自动数组分配基于突发长度

### 驱动器功能
- 并行处理写地址、写数据和写响应通道
- 支持可配置的延迟
- 完整的握手协议实现
- 错误检查和报告

### 监视器功能
- 事务重建和匹配
- 功能覆盖率收集
- 协议检查
- 分析端口输出

### 序列器和序列
- 基础序列类
- 单次读写序列
- 突发读写序列
- 随机混合序列
- 写-读-比较序列

## 使用方法

### 1. 基本设置

```systemverilog
// 导入包
import uvm_pkg::*;
import axi4_master_pkg::*;
`include "uvm_macros.svh"

// 实例化接口
axi4_interface #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32),
    .ID_WIDTH(4),
    .USER_WIDTH(1)
) axi4_if (
    .aclk(clk),
    .aresetn(resetn)
);

// 在配置数据库中设置接口
uvm_config_db#(virtual axi4_interface#(32,32,4,1))::set(
    null, "*", "vif", axi4_if);
```

### 2. 创建和配置Agent

```systemverilog
class my_env extends uvm_env;
    axi4_master_agent#(32,32,4,1) agent;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 创建代理
        agent = axi4_master_agent#(32,32,4,1)::type_id::create("agent", this);
        
        // 配置代理
        axi4_master_config cfg = axi4_master_config::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        cfg.has_coverage = 1;
        cfg.max_outstanding_transactions = 8;
        uvm_config_db#(axi4_master_config)::set(this, "agent", "config", cfg);
    endfunction
endclass
```

### 3. 运行序列

```systemverilog
// 运行单次写序列
axi4_single_write_sequence#(32,32,4,1) write_seq;
write_seq = axi4_single_write_sequence#(32,32,4,1)::type_id::create("write_seq");
write_seq.start_addr = 32'h1000;
write_seq.write_data = 32'hDEADBEEF;
write_seq.trans_id = 4'h1;
write_seq.start(sequencer);

// 运行突发读序列
axi4_burst_read_sequence#(32,32,4,1) read_seq;
read_seq = axi4_burst_read_sequence#(32,32,4,1)::type_id::create("read_seq");
read_seq.start_addr = 32'h2000;
read_seq.burst_len = 7;  // 8个传输
read_seq.burst_size = AXI4_SIZE_4B;
read_seq.burst_type = AXI4_BURST_INCR;
read_seq.start(sequencer);
```

### 4. 自定义序列

```systemverilog
class my_custom_sequence extends axi4_base_sequence#(32,32,4,1);
    `uvm_object_utils(my_custom_sequence)
    
    function new(string name = "my_custom_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi4_trans_t trans;
        
        // 创建自定义事务
        trans = axi4_trans_t::type_id::create("custom_trans");
        start_item(trans);
        
        assert(trans.randomize() with {
            trans_type == AXI4_WRITE;
            addr inside {[32'h1000:32'h1FFF]};
            len == 3;  // 4个传输
            size == AXI4_SIZE_4B;
            burst == AXI4_BURST_INCR;
        });
        
        finish_item(trans);
    endtask
endclass
```

## 配置参数

### 接口参数
- `ADDR_WIDTH`: 地址总线宽度（默认32）
- `DATA_WIDTH`: 数据总线宽度（默认32）
- `ID_WIDTH`: ID信号宽度（默认4）
- `USER_WIDTH`: 用户信号宽度（默认1）

### 配置对象参数
- `is_active`: 代理模式（UVM_ACTIVE/UVM_PASSIVE）
- `has_coverage`: 启用功能覆盖率收集
- `has_checks`: 启用协议检查
- `max_outstanding_transactions`: 最大未完成事务数
- `default_*_delay`: 默认延迟配置
- `min_addr/max_addr`: 地址范围限制

## 约束和限制

### AXI4协议约束
- 地址对齐到传输大小
- WRAP突发长度限制（1,3,7,15）
- 最大突发长度255
- 有效的突发类型和大小组合

### 实现限制
- 当前实现假设数据宽度为32位的倍数
- 不支持窄传输
- 用户信号处理简化

## 覆盖率

监视器自动收集以下覆盖率：
- 地址范围覆盖率
- 突发长度覆盖率
- 传输大小覆盖率
- 突发类型覆盖率
- 交叉覆盖率（大小×突发类型，长度×突发类型）

## 示例运行

```bash
# 使用Questasim编译和运行
vlog -sv +incdir+. *.sv
vsim -c axi4_master_tb -do "run -all; quit"

# 使用VCS编译和运行
vcs -sverilog +incdir+. *.sv
./simv

# 使用Xcelium编译和运行
xrun -sv +incdir+. *.sv
```

## 调试和波形

测试台自动生成VCD波形文件：
```systemverilog
initial begin
    $dumpfile("axi4_master_tb.vcd");
    $dumpvars(0, axi4_master_tb);
end
```

使用GTKWave或其他波形查看器查看：
```bash
gtkwave axi4_master_tb.vcd
```

## 扩展和定制

### 添加新序列类型
1. 继承`axi4_base_sequence`
2. 实现`body()`任务
3. 注册到UVM工厂

### 添加协议检查
1. 在监视器中添加检查逻辑
2. 使用`uvm_error`报告违规

### 添加性能分析
1. 在监视器中收集时序信息
2. 计算带宽和延迟统计

## 许可证

此代码仅供学习和参考使用。请根据您的项目要求调整和修改。

## 支持

如有问题或建议，请参考AXI4协议规范和UVM用户指南。
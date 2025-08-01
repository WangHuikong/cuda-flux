// AXI4 Master Agent 使用示例
// 这个文件展示了如何使用AXI4 master agent

`ifndef EXAMPLE_USAGE_SV
`define EXAMPLE_USAGE_SV

// 示例1: 基本使用
class basic_usage_example extends uvm_test;
    `uvm_component_utils(basic_usage_example)
    
    axi4_test_env test_env;
    virtual axi4_interface vif;
    
    function new(string name = "basic_usage_example", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取虚拟接口
        if (!uvm_config_db#(virtual axi4_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("EXAMPLE", "Failed to get virtual interface")
        end
        
        // 创建测试环境
        test_env = axi4_test_env::type_id::create("test_env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        // 等待复位完成
        wait_for_reset();
        
        // 运行基本测试序列
        run_basic_sequences();
        
        phase.drop_objection(this);
    endtask
    
    task wait_for_reset();
        @(posedge vif.aclk);
        while (vif.aresetn == 0) begin
            @(posedge vif.aclk);
        end
    endtask
    
    task run_basic_sequences();
        // 创建写序列
        axi4_write_sequence write_seq = axi4_write_sequence::type_id::create("write_seq");
        write_seq.num_writes = 5;
        write_seq.start_addr = 32'h1000_0000;
        write_seq.start(test_env.master_agent.sequencer);
        
        #100;
        
        // 创建读序列
        axi4_read_sequence read_seq = axi4_read_sequence::type_id::create("read_seq");
        read_seq.num_reads = 5;
        read_seq.start_addr = 32'h1000_0000;
        read_seq.start(test_env.master_agent.sequencer);
    endtask
    
endclass

// 示例2: 自定义配置
class custom_config_example extends uvm_test;
    `uvm_component_utils(custom_config_example)
    
    axi4_test_env test_env;
    virtual axi4_interface vif;
    axi4_config custom_config;
    
    function new(string name = "custom_config_example", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取虚拟接口
        if (!uvm_config_db#(virtual axi4_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("EXAMPLE", "Failed to get virtual interface")
        end
        
        // 创建自定义配置
        custom_config = axi4_config::type_id::create("custom_config");
        
        // 设置自定义参数
        custom_config.set_addr_width(32);
        custom_config.set_data_width(64);
        custom_config.set_id_width(4);
        custom_config.set_user_width(1);
        custom_config.set_timing(2, 8);  // 2-8个时钟周期的延迟
        custom_config.set_burst_length(2, 8);  // 2-8个传输的突发
        custom_config.set_addr_range(32'h2000_0000, 32'h2FFF_FFFF);  // 自定义地址范围
        custom_config.set_response_probabilities(98.0, 1.5, 0.5, 98.0, 1.5, 0.5);  // 自定义响应概率
        custom_config.set_ready_probabilities(85.0, 85.0, 85.0, 85.0, 85.0);  // 自定义ready概率
        custom_config.set_default_attributes(4'b0011, 3'b000, 4'b0000, 1'b0);
        
        // 设置配置到config database
        uvm_config_db#(axi4_config)::set(this, "*", "config", custom_config);
        uvm_config_db#(virtual axi4_interface)::set(this, "*", "vif", vif);
        
        // 创建测试环境
        test_env = axi4_test_env::type_id::create("test_env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        wait_for_reset();
        run_custom_sequences();
        
        phase.drop_objection(this);
    endtask
    
    task wait_for_reset();
        @(posedge vif.aclk);
        while (vif.aresetn == 0) begin
            @(posedge vif.aclk);
        end
    endtask
    
    task run_custom_sequences();
        // 运行随机序列
        axi4_random_sequence random_seq = axi4_random_sequence::type_id::create("random_seq");
        random_seq.num_transactions = 10;
        random_seq.start(test_env.master_agent.sequencer);
        
        #100;
        
        // 运行突发序列
        axi4_burst_sequence burst_seq = axi4_burst_sequence::type_id::create("burst_seq");
        burst_seq.num_bursts = 3;
        burst_seq.burst_length = 4;
        burst_seq.burst_size = 3;
        burst_seq.start(test_env.master_agent.sequencer);
    endtask
    
endclass

// 示例3: 自定义序列
class custom_sequence_example extends axi4_base_sequence;
    `uvm_object_utils(custom_sequence_example)
    
    // 自定义参数
    int unsigned num_transactions = 8;
    bit [31:0] base_addr = 32'h3000_0000;
    int unsigned burst_len = 4;
    
    function new(string name = "custom_sequence_example");
        super.new(name);
    endfunction
    
    task body();
        axi4_transaction trans;
        
        `uvm_info("CUSTOM_SEQUENCE", $sformatf("Starting custom sequence with %0d transactions", num_transactions), UVM_LOW)
        
        for (int i = 0; i < num_transactions; i++) begin
            trans = axi4_transaction::type_id::create($sformatf("custom_trans_%0d", i));
            
            // 配置事务
            trans.set_trans_type(i % 2 == 0 ? WRITE : READ);  // 交替读写
            trans.set_addr(base_addr + (i * 64));
            trans.set_id(i % 4);
            trans.set_burst_length(burst_len);
            trans.set_burst_size(3);  // 8字节传输
            trans.set_burst_type(INCR);
            trans.set_delay($urandom_range(1, 3));
            
            // 设置默认属性
            trans.lock = 0;
            trans.cache = config_obj.default_cache;
            trans.prot = config_obj.default_prot;
            trans.qos = config_obj.default_qos;
            trans.region = 0;
            trans.user = config_obj.default_user;
            
            // 发送事务
            start_item(trans);
            finish_item(trans);
            
            `uvm_info("CUSTOM_SEQUENCE", $sformatf("Generated %s transaction %0d: addr=0x%08x", 
                       trans.trans_type.name(), i, trans.addr), UVM_MEDIUM)
        end
    endtask
    
endclass

// 示例4: 使用自定义序列的测试
class custom_sequence_test extends uvm_test;
    `uvm_component_utils(custom_sequence_test)
    
    axi4_test_env test_env;
    virtual axi4_interface vif;
    
    function new(string name = "custom_sequence_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取虚拟接口
        if (!uvm_config_db#(virtual axi4_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("EXAMPLE", "Failed to get virtual interface")
        end
        
        // 创建测试环境
        test_env = axi4_test_env::type_id::create("test_env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        wait_for_reset();
        
        // 运行自定义序列
        custom_sequence_example custom_seq = custom_sequence_example::type_id::create("custom_seq");
        custom_seq.num_transactions = 12;
        custom_seq.base_addr = 32'h4000_0000;
        custom_seq.burst_len = 6;
        custom_seq.start(test_env.master_agent.sequencer);
        
        phase.drop_objection(this);
    endtask
    
    task wait_for_reset();
        @(posedge vif.aclk);
        while (vif.aresetn == 0) begin
            @(posedge vif.aclk);
        end
    endtask
    
endclass

// 示例5: 协议检查扩展
class extended_protocol_check extends axi4_scoreboard;
    `uvm_component_utils(extended_protocol_check)
    
    function new(string name = "extended_protocol_check", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void write(axi4_transaction trans);
        // 调用父类的检查
        super.write(trans);
        
        // 添加自定义检查
        check_custom_protocol(trans);
    endfunction
    
    function void check_custom_protocol(axi4_transaction trans);
        // 检查地址范围
        if (trans.addr < 32'h1000_0000 || trans.addr > 32'hFFFF_FFFF) begin
            `uvm_warning("EXTENDED_CHECK", $sformatf("Address out of expected range: 0x%08x", trans.addr))
        end
        
        // 检查突发长度
        if (trans.len > 16) begin
            `uvm_warning("EXTENDED_CHECK", $sformatf("Burst length too large: %0d", trans.len))
        end
        
        // 检查ID值
        if (trans.id > 15) begin
            `uvm_warning("EXTENDED_CHECK", $sformatf("Invalid ID value: %0d", trans.id))
        end
        
        // 检查写事务的数据
        if (trans.trans_type == WRITE && trans.data.size() > 0) begin
            for (int i = 0; i < trans.data.size(); i++) begin
                if (trans.data[i] == 0) begin
                    `uvm_info("EXTENDED_CHECK", $sformatf("Write data is zero at index %0d", i), UVM_MEDIUM)
                end
            end
        end
    endfunction
    
endclass

`endif // EXAMPLE_USAGE_SV
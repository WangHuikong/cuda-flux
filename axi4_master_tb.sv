// AXI4 Master Agent Testbench Example
// This testbench demonstrates usage of the AXI4 Master Agent

`timescale 1ns/1ps

module axi4_master_tb;

    import uvm_pkg::*;
    import axi4_master_pkg::*;
    `include "uvm_macros.svh"

    // Clock and reset
    logic aclk;
    logic aresetn;

    // AXI4 Interface instantiation
    axi4_interface #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .ID_WIDTH(4),
        .USER_WIDTH(1)
    ) axi4_if (
        .aclk(aclk),
        .aresetn(aresetn)
    );

    // Clock generation
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;  // 100MHz clock
    end

    // Reset generation
    initial begin
        aresetn = 0;
        #100;
        aresetn = 1;
    end

    // DUT placeholder (simple memory model)
    axi4_memory_model memory_dut (
        .axi4_if(axi4_if.slave)
    );

    // UVM testbench setup
    initial begin
        // Set interface in config DB
        uvm_config_db#(virtual axi4_interface#(32,32,4,1))::set(
            null, "*", "vif", axi4_if);
        
        // Run test
        run_test("axi4_master_test");
    end

    // Waveform dumping
    initial begin
        $dumpfile("axi4_master_tb.vcd");
        $dumpvars(0, axi4_master_tb);
    end

endmodule

// Simple AXI4 Memory Model for testing
module axi4_memory_model (
    axi4_interface.slave axi4_if
);

    // Memory array
    logic [31:0] memory [logic [31:0]];
    
    // Outstanding transactions
    typedef struct {
        logic [3:0]  id;
        logic [31:0] addr;
        logic [7:0]  len;
        int          beat_count;
    } outstanding_trans_t;
    
    outstanding_trans_t write_queue[$];
    outstanding_trans_t read_queue[$];

    // Write address channel
    always @(posedge axi4_if.aclk) begin
        if (!axi4_if.aresetn) begin
            axi4_if.awready <= 1'b0;
        end else begin
            axi4_if.awready <= 1'b1;  // Always ready
            
            if (axi4_if.awvalid && axi4_if.awready) begin
                outstanding_trans_t trans;
                trans.id = axi4_if.awid;
                trans.addr = axi4_if.awaddr;
                trans.len = axi4_if.awlen;
                trans.beat_count = 0;
                write_queue.push_back(trans);
            end
        end
    end

    // Write data channel
    always @(posedge axi4_if.aclk) begin
        if (!axi4_if.aresetn) begin
            axi4_if.wready <= 1'b0;
        end else begin
            axi4_if.wready <= 1'b1;  // Always ready
            
            if (axi4_if.wvalid && axi4_if.wready && write_queue.size() > 0) begin
                outstanding_trans_t trans = write_queue[0];
                logic [31:0] write_addr = trans.addr + (trans.beat_count * 4);
                
                // Write to memory
                memory[write_addr] = axi4_if.wdata;
                
                trans.beat_count++;
                write_queue[0] = trans;
                
                // Check for last beat
                if (axi4_if.wlast) begin
                    write_queue.pop_front();
                end
            end
        end
    end

    // Write response channel
    logic [3:0] bresp_id_queue[$];
    
    always @(posedge axi4_if.aclk) begin
        if (!axi4_if.aresetn) begin
            axi4_if.bvalid <= 1'b0;
            axi4_if.bid <= 0;
            axi4_if.bresp <= 0;
            axi4_if.buser <= 0;
        end else begin
            // Generate response after write data
            if (axi4_if.wvalid && axi4_if.wready && axi4_if.wlast && write_queue.size() > 0) begin
                bresp_id_queue.push_back(write_queue[0].id);
            end
            
            // Send response
            if (bresp_id_queue.size() > 0 && (!axi4_if.bvalid || axi4_if.bready)) begin
                axi4_if.bvalid <= 1'b1;
                axi4_if.bid <= bresp_id_queue.pop_front();
                axi4_if.bresp <= 2'b00;  // OKAY
                axi4_if.buser <= 0;
            end else if (axi4_if.bready) begin
                axi4_if.bvalid <= 1'b0;
            end
        end
    end

    // Read address channel
    always @(posedge axi4_if.aclk) begin
        if (!axi4_if.aresetn) begin
            axi4_if.arready <= 1'b0;
        end else begin
            axi4_if.arready <= 1'b1;  // Always ready
            
            if (axi4_if.arvalid && axi4_if.arready) begin
                outstanding_trans_t trans;
                trans.id = axi4_if.arid;
                trans.addr = axi4_if.araddr;
                trans.len = axi4_if.arlen;
                trans.beat_count = 0;
                read_queue.push_back(trans);
            end
        end
    end

    // Read data channel
    always @(posedge axi4_if.aclk) begin
        if (!axi4_if.aresetn) begin
            axi4_if.rvalid <= 1'b0;
            axi4_if.rid <= 0;
            axi4_if.rdata <= 0;
            axi4_if.rresp <= 0;
            axi4_if.rlast <= 0;
            axi4_if.ruser <= 0;
        end else begin
            if (read_queue.size() > 0 && (!axi4_if.rvalid || axi4_if.rready)) begin
                outstanding_trans_t trans = read_queue[0];
                logic [31:0] read_addr = trans.addr + (trans.beat_count * 4);
                
                axi4_if.rvalid <= 1'b1;
                axi4_if.rid <= trans.id;
                axi4_if.rdata <= memory.exists(read_addr) ? memory[read_addr] : 32'hDEADBEEF;
                axi4_if.rresp <= 2'b00;  // OKAY
                axi4_if.rlast <= (trans.beat_count == trans.len);
                axi4_if.ruser <= 0;
                
                trans.beat_count++;
                read_queue[0] = trans;
                
                if (axi4_if.rlast) begin
                    read_queue.pop_front();
                end
            end else if (axi4_if.rready) begin
                axi4_if.rvalid <= 1'b0;
                axi4_if.rlast <= 1'b0;
            end
        end
    end

endmodule

// UVM Test Class
class axi4_master_test extends uvm_test;

    // Environment
    axi4_master_env env;

    // UVM Factory Registration
    `uvm_component_utils(axi4_master_test)

    // Constructor
    function new(string name = "axi4_master_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create environment
        env = axi4_master_env::type_id::create("env", this);
        
        // Set default sequence
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.agent.sequencer.run_phase", 
            "default_sequence", axi4_random_sequence#(32,32,4,1)::type_id::get());
    endfunction

    // Run phase
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting AXI4 Master test", UVM_LOW)
        
        // Wait for some time to let sequences run
        #10000;
        
        `uvm_info(get_type_name(), "AXI4 Master test completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask

endclass

// UVM Environment Class
class axi4_master_env extends uvm_env;

    // Agent
    axi4_master_agent#(32,32,4,1) agent;
    
    // Scoreboard (optional)
    axi4_master_scoreboard scoreboard;

    // UVM Factory Registration
    `uvm_component_utils(axi4_master_env)

    // Constructor
    function new(string name = "axi4_master_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create agent
        agent = axi4_master_agent#(32,32,4,1)::type_id::create("agent", this);
        
        // Create scoreboard
        scoreboard = axi4_master_scoreboard::type_id::create("scoreboard", this);
        
        // Configure agent
        axi4_master_config cfg = axi4_master_config::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(axi4_master_config)::set(this, "agent", "config", cfg);
    endfunction

    // Connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect agent to scoreboard
        agent.item_collected_port.connect(scoreboard.item_collected_export);
    endfunction

endclass

// Simple Scoreboard
class axi4_master_scoreboard extends uvm_scoreboard;

    // Analysis export
    uvm_analysis_export #(axi4_transaction#(32,32,4,1)) item_collected_export;
    
    // Analysis FIFO
    uvm_tlm_analysis_fifo #(axi4_transaction#(32,32,4,1)) item_collected_fifo;
    
    // Statistics
    int write_count = 0;
    int read_count = 0;

    // UVM Factory Registration
    `uvm_component_utils(axi4_master_scoreboard)

    // Constructor
    function new(string name = "axi4_master_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        item_collected_export = new("item_collected_export", this);
        item_collected_fifo = new("item_collected_fifo", this);
    endfunction

    // Connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        item_collected_export.connect(item_collected_fifo.analysis_export);
    endfunction

    // Run phase
    task run_phase(uvm_phase phase);
        axi4_transaction#(32,32,4,1) trans;
        
        forever begin
            item_collected_fifo.get(trans);
            
            if (trans.trans_type == AXI4_WRITE) begin
                write_count++;
                `uvm_info(get_type_name(), 
                    $sformatf("Write transaction received: %s", trans.convert2string()), UVM_HIGH)
            end else begin
                read_count++;
                `uvm_info(get_type_name(), 
                    $sformatf("Read transaction received: %s", trans.convert2string()), UVM_HIGH)
            end
        end
    endtask

    // Report phase
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), 
            $sformatf("Scoreboard Summary: %0d writes, %0d reads", 
                write_count, read_count), UVM_LOW)
    endfunction

endclass
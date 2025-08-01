// AXI4 Test Environment
// This file contains the complete test environment for AXI4

`ifndef AXI4_TEST_ENV_SV
`define AXI4_TEST_ENV_SV

class axi4_test_env extends uvm_env;
    `uvm_component_utils(axi4_test_env)
    
    // Agents
    axi4_master_agent master_agent;
    
    // Scoreboard
    axi4_scoreboard scoreboard;
    
    // Coverage collector
    axi4_coverage_collector coverage_collector;
    
    // Configuration
    axi4_config config_obj;
    
    function new(string name = "axi4_test_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create configuration
        config_obj = axi4_config::type_id::create("config");
        
        // Set default configuration
        config_obj.set_addr_width(32);
        config_obj.set_data_width(64);
        config_obj.set_id_width(4);
        config_obj.set_user_width(1);
        config_obj.set_timing(0, 5);
        config_obj.set_burst_length(1, 16);
        config_obj.set_addr_range(32'h0000_0000, 32'hFFFF_FFFF);
        config_obj.set_default_attributes(4'b0011, 3'b000, 4'b0000, 1'b0);
        
        // Set configuration in config database
        uvm_config_db#(axi4_config)::set(this, "*", "config", config_obj);
        
        // Build agents
        master_agent = axi4_master_agent::type_id::create("master_agent", this);
        
        // Build scoreboard
        scoreboard = axi4_scoreboard::type_id::create("scoreboard", this);
        
        // Build coverage collector
        coverage_collector = axi4_coverage_collector::type_id::create("coverage_collector", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect monitor to scoreboard
        master_agent.monitor.ap.connect(scoreboard.master_ap);
        
        // Connect monitor to coverage collector
        master_agent.monitor.ap.connect(coverage_collector.analysis_export);
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI4_TEST_ENV", "Test environment report completed", UVM_LOW)
    endfunction
    
endclass

// Scoreboard class
class axi4_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi4_scoreboard)
    
    // Analysis ports
    uvm_analysis_imp #(axi4_transaction, axi4_scoreboard) master_ap;
    
    // Statistics
    int unsigned total_transactions = 0;
    int unsigned read_transactions = 0;
    int unsigned write_transactions = 0;
    int unsigned error_transactions = 0;
    
    function new(string name = "axi4_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        master_ap = new("master_ap", this);
    endfunction
    
    function void write(axi4_transaction trans);
        total_transactions++;
        
        case (trans.trans_type)
            READ:  read_transactions++;
            WRITE: write_transactions++;
            default: error_transactions++;
        endcase
        
        // Check for protocol violations
        check_protocol_compliance(trans);
        
        `uvm_info("AXI4_SCOREBOARD", $sformatf("Received %s transaction: addr=0x%08x, len=%0d", 
                   trans.trans_type.name(), trans.addr, trans.len), UVM_MEDIUM)
    endfunction
    
    function void check_protocol_compliance(axi4_transaction trans);
        // Check address alignment
        if (trans.addr % (1 << trans.size) != 0) begin
            `uvm_error("AXI4_SCOREBOARD", $sformatf("Address alignment violation: addr=0x%08x, size=%0d", trans.addr, trans.size))
        end
        
        // Check burst length
        if (trans.len > 255) begin
            `uvm_error("AXI4_SCOREBOARD", $sformatf("Invalid burst length: %0d", trans.len))
        end
        
        // Check burst size
        if (trans.size > 6) begin
            `uvm_error("AXI4_SCOREBOARD", $sformatf("Invalid burst size: %0d", trans.size))
        end
        
        // Check response codes
        if (trans.resp != OKAY && trans.resp != EXOKAY && trans.resp != SLVERR && trans.resp != DECERR) begin
            `uvm_error("AXI4_SCOREBOARD", $sformatf("Invalid response code: %0d", trans.resp))
        end
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI4_SCOREBOARD", $sformatf("Scoreboard Report:\n  Total transactions: %0d\n  Read transactions: %0d\n  Write transactions: %0d\n  Error transactions: %0d", 
                   total_transactions, read_transactions, write_transactions, error_transactions), UVM_LOW)
    endfunction
    
endclass

// Coverage collector class
class axi4_coverage_collector extends uvm_subscriber #(axi4_transaction);
    `uvm_component_utils(axi4_coverage_collector)
    
    // Coverage groups
    covergroup axi4_cov;
        // Transaction type coverage
        TRANS_TYPE_CP: coverpoint item.trans_type {
            bins read = {READ};
            bins write = {WRITE};
        }
        
        // Address coverage
        ADDR_CP: coverpoint item.addr {
            bins low_addr = {[0:32'h3FFF_FFFF]};
            bins mid_addr = {[32'h4000_0000:32'h7FFF_FFFF]};
            bins high_addr = {[32'h8000_0000:32'hFFFF_FFFF]};
        }
        
        // Burst length coverage
        LEN_CP: coverpoint item.len {
            bins single = {0};
            bins small = {[1:7]};
            bins medium = {[8:15]};
            bins large = {[16:255]};
        }
        
        // Burst size coverage
        SIZE_CP: coverpoint item.size {
            bins byte = {0};
            bins halfword = {1};
            bins word = {2};
            bins doubleword = {3};
            bins quadword = {4};
            bins octword = {5};
            bins hexword = {6};
        }
        
        // Burst type coverage
        BURST_CP: coverpoint item.burst {
            bins fixed = {FIXED};
            bins incr = {INCR};
            bins wrap = {WRAP};
        }
        
        // Response coverage
        RESP_CP: coverpoint item.resp {
            bins okay = {OKAY};
            bins exokay = {EXOKAY};
            bins slverr = {SLVERR};
            bins decerr = {DECERR};
        }
        
        // Cross coverage
        TRANS_ADDR_CROSS: cross TRANS_TYPE_CP, ADDR_CP;
        TRANS_LEN_CROSS: cross TRANS_TYPE_CP, LEN_CP;
        TRANS_SIZE_CROSS: cross TRANS_TYPE_CP, SIZE_CP;
        TRANS_BURST_CROSS: cross TRANS_TYPE_CP, BURST_CP;
        LEN_SIZE_CROSS: cross LEN_CP, SIZE_CP;
        BURST_SIZE_CROSS: cross BURST_CP, SIZE_CP;
    endgroup
    
    function new(string name = "axi4_coverage_collector", uvm_component parent = null);
        super.new(name, parent);
        axi4_cov = new();
    endfunction
    
    function void write(axi4_transaction t);
        item = t;
        axi4_cov.sample();
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI4_COVERAGE_COLLECTOR", $sformatf("Coverage Report:\n  Coverage: %0.2f%%", axi4_cov.get_coverage()), UVM_LOW)
    endfunction
    
endclass

`endif // AXI4_TEST_ENV_SV
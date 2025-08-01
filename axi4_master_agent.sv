// AXI4 Master Agent
// This agent contains driver, monitor, and sequencer for AXI4 master functionality

`ifndef AXI4_MASTER_AGENT_SV
`define AXI4_MASTER_AGENT_SV

class axi4_master_agent #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends uvm_agent;

    // Component handles
    axi4_master_driver#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)     driver;
    axi4_master_monitor#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)    monitor;
    axi4_master_sequencer#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)  sequencer;

    // Analysis port from monitor
    uvm_analysis_port #(axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)) item_collected_port;

    // Configuration object
    axi4_master_config config_obj;

    // UVM Factory Registration
    `uvm_component_param_utils(axi4_master_agent#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_master_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get configuration object
        if (!uvm_config_db#(axi4_master_config)::get(this, "", "config", config_obj)) begin
            `uvm_info(get_type_name(), "Config object not found, using default configuration", UVM_MEDIUM)
            config_obj = axi4_master_config::type_id::create("config_obj");
        end

        // Set agent configuration
        is_active = config_obj.is_active;

        // Always create monitor
        monitor = axi4_master_monitor#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)::type_id::create("monitor", this);

        // Create driver and sequencer only if agent is active
        if (is_active == UVM_ACTIVE) begin
            driver = axi4_master_driver#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)::type_id::create("driver", this);
            sequencer = axi4_master_sequencer#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)::type_id::create("sequencer", this);
        end

        `uvm_info(get_type_name(), 
            $sformatf("AXI4 Master Agent built with mode: %s", 
                (is_active == UVM_ACTIVE) ? "ACTIVE" : "PASSIVE"), UVM_MEDIUM)
    endfunction

    // Connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect analysis port from monitor
        item_collected_port = monitor.item_collected_port;

        // Connect driver to sequencer if active
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            `uvm_info(get_type_name(), "Driver connected to sequencer", UVM_HIGH)
        end
    endfunction

    // Run phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        // Additional run-time functionality can be added here
        `uvm_info(get_type_name(), "AXI4 Master Agent running", UVM_HIGH)
    endtask

endclass

// AXI4 Master Configuration Class
class axi4_master_config extends uvm_object;

    // Configuration parameters
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    // Interface configuration
    bit has_coverage = 1;
    bit has_checks = 1;
    
    // Timing configuration
    int max_outstanding_transactions = 16;
    int default_addr_delay = 0;
    int default_data_delay = 0;
    int default_resp_delay = 0;

    // Address range configuration
    logic [31:0] min_addr = 32'h0000_0000;
    logic [31:0] max_addr = 32'hFFFF_FFFF;

    // UVM Factory Registration
    `uvm_object_utils_begin(axi4_master_config)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_int(has_coverage, UVM_ALL_ON)
        `uvm_field_int(has_checks, UVM_ALL_ON)
        `uvm_field_int(max_outstanding_transactions, UVM_ALL_ON)
        `uvm_field_int(default_addr_delay, UVM_ALL_ON)
        `uvm_field_int(default_data_delay, UVM_ALL_ON)
        `uvm_field_int(default_resp_delay, UVM_ALL_ON)
        `uvm_field_int(min_addr, UVM_ALL_ON)
        `uvm_field_int(max_addr, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "axi4_master_config");
        super.new(name);
    endfunction

    // Validation function
    function bit is_valid();
        if (min_addr >= max_addr) begin
            `uvm_error("CONFIG_ERROR", "min_addr must be less than max_addr")
            return 0;
        end
        
        if (max_outstanding_transactions <= 0) begin
            `uvm_error("CONFIG_ERROR", "max_outstanding_transactions must be positive")
            return 0;
        end
        
        return 1;
    endfunction

endclass

// AXI4 Master Agent Package
package axi4_master_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Include all component files
    `include "axi4_transaction.sv"
    `include "axi4_master_driver.sv"
    `include "axi4_master_monitor.sv"
    `include "axi4_master_sequencer.sv"
    `include "axi4_master_agent.sv"
    
endpackage

`endif // AXI4_MASTER_AGENT_SV
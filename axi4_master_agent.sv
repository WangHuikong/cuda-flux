// AXI4 Master Agent
// This file contains the AXI4 master agent implementation
// Supports AXI4 protocol with configurable data width and address width

`ifndef AXI4_MASTER_AGENT_SV
`define AXI4_MASTER_AGENT_SV

`include "axi4_interface.sv"
`include "axi4_transaction.sv"
`include "axi4_master_driver.sv"
`include "axi4_master_monitor.sv"
`include "axi4_master_sequencer.sv"

class axi4_master_agent extends uvm_agent;
    `uvm_component_utils(axi4_master_agent)
    
    // Agent components
    axi4_master_driver    driver;
    axi4_master_monitor   monitor;
    axi4_master_sequencer sequencer;
    
    // Configuration
    axi4_config config_obj;
    
    // Virtual interface
    virtual axi4_interface vif;
    
    function new(string name = "axi4_master_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(axi4_config)::get(this, "", "config", config_obj)) begin
            `uvm_fatal("AXI4_MASTER_AGENT", "Failed to get config object")
        end
        
        // Get virtual interface
        if (!uvm_config_db#(virtual axi4_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("AXI4_MASTER_AGENT", "Failed to get virtual interface")
        end
        
        // Build monitor (always built)
        monitor = axi4_master_monitor::type_id::create("monitor", this);
        
        // Build driver and sequencer only if agent is active
        if (get_is_active() == UVM_ACTIVE) begin
            driver = axi4_master_driver::type_id::create("driver", this);
            sequencer = axi4_master_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect monitor
        monitor.vif = vif;
        monitor.config_obj = config_obj;
        
        // Connect driver and sequencer if active
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            driver.vif = vif;
            driver.config_obj = config_obj;
        end
    endfunction
    
    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("AXI4_MASTER_AGENT", "AXI4 Master Agent started", UVM_LOW)
    endfunction
    
endclass

`endif // AXI4_MASTER_AGENT_SV
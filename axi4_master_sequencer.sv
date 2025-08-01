// AXI4 Master Sequencer
// This file contains the sequencer implementation for AXI4 master

`ifndef AXI4_MASTER_SEQUENCER_SV
`define AXI4_MASTER_SEQUENCER_SV

class axi4_master_sequencer extends uvm_sequencer #(axi4_transaction);
    `uvm_component_utils(axi4_master_sequencer)
    
    // Configuration
    axi4_config config_obj;
    
    // Statistics
    int unsigned sequence_count = 0;
    int unsigned transaction_count = 0;
    
    function new(string name = "axi4_master_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(axi4_config)::get(this, "", "config", config_obj)) begin
            `uvm_fatal("AXI4_MASTER_SEQUENCER", "Failed to get config object")
        end
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI4_MASTER_SEQUENCER", $sformatf("Sequencer Report:\n  Sequences executed: %0d\n  Transactions generated: %0d", 
                   sequence_count, transaction_count), UVM_LOW)
    endfunction
    
endclass

`endif // AXI4_MASTER_SEQUENCER_SV
// AXI4 Master Driver
// This file contains the driver implementation for AXI4 master

`ifndef AXI4_MASTER_DRIVER_SV
`define AXI4_MASTER_DRIVER_SV

class axi4_master_driver extends uvm_driver #(axi4_transaction);
    `uvm_component_utils(axi4_master_driver)
    
    // Virtual interface
    virtual axi4_interface vif;
    
    // Configuration
    axi4_config config_obj;
    
    // Analysis port for coverage
    uvm_analysis_port #(axi4_transaction) ap;
    
    // Internal state
    bit [3:0] current_id = 0;
    int unsigned transaction_count = 0;
    
    function new(string name = "axi4_master_driver", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    task run_phase(uvm_phase phase);
        // Initialize interface signals
        initialize_signals();
        
        // Wait for reset to complete
        wait_for_reset();
        
        forever begin
            // Get transaction from sequencer
            seq_item_port.get_next_item(req);
            
            // Drive the transaction
            drive_transaction(req);
            
            // Send transaction to analysis port
            ap.write(req);
            
            // Report completion
            `uvm_info("AXI4_MASTER_DRIVER", $sformatf("Completed transaction %0d", transaction_count), UVM_MEDIUM)
            transaction_count++;
            
            // Return transaction to sequencer
            seq_item_port.item_done();
        end
    endtask
    
    task initialize_signals();
        // Initialize all signals to safe values
        vif.master_cb.awid <= 0;
        vif.master_cb.awaddr <= 0;
        vif.master_cb.awlen <= 0;
        vif.master_cb.awsize <= 0;
        vif.master_cb.awburst <= 0;
        vif.master_cb.awlock <= 0;
        vif.master_cb.awcache <= 0;
        vif.master_cb.awprot <= 0;
        vif.master_cb.awqos <= 0;
        vif.master_cb.awregion <= 0;
        vif.master_cb.awuser <= 0;
        vif.master_cb.awvalid <= 0;
        
        vif.master_cb.wdata <= 0;
        vif.master_cb.wstrb <= 0;
        vif.master_cb.wlast <= 0;
        vif.master_cb.wuser <= 0;
        vif.master_cb.wvalid <= 0;
        
        vif.master_cb.bready <= 1;
        
        vif.master_cb.arid <= 0;
        vif.master_cb.araddr <= 0;
        vif.master_cb.arlen <= 0;
        vif.master_cb.arsize <= 0;
        vif.master_cb.arburst <= 0;
        vif.master_cb.arlock <= 0;
        vif.master_cb.arcache <= 0;
        vif.master_cb.arprot <= 0;
        vif.master_cb.arqos <= 0;
        vif.master_cb.arregion <= 0;
        vif.master_cb.aruser <= 0;
        vif.master_cb.arvalid <= 0;
        
        vif.master_cb.rready <= 1;
    endtask
    
    task wait_for_reset();
        // Wait for reset to be deasserted
        @(posedge vif.aclk);
        while (vif.aresetn == 0) begin
            @(posedge vif.aclk);
        end
        `uvm_info("AXI4_MASTER_DRIVER", "Reset deasserted, starting to drive", UVM_LOW)
    endtask
    
    task drive_transaction(axi4_transaction trans);
        case (trans.trans_type)
            READ:  drive_read_transaction(trans);
            WRITE: drive_write_transaction(trans);
            default: `uvm_error("AXI4_MASTER_DRIVER", "Unknown transaction type")
        endcase
    endtask
    
    task drive_read_transaction(axi4_transaction trans);
        // Drive read address channel
        drive_read_address(trans);
        
        // Wait for read response
        wait_for_read_response(trans);
    endtask
    
    task drive_write_transaction(axi4_transaction trans);
        // Drive write address channel
        drive_write_address(trans);
        
        // Drive write data channel
        drive_write_data(trans);
        
        // Wait for write response
        wait_for_write_response(trans);
    endtask
    
    task drive_read_address(axi4_transaction trans);
        // Apply delay if specified
        if (trans.delay > 0) begin
            repeat (trans.delay) @(posedge vif.aclk);
        end
        
        // Drive address channel signals
        vif.master_cb.arid <= trans.id;
        vif.master_cb.araddr <= trans.addr;
        vif.master_cb.arlen <= trans.len;
        vif.master_cb.arsize <= trans.size;
        vif.master_cb.arburst <= trans.burst;
        vif.master_cb.arlock <= trans.lock;
        vif.master_cb.arcache <= trans.cache;
        vif.master_cb.arprot <= trans.prot;
        vif.master_cb.arqos <= trans.qos;
        vif.master_cb.arregion <= trans.region;
        vif.master_cb.aruser <= trans.user;
        vif.master_cb.arvalid <= 1;
        
        // Wait for arready
        do begin
            @(posedge vif.aclk);
        end while (vif.master_cb.arready != 1);
        
        // Clear arvalid
        vif.master_cb.arvalid <= 0;
        
        `uvm_info("AXI4_MASTER_DRIVER", $sformatf("Read address driven: addr=0x%08x, len=%0d", trans.addr, trans.len), UVM_HIGH)
    endtask
    
    task drive_write_address(axi4_transaction trans);
        // Apply delay if specified
        if (trans.delay > 0) begin
            repeat (trans.delay) @(posedge vif.aclk);
        end
        
        // Drive address channel signals
        vif.master_cb.awid <= trans.id;
        vif.master_cb.awaddr <= trans.addr;
        vif.master_cb.awlen <= trans.len;
        vif.master_cb.awsize <= trans.size;
        vif.master_cb.awburst <= trans.burst;
        vif.master_cb.awlock <= trans.lock;
        vif.master_cb.awcache <= trans.cache;
        vif.master_cb.awprot <= trans.prot;
        vif.master_cb.awqos <= trans.qos;
        vif.master_cb.awregion <= trans.region;
        vif.master_cb.awuser <= trans.user;
        vif.master_cb.awvalid <= 1;
        
        // Wait for awready
        do begin
            @(posedge vif.aclk);
        end while (vif.master_cb.awready != 1);
        
        // Clear awvalid
        vif.master_cb.awvalid <= 0;
        
        `uvm_info("AXI4_MASTER_DRIVER", $sformatf("Write address driven: addr=0x%08x, len=%0d", trans.addr, trans.len), UVM_HIGH)
    endtask
    
    task drive_write_data(axi4_transaction trans);
        // Drive each beat of the burst
        for (int i = 0; i <= trans.len; i++) begin
            // Drive data signals
            vif.master_cb.wdata <= trans.data[i];
            vif.master_cb.wstrb <= trans.strb[i];
            vif.master_cb.wlast <= trans.last[i];
            vif.master_cb.wuser <= trans.user;
            vif.master_cb.wvalid <= 1;
            
            // Wait for wready
            do begin
                @(posedge vif.aclk);
            end while (vif.master_cb.wready != 1);
            
            // Clear wvalid after handshake
            vif.master_cb.wvalid <= 0;
            
            `uvm_info("AXI4_MASTER_DRIVER", $sformatf("Write data beat %0d: data=0x%016x, strb=0x%02x", i, trans.data[i], trans.strb[i]), UVM_HIGH)
        end
    endtask
    
    task wait_for_read_response(axi4_transaction trans);
        int beat_count = 0;
        
        // Wait for all beats of the burst
        while (beat_count <= trans.len) begin
            // Wait for rvalid
            do begin
                @(posedge vif.aclk);
            end while (vif.master_cb.rvalid != 1);
            
            // Check response
            if (vif.master_cb.rresp != OKAY) begin
                `uvm_warning("AXI4_MASTER_DRIVER", $sformatf("Read response error: %0d", vif.master_cb.rresp))
            end
            
            // Check if this is the last beat
            if (vif.master_cb.rlast == 1) begin
                beat_count = trans.len + 1;  // Exit loop
            end else begin
                beat_count++;
            end
            
            `uvm_info("AXI4_MASTER_DRIVER", $sformatf("Read response beat %0d: data=0x%016x, resp=%0d", beat_count-1, vif.master_cb.rdata, vif.master_cb.rresp), UVM_HIGH)
        end
    endtask
    
    task wait_for_write_response(axi4_transaction trans);
        // Wait for bvalid
        do begin
            @(posedge vif.aclk);
        end while (vif.master_cb.bvalid != 1);
        
        // Check response
        if (vif.master_cb.bresp != OKAY) begin
            `uvm_warning("AXI4_MASTER_DRIVER", $sformatf("Write response error: %0d", vif.master_cb.bresp))
        end
        
        `uvm_info("AXI4_MASTER_DRIVER", $sformatf("Write response: resp=%0d", vif.master_cb.bresp), UVM_HIGH)
    endtask
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI4_MASTER_DRIVER", $sformatf("Total transactions driven: %0d", transaction_count), UVM_LOW)
    endfunction
    
endclass

`endif // AXI4_MASTER_DRIVER_SV
// AXI4 Master Monitor
// This file contains the monitor implementation for AXI4 master

`ifndef AXI4_MASTER_MONITOR_SV
`define AXI4_MASTER_MONITOR_SV

class axi4_master_monitor extends uvm_monitor;
    `uvm_component_utils(axi4_master_monitor)
    
    // Virtual interface
    virtual axi4_interface vif;
    
    // Configuration
    axi4_config config_obj;
    
    // Analysis ports
    uvm_analysis_port #(axi4_transaction) ap;
    
    // Internal state
    int unsigned transaction_count = 0;
    int unsigned read_count = 0;
    int unsigned write_count = 0;
    
    // Coverage
    covergroup axi4_cov;
        // Address coverage
        ADDR_CP: coverpoint vif.awaddr {
            bins low_addr = {[0:32'h3FFF_FFFF]};
            bins mid_addr = {[32'h4000_0000:32'h7FFF_FFFF]};
            bins high_addr = {[32'h8000_0000:32'hFFFF_FFFF]};
        }
        
        // Burst length coverage
        LEN_CP: coverpoint vif.awlen {
            bins single = {0};
            bins small = {[1:7]};
            bins medium = {[8:15]};
            bins large = {[16:255]};
        }
        
        // Burst size coverage
        SIZE_CP: coverpoint vif.awsize {
            bins byte = {0};
            bins halfword = {1};
            bins word = {2};
            bins doubleword = {3};
            bins quadword = {4};
            bins octword = {5};
            bins hexword = {6};
        }
        
        // Burst type coverage
        BURST_CP: coverpoint vif.awburst {
            bins fixed = {0};
            bins incr = {1};
            bins wrap = {2};
        }
        
        // Response coverage
        RESP_CP: coverpoint vif.bresp {
            bins okay = {0};
            bins exokay = {1};
            bins slverr = {2};
            bins decerr = {3};
        }
        
        // Cross coverage
        ADDR_LEN_CROSS: cross ADDR_CP, LEN_CP;
        LEN_SIZE_CROSS: cross LEN_CP, SIZE_CP;
        BURST_SIZE_CROSS: cross BURST_CP, SIZE_CP;
    endgroup
    
    function new(string name = "axi4_master_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
        axi4_cov = new();
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    task run_phase(uvm_phase phase);
        // Wait for reset to complete
        wait_for_reset();
        
        // Start monitoring threads
        fork
            monitor_write_transactions();
            monitor_read_transactions();
        join
    endtask
    
    task wait_for_reset();
        // Wait for reset to be deasserted
        @(posedge vif.aclk);
        while (vif.aresetn == 0) begin
            @(posedge vif.aclk);
        end
        `uvm_info("AXI4_MASTER_MONITOR", "Reset deasserted, starting to monitor", UVM_LOW)
    endtask
    
    task monitor_write_transactions();
        axi4_transaction trans;
        
        forever begin
            // Wait for write address handshake
            wait_for_write_address_handshake();
            
            // Create transaction
            trans = axi4_transaction::type_id::create("write_trans");
            trans.set_trans_type(WRITE);
            
            // Capture write address information
            capture_write_address(trans);
            
            // Monitor write data beats
            monitor_write_data_beats(trans);
            
            // Wait for write response
            wait_for_write_response(trans);
            
            // Send transaction to analysis port
            ap.write(trans);
            
            // Update statistics
            write_count++;
            transaction_count++;
            
            `uvm_info("AXI4_MASTER_MONITOR", $sformatf("Monitored write transaction %0d", write_count), UVM_MEDIUM)
        end
    endtask
    
    task monitor_read_transactions();
        axi4_transaction trans;
        
        forever begin
            // Wait for read address handshake
            wait_for_read_address_handshake();
            
            // Create transaction
            trans = axi4_transaction::type_id::create("read_trans");
            trans.set_trans_type(READ);
            
            // Capture read address information
            capture_read_address(trans);
            
            // Monitor read data beats
            monitor_read_data_beats(trans);
            
            // Send transaction to analysis port
            ap.write(trans);
            
            // Update statistics
            read_count++;
            transaction_count++;
            
            `uvm_info("AXI4_MASTER_MONITOR", $sformatf("Monitored read transaction %0d", read_count), UVM_MEDIUM)
        end
    endtask
    
    task wait_for_write_address_handshake();
        // Wait for awvalid and awready both high
        do begin
            @(posedge vif.aclk);
        end while (!(vif.awvalid && vif.awready));
    endtask
    
    task wait_for_read_address_handshake();
        // Wait for arvalid and arready both high
        do begin
            @(posedge vif.aclk);
        end while (!(vif.arvalid && vif.arready));
    endtask
    
    task capture_write_address(axi4_transaction trans);
        // Capture address channel signals
        trans.set_addr(vif.awaddr);
        trans.set_id(vif.awid);
        trans.set_burst_length(vif.awlen);
        trans.set_burst_size(vif.awsize);
        trans.set_burst_type(axi4_burst_t'(vif.awburst));
        trans.lock = vif.awlock;
        trans.cache = vif.awcache;
        trans.prot = vif.awprot;
        trans.qos = vif.awqos;
        trans.region = vif.awregion;
        trans.user = vif.awuser;
    endtask
    
    task capture_read_address(axi4_transaction trans);
        // Capture address channel signals
        trans.set_addr(vif.araddr);
        trans.set_id(vif.arid);
        trans.set_burst_length(vif.arlen);
        trans.set_burst_size(vif.arsize);
        trans.set_burst_type(axi4_burst_t'(vif.arburst));
        trans.lock = vif.arlock;
        trans.cache = vif.arcache;
        trans.prot = vif.arprot;
        trans.qos = vif.arqos;
        trans.region = vif.arregion;
        trans.user = vif.aruser;
    endtask
    
    task monitor_write_data_beats(axi4_transaction trans);
        int beat_count = 0;
        bit [63:0] data_array[];
        bit [7:0]  strb_array[];
        bit        last_array[];
        
        // Allocate arrays
        data_array = new[trans.len + 1];
        strb_array = new[trans.len + 1];
        last_array = new[trans.len + 1];
        
        // Monitor each beat
        while (beat_count <= trans.len) begin
            // Wait for write data handshake
            do begin
                @(posedge vif.aclk);
            end while (!(vif.wvalid && vif.wready));
            
            // Capture data
            data_array[beat_count] = vif.wdata;
            strb_array[beat_count] = vif.wstrb;
            last_array[beat_count] = vif.wlast;
            
            `uvm_info("AXI4_MASTER_MONITOR", $sformatf("Write data beat %0d: data=0x%016x, strb=0x%02x, last=%0b", 
                       beat_count, vif.wdata, vif.wstrb, vif.wlast), UVM_HIGH)
            
            beat_count++;
        end
        
        // Set data in transaction
        trans.set_data(data_array);
        trans.set_strb(strb_array);
        foreach (last_array[i]) begin
            trans.last[i] = last_array[i];
        end
    endtask
    
    task monitor_read_data_beats(axi4_transaction trans);
        int beat_count = 0;
        bit [63:0] data_array[];
        bit [1:0]  resp_array[];
        bit        last_array[];
        
        // Allocate arrays
        data_array = new[trans.len + 1];
        resp_array = new[trans.len + 1];
        last_array = new[trans.len + 1];
        
        // Monitor each beat
        while (beat_count <= trans.len) begin
            // Wait for read data handshake
            do begin
                @(posedge vif.aclk);
            end while (!(vif.rvalid && vif.rready));
            
            // Capture data
            data_array[beat_count] = vif.rdata;
            resp_array[beat_count] = vif.rresp;
            last_array[beat_count] = vif.rlast;
            
            `uvm_info("AXI4_MASTER_MONITOR", $sformatf("Read data beat %0d: data=0x%016x, resp=%0d, last=%0b", 
                       beat_count, vif.rdata, vif.rresp, vif.rlast), UVM_HIGH)
            
            beat_count++;
        end
        
        // Set data in transaction
        trans.set_data(data_array);
        foreach (resp_array[i]) begin
            trans.resp = axi4_resp_t'(resp_array[i]);
        end
        foreach (last_array[i]) begin
            trans.last[i] = last_array[i];
        end
    endtask
    
    task wait_for_write_response(axi4_transaction trans);
        // Wait for write response handshake
        do begin
            @(posedge vif.aclk);
        end while (!(vif.bvalid && vif.bready));
        
        // Capture response
        trans.set_response(axi4_resp_t'(vif.bresp));
        trans.resp_id = vif.bid;
        
        `uvm_info("AXI4_MASTER_MONITOR", $sformatf("Write response: resp=%0d, id=%0d", vif.bresp, vif.bid), UVM_HIGH)
        
        // Sample coverage
        axi4_cov.sample();
    endtask
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI4_MASTER_MONITOR", $sformatf("Monitoring Report:\n  Total transactions: %0d\n  Read transactions: %0d\n  Write transactions: %0d", 
                   transaction_count, read_count, write_count), UVM_LOW)
    endfunction
    
endclass

`endif // AXI4_MASTER_MONITOR_SV
// AXI4 Master Agent
`include "axi4_if.sv"
`include "axi4_transaction.sv"

import axi4_transaction_pkg::*;

class axi4_master_agent #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
);

    // Virtual interface
    virtual axi4_if.master vif;
    
    // Configuration
    axi4_master_config_t config;
    
    // Components
    axi4_master_driver_t driver;
    axi4_master_monitor_t monitor;
    axi4_master_sequencer_t sequencer;
    
    // Mailboxes for communication
    mailbox #(axi4_transaction_t) req_mbx;
    mailbox #(axi4_transaction_t) rsp_mbx;
    
    // Event for synchronization
    event transaction_complete;
    
    // Constructor
    function new(virtual axi4_if.master vif);
        this.vif = vif;
        this.config = new();
        this.req_mbx = new();
        this.rsp_mbx = new();
        
        // Create components
        this.driver = new(this.vif, this.req_mbx, this.rsp_mbx, this.transaction_complete);
        this.monitor = new(this.vif, this.rsp_mbx);
        this.sequencer = new(this.req_mbx);
    endfunction
    
    // Start all components
    task start();
        fork
            driver.run();
            monitor.run();
        join_none
    endtask
    
    // Stop all components
    task stop();
        driver.stop();
        monitor.stop();
    endtask
    
    // Send transaction
    task send_transaction(axi4_transaction_t trans);
        req_mbx.put(trans);
    endtask
    
    // Get response
    task get_response(output axi4_transaction_t trans);
        rsp_mbx.get(trans);
    endtask
    
    // Wait for transaction completion
    task wait_for_completion();
        @(transaction_complete);
    endtask

endclass

// AXI4 Master Configuration
class axi4_master_config_t;
    // Timing parameters
    int min_delay = 0;
    int max_delay = 10;
    
    // Protocol parameters
    bit enable_checks = 1;
    bit enable_coverage = 1;
    
    // Default values
    axi4_burst_t default_burst = AXI4_INCR;
    axi4_size_t  default_size  = AXI4_SIZE_8B;
    axi4_lock_t  default_lock  = AXI4_NORMAL;
    
    function new();
        // Initialize with default values
    endfunction
endclass

// AXI4 Master Driver
class axi4_master_driver_t #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
);

    virtual axi4_if.master vif;
    mailbox #(axi4_transaction_t) req_mbx;
    mailbox #(axi4_transaction_t) rsp_mbx;
    event transaction_complete;
    
    // Control
    bit running = 0;
    
    // Constructor
    function new(
        virtual axi4_if.master vif,
        mailbox #(axi4_transaction_t) req_mbx,
        mailbox #(axi4_transaction_t) rsp_mbx,
        event transaction_complete
    );
        this.vif = vif;
        this.req_mbx = req_mbx;
        this.rsp_mbx = rsp_mbx;
        this.transaction_complete = transaction_complete;
    endfunction
    
    // Main run task
    task run();
        running = 1;
        fork
            forever begin
                axi4_transaction_t trans;
                req_mbx.get(trans);
                drive_transaction(trans);
                rsp_mbx.put(trans);
                -> transaction_complete;
            end
        join_none
    endtask
    
    // Stop driver
    task stop();
        running = 0;
    endtask
    
    // Drive a single transaction
    task drive_transaction(axi4_transaction_t trans);
        if (trans.trans_type == AXI4_WRITE) begin
            drive_write_transaction(trans);
        end else begin
            drive_read_transaction(trans);
        end
    endtask
    
    // Drive write transaction
    task drive_write_transaction(axi4_transaction_t trans);
        // Drive write address channel
        drive_write_address(trans.write_addr);
        
        // Drive write data channel
        foreach (trans.write_data[i]) begin
            drive_write_data(trans.write_data[i]);
        end
        
        // Wait for write response
        drive_write_response(trans.write_resp);
    endtask
    
    // Drive read transaction
    task drive_read_transaction(axi4_transaction_t trans);
        // Drive read address channel
        drive_read_address(trans.read_addr);
        
        // Wait for read data
        foreach (trans.read_data[i]) begin
            drive_read_data(trans.read_data[i]);
        end
    endtask
    
    // Drive write address channel
    task drive_write_address(axi4_write_addr_t addr);
        // Wait for ready
        do @(vif.master_cb);
        while (!vif.master_cb.awready);
        
        // Drive address signals
        vif.master_cb.awid <= addr.id;
        vif.master_cb.awaddr <= addr.addr;
        vif.master_cb.awlen <= addr.len;
        vif.master_cb.awsize <= addr.size;
        vif.master_cb.awburst <= addr.burst;
        vif.master_cb.awlock <= addr.lock;
        vif.master_cb.awcache <= addr.cache;
        vif.master_cb.awprot <= addr.prot;
        vif.master_cb.awqos <= addr.qos;
        vif.master_cb.awregion <= addr.region;
        vif.master_cb.awuser <= addr.user;
        vif.master_cb.awvalid <= 1'b1;
        
        // Wait for handshake
        @(vif.master_cb);
        while (!vif.master_cb.awready) @(vif.master_cb);
        vif.master_cb.awvalid <= 1'b0;
    endtask
    
    // Drive write data channel
    task drive_write_data(axi4_write_data_t data);
        // Wait for ready
        do @(vif.master_cb);
        while (!vif.master_cb.wready);
        
        // Drive data signals
        vif.master_cb.wdata <= data.data;
        vif.master_cb.wstrb <= data.strb;
        vif.master_cb.wlast <= data.last;
        vif.master_cb.wuser <= data.user;
        vif.master_cb.wvalid <= 1'b1;
        
        // Wait for handshake
        @(vif.master_cb);
        while (!vif.master_cb.wready) @(vif.master_cb);
        vif.master_cb.wvalid <= 1'b0;
    endtask
    
    // Drive write response channel
    task drive_write_response(axi4_write_resp_t resp);
        // Wait for valid response
        do @(vif.master_cb);
        while (!vif.master_cb.bvalid);
        
        // Capture response
        resp.id = vif.master_cb.bid;
        resp.resp = axi4_resp_t'(vif.master_cb.bresp);
        resp.user = vif.master_cb.buser;
        
        // Drive ready
        vif.master_cb.bready <= 1'b1;
        @(vif.master_cb);
        vif.master_cb.bready <= 1'b0;
    endtask
    
    // Drive read address channel
    task drive_read_address(axi4_read_addr_t addr);
        // Wait for ready
        do @(vif.master_cb);
        while (!vif.master_cb.arready);
        
        // Drive address signals
        vif.master_cb.arid <= addr.id;
        vif.master_cb.araddr <= addr.addr;
        vif.master_cb.arlen <= addr.len;
        vif.master_cb.arsize <= addr.size;
        vif.master_cb.arburst <= addr.burst;
        vif.master_cb.arlock <= addr.lock;
        vif.master_cb.arcache <= addr.cache;
        vif.master_cb.arprot <= addr.prot;
        vif.master_cb.arqos <= addr.qos;
        vif.master_cb.arregion <= addr.region;
        vif.master_cb.aruser <= addr.user;
        vif.master_cb.arvalid <= 1'b1;
        
        // Wait for handshake
        @(vif.master_cb);
        while (!vif.master_cb.arready) @(vif.master_cb);
        vif.master_cb.arvalid <= 1'b0;
    endtask
    
    // Drive read data channel
    task drive_read_data(axi4_read_data_t data);
        // Wait for valid data
        do @(vif.master_cb);
        while (!vif.master_cb.rvalid);
        
        // Capture data
        data.id = vif.master_cb.rid;
        data.data = vif.master_cb.rdata;
        data.resp = axi4_resp_t'(vif.master_cb.rresp);
        data.last = vif.master_cb.rlast;
        data.user = vif.master_cb.ruser;
        
        // Drive ready
        vif.master_cb.rready <= 1'b1;
        @(vif.master_cb);
        vif.master_cb.rready <= 1'b0;
    endtask

endclass

// AXI4 Master Monitor
class axi4_master_monitor_t #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
);

    virtual axi4_if.master vif;
    mailbox #(axi4_transaction_t) rsp_mbx;
    
    // Control
    bit running = 0;
    
    // Constructor
    function new(virtual axi4_if.master vif, mailbox #(axi4_transaction_t) rsp_mbx);
        this.vif = vif;
        this.rsp_mbx = rsp_mbx;
    endfunction
    
    // Main run task
    task run();
        running = 1;
        fork
            monitor_write_channel();
            monitor_read_channel();
        join_none
    endtask
    
    // Stop monitor
    task stop();
        running = 0;
    endtask
    
    // Monitor write channel
    task monitor_write_channel();
        forever begin
            @(posedge vif.aclk);
            if (vif.awvalid && vif.awready) begin
                $display("Monitor: Write address handshake detected");
                // Add monitoring logic here
            end
            if (vif.wvalid && vif.wready) begin
                $display("Monitor: Write data handshake detected");
                // Add monitoring logic here
            end
            if (vif.bvalid && vif.bready) begin
                $display("Monitor: Write response handshake detected");
                // Add monitoring logic here
            end
        end
    endtask
    
    // Monitor read channel
    task monitor_read_channel();
        forever begin
            @(posedge vif.aclk);
            if (vif.arvalid && vif.arready) begin
                $display("Monitor: Read address handshake detected");
                // Add monitoring logic here
            end
            if (vif.rvalid && vif.rready) begin
                $display("Monitor: Read data handshake detected");
                // Add monitoring logic here
            end
        end
    endtask

endclass

// AXI4 Master Sequencer
class axi4_master_sequencer_t;

    mailbox #(axi4_transaction_t) req_mbx;
    
    // Constructor
    function new(mailbox #(axi4_transaction_t) req_mbx);
        this.req_mbx = req_mbx;
    endfunction
    
    // Send transaction
    task send_transaction(axi4_transaction_t trans);
        req_mbx.put(trans);
    endtask

endclass
// AXI4 Master Agent Test
`include "../inc/axi4_if.sv"
`include "../inc/axi4_transaction.sv"
`include "../rtl/axi4_master_agent.sv"

import axi4_transaction_pkg::*;

module axi4_master_test;

    // Clock and reset
    logic aclk = 0;
    logic aresetn = 0;
    
    // AXI4 interface
    axi4_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(64),
        .ID_WIDTH(4),
        .USER_WIDTH(1)
    ) axi4_if_inst(
        .aclk(aclk),
        .aresetn(aresetn)
    );
    
    // AXI4 Master Agent
    axi4_master_agent #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(64),
        .ID_WIDTH(4),
        .USER_WIDTH(1)
    ) master_agent;
    
    // Clock generation
    always #5 aclk = ~aclk;
    
    // Test stimulus
    initial begin
        // Initialize
        master_agent = new(axi4_if_inst.master);
        
        // Reset
        aresetn = 0;
        #100;
        aresetn = 1;
        #50;
        
        // Start agent
        master_agent.start();
        
        // Test write transaction
        test_write_transaction();
        
        // Test read transaction
        test_read_transaction();
        
        // Wait for completion
        #1000;
        
        // Stop agent
        master_agent.stop();
        
        $display("Test completed successfully!");
        $finish;
    end
    
    // Test write transaction
    task test_write_transaction();
        axi4_transaction_t trans;
        
        // Create write transaction
        trans = new();
        trans.trans_type = AXI4_WRITE;
        
        // Configure write address
        trans.write_addr.id = 4'h1;
        trans.write_addr.addr = 32'h1000_0000;
        trans.write_addr.len = 8'h3;  // 4 beats
        trans.write_addr.size = AXI4_SIZE_8B;
        trans.write_addr.burst = AXI4_INCR;
        trans.write_addr.lock = AXI4_NORMAL;
        trans.write_addr.cache = 4'b0010;
        trans.write_addr.prot = 3'b000;
        trans.write_addr.qos = 0;
        trans.write_addr.region = 0;
        trans.write_addr.user = 0;
        
        // Configure write data
        trans.write_data = new[4];
        for (int i = 0; i < 4; i++) begin
            trans.write_data[i] = new();
            trans.write_data[i].data = 64'h1234_5678_9ABC_DEF0 + i;
            trans.write_data[i].strb = 8'hFF;
            trans.write_data[i].last = (i == 3);
            trans.write_data[i].user = 0;
        end
        
        // Configure write response
        trans.write_resp = new();
        
        $display("Sending write transaction...");
        trans.display("  ");
        
        // Send transaction
        master_agent.send_transaction(trans);
        
        // Wait for completion
        master_agent.wait_for_completion();
        
        // Get response
        master_agent.get_response(trans);
        
        $display("Write transaction completed!");
        trans.display("  ");
    endtask
    
    // Test read transaction
    task test_read_transaction();
        axi4_transaction_t trans;
        
        // Create read transaction
        trans = new();
        trans.trans_type = AXI4_READ;
        
        // Configure read address
        trans.read_addr.id = 4'h2;
        trans.read_addr.addr = 32'h2000_0000;
        trans.read_addr.len = 8'h2;  // 3 beats
        trans.read_addr.size = AXI4_SIZE_8B;
        trans.read_addr.burst = AXI4_INCR;
        trans.read_addr.lock = AXI4_NORMAL;
        trans.read_addr.cache = 4'b0010;
        trans.read_addr.prot = 3'b000;
        trans.read_addr.qos = 0;
        trans.read_addr.region = 0;
        trans.read_addr.user = 0;
        
        // Configure read data array
        trans.read_data = new[3];
        for (int i = 0; i < 3; i++) begin
            trans.read_data[i] = new();
        end
        
        $display("Sending read transaction...");
        trans.display("  ");
        
        // Send transaction
        master_agent.send_transaction(trans);
        
        // Wait for completion
        master_agent.wait_for_completion();
        
        // Get response
        master_agent.get_response(trans);
        
        $display("Read transaction completed!");
        trans.display("  ");
    endtask
    
    // Simple AXI4 slave for testing
    always @(posedge aclk) begin
        if (!aresetn) begin
            // Reset all signals
            axi4_if_inst.awready <= 1'b0;
            axi4_if_inst.wready <= 1'b0;
            axi4_if_inst.bid <= 4'h0;
            axi4_if_inst.bresp <= 2'b00;
            axi4_if_inst.buser <= 1'b0;
            axi4_if_inst.bvalid <= 1'b0;
            axi4_if_inst.arready <= 1'b0;
            axi4_if_inst.rid <= 4'h0;
            axi4_if_inst.rdata <= 64'h0;
            axi4_if_inst.rresp <= 2'b00;
            axi4_if_inst.rlast <= 1'b0;
            axi4_if_inst.ruser <= 1'b0;
            axi4_if_inst.rvalid <= 1'b0;
        end else begin
            // Simple slave behavior
            axi4_if_inst.awready <= 1'b1;
            axi4_if_inst.wready <= 1'b1;
            axi4_if_inst.arready <= 1'b1;
            
            // Write response
            if (axi4_if_inst.awvalid && axi4_if_inst.awready) begin
                axi4_if_inst.bid <= axi4_if_inst.awid;
                axi4_if_inst.bresp <= 2'b00; // OKAY
                axi4_if_inst.buser <= axi4_if_inst.awuser;
                axi4_if_inst.bvalid <= 1'b1;
            end else if (axi4_if_inst.bvalid && axi4_if_inst.bready) begin
                axi4_if_inst.bvalid <= 1'b0;
            end
            
            // Read data
            if (axi4_if_inst.arvalid && axi4_if_inst.arready) begin
                axi4_if_inst.rid <= axi4_if_inst.arid;
                axi4_if_inst.rdata <= 64'hDEAD_BEEF_CAFE_BABE;
                axi4_if_inst.rresp <= 2'b00; // OKAY
                axi4_if_inst.rlast <= 1'b1;
                axi4_if_inst.ruser <= axi4_if_inst.aruser;
                axi4_if_inst.rvalid <= 1'b1;
            end else if (axi4_if_inst.rvalid && axi4_if_inst.rready) begin
                axi4_if_inst.rvalid <= 1'b0;
                axi4_if_inst.rlast <= 1'b0;
            end
        end
    end

endmodule
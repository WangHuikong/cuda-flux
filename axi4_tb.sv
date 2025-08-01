// AXI4 Testbench
// This file contains the complete testbench for AXI4 testing

`ifndef AXI4_TB_SV
`define AXI4_TB_SV

module axi4_tb;
    
    // Clock and reset
    logic aclk;
    logic aresetn;
    
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
    
    // AXI4 interface instantiation
    axi4_interface #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(64),
        .ID_WIDTH(4),
        .USER_WIDTH(1)
    ) axi4_if (
        .aclk(aclk),
        .aresetn(aresetn)
    );
    
    // AXI4 slave instantiation
    axi4_slave #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(64),
        .ID_WIDTH(4),
        .USER_WIDTH(1)
    ) slave_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        
        // Write Address Channel
        .awid(axi4_if.awid),
        .awaddr(axi4_if.awaddr),
        .awlen(axi4_if.awlen),
        .awsize(axi4_if.awsize),
        .awburst(axi4_if.awburst),
        .awlock(axi4_if.awlock),
        .awcache(axi4_if.awcache),
        .awprot(axi4_if.awprot),
        .awqos(axi4_if.awqos),
        .awregion(axi4_if.awregion),
        .awuser(axi4_if.awuser),
        .awvalid(axi4_if.awvalid),
        .awready(axi4_if.awready),
        
        // Write Data Channel
        .wdata(axi4_if.wdata),
        .wstrb(axi4_if.wstrb),
        .wlast(axi4_if.wlast),
        .wuser(axi4_if.wuser),
        .wvalid(axi4_if.wvalid),
        .wready(axi4_if.wready),
        
        // Write Response Channel
        .bid(axi4_if.bid),
        .bresp(axi4_if.bresp),
        .buser(axi4_if.buser),
        .bvalid(axi4_if.bvalid),
        .bready(axi4_if.bready),
        
        // Read Address Channel
        .arid(axi4_if.arid),
        .araddr(axi4_if.araddr),
        .arlen(axi4_if.arlen),
        .arsize(axi4_if.arsize),
        .arburst(axi4_if.arburst),
        .arlock(axi4_if.arlock),
        .arcache(axi4_if.arcache),
        .arprot(axi4_if.arprot),
        .arqos(axi4_if.arqos),
        .arregion(axi4_if.arregion),
        .aruser(axi4_if.aruser),
        .arvalid(axi4_if.arvalid),
        .arready(axi4_if.arready),
        
        // Read Data Channel
        .rid(axi4_if.rid),
        .rdata(axi4_if.rdata),
        .rresp(axi4_if.rresp),
        .rlast(axi4_if.rlast),
        .ruser(axi4_if.ruser),
        .rvalid(axi4_if.rvalid),
        .rready(axi4_if.rready)
    );
    
    // UVM test instantiation
    axi4_test test_inst;
    
    // UVM initialization
    initial begin
        // Set virtual interface in config database
        uvm_config_db#(virtual axi4_interface)::set(null, "*", "vif", axi4_if);
        
        // Run test
        run_test();
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("axi4_tb.vcd");
        $dumpvars(0, axi4_tb);
    end
    
    // Monitor for basic protocol checking
    always @(posedge aclk) begin
        // Check for valid handshake signals
        if (axi4_if.awvalid && axi4_if.awready) begin
            $display("Write Address Handshake: addr=0x%08x, len=%0d, size=%0d, burst=%0d", 
                     axi4_if.awaddr, axi4_if.awlen, axi4_if.awsize, axi4_if.awburst);
        end
        
        if (axi4_if.wvalid && axi4_if.wready) begin
            $display("Write Data Handshake: data=0x%016x, strb=0x%02x, last=%0b", 
                     axi4_if.wdata, axi4_if.wstrb, axi4_if.wlast);
        end
        
        if (axi4_if.bvalid && axi4_if.bready) begin
            $display("Write Response: resp=%0d, id=%0d", axi4_if.bresp, axi4_if.bid);
        end
        
        if (axi4_if.arvalid && axi4_if.arready) begin
            $display("Read Address Handshake: addr=0x%08x, len=%0d, size=%0d, burst=%0d", 
                     axi4_if.araddr, axi4_if.arlen, axi4_if.arsize, axi4_if.arburst);
        end
        
        if (axi4_if.rvalid && axi4_if.rready) begin
            $display("Read Data Handshake: data=0x%016x, resp=%0d, last=%0b, id=%0d", 
                     axi4_if.rdata, axi4_if.rresp, axi4_if.rlast, axi4_if.rid);
        end
    end
    
    // Timeout
    initial begin
        #10000;  // 10us timeout
        $display("Simulation timeout reached");
        $finish;
    end
    
    // End simulation when test completes
    final begin
        $display("AXI4 Testbench completed");
    end
    
endmodule

`endif // AXI4_TB_SV
// AXI4 Interface Definition
// This file contains the AXI4 interface with all required signals

`ifndef AXI4_INTERFACE_SV
`define AXI4_INTERFACE_SV

interface axi4_interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter ID_WIDTH   = 4,
    parameter USER_WIDTH = 1
) (
    input logic aclk,
    input logic aresetn
);
    
    // Write Address Channel (AW)
    logic [ID_WIDTH-1:0]     awid;
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic [7:0]              awlen;
    logic [2:0]              awsize;
    logic [1:0]              awburst;
    logic                    awlock;
    logic [3:0]              awcache;
    logic [2:0]              awprot;
    logic [3:0]              awqos;
    logic [3:0]              awregion;
    logic [USER_WIDTH-1:0]   awuser;
    logic                    awvalid;
    logic                    awready;
    
    // Write Data Channel (W)
    logic [DATA_WIDTH-1:0]   wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic                    wlast;
    logic [USER_WIDTH-1:0]   wuser;
    logic                    wvalid;
    logic                    wready;
    
    // Write Response Channel (B)
    logic [ID_WIDTH-1:0]     bid;
    logic [1:0]              bresp;
    logic [USER_WIDTH-1:0]   buser;
    logic                    bvalid;
    logic                    bready;
    
    // Read Address Channel (AR)
    logic [ID_WIDTH-1:0]     arid;
    logic [ADDR_WIDTH-1:0]   araddr;
    logic [7:0]              arlen;
    logic [2:0]              arsize;
    logic [1:0]              arburst;
    logic                    arlock;
    logic [3:0]              arcache;
    logic [2:0]              arprot;
    logic [3:0]              arqos;
    logic [3:0]              arregion;
    logic [USER_WIDTH-1:0]   aruser;
    logic                    arvalid;
    logic                    arready;
    
    // Read Data Channel (R)
    logic [ID_WIDTH-1:0]     rid;
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;
    logic                    rlast;
    logic [USER_WIDTH-1:0]   ruser;
    logic                    rvalid;
    logic                    rready;
    
    // Clocking blocks for master and slave
    clocking master_cb @(posedge aclk);
        // Write Address
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid;
        input  awready;
        
        // Write Data
        output wdata, wstrb, wlast, wuser, wvalid;
        input  wready;
        
        // Write Response
        input  bid, bresp, buser, bvalid;
        output bready;
        
        // Read Address
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid;
        input  arready;
        
        // Read Data
        input  rid, rdata, rresp, rlast, ruser, rvalid;
        output rready;
    endclocking
    
    clocking slave_cb @(posedge aclk);
        // Write Address
        input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid;
        output awready;
        
        // Write Data
        input  wdata, wstrb, wlast, wuser, wvalid;
        output wready;
        
        // Write Response
        output bid, bresp, buser, bvalid;
        input  bready;
        
        // Read Address
        input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid;
        output arready;
        
        // Read Data
        output rid, rdata, rresp, rlast, ruser, rvalid;
        input  rready;
    endclocking
    
    // Modport for master
    modport master(
        clocking master_cb,
        input aclk, aresetn
    );
    
    // Modport for slave
    modport slave(
        clocking slave_cb,
        input aclk, aresetn
    );
    
    // Modport for monitor (no clocking block)
    modport monitor(
        input aclk, aresetn,
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid, awready,
        input wdata, wstrb, wlast, wuser, wvalid, wready,
        input bid, bresp, buser, bvalid, bready,
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid, arready,
        input rid, rdata, rresp, rlast, ruser, rvalid, rready
    );
    
endinterface

`endif // AXI4_INTERFACE_SV
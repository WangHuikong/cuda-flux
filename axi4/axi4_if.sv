package axi4_if_pkg;
  parameter int ADDR_WIDTH = 32;
  parameter int DATA_WIDTH = 32;
endpackage : axi4_if_pkg

`include "uvm_macros.svh"

interface axi4_if #(parameter int ADDR_WIDTH = 32,
                     parameter int DATA_WIDTH = 32)
  (input logic ACLK,
   input logic ARESETn);

  // Write address channel
  logic                 AWVALID;
  logic                 AWREADY;
  logic [ADDR_WIDTH-1:0] AWADDR;
  // Write data channel
  logic                 WVALID;
  logic                 WREADY;
  logic [DATA_WIDTH-1:0] WDATA;
  logic [DATA_WIDTH/8-1:0] WSTRB;
  // Write response channel
  logic                 BVALID;
  logic                 BREADY;
  logic [1:0]           BRESP;

  // Read address channel
  logic                 ARVALID;
  logic                 ARREADY;
  logic [ADDR_WIDTH-1:0] ARADDR;
  // Read data channel
  logic                 RVALID;
  logic                 RREADY;
  logic [DATA_WIDTH-1:0] RDATA;
  logic [1:0]           RRESP;

  // Master modport
  modport master (
    input  ARESETn,
    input  AWREADY,
    input  WREADY,
    input  BVALID,
    input  BRESP,
    input  ARREADY,
    input  RVALID,
    input  RDATA,
    input  RRESP,
    output AWVALID,
    output AWADDR,
    output WVALID,
    output WDATA,
    output WSTRB,
    output BREADY,
    output ARVALID,
    output ARADDR,
    output RREADY
  );

  // Slave modport (optional)
  modport slave (
    input  AWVALID,
    input  AWADDR,
    input  WVALID,
    input  WDATA,
    input  WSTRB,
    input  BREADY,
    input  ARVALID,
    input  ARADDR,
    input  RREADY,
    output AWREADY,
    output WREADY,
    output BVALID,
    output BRESP,
    output ARREADY,
    output RVALID,
    output RDATA,
    output RRESP
  );

endinterface : axi4_if
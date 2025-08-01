// AXI4 Slave Module
// This file contains a simple AXI4 slave implementation for testing

`ifndef AXI4_SLAVE_SV
`define AXI4_SLAVE_SV

module axi4_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter ID_WIDTH   = 4,
    parameter USER_WIDTH = 1
) (
    input logic aclk,
    input logic aresetn,
    
    // Write Address Channel
    input  logic [ID_WIDTH-1:0]     awid,
    input  logic [ADDR_WIDTH-1:0]   awaddr,
    input  logic [7:0]              awlen,
    input  logic [2:0]              awsize,
    input  logic [1:0]              awburst,
    input  logic                    awlock,
    input  logic [3:0]              awcache,
    input  logic [2:0]              awprot,
    input  logic [3:0]              awqos,
    input  logic [3:0]              awregion,
    input  logic [USER_WIDTH-1:0]   awuser,
    input  logic                    awvalid,
    output logic                    awready,
    
    // Write Data Channel
    input  logic [DATA_WIDTH-1:0]   wdata,
    input  logic [DATA_WIDTH/8-1:0] wstrb,
    input  logic                    wlast,
    input  logic [USER_WIDTH-1:0]   wuser,
    input  logic                    wvalid,
    output logic                    wready,
    
    // Write Response Channel
    output logic [ID_WIDTH-1:0]     bid,
    output logic [1:0]              bresp,
    output logic [USER_WIDTH-1:0]   buser,
    output logic                    bvalid,
    input  logic                    bready,
    
    // Read Address Channel
    input  logic [ID_WIDTH-1:0]     arid,
    input  logic [ADDR_WIDTH-1:0]   araddr,
    input  logic [7:0]              arlen,
    input  logic [2:0]              arsize,
    input  logic [1:0]              arburst,
    input  logic                    arlock,
    input  logic [3:0]              arcache,
    input  logic [2:0]              arprot,
    input  logic [3:0]              arqos,
    input  logic [3:0]              arregion,
    input  logic [USER_WIDTH-1:0]   aruser,
    input  logic                    arvalid,
    output logic                    arready,
    
    // Read Data Channel
    output logic [ID_WIDTH-1:0]     rid,
    output logic [DATA_WIDTH-1:0]   rdata,
    output logic [1:0]              rresp,
    output logic                    rlast,
    output logic [USER_WIDTH-1:0]   ruser,
    output logic                    rvalid,
    input  logic                    rready
);
    
    // Memory array for storing data
    logic [DATA_WIDTH-1:0] memory [0:1023];  // 1KB memory
    
    // Internal state
    logic [7:0] write_count;
    logic [7:0] read_count;
    logic [ID_WIDTH-1:0] current_write_id;
    logic [ID_WIDTH-1:0] current_read_id;
    logic [ADDR_WIDTH-1:0] current_write_addr;
    logic [ADDR_WIDTH-1:0] current_read_addr;
    logic [7:0] current_write_len;
    logic [7:0] current_read_len;
    logic [2:0] current_write_size;
    logic [2:0] current_read_size;
    logic [1:0] current_write_burst;
    logic [1:0] current_read_burst;
    
    // State machine states
    typedef enum {IDLE, WRITE_ADDR, WRITE_DATA, WRITE_RESP, READ_ADDR, READ_DATA} state_t;
    state_t state, next_state;
    
    // Ready signal generation
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready <= 1'b0;
            wready <= 1'b0;
            arready <= 1'b0;
        end else begin
            // Simple ready generation - can be made more sophisticated
            awready <= $urandom_range(0, 100) < 80;  // 80% ready probability
            wready <= $urandom_range(0, 100) < 80;   // 80% ready probability
            arready <= $urandom_range(0, 100) < 80;  // 80% ready probability
        end
    end
    
    // State machine
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            write_count <= 0;
            read_count <= 0;
            bvalid <= 0;
            rvalid <= 0;
            bid <= 0;
            rid <= 0;
            rdata <= 0;
            rresp <= 0;
            rlast <= 0;
            bresp <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    // Wait for address handshake
                    if (awvalid && awready) begin
                        current_write_id <= awid;
                        current_write_addr <= awaddr;
                        current_write_len <= awlen;
                        current_write_size <= awsize;
                        current_write_burst <= awburst;
                        write_count <= 0;
                        next_state <= WRITE_DATA;
                    end else if (arvalid && arready) begin
                        current_read_id <= arid;
                        current_read_addr <= araddr;
                        current_read_len <= arlen;
                        current_read_size <= arsize;
                        current_read_burst <= arburst;
                        read_count <= 0;
                        next_state <= READ_DATA;
                    end else begin
                        next_state <= IDLE;
                    end
                end
                
                WRITE_DATA: begin
                    if (wvalid && wready) begin
                        // Store data in memory
                        memory[current_write_addr >> 3] <= wdata;
                        
                        if (wlast) begin
                            next_state <= WRITE_RESP;
                        end else begin
                            write_count <= write_count + 1;
                            // Calculate next address based on burst type
                            case (current_write_burst)
                                2'b00: current_write_addr <= current_write_addr;  // FIXED
                                2'b01: current_write_addr <= current_write_addr + (1 << current_write_size);  // INCR
                                2'b10: current_write_addr <= wrap_address(current_write_addr, current_write_len, current_write_size);  // WRAP
                                default: current_write_addr <= current_write_addr + (1 << current_write_size);
                            endcase
                            next_state <= WRITE_DATA;
                        end
                    end else begin
                        next_state <= WRITE_DATA;
                    end
                end
                
                WRITE_RESP: begin
                    bid <= current_write_id;
                    bresp <= $urandom_range(0, 100) < 95 ? 2'b00 : 2'b10;  // 95% OKAY, 5% SLVERR
                    bvalid <= 1;
                    
                    if (bready) begin
                        bvalid <= 0;
                        next_state <= IDLE;
                    end else begin
                        next_state <= WRITE_RESP;
                    end
                end
                
                READ_DATA: begin
                    if (rready) begin
                        rid <= current_read_id;
                        rdata <= memory[current_read_addr >> 3];
                        rresp <= $urandom_range(0, 100) < 95 ? 2'b00 : 2'b10;  // 95% OKAY, 5% SLVERR
                        rlast <= (read_count == current_read_len);
                        rvalid <= 1;
                        
                        if (read_count == current_read_len) begin
                            next_state <= IDLE;
                            rvalid <= 0;
                        end else begin
                            read_count <= read_count + 1;
                            // Calculate next address based on burst type
                            case (current_read_burst)
                                2'b00: current_read_addr <= current_read_addr;  // FIXED
                                2'b01: current_read_addr <= current_read_addr + (1 << current_read_size);  // INCR
                                2'b10: current_read_addr <= wrap_address(current_read_addr, current_read_len, current_read_size);  // WRAP
                                default: current_read_addr <= current_read_addr + (1 << current_read_size);
                            endcase
                            next_state <= READ_DATA;
                        end
                    end else begin
                        next_state <= READ_DATA;
                    end
                end
                
                default: next_state <= IDLE;
            endcase
        end
    end
    
    // Function to calculate wrap address
    function automatic logic [ADDR_WIDTH-1:0] wrap_address(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [7:0] len,
        input logic [2:0] size
    );
        logic [ADDR_WIDTH-1:0] wrap_boundary;
        logic [ADDR_WIDTH-1:0] aligned_addr;
        logic [ADDR_WIDTH-1:0] wrap_addr;
        
        wrap_boundary = (len + 1) << size;
        aligned_addr = addr & ~((1 << size) - 1);
        wrap_addr = aligned_addr + ((addr + (1 << size)) & (wrap_boundary - 1));
        
        return wrap_addr;
    endfunction
    
    // Initialize memory with some data
    initial begin
        for (int i = 0; i < 1024; i++) begin
            memory[i] = i * 64'h0101010101010101;
        end
    end
    
endmodule

`endif // AXI4_SLAVE_SV
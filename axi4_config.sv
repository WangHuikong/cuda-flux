// AXI4 Configuration Class
// This file contains the configuration class for AXI4 interface

`ifndef AXI4_CONFIG_SV
`define AXI4_CONFIG_SV

class axi4_config extends uvm_object;
    `uvm_object_utils(axi4_config)
    
    // Interface parameters
    int unsigned ADDR_WIDTH = 32;
    int unsigned DATA_WIDTH = 64;
    int unsigned ID_WIDTH   = 4;
    int unsigned USER_WIDTH = 1;
    
    // Timing parameters
    int unsigned MIN_DELAY = 0;
    int unsigned MAX_DELAY = 10;
    
    // Burst parameters
    int unsigned MIN_BURST_LENGTH = 1;
    int unsigned MAX_BURST_LENGTH = 16;
    
    // Response probabilities
    real WRITE_RESP_OKAY_PCT = 90.0;    // 90% OKAY responses
    real WRITE_RESP_SLVERR_PCT = 8.0;   // 8% SLVERR responses
    real WRITE_RESP_DECERR_PCT = 2.0;   // 2% DECERR responses
    
    real READ_RESP_OKAY_PCT = 90.0;     // 90% OKAY responses
    real READ_RESP_SLVERR_PCT = 8.0;    // 8% SLVERR responses
    real READ_RESP_DECERR_PCT = 2.0;    // 2% DECERR responses
    
    // Ready signal probabilities
    real AWREADY_PROB = 80.0;           // 80% probability of awready being high
    real WREADY_PROB = 80.0;            // 80% probability of wready being high
    real BREADY_PROB = 80.0;            // 80% probability of bready being high
    real ARREADY_PROB = 80.0;           // 80% probability of arready being high
    real RREADY_PROB = 80.0;            // 80% probability of rready being high
    
    // Address range
    bit [31:0] MIN_ADDR = 32'h0000_0000;
    bit [31:0] MAX_ADDR = 32'hFFFF_FFFF;
    
    // Data patterns
    enum {RANDOM_DATA, INCREMENTAL_DATA, FIXED_DATA} data_pattern = RANDOM_DATA;
    bit [63:0] fixed_data = 64'hDEAD_BEEF_CAFE_BABE;
    
    // Burst types
    enum {FIXED, INCR, WRAP} burst_type = INCR;
    
    // Cache attributes
    bit [3:0] default_cache = 4'b0011;  // Cacheable, bufferable
    
    // Protection attributes
    bit [2:0] default_prot = 3'b000;    // Normal, secure, data
    
    // QoS attributes
    bit [3:0] default_qos = 4'b0000;    // No QoS
    
    // User attributes
    bit [0:0] default_user = 1'b0;      // No user attributes
    
    function new(string name = "axi4_config");
        super.new(name);
    endfunction
    
    function void set_addr_width(int unsigned width);
        ADDR_WIDTH = width;
    endfunction
    
    function void set_data_width(int unsigned width);
        DATA_WIDTH = width;
    endfunction
    
    function void set_id_width(int unsigned width);
        ID_WIDTH = width;
    endfunction
    
    function void set_user_width(int unsigned width);
        USER_WIDTH = width;
    endfunction
    
    function void set_timing(int unsigned min_delay, int unsigned max_delay);
        MIN_DELAY = min_delay;
        MAX_DELAY = max_delay;
    endfunction
    
    function void set_burst_length(int unsigned min_len, int unsigned max_len);
        MIN_BURST_LENGTH = min_len;
        MAX_BURST_LENGTH = max_len;
    endfunction
    
    function void set_response_probabilities(real write_okay, real write_slverr, real write_decerr,
                                          real read_okay, real read_slverr, real read_decerr);
        WRITE_RESP_OKAY_PCT = write_okay;
        WRITE_RESP_SLVERR_PCT = write_slverr;
        WRITE_RESP_DECERR_PCT = write_decerr;
        READ_RESP_OKAY_PCT = read_okay;
        READ_RESP_SLVERR_PCT = read_slverr;
        READ_RESP_DECERR_PCT = read_decerr;
    endfunction
    
    function void set_ready_probabilities(real awready, real wready, real bready, real arready, real rready);
        AWREADY_PROB = awready;
        WREADY_PROB = wready;
        BREADY_PROB = bready;
        ARREADY_PROB = arready;
        RREADY_PROB = rready;
    endfunction
    
    function void set_addr_range(bit [31:0] min_addr, bit [31:0] max_addr);
        MIN_ADDR = min_addr;
        MAX_ADDR = max_addr;
    endfunction
    
    function void set_data_pattern(enum {RANDOM_DATA, INCREMENTAL_DATA, FIXED_DATA} pattern);
        data_pattern = pattern;
    endfunction
    
    function void set_fixed_data(bit [63:0] data);
        fixed_data = data;
    endfunction
    
    function void set_burst_type(enum {FIXED, INCR, WRAP} burst);
        burst_type = burst;
    endfunction
    
    function void set_default_attributes(bit [3:0] cache, bit [2:0] prot, bit [3:0] qos, bit [0:0] user);
        default_cache = cache;
        default_prot = prot;
        default_qos = qos;
        default_user = user;
    endfunction
    
    function string convert2string();
        string s;
        s = $sformatf("AXI4 Config:\n");
        s = {s, $sformatf("  ADDR_WIDTH: %0d\n", ADDR_WIDTH)};
        s = {s, $sformatf("  DATA_WIDTH: %0d\n", DATA_WIDTH)};
        s = {s, $sformatf("  ID_WIDTH: %0d\n", ID_WIDTH)};
        s = {s, $sformatf("  USER_WIDTH: %0d\n", USER_WIDTH)};
        s = {s, $sformatf("  MIN_DELAY: %0d\n", MIN_DELAY)};
        s = {s, $sformatf("  MAX_DELAY: %0d\n", MAX_DELAY)};
        s = {s, $sformatf("  MIN_BURST_LENGTH: %0d\n", MIN_BURST_LENGTH)};
        s = {s, $sformatf("  MAX_BURST_LENGTH: %0d\n", MAX_BURST_LENGTH)};
        return s;
    endfunction
    
endclass

`endif // AXI4_CONFIG_SV
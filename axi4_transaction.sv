// AXI4 Transaction Class
// This class defines the transaction item for AXI4 operations

`ifndef AXI4_TRANSACTION_SV
`define AXI4_TRANSACTION_SV

// AXI4 Transaction Types
typedef enum {
    AXI4_READ,
    AXI4_WRITE
} axi4_trans_type_e;

// AXI4 Burst Types
typedef enum logic [1:0] {
    AXI4_BURST_FIXED = 2'b00,
    AXI4_BURST_INCR  = 2'b01,
    AXI4_BURST_WRAP  = 2'b10
} axi4_burst_type_e;

// AXI4 Response Types
typedef enum logic [1:0] {
    AXI4_RESP_OKAY   = 2'b00,
    AXI4_RESP_EXOKAY = 2'b01,
    AXI4_RESP_SLVERR = 2'b10,
    AXI4_RESP_DECERR = 2'b11
} axi4_resp_type_e;

// AXI4 Size Types
typedef enum logic [2:0] {
    AXI4_SIZE_1B   = 3'b000,
    AXI4_SIZE_2B   = 3'b001,
    AXI4_SIZE_4B   = 3'b010,
    AXI4_SIZE_8B   = 3'b011,
    AXI4_SIZE_16B  = 3'b100,
    AXI4_SIZE_32B  = 3'b101,
    AXI4_SIZE_64B  = 3'b110,
    AXI4_SIZE_128B = 3'b111
} axi4_size_type_e;

class axi4_transaction #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends uvm_sequence_item;

    // Transaction Type
    rand axi4_trans_type_e trans_type;

    // Address Channel
    rand logic [ID_WIDTH-1:0]     id;
    rand logic [ADDR_WIDTH-1:0]   addr;
    rand logic [7:0]              len;          // Number of transfers - 1
    rand axi4_size_type_e         size;         // Size of each transfer
    rand axi4_burst_type_e        burst;        // Burst type
    rand logic                    lock;         // Atomic access
    rand logic [3:0]              cache;        // Cache attributes
    rand logic [2:0]              prot;         // Protection attributes
    rand logic [3:0]              qos;          // Quality of Service
    rand logic [3:0]              region;       // Region identifier
    rand logic [USER_WIDTH-1:0]   user;         // User-defined attributes

    // Data Channel (for write transactions)
    rand logic [DATA_WIDTH-1:0]   data[];       // Write data array
    rand logic [DATA_WIDTH/8-1:0] strb[];       // Write strobe array
    rand logic [USER_WIDTH-1:0]   wuser[];      // Write user array

    // Response Channel
    axi4_resp_type_e              resp[];       // Response array
    logic [USER_WIDTH-1:0]        ruser[];      // Read user array (for read)
    logic [USER_WIDTH-1:0]        buser;        // Write response user (for write)

    // Timing control
    rand int unsigned addr_delay;    // Delay before address phase
    rand int unsigned data_delay[];  // Delay before each data beat
    rand int unsigned resp_delay;    // Delay before response ready

    // UVM Factory Registration
    `uvm_object_param_utils_begin(axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))
        `uvm_field_enum(axi4_trans_type_e, trans_type, UVM_ALL_ON)
        `uvm_field_int(id, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(len, UVM_ALL_ON)
        `uvm_field_enum(axi4_size_type_e, size, UVM_ALL_ON)
        `uvm_field_enum(axi4_burst_type_e, burst, UVM_ALL_ON)
        `uvm_field_int(lock, UVM_ALL_ON)
        `uvm_field_int(cache, UVM_ALL_ON)
        `uvm_field_int(prot, UVM_ALL_ON)
        `uvm_field_int(qos, UVM_ALL_ON)
        `uvm_field_int(region, UVM_ALL_ON)
        `uvm_field_int(user, UVM_ALL_ON)
        `uvm_field_array_int(data, UVM_ALL_ON)
        `uvm_field_array_int(strb, UVM_ALL_ON)
        `uvm_field_array_int(wuser, UVM_ALL_ON)
        `uvm_field_int(addr_delay, UVM_ALL_ON)
        `uvm_field_array_int(data_delay, UVM_ALL_ON)
        `uvm_field_int(resp_delay, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "axi4_transaction");
        super.new(name);
    endfunction

    // Post randomize function to allocate arrays based on len
    function void post_randomize();
        int num_beats = len + 1;
        
        // Allocate data arrays for write transactions
        if (trans_type == AXI4_WRITE) begin
            data = new[num_beats];
            strb = new[num_beats];
            wuser = new[num_beats];
            
            // Initialize data arrays with random values
            foreach (data[i]) begin
                data[i] = $urandom();
                strb[i] = $urandom();
                wuser[i] = $urandom();
            end
        end
        
        // Allocate response arrays
        resp = new[num_beats];
        if (trans_type == AXI4_READ) begin
            ruser = new[num_beats];
        end
        
        // Allocate delay arrays
        data_delay = new[num_beats];
        foreach (data_delay[i]) begin
            data_delay[i] = $urandom_range(0, 10);
        end
    endfunction

    // Constraints
    constraint c_valid_len {
        len inside {[0:255]};
    }

    constraint c_valid_size {
        size inside {AXI4_SIZE_1B, AXI4_SIZE_2B, AXI4_SIZE_4B, AXI4_SIZE_8B, 
                     AXI4_SIZE_16B, AXI4_SIZE_32B, AXI4_SIZE_64B, AXI4_SIZE_128B};
    }

    constraint c_valid_burst {
        burst inside {AXI4_BURST_FIXED, AXI4_BURST_INCR, AXI4_BURST_WRAP};
    }

    constraint c_addr_alignment {
        // Address should be aligned to the transfer size
        (size == AXI4_SIZE_1B)   -> (addr[0:0] == 0);
        (size == AXI4_SIZE_2B)   -> (addr[1:0] == 0);
        (size == AXI4_SIZE_4B)   -> (addr[2:0] == 0);
        (size == AXI4_SIZE_8B)   -> (addr[3:0] == 0);
        (size == AXI4_SIZE_16B)  -> (addr[4:0] == 0);
        (size == AXI4_SIZE_32B)  -> (addr[5:0] == 0);
        (size == AXI4_SIZE_64B)  -> (addr[6:0] == 0);
        (size == AXI4_SIZE_128B) -> (addr[7:0] == 0);
    }

    constraint c_wrap_burst {
        // For WRAP bursts, len must be 1, 3, 7, or 15
        (burst == AXI4_BURST_WRAP) -> (len inside {1, 3, 7, 15});
    }

    constraint c_reasonable_delays {
        addr_delay inside {[0:20]};
        resp_delay inside {[0:20]};
    }

    constraint c_default_values {
        lock == 0;
        cache == 4'b0000;
        prot == 3'b000;
        qos == 4'b0000;
        region == 4'b0000;
        user == 0;
    }

    // Utility functions
    function int get_transfer_size_bytes();
        case (size)
            AXI4_SIZE_1B:   return 1;
            AXI4_SIZE_2B:   return 2;
            AXI4_SIZE_4B:   return 4;
            AXI4_SIZE_8B:   return 8;
            AXI4_SIZE_16B:  return 16;
            AXI4_SIZE_32B:  return 32;
            AXI4_SIZE_64B:  return 64;
            AXI4_SIZE_128B: return 128;
            default:        return 1;
        endcase
    endfunction

    function int get_total_bytes();
        return (len + 1) * get_transfer_size_bytes();
    endfunction

    function logic [ADDR_WIDTH-1:0] get_wrap_boundary();
        int wrap_size = get_total_bytes();
        return (addr / wrap_size) * wrap_size;
    endfunction

    // Convert to string for debugging
    function string convert2string();
        string s;
        s = $sformatf("AXI4 Transaction:\n");
        s = {s, $sformatf("  Type: %s\n", trans_type.name())};
        s = {s, $sformatf("  ID: 0x%0h\n", id)};
        s = {s, $sformatf("  Addr: 0x%0h\n", addr)};
        s = {s, $sformatf("  Len: %0d\n", len)};
        s = {s, $sformatf("  Size: %s\n", size.name())};
        s = {s, $sformatf("  Burst: %s\n", burst.name())};
        s = {s, $sformatf("  Total Bytes: %0d\n", get_total_bytes())};
        return s;
    endfunction

endclass

`endif // AXI4_TRANSACTION_SV
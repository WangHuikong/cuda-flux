// AXI4 Transaction Types
package axi4_transaction_pkg;

    // AXI4 Burst Types
    typedef enum logic [1:0] {
        AXI4_FIXED = 2'b00,
        AXI4_INCR  = 2'b01,
        AXI4_WRAP  = 2'b10
    } axi4_burst_t;

    // AXI4 Response Types
    typedef enum logic [1:0] {
        AXI4_OKAY   = 2'b00,
        AXI4_EXOKAY = 2'b01,
        AXI4_SLVERR = 2'b10,
        AXI4_DECERR = 2'b11
    } axi4_resp_t;

    // AXI4 Lock Types
    typedef enum logic {
        AXI4_NORMAL = 1'b0,
        AXI4_EXCLUSIVE = 1'b1
    } axi4_lock_t;

    // AXI4 Size Types (log2 of data width)
    typedef enum logic [2:0] {
        AXI4_SIZE_1B   = 3'b000,
        AXI4_SIZE_2B   = 3'b001,
        AXI4_SIZE_4B   = 3'b010,
        AXI4_SIZE_8B   = 3'b011,
        AXI4_SIZE_16B  = 3'b100,
        AXI4_SIZE_32B  = 3'b101,
        AXI4_SIZE_64B  = 3'b110,
        AXI4_SIZE_128B = 3'b111
    } axi4_size_t;

    // AXI4 Transaction Type
    typedef enum {
        AXI4_READ,
        AXI4_WRITE
    } axi4_transaction_type_t;

    // AXI4 Write Address Transaction
    class axi4_write_addr_t;
        rand logic [3:0]  id;
        rand logic [31:0] addr;
        rand logic [7:0]  len;
        rand axi4_size_t  size;
        rand axi4_burst_t burst;
        rand axi4_lock_t  lock;
        rand logic [3:0]  cache;
        rand logic [2:0]  prot;
        rand logic [3:0]  qos;
        rand logic [3:0]  region;
        rand logic [0:0]  user;
        
        constraint addr_alignment {
            addr % (1 << size) == 0;
        }
        
        constraint len_range {
            len >= 0;
            len <= 255;
        }
        
        function new();
            id = 0;
            addr = 0;
            len = 0;
            size = AXI4_SIZE_8B;
            burst = AXI4_INCR;
            lock = AXI4_NORMAL;
            cache = 4'b0010;
            prot = 3'b000;
            qos = 0;
            region = 0;
            user = 0;
        endfunction
        
        function void display(string prefix = "");
            $display("%sAXI4 Write Address Transaction:", prefix);
            $display("%s  ID: %h", prefix, id);
            $display("%s  Address: %h", prefix, addr);
            $display("%s  Length: %d", prefix, len);
            $display("%s  Size: %s", prefix, size.name());
            $display("%s  Burst: %s", prefix, burst.name());
        endfunction
    endclass

    // AXI4 Write Data Transaction
    class axi4_write_data_t;
        rand logic [63:0] data;
        rand logic [7:0]  strb;
        rand logic        last;
        rand logic [0:0]  user;
        
        constraint strb_valid {
            strb != 0; // At least one byte must be valid
        }
        
        function new();
            data = 0;
            strb = 8'hFF;
            last = 0;
            user = 0;
        endfunction
        
        function void display(string prefix = "");
            $display("%sAXI4 Write Data Transaction:", prefix);
            $display("%s  Data: %h", prefix, data);
            $display("%s  Strobe: %b", prefix, strb);
            $display("%s  Last: %b", prefix, last);
        endfunction
    endclass

    // AXI4 Write Response Transaction
    class axi4_write_resp_t;
        logic [3:0]  id;
        axi4_resp_t resp;
        logic [0:0] user;
        
        function new();
            id = 0;
            resp = AXI4_OKAY;
            user = 0;
        endfunction
        
        function void display(string prefix = "");
            $display("%sAXI4 Write Response Transaction:", prefix);
            $display("%s  ID: %h", prefix, id);
            $display("%s  Response: %s", prefix, resp.name());
        endfunction
    endclass

    // AXI4 Read Address Transaction
    class axi4_read_addr_t;
        rand logic [3:0]  id;
        rand logic [31:0] addr;
        rand logic [7:0]  len;
        rand axi4_size_t  size;
        rand axi4_burst_t burst;
        rand axi4_lock_t  lock;
        rand logic [3:0]  cache;
        rand logic [2:0]  prot;
        rand logic [3:0]  qos;
        rand logic [3:0]  region;
        rand logic [0:0]  user;
        
        constraint addr_alignment {
            addr % (1 << size) == 0;
        }
        
        constraint len_range {
            len >= 0;
            len <= 255;
        }
        
        function new();
            id = 0;
            addr = 0;
            len = 0;
            size = AXI4_SIZE_8B;
            burst = AXI4_INCR;
            lock = AXI4_NORMAL;
            cache = 4'b0010;
            prot = 3'b000;
            qos = 0;
            region = 0;
            user = 0;
        endfunction
        
        function void display(string prefix = "");
            $display("%sAXI4 Read Address Transaction:", prefix);
            $display("%s  ID: %h", prefix, id);
            $display("%s  Address: %h", prefix, addr);
            $display("%s  Length: %d", prefix, len);
            $display("%s  Size: %s", prefix, size.name());
            $display("%s  Burst: %s", prefix, burst.name());
        endfunction
    endclass

    // AXI4 Read Data Transaction
    class axi4_read_data_t;
        logic [3:0]  id;
        logic [63:0] data;
        axi4_resp_t resp;
        logic        last;
        logic [0:0] user;
        
        function new();
            id = 0;
            data = 0;
            resp = AXI4_OKAY;
            last = 0;
            user = 0;
        endfunction
        
        function void display(string prefix = "");
            $display("%sAXI4 Read Data Transaction:", prefix);
            $display("%s  ID: %h", prefix, id);
            $display("%s  Data: %h", prefix, data);
            $display("%s  Response: %s", prefix, resp.name());
            $display("%s  Last: %b", prefix, last);
        endfunction
    endclass

    // Complete AXI4 Transaction
    class axi4_transaction_t;
        axi4_transaction_type_t trans_type;
        axi4_write_addr_t       write_addr;
        axi4_write_data_t       write_data[];
        axi4_write_resp_t       write_resp;
        axi4_read_addr_t        read_addr;
        axi4_read_data_t        read_data[];
        
        function new();
            write_addr = new();
            write_resp = new();
            read_addr = new();
        endfunction
        
        function void display(string prefix = "");
            $display("%sAXI4 Transaction:", prefix);
            $display("%s  Type: %s", prefix, trans_type.name());
            
            if (trans_type == AXI4_WRITE) begin
                write_addr.display(prefix + "  ");
                foreach (write_data[i]) begin
                    $display("%s  Write Data[%0d]:", prefix, i);
                    write_data[i].display(prefix + "    ");
                end
                write_resp.display(prefix + "  ");
            end else begin
                read_addr.display(prefix + "  ");
                foreach (read_data[i]) begin
                    $display("%s  Read Data[%0d]:", prefix, i);
                    read_data[i].display(prefix + "    ");
                end
            end
        endfunction
    endclass

endpackage
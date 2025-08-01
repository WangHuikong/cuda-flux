// AXI4 Transaction Class
// This file contains the transaction class for AXI4 operations

`ifndef AXI4_TRANSACTION_SV
`define AXI4_TRANSACTION_SV

// AXI4 burst types
typedef enum {FIXED, INCR, WRAP} axi4_burst_t;

// AXI4 response types
typedef enum {OKAY, EXOKAY, SLVERR, DECERR} axi4_resp_t;

// AXI4 transaction types
typedef enum {READ, WRITE} axi4_trans_type_t;

class axi4_transaction extends uvm_sequence_item;
    `uvm_object_utils(axi4_transaction)
    
    // Transaction type
    rand axi4_trans_type_t trans_type;
    
    // Address information
    rand bit [31:0] addr;
    rand bit [3:0]  id;
    rand bit [7:0]  len;
    rand bit [2:0]  size;
    rand axi4_burst_t burst;
    rand bit        lock;
    rand bit [3:0]  cache;
    rand bit [2:0]  prot;
    rand bit [3:0]  qos;
    rand bit [3:0]  region;
    rand bit [0:0]  user;
    
    // Data information
    rand bit [63:0] data[];
    rand bit [7:0]  strb[];
    rand bit        last[];
    
    // Response information
    rand axi4_resp_t resp;
    rand bit [3:0]   resp_id;
    
    // Timing information
    rand int unsigned delay;
    
    // Constraints
    constraint addr_constraint {
        addr >= 32'h0000_0000;
        addr <= 32'hFFFF_FFFF;
        addr % (1 << size) == 0;  // Address alignment
    }
    
    constraint id_constraint {
        id >= 0;
        id <= 15;
    }
    
    constraint len_constraint {
        len >= 0;
        len <= 255;
    }
    
    constraint size_constraint {
        size >= 0;
        size <= 6;  // Max 64 bytes per transfer
    }
    
    constraint burst_constraint {
        burst dist {FIXED := 10, INCR := 80, WRAP := 10};
    }
    
    constraint cache_constraint {
        cache >= 0;
        cache <= 15;
    }
    
    constraint prot_constraint {
        prot >= 0;
        prot <= 7;
    }
    
    constraint qos_constraint {
        qos >= 0;
        qos <= 15;
    }
    
    constraint region_constraint {
        region >= 0;
        region <= 15;
    }
    
    constraint user_constraint {
        user >= 0;
        user <= 1;
    }
    
    constraint delay_constraint {
        delay >= 0;
        delay <= 10;
    }
    
    constraint data_size_constraint {
        data.size() == len + 1;
        strb.size() == len + 1;
        last.size() == len + 1;
    }
    
    constraint last_constraint {
        foreach (last[i]) {
            if (i == len) last[i] == 1;
            else last[i] == 0;
        }
    }
    
    function new(string name = "axi4_transaction");
        super.new(name);
    endfunction
    
    function void post_randomize();
        // Generate data based on transaction type
        if (trans_type == WRITE) begin
            data = new[len + 1];
            strb = new[len + 1];
            last = new[len + 1];
            
            for (int i = 0; i <= len; i++) begin
                data[i] = $random;
                strb[i] = $random;
                last[i] = (i == len) ? 1'b1 : 1'b0;
            end
        end
    endfunction
    
    function void set_trans_type(axi4_trans_type_t type);
        trans_type = type;
    endfunction
    
    function void set_addr(bit [31:0] address);
        addr = address;
    endfunction
    
    function void set_id(bit [3:0] transaction_id);
        id = transaction_id;
    endfunction
    
    function void set_burst_length(bit [7:0] length);
        len = length;
    endfunction
    
    function void set_burst_size(bit [2:0] burst_size);
        size = burst_size;
    endfunction
    
    function void set_burst_type(axi4_burst_t burst_type);
        burst = burst_type;
    endfunction
    
    function void set_data(bit [63:0] data_array[]);
        data = new[data_array.size()];
        foreach (data_array[i]) begin
            data[i] = data_array[i];
        end
    endfunction
    
    function void set_strb(bit [7:0] strb_array[]);
        strb = new[strb_array.size()];
        foreach (strb_array[i]) begin
            strb[i] = strb_array[i];
        end
    endfunction
    
    function void set_response(axi4_resp_t response);
        resp = response;
    endfunction
    
    function void set_delay(int unsigned delay_value);
        delay = delay_value;
    endfunction
    
    function string convert2string();
        string s;
        s = $sformatf("AXI4 Transaction:\n");
        s = {s, $sformatf("  Type: %s\n", trans_type.name())};
        s = {s, $sformatf("  Address: 0x%08x\n", addr)};
        s = {s, $sformatf("  ID: %0d\n", id)};
        s = {s, $sformatf("  Length: %0d\n", len)};
        s = {s, $sformatf("  Size: %0d\n", size)};
        s = {s, $sformatf("  Burst: %s\n", burst.name())};
        s = {s, $sformatf("  Lock: %0b\n", lock)};
        s = {s, $sformatf("  Cache: 0x%01x\n", cache)};
        s = {s, $sformatf("  Prot: 0x%01x\n", prot)};
        s = {s, $sformatf("  QoS: 0x%01x\n", qos)};
        s = {s, $sformatf("  Region: 0x%01x\n", region)};
        s = {s, $sformatf("  User: %0b\n", user)};
        s = {s, $sformatf("  Delay: %0d\n", delay)};
        
        if (trans_type == WRITE && data.size() > 0) begin
            s = {s, $sformatf("  Data[0]: 0x%016x\n", data[0])};
            if (data.size() > 1) begin
                s = {s, $sformatf("  Data[%0d]: 0x%016x\n", data.size()-1, data[data.size()-1])};
            end
        end
        
        if (resp != null) begin
            s = {s, $sformatf("  Response: %s\n", resp.name())};
        end
        
        return s;
    endfunction
    
    function void do_copy(uvm_object rhs);
        axi4_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("AXI4_TRANSACTION", "Failed to cast rhs")
            return;
        end
        
        super.do_copy(rhs);
        trans_type = rhs_.trans_type;
        addr = rhs_.addr;
        id = rhs_.id;
        len = rhs_.len;
        size = rhs_.size;
        burst = rhs_.burst;
        lock = rhs_.lock;
        cache = rhs_.cache;
        prot = rhs_.prot;
        qos = rhs_.qos;
        region = rhs_.region;
        user = rhs_.user;
        delay = rhs_.delay;
        resp = rhs_.resp;
        resp_id = rhs_.resp_id;
        
        if (rhs_.data.size() > 0) begin
            data = new[rhs_.data.size()];
            foreach (rhs_.data[i]) begin
                data[i] = rhs_.data[i];
            end
        end
        
        if (rhs_.strb.size() > 0) begin
            strb = new[rhs_.strb.size()];
            foreach (rhs_.strb[i]) begin
                strb[i] = rhs_.strb[i];
            end
        end
        
        if (rhs_.last.size() > 0) begin
            last = new[rhs_.last.size()];
            foreach (rhs_.last[i]) begin
                last[i] = rhs_.last[i];
            end
        end
    endfunction
    
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        axi4_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            return 0;
        end
        
        if (trans_type != rhs_.trans_type) return 0;
        if (addr != rhs_.addr) return 0;
        if (id != rhs_.id) return 0;
        if (len != rhs_.len) return 0;
        if (size != rhs_.size) return 0;
        if (burst != rhs_.burst) return 0;
        if (lock != rhs_.lock) return 0;
        if (cache != rhs_.cache) return 0;
        if (prot != rhs_.prot) return 0;
        if (qos != rhs_.qos) return 0;
        if (region != rhs_.region) return 0;
        if (user != rhs_.user) return 0;
        if (delay != rhs_.delay) return 0;
        if (resp != rhs_.resp) return 0;
        if (resp_id != rhs_.resp_id) return 0;
        
        if (data.size() != rhs_.data.size()) return 0;
        foreach (data[i]) begin
            if (data[i] != rhs_.data[i]) return 0;
        end
        
        if (strb.size() != rhs_.strb.size()) return 0;
        foreach (strb[i]) begin
            if (strb[i] != rhs_.strb[i]) return 0;
        end
        
        if (last.size() != rhs_.last.size()) return 0;
        foreach (last[i]) begin
            if (last[i] != rhs_.last[i]) return 0;
        end
        
        return 1;
    endfunction
    
endclass

`endif // AXI4_TRANSACTION_SV
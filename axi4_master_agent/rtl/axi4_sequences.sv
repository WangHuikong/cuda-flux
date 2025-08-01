// AXI4 Sequences
`include "../inc/axi4_transaction.sv"

import axi4_transaction_pkg::*;

// Base sequence class
class axi4_base_sequence;
    mailbox #(axi4_transaction_t) req_mbx;
    
    function new(mailbox #(axi4_transaction_t) req_mbx);
        this.req_mbx = req_mbx;
    endfunction
    
    // Send transaction
    task send_transaction(axi4_transaction_t trans);
        req_mbx.put(trans);
    endtask
endclass

// Single write sequence
class axi4_single_write_sequence extends axi4_base_sequence;
    logic [31:0] addr;
    logic [63:0] data;
    logic [3:0]  id;
    
    function new(mailbox #(axi4_transaction_t) req_mbx);
        super.new(req_mbx);
        addr = 32'h0;
        data = 64'h0;
        id = 4'h0;
    endfunction
    
    task body();
        axi4_transaction_t trans;
        
        trans = new();
        trans.trans_type = AXI4_WRITE;
        
        // Configure write address
        trans.write_addr.id = id;
        trans.write_addr.addr = addr;
        trans.write_addr.len = 8'h0;  // Single beat
        trans.write_addr.size = AXI4_SIZE_8B;
        trans.write_addr.burst = AXI4_INCR;
        trans.write_addr.lock = AXI4_NORMAL;
        trans.write_addr.cache = 4'b0010;
        trans.write_addr.prot = 3'b000;
        trans.write_addr.qos = 0;
        trans.write_addr.region = 0;
        trans.write_addr.user = 0;
        
        // Configure write data
        trans.write_data = new[1];
        trans.write_data[0] = new();
        trans.write_data[0].data = data;
        trans.write_data[0].strb = 8'hFF;
        trans.write_data[0].last = 1'b1;
        trans.write_data[0].user = 0;
        
        // Configure write response
        trans.write_resp = new();
        
        send_transaction(trans);
    endtask
endclass

// Burst write sequence
class axi4_burst_write_sequence extends axi4_base_sequence;
    logic [31:0] addr;
    logic [63:0] data[];
    logic [3:0]  id;
    int          length;
    
    function new(mailbox #(axi4_transaction_t) req_mbx);
        super.new(req_mbx);
        addr = 32'h0;
        id = 4'h0;
        length = 4;
    endfunction
    
    task body();
        axi4_transaction_t trans;
        
        trans = new();
        trans.trans_type = AXI4_WRITE;
        
        // Configure write address
        trans.write_addr.id = id;
        trans.write_addr.addr = addr;
        trans.write_addr.len = length - 1;  // AXI4 length is number of transfers - 1
        trans.write_addr.size = AXI4_SIZE_8B;
        trans.write_addr.burst = AXI4_INCR;
        trans.write_addr.lock = AXI4_NORMAL;
        trans.write_addr.cache = 4'b0010;
        trans.write_addr.prot = 3'b000;
        trans.write_addr.qos = 0;
        trans.write_addr.region = 0;
        trans.write_addr.user = 0;
        
        // Configure write data
        trans.write_data = new[length];
        for (int i = 0; i < length; i++) begin
            trans.write_data[i] = new();
            trans.write_data[i].data = (data.size() > i) ? data[i] : (64'h1234_5678_9ABC_DEF0 + i);
            trans.write_data[i].strb = 8'hFF;
            trans.write_data[i].last = (i == length - 1);
            trans.write_data[i].user = 0;
        end
        
        // Configure write response
        trans.write_resp = new();
        
        send_transaction(trans);
    endtask
endclass

// Single read sequence
class axi4_single_read_sequence extends axi4_base_sequence;
    logic [31:0] addr;
    logic [3:0]  id;
    
    function new(mailbox #(axi4_transaction_t) req_mbx);
        super.new(req_mbx);
        addr = 32'h0;
        id = 4'h0;
    endfunction
    
    task body();
        axi4_transaction_t trans;
        
        trans = new();
        trans.trans_type = AXI4_READ;
        
        // Configure read address
        trans.read_addr.id = id;
        trans.read_addr.addr = addr;
        trans.read_addr.len = 8'h0;  // Single beat
        trans.read_addr.size = AXI4_SIZE_8B;
        trans.read_addr.burst = AXI4_INCR;
        trans.read_addr.lock = AXI4_NORMAL;
        trans.read_addr.cache = 4'b0010;
        trans.read_addr.prot = 3'b000;
        trans.read_addr.qos = 0;
        trans.read_addr.region = 0;
        trans.read_addr.user = 0;
        
        // Configure read data array
        trans.read_data = new[1];
        trans.read_data[0] = new();
        
        send_transaction(trans);
    endtask
endclass

// Burst read sequence
class axi4_burst_read_sequence extends axi4_base_sequence;
    logic [31:0] addr;
    logic [3:0]  id;
    int          length;
    
    function new(mailbox #(axi4_transaction_t) req_mbx);
        super.new(req_mbx);
        addr = 32'h0;
        id = 4'h0;
        length = 4;
    endfunction
    
    task body();
        axi4_transaction_t trans;
        
        trans = new();
        trans.trans_type = AXI4_READ;
        
        // Configure read address
        trans.read_addr.id = id;
        trans.read_addr.addr = addr;
        trans.read_addr.len = length - 1;  // AXI4 length is number of transfers - 1
        trans.read_addr.size = AXI4_SIZE_8B;
        trans.read_addr.burst = AXI4_INCR;
        trans.read_addr.lock = AXI4_NORMAL;
        trans.read_addr.cache = 4'b0010;
        trans.read_addr.prot = 3'b000;
        trans.read_addr.qos = 0;
        trans.read_addr.region = 0;
        trans.read_addr.user = 0;
        
        // Configure read data array
        trans.read_data = new[length];
        for (int i = 0; i < length; i++) begin
            trans.read_data[i] = new();
        end
        
        send_transaction(trans);
    endtask
endclass

// Random sequence
class axi4_random_sequence extends axi4_base_sequence;
    int num_transactions;
    
    function new(mailbox #(axi4_transaction_t) req_mbx);
        super.new(req_mbx);
        num_transactions = 10;
    endfunction
    
    task body();
        for (int i = 0; i < num_transactions; i++) begin
            if ($random % 2 == 0) begin
                axi4_single_write_sequence write_seq;
                write_seq = new(req_mbx);
                write_seq.addr = $random;
                write_seq.data = $random;
                write_seq.id = $random % 16;
                write_seq.body();
            end else begin
                axi4_single_read_sequence read_seq;
                read_seq = new(req_mbx);
                read_seq.addr = $random;
                read_seq.id = $random % 16;
                read_seq.body();
            end
        end
    endtask
endclass

// Memory test sequence
class axi4_memory_test_sequence extends axi4_base_sequence;
    logic [31:0] base_addr;
    int          num_words;
    
    function new(mailbox #(axi4_transaction_t) req_mbx);
        super.new(req_mbx);
        base_addr = 32'h1000_0000;
        num_words = 16;
    endfunction
    
    task body();
        // Write test pattern
        for (int i = 0; i < num_words; i++) begin
            axi4_single_write_sequence write_seq;
            write_seq = new(req_mbx);
            write_seq.addr = base_addr + (i * 8);
            write_seq.data = 64'hDEAD_BEEF_0000_0000 + i;
            write_seq.id = 4'h1;
            write_seq.body();
        end
        
        // Read back and verify
        for (int i = 0; i < num_words; i++) begin
            axi4_single_read_sequence read_seq;
            read_seq = new(req_mbx);
            read_seq.addr = base_addr + (i * 8);
            read_seq.id = 4'h2;
            read_seq.body();
        end
    endtask
endclass
// AXI4 Sequences
// This file contains various sequences for AXI4 testing

`ifndef AXI4_SEQUENCES_SV
`define AXI4_SEQUENCES_SV

// Base sequence class
class axi4_base_sequence extends uvm_sequence #(axi4_transaction);
    `uvm_object_utils(axi4_base_sequence)
    
    // Configuration
    axi4_config config_obj;
    
    function new(string name = "axi4_base_sequence");
        super.new(name);
    endfunction
    
    function void pre_body();
        super.pre_body();
        
        // Get configuration
        if (!uvm_config_db#(axi4_config)::get(m_sequencer, "", "config", config_obj)) begin
            `uvm_fatal("AXI4_BASE_SEQUENCE", "Failed to get config object")
        end
    endfunction
    
endclass

// Random sequence
class axi4_random_sequence extends axi4_base_sequence;
    `uvm_object_utils(axi4_random_sequence)
    
    // Number of transactions to generate
    int unsigned num_transactions = 10;
    
    function new(string name = "axi4_random_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi4_transaction trans;
        
        `uvm_info("AXI4_RANDOM_SEQUENCE", $sformatf("Starting random sequence with %0d transactions", num_transactions), UVM_LOW)
        
        for (int i = 0; i < num_transactions; i++) begin
            trans = axi4_transaction::type_id::create($sformatf("trans_%0d", i));
            
            // Randomize transaction
            if (!trans.randomize()) begin
                `uvm_error("AXI4_RANDOM_SEQUENCE", "Failed to randomize transaction")
                continue;
            end
            
            // Send transaction
            start_item(trans);
            finish_item(trans);
            
            `uvm_info("AXI4_RANDOM_SEQUENCE", $sformatf("Generated transaction %0d: %s", i, trans.convert2string()), UVM_MEDIUM)
        end
    endtask
    
endclass

// Write sequence
class axi4_write_sequence extends axi4_base_sequence;
    `uvm_object_utils(axi4_write_sequence)
    
    // Number of write transactions
    int unsigned num_writes = 5;
    
    // Write parameters
    bit [31:0] start_addr = 32'h1000_0000;
    int unsigned burst_length = 4;
    int unsigned burst_size = 3;  // 8 bytes per transfer
    
    function new(string name = "axi4_write_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi4_transaction trans;
        
        `uvm_info("AXI4_WRITE_SEQUENCE", $sformatf("Starting write sequence with %0d transactions", num_writes), UVM_LOW)
        
        for (int i = 0; i < num_writes; i++) begin
            trans = axi4_transaction::type_id::create($sformatf("write_trans_%0d", i));
            
            // Configure write transaction
            trans.set_trans_type(WRITE);
            trans.set_addr(start_addr + (i * 64));  // 64-byte increments
            trans.set_id(i % 4);
            trans.set_burst_length(burst_length);
            trans.set_burst_size(burst_size);
            trans.set_burst_type(INCR);
            trans.set_delay($urandom_range(0, 5));
            
            // Set default attributes
            trans.lock = 0;
            trans.cache = config_obj.default_cache;
            trans.prot = config_obj.default_prot;
            trans.qos = config_obj.default_qos;
            trans.region = 0;
            trans.user = config_obj.default_user;
            
            // Send transaction
            start_item(trans);
            finish_item(trans);
            
            `uvm_info("AXI4_WRITE_SEQUENCE", $sformatf("Generated write transaction %0d: addr=0x%08x", i, trans.addr), UVM_MEDIUM)
        end
    endtask
    
endclass

// Read sequence
class axi4_read_sequence extends axi4_base_sequence;
    `uvm_object_utils(axi4_read_sequence)
    
    // Number of read transactions
    int unsigned num_reads = 5;
    
    // Read parameters
    bit [31:0] start_addr = 32'h1000_0000;
    int unsigned burst_length = 4;
    int unsigned burst_size = 3;  // 8 bytes per transfer
    
    function new(string name = "axi4_read_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi4_transaction trans;
        
        `uvm_info("AXI4_READ_SEQUENCE", $sformatf("Starting read sequence with %0d transactions", num_reads), UVM_LOW)
        
        for (int i = 0; i < num_reads; i++) begin
            trans = axi4_transaction::type_id::create($sformatf("read_trans_%0d", i));
            
            // Configure read transaction
            trans.set_trans_type(READ);
            trans.set_addr(start_addr + (i * 64));  // 64-byte increments
            trans.set_id(i % 4);
            trans.set_burst_length(burst_length);
            trans.set_burst_size(burst_size);
            trans.set_burst_type(INCR);
            trans.set_delay($urandom_range(0, 5));
            
            // Set default attributes
            trans.lock = 0;
            trans.cache = config_obj.default_cache;
            trans.prot = config_obj.default_prot;
            trans.qos = config_obj.default_qos;
            trans.region = 0;
            trans.user = config_obj.default_user;
            
            // Send transaction
            start_item(trans);
            finish_item(trans);
            
            `uvm_info("AXI4_READ_SEQUENCE", $sformatf("Generated read transaction %0d: addr=0x%08x", i, trans.addr), UVM_MEDIUM)
        end
    endtask
    
endclass

// Mixed read/write sequence
class axi4_mixed_sequence extends axi4_base_sequence;
    `uvm_object_utils(axi4_mixed_sequence)
    
    // Number of transactions
    int unsigned num_transactions = 10;
    
    // Transaction parameters
    bit [31:0] start_addr = 32'h2000_0000;
    int unsigned burst_length = 2;
    int unsigned burst_size = 2;  // 4 bytes per transfer
    
    function new(string name = "axi4_mixed_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi4_transaction trans;
        
        `uvm_info("AXI4_MIXED_SEQUENCE", $sformatf("Starting mixed sequence with %0d transactions", num_transactions), UVM_LOW)
        
        for (int i = 0; i < num_transactions; i++) begin
            trans = axi4_transaction::type_id::create($sformatf("mixed_trans_%0d", i));
            
            // Randomly choose read or write
            if ($urandom_range(0, 1) == 0) begin
                trans.set_trans_type(WRITE);
            end else begin
                trans.set_trans_type(READ);
            end
            
            // Configure transaction
            trans.set_addr(start_addr + (i * 32));  // 32-byte increments
            trans.set_id(i % 4);
            trans.set_burst_length(burst_length);
            trans.set_burst_size(burst_size);
            trans.set_burst_type(INCR);
            trans.set_delay($urandom_range(0, 3));
            
            // Set default attributes
            trans.lock = 0;
            trans.cache = config_obj.default_cache;
            trans.prot = config_obj.default_prot;
            trans.qos = config_obj.default_qos;
            trans.region = 0;
            trans.user = config_obj.default_user;
            
            // Send transaction
            start_item(trans);
            finish_item(trans);
            
            `uvm_info("AXI4_MIXED_SEQUENCE", $sformatf("Generated %s transaction %0d: addr=0x%08x", 
                       trans.trans_type.name(), i, trans.addr), UVM_MEDIUM)
        end
    endtask
    
endclass

// Burst sequence
class axi4_burst_sequence extends axi4_base_sequence;
    `uvm_object_utils(axi4_burst_sequence)
    
    // Burst parameters
    int unsigned num_bursts = 3;
    int unsigned burst_length = 8;
    int unsigned burst_size = 3;  // 8 bytes per transfer
    
    function new(string name = "axi4_burst_sequence");
        super.new(name);
    endfunction
    
    task body();
        axi4_transaction trans;
        
        `uvm_info("AXI4_BURST_SEQUENCE", $sformatf("Starting burst sequence with %0d bursts", num_bursts), UVM_LOW)
        
        for (int i = 0; i < num_bursts; i++) begin
            // Write burst
            trans = axi4_transaction::type_id::create($sformatf("write_burst_%0d", i));
            trans.set_trans_type(WRITE);
            trans.set_addr(32'h3000_0000 + (i * 128));
            trans.set_id(i);
            trans.set_burst_length(burst_length);
            trans.set_burst_size(burst_size);
            trans.set_burst_type(INCR);
            trans.set_delay(1);
            
            // Set default attributes
            trans.lock = 0;
            trans.cache = config_obj.default_cache;
            trans.prot = config_obj.default_prot;
            trans.qos = config_obj.default_qos;
            trans.region = 0;
            trans.user = config_obj.default_user;
            
            start_item(trans);
            finish_item(trans);
            
            // Read burst
            trans = axi4_transaction::type_id::create($sformatf("read_burst_%0d", i));
            trans.set_trans_type(READ);
            trans.set_addr(32'h3000_0000 + (i * 128));
            trans.set_id(i);
            trans.set_burst_length(burst_length);
            trans.set_burst_size(burst_size);
            trans.set_burst_type(INCR);
            trans.set_delay(1);
            
            // Set default attributes
            trans.lock = 0;
            trans.cache = config_obj.default_cache;
            trans.prot = config_obj.default_prot;
            trans.qos = config_obj.default_qos;
            trans.region = 0;
            trans.user = config_obj.default_user;
            
            start_item(trans);
            finish_item(trans);
            
            `uvm_info("AXI4_BURST_SEQUENCE", $sformatf("Generated burst pair %0d", i), UVM_MEDIUM)
        end
    endtask
    
endclass

`endif // AXI4_SEQUENCES_SV
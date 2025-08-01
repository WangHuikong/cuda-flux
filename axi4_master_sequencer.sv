// AXI4 Master Sequencer
// This sequencer manages the flow of AXI4 transactions to the driver

`ifndef AXI4_MASTER_SEQUENCER_SV
`define AXI4_MASTER_SEQUENCER_SV

class axi4_master_sequencer #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends uvm_sequencer #(axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH));

    // Transaction handle
    typedef axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH) axi4_trans_t;

    // UVM Factory Registration
    `uvm_component_param_utils(axi4_master_sequencer#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_master_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

// Base AXI4 Sequence
class axi4_base_sequence #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends uvm_sequence #(axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH));

    // Transaction handle
    typedef axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH) axi4_trans_t;

    // UVM Factory Registration
    `uvm_object_param_utils(axi4_base_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_base_sequence");
        super.new(name);
    endfunction

    // Pre-body task for common setup
    task pre_body();
        if (starting_phase != null) begin
            starting_phase.raise_objection(this, get_type_name());
        end
    endtask

    // Post-body task for common cleanup
    task post_body();
        if (starting_phase != null) begin
            starting_phase.drop_objection(this, get_type_name());
        end
    endtask

endclass

// Single Write Sequence
class axi4_single_write_sequence #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends axi4_base_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH);

    // Configurable parameters
    rand logic [ADDR_WIDTH-1:0] start_addr;
    rand logic [DATA_WIDTH-1:0] write_data;
    rand logic [ID_WIDTH-1:0]   trans_id;

    // UVM Factory Registration
    `uvm_object_param_utils(axi4_single_write_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_single_write_sequence");
        super.new(name);
    endfunction

    // Main sequence body
    task body();
        axi4_trans_t trans;
        
        trans = axi4_trans_t::type_id::create("single_write_trans");
        
        start_item(trans);
        
        assert(trans.randomize() with {
            trans_type == AXI4_WRITE;
            addr == start_addr;
            len == 0;  // Single beat
            size == AXI4_SIZE_4B;
            burst == AXI4_BURST_INCR;
            id == trans_id;
        });
        
        // Override data if specified
        trans.data[0] = write_data;
        
        finish_item(trans);
        
        `uvm_info(get_type_name(), 
            $sformatf("Single write completed: ADDR=0x%0h, DATA=0x%0h", 
                start_addr, write_data), UVM_MEDIUM)
    endtask

endclass

// Single Read Sequence
class axi4_single_read_sequence #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends axi4_base_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH);

    // Configurable parameters
    rand logic [ADDR_WIDTH-1:0] start_addr;
    rand logic [ID_WIDTH-1:0]   trans_id;

    // UVM Factory Registration
    `uvm_object_param_utils(axi4_single_read_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_single_read_sequence");
        super.new(name);
    endfunction

    // Main sequence body
    task body();
        axi4_trans_t trans;
        
        trans = axi4_trans_t::type_id::create("single_read_trans");
        
        start_item(trans);
        
        assert(trans.randomize() with {
            trans_type == AXI4_READ;
            addr == start_addr;
            len == 0;  // Single beat
            size == AXI4_SIZE_4B;
            burst == AXI4_BURST_INCR;
            id == trans_id;
        });
        
        finish_item(trans);
        
        `uvm_info(get_type_name(), 
            $sformatf("Single read completed: ADDR=0x%0h", start_addr), UVM_MEDIUM)
    endtask

endclass

// Burst Write Sequence
class axi4_burst_write_sequence #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends axi4_base_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH);

    // Configurable parameters
    rand logic [ADDR_WIDTH-1:0] start_addr;
    rand logic [7:0]            burst_len;
    rand axi4_size_type_e       burst_size;
    rand axi4_burst_type_e      burst_type;
    rand logic [ID_WIDTH-1:0]   trans_id;

    // Constraints
    constraint c_burst_len {
        burst_len inside {[1:15]};  // 2-16 beats
    }

    constraint c_burst_size {
        burst_size inside {AXI4_SIZE_1B, AXI4_SIZE_2B, AXI4_SIZE_4B, AXI4_SIZE_8B};
    }

    // UVM Factory Registration
    `uvm_object_param_utils(axi4_burst_write_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_burst_write_sequence");
        super.new(name);
    endfunction

    // Main sequence body
    task body();
        axi4_trans_t trans;
        
        trans = axi4_trans_t::type_id::create("burst_write_trans");
        
        start_item(trans);
        
        assert(trans.randomize() with {
            trans_type == AXI4_WRITE;
            addr == start_addr;
            len == burst_len;
            size == burst_size;
            burst == burst_type;
            id == trans_id;
        });
        
        finish_item(trans);
        
        `uvm_info(get_type_name(), 
            $sformatf("Burst write completed: ADDR=0x%0h, LEN=%0d, SIZE=%s, TYPE=%s", 
                start_addr, burst_len, burst_size.name(), burst_type.name()), UVM_MEDIUM)
    endtask

endclass

// Burst Read Sequence
class axi4_burst_read_sequence #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends axi4_base_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH);

    // Configurable parameters
    rand logic [ADDR_WIDTH-1:0] start_addr;
    rand logic [7:0]            burst_len;
    rand axi4_size_type_e       burst_size;
    rand axi4_burst_type_e      burst_type;
    rand logic [ID_WIDTH-1:0]   trans_id;

    // Constraints
    constraint c_burst_len {
        burst_len inside {[1:15]};  // 2-16 beats
    }

    constraint c_burst_size {
        burst_size inside {AXI4_SIZE_1B, AXI4_SIZE_2B, AXI4_SIZE_4B, AXI4_SIZE_8B};
    }

    // UVM Factory Registration
    `uvm_object_param_utils(axi4_burst_read_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_burst_read_sequence");
        super.new(name);
    endfunction

    // Main sequence body
    task body();
        axi4_trans_t trans;
        
        trans = axi4_trans_t::type_id::create("burst_read_trans");
        
        start_item(trans);
        
        assert(trans.randomize() with {
            trans_type == AXI4_READ;
            addr == start_addr;
            len == burst_len;
            size == burst_size;
            burst == burst_type;
            id == trans_id;
        });
        
        finish_item(trans);
        
        `uvm_info(get_type_name(), 
            $sformatf("Burst read completed: ADDR=0x%0h, LEN=%0d, SIZE=%s, TYPE=%s", 
                start_addr, burst_len, burst_size.name(), burst_type.name()), UVM_MEDIUM)
    endtask

endclass

// Random Mixed Sequence
class axi4_random_sequence #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends axi4_base_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH);

    // Configurable parameters
    rand int num_transactions;
    
    // Constraints
    constraint c_num_trans {
        num_transactions inside {[10:50]};
    }

    // UVM Factory Registration
    `uvm_object_param_utils(axi4_random_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_random_sequence");
        super.new(name);
    endfunction

    // Main sequence body
    task body();
        axi4_trans_t trans;
        
        for (int i = 0; i < num_transactions; i++) begin
            trans = axi4_trans_t::type_id::create($sformatf("random_trans_%0d", i));
            
            start_item(trans);
            assert(trans.randomize());
            finish_item(trans);
            
            `uvm_info(get_type_name(), 
                $sformatf("Random transaction %0d completed: %s", 
                    i, trans.convert2string()), UVM_HIGH)
        end
        
        `uvm_info(get_type_name(), 
            $sformatf("Random sequence completed with %0d transactions", 
                num_transactions), UVM_MEDIUM)
    endtask

endclass

// Write-Read-Compare Sequence
class axi4_write_read_sequence #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends axi4_base_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH);

    // Configurable parameters
    rand logic [ADDR_WIDTH-1:0] start_addr;
    rand logic [DATA_WIDTH-1:0] write_data;
    rand logic [ID_WIDTH-1:0]   trans_id;

    // UVM Factory Registration
    `uvm_object_param_utils(axi4_write_read_sequence#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_write_read_sequence");
        super.new(name);
    endfunction

    // Main sequence body
    task body();
        axi4_trans_t write_trans, read_trans;
        
        // Write transaction
        write_trans = axi4_trans_t::type_id::create("write_trans");
        start_item(write_trans);
        assert(write_trans.randomize() with {
            trans_type == AXI4_WRITE;
            addr == start_addr;
            len == 0;  // Single beat
            size == AXI4_SIZE_4B;
            burst == AXI4_BURST_INCR;
            id == trans_id;
        });
        write_trans.data[0] = write_data;
        finish_item(write_trans);
        
        // Small delay between write and read
        #100;
        
        // Read transaction
        read_trans = axi4_trans_t::type_id::create("read_trans");
        start_item(read_trans);
        assert(read_trans.randomize() with {
            trans_type == AXI4_READ;
            addr == start_addr;
            len == 0;  // Single beat
            size == AXI4_SIZE_4B;
            burst == AXI4_BURST_INCR;
            id == trans_id + 1;
        });
        finish_item(read_trans);
        
        `uvm_info(get_type_name(), 
            $sformatf("Write-Read sequence completed: ADDR=0x%0h, WRITE_DATA=0x%0h", 
                start_addr, write_data), UVM_MEDIUM)
    endtask

endclass

`endif // AXI4_MASTER_SEQUENCER_SV
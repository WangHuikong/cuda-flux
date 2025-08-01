// AXI4 Test Case
// This file contains the test implementation for AXI4

`ifndef AXI4_TEST_SV
`define AXI4_TEST_SV

class axi4_test extends uvm_test;
    `uvm_component_utils(axi4_test)
    
    // Test environment
    axi4_test_env test_env;
    
    // Virtual interface
    virtual axi4_interface vif;
    
    // Test configuration
    axi4_config test_config;
    
    function new(string name = "axi4_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get virtual interface
        if (!uvm_config_db#(virtual axi4_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("AXI4_TEST", "Failed to get virtual interface")
        end
        
        // Create test configuration
        test_config = axi4_config::type_id::create("test_config");
        
        // Configure test parameters
        test_config.set_addr_width(32);
        test_config.set_data_width(64);
        test_config.set_id_width(4);
        test_config.set_user_width(1);
        test_config.set_timing(0, 3);
        test_config.set_burst_length(1, 8);
        test_config.set_addr_range(32'h1000_0000, 32'h1FFF_FFFF);
        test_config.set_response_probabilities(95.0, 3.0, 2.0, 95.0, 3.0, 2.0);
        test_config.set_ready_probabilities(90.0, 90.0, 90.0, 90.0, 90.0);
        test_config.set_default_attributes(4'b0011, 3'b000, 4'b0000, 1'b0);
        
        // Set configuration in config database
        uvm_config_db#(axi4_config)::set(this, "*", "config", test_config);
        uvm_config_db#(virtual axi4_interface)::set(this, "*", "vif", vif);
        
        // Build test environment
        test_env = axi4_test_env::type_id::create("test_env", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    
    task run_phase(uvm_phase phase);
        // Phase objection to keep test running
        phase.raise_objection(this);
        
        `uvm_info("AXI4_TEST", "Starting AXI4 test", UVM_LOW)
        
        // Wait for reset to complete
        wait_for_reset();
        
        // Run test sequences
        run_test_sequences();
        
        // Wait for all transactions to complete
        #1000;
        
        `uvm_info("AXI4_TEST", "AXI4 test completed", UVM_LOW)
        
        // Drop objection
        phase.drop_objection(this);
    endtask
    
    task wait_for_reset();
        // Wait for reset to be deasserted
        @(posedge vif.aclk);
        while (vif.aresetn == 0) begin
            @(posedge vif.aclk);
        end
        `uvm_info("AXI4_TEST", "Reset deasserted", UVM_LOW)
    endtask
    
    task run_test_sequences();
        axi4_random_sequence random_seq;
        axi4_write_sequence write_seq;
        axi4_read_sequence read_seq;
        axi4_mixed_sequence mixed_seq;
        axi4_burst_sequence burst_seq;
        
        // Create sequences
        random_seq = axi4_random_sequence::type_id::create("random_seq");
        write_seq = axi4_write_sequence::type_id::create("write_seq");
        read_seq = axi4_read_sequence::type_id::create("read_seq");
        mixed_seq = axi4_mixed_sequence::type_id::create("mixed_seq");
        burst_seq = axi4_burst_sequence::type_id::create("burst_seq");
        
        // Configure sequences
        random_seq.num_transactions = 5;
        write_seq.num_writes = 3;
        read_seq.num_reads = 3;
        mixed_seq.num_transactions = 6;
        burst_seq.num_bursts = 2;
        
        // Run sequences
        `uvm_info("AXI4_TEST", "Running random sequence", UVM_LOW)
        random_seq.start(test_env.master_agent.sequencer);
        
        #100;
        
        `uvm_info("AXI4_TEST", "Running write sequence", UVM_LOW)
        write_seq.start(test_env.master_agent.sequencer);
        
        #100;
        
        `uvm_info("AXI4_TEST", "Running read sequence", UVM_LOW)
        read_seq.start(test_env.master_agent.sequencer);
        
        #100;
        
        `uvm_info("AXI4_TEST", "Running mixed sequence", UVM_LOW)
        mixed_seq.start(test_env.master_agent.sequencer);
        
        #100;
        
        `uvm_info("AXI4_TEST", "Running burst sequence", UVM_LOW)
        burst_seq.start(test_env.master_agent.sequencer);
    endtask
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI4_TEST", "Test report completed", UVM_LOW)
    endfunction
    
endclass

// Specific test cases
class axi4_write_test extends axi4_test;
    `uvm_component_utils(axi4_write_test)
    
    function new(string name = "axi4_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_test_sequences();
        axi4_write_sequence write_seq;
        
        write_seq = axi4_write_sequence::type_id::create("write_seq");
        write_seq.num_writes = 10;
        write_seq.start_addr = 32'h2000_0000;
        write_seq.burst_length = 4;
        write_seq.burst_size = 3;
        
        `uvm_info("AXI4_WRITE_TEST", "Running write-only test", UVM_LOW)
        write_seq.start(test_env.master_agent.sequencer);
    endtask
    
endclass

class axi4_read_test extends axi4_test;
    `uvm_component_utils(axi4_read_test)
    
    function new(string name = "axi4_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_test_sequences();
        axi4_read_sequence read_seq;
        
        read_seq = axi4_read_sequence::type_id::create("read_seq");
        read_seq.num_reads = 10;
        read_seq.start_addr = 32'h2000_0000;
        read_seq.burst_length = 4;
        read_seq.burst_size = 3;
        
        `uvm_info("AXI4_READ_TEST", "Running read-only test", UVM_LOW)
        read_seq.start(test_env.master_agent.sequencer);
    endtask
    
endclass

class axi4_burst_test extends axi4_test;
    `uvm_component_utils(axi4_burst_test)
    
    function new(string name = "axi4_burst_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_test_sequences();
        axi4_burst_sequence burst_seq;
        
        burst_seq = axi4_burst_sequence::type_id::create("burst_seq");
        burst_seq.num_bursts = 5;
        burst_seq.burst_length = 8;
        burst_seq.burst_size = 3;
        
        `uvm_info("AXI4_BURST_TEST", "Running burst test", UVM_LOW)
        burst_seq.start(test_env.master_agent.sequencer);
    endtask
    
endclass

class axi4_random_test extends axi4_test;
    `uvm_component_utils(axi4_random_test)
    
    function new(string name = "axi4_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_test_sequences();
        axi4_random_sequence random_seq;
        
        random_seq = axi4_random_sequence::type_id::create("random_seq");
        random_seq.num_transactions = 20;
        
        `uvm_info("AXI4_RANDOM_TEST", "Running random test", UVM_LOW)
        random_seq.start(test_env.master_agent.sequencer);
    endtask
    
endclass

`endif // AXI4_TEST_SV
// AXI4 Master Driver
// This driver receives transactions from sequencer and drives them on AXI4 interface

`ifndef AXI4_MASTER_DRIVER_SV
`define AXI4_MASTER_DRIVER_SV

class axi4_master_driver #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends uvm_driver #(axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH));

    // Virtual interface handle
    virtual axi4_interface#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH).master vif;

    // Transaction handle
    typedef axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH) axi4_trans_t;

    // UVM Factory Registration
    `uvm_component_param_utils(axi4_master_driver#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_master_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get virtual interface from config DB
        if (!uvm_config_db#(virtual axi4_interface#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))::get(
            this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
        end
    endfunction

    // Run phase
    task run_phase(uvm_phase phase);
        axi4_trans_t trans;
        
        // Initialize interface
        initialize_interface();
        
        forever begin
            // Get next transaction from sequencer
            seq_item_port.get_next_item(trans);
            
            `uvm_info(get_type_name(), $sformatf("Driving transaction:\n%s", trans.convert2string()), UVM_MEDIUM)
            
            // Drive the transaction
            case (trans.trans_type)
                AXI4_WRITE: drive_write_transaction(trans);
                AXI4_READ:  drive_read_transaction(trans);
                default:    `uvm_error(get_type_name(), "Invalid transaction type")
            endcase
            
            // Signal completion to sequencer
            seq_item_port.item_done();
        end
    endtask

    // Initialize interface signals
    task initialize_interface();
        `uvm_info(get_type_name(), "Initializing AXI4 Master interface", UVM_HIGH)
        
        // Initialize write address channel
        vif.awid     <= 0;
        vif.awaddr   <= 0;
        vif.awlen    <= 0;
        vif.awsize   <= 0;
        vif.awburst  <= 0;
        vif.awlock   <= 0;
        vif.awcache  <= 0;
        vif.awprot   <= 0;
        vif.awqos    <= 0;
        vif.awregion <= 0;
        vif.awuser   <= 0;
        vif.awvalid  <= 0;

        // Initialize write data channel
        vif.wdata    <= 0;
        vif.wstrb    <= 0;
        vif.wlast    <= 0;
        vif.wuser    <= 0;
        vif.wvalid   <= 0;

        // Initialize write response channel
        vif.bready   <= 0;

        // Initialize read address channel
        vif.arid     <= 0;
        vif.araddr   <= 0;
        vif.arlen    <= 0;
        vif.arsize   <= 0;
        vif.arburst  <= 0;
        vif.arlock   <= 0;
        vif.arcache  <= 0;
        vif.arprot   <= 0;
        vif.arqos    <= 0;
        vif.arregion <= 0;
        vif.aruser   <= 0;
        vif.arvalid  <= 0;

        // Initialize read data channel
        vif.rready   <= 0;

        // Wait for reset deassertion
        wait (vif.aresetn === 1'b1);
        @(posedge vif.aclk);
    endtask

    // Drive write transaction
    task drive_write_transaction(axi4_trans_t trans);
        fork
            drive_write_address(trans);
            drive_write_data(trans);
            drive_write_response(trans);
        join
    endtask

    // Drive write address channel
    task drive_write_address(axi4_trans_t trans);
        // Apply address delay
        repeat (trans.addr_delay) @(posedge vif.aclk);
        
        // Drive address channel
        vif.awid     <= trans.id;
        vif.awaddr   <= trans.addr;
        vif.awlen    <= trans.len;
        vif.awsize   <= trans.size;
        vif.awburst  <= trans.burst;
        vif.awlock   <= trans.lock;
        vif.awcache  <= trans.cache;
        vif.awprot   <= trans.prot;
        vif.awqos    <= trans.qos;
        vif.awregion <= trans.region;
        vif.awuser   <= trans.user;
        vif.awvalid  <= 1'b1;

        // Wait for handshake
        do @(posedge vif.aclk);
        while (!vif.awready);

        // Deassert valid
        vif.awvalid <= 1'b0;
        
        `uvm_info(get_type_name(), "Write address phase completed", UVM_HIGH)
    endtask

    // Drive write data channel
    task drive_write_data(axi4_trans_t trans);
        int num_beats = trans.len + 1;
        
        for (int i = 0; i < num_beats; i++) begin
            // Apply data delay
            repeat (trans.data_delay[i]) @(posedge vif.aclk);
            
            // Drive data
            vif.wdata  <= trans.data[i];
            vif.wstrb  <= trans.strb[i];
            vif.wlast  <= (i == num_beats - 1) ? 1'b1 : 1'b0;
            vif.wuser  <= trans.wuser[i];
            vif.wvalid <= 1'b1;

            // Wait for handshake
            do @(posedge vif.aclk);
            while (!vif.wready);
        end

        // Deassert valid
        vif.wvalid <= 1'b0;
        vif.wlast  <= 1'b0;
        
        `uvm_info(get_type_name(), "Write data phase completed", UVM_HIGH)
    endtask

    // Drive write response channel
    task drive_write_response(axi4_trans_t trans);
        // Apply response delay
        repeat (trans.resp_delay) @(posedge vif.aclk);
        
        // Assert ready for response
        vif.bready <= 1'b1;

        // Wait for response
        do @(posedge vif.aclk);
        while (!vif.bvalid);

        // Capture response
        trans.buser = vif.buser;
        
        // Deassert ready
        vif.bready <= 1'b0;
        
        `uvm_info(get_type_name(), "Write response phase completed", UVM_HIGH)
    endtask

    // Drive read transaction
    task drive_read_transaction(axi4_trans_t trans);
        fork
            drive_read_address(trans);
            drive_read_data(trans);
        join
    endtask

    // Drive read address channel
    task drive_read_address(axi4_trans_t trans);
        // Apply address delay
        repeat (trans.addr_delay) @(posedge vif.aclk);
        
        // Drive address channel
        vif.arid     <= trans.id;
        vif.araddr   <= trans.addr;
        vif.arlen    <= trans.len;
        vif.arsize   <= trans.size;
        vif.arburst  <= trans.burst;
        vif.arlock   <= trans.lock;
        vif.arcache  <= trans.cache;
        vif.arprot   <= trans.prot;
        vif.arqos    <= trans.qos;
        vif.arregion <= trans.region;
        vif.aruser   <= trans.user;
        vif.arvalid  <= 1'b1;

        // Wait for handshake
        do @(posedge vif.aclk);
        while (!vif.arready);

        // Deassert valid
        vif.arvalid <= 1'b0;
        
        `uvm_info(get_type_name(), "Read address phase completed", UVM_HIGH)
    endtask

    // Drive read data channel
    task drive_read_data(axi4_trans_t trans);
        int num_beats = trans.len + 1;
        int beat_count = 0;
        
        // Apply response delay
        repeat (trans.resp_delay) @(posedge vif.aclk);
        
        // Assert ready for data
        vif.rready <= 1'b1;

        // Collect all data beats
        while (beat_count < num_beats) begin
            @(posedge vif.aclk);
            
            if (vif.rvalid) begin
                // Capture read data and response
                trans.resp[beat_count] = axi4_resp_type_e'(vif.rresp);
                trans.ruser[beat_count] = vif.ruser;
                
                `uvm_info(get_type_name(), 
                    $sformatf("Read beat %0d: data=0x%0h, resp=%s", 
                        beat_count, vif.rdata, trans.resp[beat_count].name()), UVM_HIGH)
                
                beat_count++;
                
                // Check for last beat
                if (vif.rlast && beat_count != num_beats) begin
                    `uvm_error(get_type_name(), 
                        $sformatf("Unexpected RLAST at beat %0d, expected %0d beats", 
                            beat_count, num_beats))
                end
            end
        end

        // Deassert ready
        vif.rready <= 1'b0;
        
        `uvm_info(get_type_name(), "Read data phase completed", UVM_HIGH)
    endtask

    // Reset handling
    task handle_reset();
        `uvm_info(get_type_name(), "Reset detected, reinitializing interface", UVM_MEDIUM)
        initialize_interface();
    endtask

endclass

`endif // AXI4_MASTER_DRIVER_SV
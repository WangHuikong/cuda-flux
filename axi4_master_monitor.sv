// AXI4 Master Monitor
// This monitor observes transactions on AXI4 interface and sends them to analysis port

`ifndef AXI4_MASTER_MONITOR_SV
`define AXI4_MASTER_MONITOR_SV

class axi4_master_monitor #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4,
    parameter int USER_WIDTH = 1
) extends uvm_monitor;

    // Virtual interface handle
    virtual axi4_interface#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH).monitor vif;

    // Analysis port for sending collected transactions
    uvm_analysis_port #(axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH)) item_collected_port;

    // Transaction handle
    typedef axi4_transaction#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH) axi4_trans_t;

    // Outstanding transaction tracking
    axi4_trans_t write_addr_queue[$];
    axi4_trans_t read_addr_queue[$];
    axi4_trans_t write_data_queue[$];

    // Coverage
    covergroup axi4_coverage;
        option.per_instance = 1;
        
        // Address coverage
        cp_addr: coverpoint vif.awaddr {
            bins low_addr  = {[0:'h0000_FFFF]};
            bins mid_addr  = {['h0001_0000:'hFFFE_FFFF]};
            bins high_addr = {['hFFFF_0000:'hFFFF_FFFF]};
        }
        
        // Length coverage
        cp_len: coverpoint vif.awlen {
            bins single = {0};
            bins short_burst = {[1:7]};
            bins medium_burst = {[8:15]};
            bins long_burst = {[16:255]};
        }
        
        // Size coverage
        cp_size: coverpoint vif.awsize {
            bins size_1B   = {3'b000};
            bins size_2B   = {3'b001};
            bins size_4B   = {3'b010};
            bins size_8B   = {3'b011};
            bins size_16B  = {3'b100};
            bins size_32B  = {3'b101};
            bins size_64B  = {3'b110};
            bins size_128B = {3'b111};
        }
        
        // Burst type coverage
        cp_burst: coverpoint vif.awburst {
            bins fixed = {2'b00};
            bins incr  = {2'b01};
            bins wrap  = {2'b10};
        }
        
        // Cross coverage
        cp_size_x_burst: cross cp_size, cp_burst;
        cp_len_x_burst: cross cp_len, cp_burst;
    endgroup

    // UVM Factory Registration
    `uvm_component_param_utils(axi4_master_monitor#(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, USER_WIDTH))

    // Constructor
    function new(string name = "axi4_master_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
        axi4_coverage = new();
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
        fork
            monitor_write_address();
            monitor_write_data();
            monitor_write_response();
            monitor_read_address();
            monitor_read_data();
            collect_coverage();
        join_none
    endtask

    // Monitor write address channel
    task monitor_write_address();
        axi4_trans_t trans;
        
        forever begin
            @(posedge vif.aclk);
            
            if (vif.aresetn && vif.awvalid && vif.awready) begin
                trans = axi4_trans_t::type_id::create("write_trans");
                
                // Collect address channel information
                trans.trans_type = AXI4_WRITE;
                trans.id         = vif.awid;
                trans.addr       = vif.awaddr;
                trans.len        = vif.awlen;
                trans.size       = axi4_size_type_e'(vif.awsize);
                trans.burst      = axi4_burst_type_e'(vif.awburst);
                trans.lock       = vif.awlock;
                trans.cache      = vif.awcache;
                trans.prot       = vif.awprot;
                trans.qos        = vif.awqos;
                trans.region     = vif.awregion;
                trans.user       = vif.awuser;
                
                // Initialize arrays
                trans.post_randomize();
                
                // Add to queue for data phase matching
                write_addr_queue.push_back(trans);
                
                `uvm_info(get_type_name(), 
                    $sformatf("Write address captured: ID=0x%0h, ADDR=0x%0h, LEN=%0d", 
                        trans.id, trans.addr, trans.len), UVM_HIGH)
            end
        end
    endtask

    // Monitor write data channel
    task monitor_write_data();
        axi4_trans_t trans;
        int beat_count;
        int num_beats;
        
        forever begin
            @(posedge vif.aclk);
            
            if (vif.aresetn && vif.wvalid && vif.wready) begin
                // Find matching address transaction
                if (write_addr_queue.size() == 0) begin
                    `uvm_error(get_type_name(), "Write data without matching address")
                    continue;
                end
                
                if (beat_count == 0) begin
                    trans = write_addr_queue.pop_front();
                    num_beats = trans.len + 1;
                    beat_count = 0;
                end
                
                // Collect data beat
                trans.data[beat_count] = vif.wdata;
                trans.strb[beat_count] = vif.wstrb;
                trans.wuser[beat_count] = vif.wuser;
                
                beat_count++;
                
                `uvm_info(get_type_name(), 
                    $sformatf("Write data beat %0d: DATA=0x%0h, STRB=0x%0h", 
                        beat_count-1, vif.wdata, vif.wstrb), UVM_HIGH)
                
                // Check for last beat
                if (vif.wlast) begin
                    if (beat_count != num_beats) begin
                        `uvm_error(get_type_name(), 
                            $sformatf("WLAST mismatch: expected %0d beats, got %0d", 
                                num_beats, beat_count))
                    end
                    
                    // Add to queue for response matching
                    write_data_queue.push_back(trans);
                    beat_count = 0;
                end
            end
        end
    endtask

    // Monitor write response channel
    task monitor_write_response();
        axi4_trans_t trans;
        
        forever begin
            @(posedge vif.aclk);
            
            if (vif.aresetn && vif.bvalid && vif.bready) begin
                // Find matching data transaction
                if (write_data_queue.size() == 0) begin
                    `uvm_error(get_type_name(), "Write response without matching data")
                    continue;
                end
                
                trans = write_data_queue.pop_front();
                
                // Collect response
                trans.buser = vif.buser;
                
                `uvm_info(get_type_name(), 
                    $sformatf("Write response: ID=0x%0h, RESP=%s", 
                        vif.bid, axi4_resp_type_e'(vif.bresp).name()), UVM_HIGH)
                
                // Send completed transaction
                item_collected_port.write(trans);
                
                `uvm_info(get_type_name(), 
                    $sformatf("Write transaction completed:\n%s", trans.convert2string()), UVM_MEDIUM)
            end
        end
    endtask

    // Monitor read address channel
    task monitor_read_address();
        axi4_trans_t trans;
        
        forever begin
            @(posedge vif.aclk);
            
            if (vif.aresetn && vif.arvalid && vif.arready) begin
                trans = axi4_trans_t::type_id::create("read_trans");
                
                // Collect address channel information
                trans.trans_type = AXI4_READ;
                trans.id         = vif.arid;
                trans.addr       = vif.araddr;
                trans.len        = vif.arlen;
                trans.size       = axi4_size_type_e'(vif.arsize);
                trans.burst      = axi4_burst_type_e'(vif.arburst);
                trans.lock       = vif.arlock;
                trans.cache      = vif.arcache;
                trans.prot       = vif.arprot;
                trans.qos        = vif.arqos;
                trans.region     = vif.arregion;
                trans.user       = vif.aruser;
                
                // Initialize arrays
                trans.post_randomize();
                
                // Add to queue for data phase matching
                read_addr_queue.push_back(trans);
                
                `uvm_info(get_type_name(), 
                    $sformatf("Read address captured: ID=0x%0h, ADDR=0x%0h, LEN=%0d", 
                        trans.id, trans.addr, trans.len), UVM_HIGH)
            end
        end
    endtask

    // Monitor read data channel
    task monitor_read_data();
        axi4_trans_t trans;
        int beat_count;
        int num_beats;
        
        forever begin
            @(posedge vif.aclk);
            
            if (vif.aresetn && vif.rvalid && vif.rready) begin
                // Find matching address transaction
                if (read_addr_queue.size() == 0) begin
                    `uvm_error(get_type_name(), "Read data without matching address")
                    continue;
                end
                
                if (beat_count == 0) begin
                    trans = read_addr_queue.pop_front();
                    num_beats = trans.len + 1;
                    beat_count = 0;
                end
                
                // Collect data beat
                trans.resp[beat_count] = axi4_resp_type_e'(vif.rresp);
                trans.ruser[beat_count] = vif.ruser;
                
                beat_count++;
                
                `uvm_info(get_type_name(), 
                    $sformatf("Read data beat %0d: DATA=0x%0h, RESP=%s", 
                        beat_count-1, vif.rdata, trans.resp[beat_count-1].name()), UVM_HIGH)
                
                // Check for last beat
                if (vif.rlast) begin
                    if (beat_count != num_beats) begin
                        `uvm_error(get_type_name(), 
                            $sformatf("RLAST mismatch: expected %0d beats, got %0d", 
                                num_beats, beat_count))
                    end
                    
                    // Send completed transaction
                    item_collected_port.write(trans);
                    
                    `uvm_info(get_type_name(), 
                        $sformatf("Read transaction completed:\n%s", trans.convert2string()), UVM_MEDIUM)
                    
                    beat_count = 0;
                end
            end
        end
    endtask

    // Collect functional coverage
    task collect_coverage();
        forever begin
            @(posedge vif.aclk);
            
            if (vif.aresetn) begin
                // Sample coverage on valid address phases
                if (vif.awvalid && vif.awready) begin
                    axi4_coverage.sample();
                end
                if (vif.arvalid && vif.arready) begin
                    axi4_coverage.sample();
                end
            end
        end
    endtask

    // Report phase
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), 
            $sformatf("Coverage: %.2f%%", axi4_coverage.get_coverage()), UVM_LOW)
    endfunction

endclass

`endif // AXI4_MASTER_MONITOR_SV
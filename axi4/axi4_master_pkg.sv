package axi4_master_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Users may override these defaults via parameter overrides when compiling
  parameter int ADDR_WIDTH = 32;
  parameter int DATA_WIDTH = 32;

  //--------------------------------------------------------------------
  // Sequence item
  //--------------------------------------------------------------------
  class axi4_master_seq_item extends uvm_sequence_item;
    rand logic [ADDR_WIDTH-1:0] addr;
    rand logic [DATA_WIDTH-1:0] data;
    rand bit                     write; // 1=write,0=read

    // Optional: strobe for write; default all active
    rand logic [DATA_WIDTH/8-1:0] wstrb;

    constraint c_wstrb { wstrb == '1; }

    `uvm_object_utils_begin(axi4_master_seq_item)
      `uvm_field_int(addr,   UVM_ALL_ON | UVM_DEC)
      `uvm_field_int(data,   UVM_ALL_ON | UVM_DEC)
      `uvm_field_int(write,  UVM_ALL_ON)
      `uvm_field_int(wstrb,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4_master_seq_item");
      super.new(name);
    endfunction : new
  endclass : axi4_master_seq_item

  //--------------------------------------------------------------------
  // Sequencer
  //--------------------------------------------------------------------
  class axi4_master_sequencer extends uvm_sequencer #(axi4_master_seq_item);
    `uvm_component_utils(axi4_master_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction : new
  endclass : axi4_master_sequencer

  //--------------------------------------------------------------------
  // Driver
  //--------------------------------------------------------------------
  typedef virtual axi4_if #(ADDR_WIDTH, DATA_WIDTH) axi4_vif_t;

  class axi4_master_driver extends uvm_driver #(axi4_master_seq_item);
    `uvm_component_utils(axi4_master_driver)

    axi4_vif_t vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(axi4_vif_t)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "Virtual interface must be set via config DB with field name 'vif'")
      end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      axi4_master_seq_item req;
      forever begin
        seq_item_port.get_next_item(req);
        if (req.write)
          drive_write(req);
        else
          drive_read(req);
        seq_item_port.item_done();
      end
    endtask : run_phase

    // -----------------------------------------
    // Write transaction
    // -----------------------------------------
    virtual task drive_write(axi4_master_seq_item tr);
      // Address phase
      @(posedge vif.ACLK);
      vif.AWADDR  <= tr.addr;
      vif.AWVALID <= 1'b1;
      do @(posedge vif.ACLK); while (!vif.AWREADY);
      vif.AWVALID <= 1'b0;

      // Data phase
      vif.WDATA  <= tr.data;
      vif.WSTRB  <= tr.wstrb;
      vif.WVALID <= 1'b1;
      do @(posedge vif.ACLK); while (!vif.WREADY);
      vif.WVALID <= 1'b0;

      // Response phase
      vif.BREADY <= 1'b1;
      do @(posedge vif.ACLK); while (!vif.BVALID);
      vif.BREADY <= 1'b0;
    endtask : drive_write

    // -----------------------------------------
    // Read transaction
    // -----------------------------------------
    virtual task drive_read(axi4_master_seq_item tr);
      // Address phase
      @(posedge vif.ACLK);
      vif.ARADDR  <= tr.addr;
      vif.ARVALID <= 1'b1;
      do @(posedge vif.ACLK); while (!vif.ARREADY);
      vif.ARVALID <= 1'b0;

      // Data phase
      vif.RREADY <= 1'b1;
      do @(posedge vif.ACLK); while (!vif.RVALID);
      tr.data = vif.RDATA; // capture data back into sequence item
      vif.RREADY <= 1'b0;
    endtask : drive_read

  endclass : axi4_master_driver

  //--------------------------------------------------------------------
  // Monitor (simple)
  //--------------------------------------------------------------------
  class axi4_master_monitor extends uvm_monitor;
    `uvm_component_utils(axi4_master_monitor)

    uvm_analysis_port #(axi4_master_seq_item) ap;
    axi4_vif_t vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(axi4_vif_t)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "Virtual interface must be set via config DB with field name 'vif'")
      end
    endfunction : build_phase

    // A minimal monitor capturing completed transactions
    virtual task run_phase(uvm_phase phase);
      axi4_master_seq_item item;
      forever begin
        // Capture write transactions
        @(posedge vif.ACLK);
        if (vif.AWVALID && vif.AWREADY) begin
          item = axi4_master_seq_item::type_id::create("mon_item");
          item.addr  = vif.AWADDR;
          item.write = 1;
          // capture data when W handshake completes
          do @(posedge vif.ACLK); while (!(vif.WVALID && vif.WREADY));
          item.data  = vif.WDATA;
          ap.write(item);
        end
        // Capture read transactions
        if (vif.ARVALID && vif.ARREADY) begin
          item = axi4_master_seq_item::type_id::create("mon_item");
          item.addr  = vif.ARADDR;
          item.write = 0;
          // capture data when R handshake completes
          do @(posedge vif.ACLK); while (!(vif.RVALID));
          item.data  = vif.RDATA;
          ap.write(item);
        end
      end
    endtask : run_phase
  endclass : axi4_master_monitor

  //--------------------------------------------------------------------
  // Agent
  //--------------------------------------------------------------------
  class axi4_master_agent extends uvm_agent;
    `uvm_component_utils(axi4_master_agent)

    axi4_master_sequencer m_sequencer;
    axi4_master_driver    m_driver;
    axi4_master_monitor   m_monitor;

    uvm_analysis_port #(axi4_master_seq_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (is_active == UVM_ACTIVE) begin
        m_sequencer = axi4_master_sequencer::type_id::create("m_sequencer", this);
        m_driver    = axi4_master_driver   ::type_id::create("m_driver",    this);
      end
      m_monitor     = axi4_master_monitor  ::type_id::create("m_monitor",   this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (is_active == UVM_ACTIVE) begin
        m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
      end
      // broadcast monitor observations
      m_monitor.ap.connect(ap);
    endfunction : connect_phase

  endclass : axi4_master_agent

endpackage : axi4_master_pkg
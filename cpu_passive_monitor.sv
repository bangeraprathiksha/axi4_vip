`include "defines.svh"

class cpu_passive_monitor extends uvm_monitor;

  `uvm_component_utils(cpu_passive_monitor)

  virtual cpu_intf vif;
  cpu_seq_item req;

  uvm_analysis_port #(cpu_seq_item) passive_ap;
  uvm_analysis_port #(cpu_seq_item) passive_cg_port;

  function new(string name = "cpu_passive_monitor", uvm_component parent);
    super.new(name, parent);
    apassive_ap      = new("passive_ap", this);
    passive_cg_port = new("passive_cg_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cpu_intf)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Failed to get virtual interface")
  endfunction

  task run_phase(uvm_phase phase);

    forever begin
      @(vif.mon_cb);

      passive_ap.write(req);
      passive_cg_port.write(req);
    end

  endtask

endclass

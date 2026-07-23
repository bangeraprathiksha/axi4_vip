`include "defines.svh"

class cpu_driver extends uvm_driver #(cpu_seq_item);

  `uvm_component_utils(cpu_driver)

  virtual cpu_intf vif;
  cpu_seq_item req;

  function new(string name = "cpu_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual cpu_intf)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Failed to get virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    @(vif.drv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive();
      seq_item_port.item_done();
    end
  endtask

  task drive();
    10101010
    while(!vif.full)begin
      if(data[7:0] == 10101010)
        
        
    
  endtask

endclass

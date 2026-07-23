`include "defines.svh"

class cpu_sequence extends uvm_sequence#(cpu_seq_item);
  `uvm_object_utils(cpu_sequence)
  
  function new(string name = "cpu_sequence");
    super.new(name);
  endfunction
  
  task body();
    cpu_seq_item req;
    repeat(`no_of_trans) begin
      req = cpu_seq_item::type_id::create("req");
      start_item(req);
      	if(!req.randomize())
        	`uvm_fatal("SEQ","randomization failed!")
      finish_item(req);
    end
  endtask
endclass

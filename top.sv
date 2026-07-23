`include "uvm_macros.svh"
import uvm_pkg::*;

`include "cpu_pkg.sv"
import cpu_pkg::*;

`include "cpu_intf.sv"
`include "defines.svh"

module top;

  logic clk;

  initial begin
    clk = 0;
    forever #5 clk = ~clk; //100Mhz
  end

  cpu_intf intf (.clk(clk));

  initial begin
    uvm_config_db#(virtual cpu_intf)::set(null,"*","vif",intf);
    run_test("cpu_test");
  end
  
  bind top fifo_assertions fifo_assert_inst(intf);

endmodule

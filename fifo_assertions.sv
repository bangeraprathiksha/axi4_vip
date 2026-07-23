module fifo_assertions(cpu_intf vif);

property p_fifo_empty_reset;
   @(posedge vif.clk)
   vif.rst |=> vif.empty;
endproperty

assert property(p_fifo_empty_reset)
   else $error("FIFO Empty reset assertion failed");

property p_rddata_reset;
   @(posedge vif.clk)
   vif.rst |=> (vif.rd_data == '0);
endproperty

assert property(p_rddata_reset)
   else $error("Read Data reset assertion failed");

property p_no_write_when_full;
   @(posedge vif.clk)
  disable iff(!vif.rst)
   vif.full |-> !vif.wr_en;
endproperty

assert property(p_no_write_when_full)
   else $error("Write attempted when FIFO Full");


property p_wr_data_valid;
   @(posedge vif.clk)
  disable iff(!vif.rst)
   vif.wr_en && !vif.full |-> !$isunknown(vif.wr_data);
endproperty

assert property(p_wr_data_valid)
   else $error("wr_data contains X/Z");


property p_no_read_when_empty;
   @(posedge vif.clk)
  disable iff(!vif.rst)
   vif.empty |-> !vif.rd_en;
endproperty

assert property(p_no_read_when_empty)
   else $error("Read attempted when FIFO Empty");


property p_rd_data_valid;
   @(posedge vif.clk)
  disable iff(!vif.rst)
   vif.rd_en && !vif.empty |-> !$isunknown(vif.rd_data);
endproperty

assert property(p_rd_data_valid)
   else $error("rd_data contains X/Z");


endmodule

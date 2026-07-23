`include "defines.svh"
`uvm_analysis_imp_decl(_cpu)
`uvm_analysis_imp_decl(_slave)

class cpu_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(cpu_scoreboard)

  uvm_analysis_imp_cpu  #(cpu_seq_item, cpu_scoreboard) cpu_imp;
  uvm_analysis_imp_slave#(cpu_seq_item, cpu_scoreboard) slave_imp;

  // FIFO Model (Write FIFO)
  bit is_write;
  bit [127:0] fifo_mem [0:4095];
  int wr_ptr;
  int rd_ptr;
  bit empty;
  bit full; 
  bit [127:0] rd_data;
  localparam  bit[7:0] SOP = 8'b10101010;
  localparam  bit[7:0] EOP = 8'b01010011;
  bit start_pkt_collect;
  int pkt_start_ptr;
  
  int pkt_start_q[$];
  int pkt_end_q[$];
  
  
  typedef struct {
    bit [3:0]     txn_id;
    bit [31:0]    addr;
    bit [3:0]     len;
    bit [2:0]     size;
    bit [1:0]     burst;
    bit [1:0]     lock;
    bit [1:0]     cache;
    bit [2:0]     prot;
    bit [3:0]     strobe;
    bit [1023:0]  data;
 } exp_write_pkt_t;

  typedef struct {
    bit [3:0]  txn_id;
    bit [31:0] addr;
    bit [3:0]  len;
    bit [2:0]  size;
    bit [1:0]  burst;
    bit [1:0]  lock;
    bit [1:0]  cache;
    bit [2:0]  prot;
  } exp_read_pkt_t;

  exp_read_pkt_t exp_read_q[$];  
  exp_write_pkt_t exp_write_q[$];
 
  

  function new(string name = "cpu_scoreboard",uvm_component parent);
    super.new(name,parent);
    cpu_imp   = new("cpu_imp",this);
    slave_imp = new("slave_imp",this);
    wr_ptr = 0;
    rd_ptr = 0;
    start_pkt_collect = 0;
    empty = 1;
    full = 0;
    
  endfunction

  // CPU Monitor writes into FIFO
  function void cpu_write(cpu_seq_item t);
    if(!t.wr_en)
      return;

    // Start Of Packet
    if(!start_pkt_collect && (t.wr_data[127:120] == SOP)) begin
      start_pkt_collect = 1;
      pkt_start_ptr     = wr_ptr;
      fifo_mem[wr_ptr] = t.wr_data;
      
      `uvm_info("SB",$sformatf("SOP : FIFO[%0d] <= %032h",wr_ptr,t.wr_data),UVM_LOW)
      wr_ptr++;
      
    end

    // Middle / End Packet
    else if(start_pkt_collect) begin
      fifo_mem[wr_ptr] = t.wr_data;
      
      `uvm_info("SB",$sformatf("FIFO[%0d] <= %032h",wr_ptr,t.wr_data),UVM_LOW)

      if(t.wr_data[7:0] == EOP) begin
        start_pkt_collect = 0;
        
        pkt_start_q.push_back(pkt_start_ptr);
        pkt_end_q.push_back(wr_ptr);
        
        `uvm_info("SB",$sformatf("Packet Stored : FIFO[%0d] -> FIFO[%0d]",pkt_start_ptr,wr_ptr),UVM_LOW)
        // run_phase() will decode this packet
        
      end
      wr_ptr++;
      
    end
    
    else begin
      `uvm_error("SB","Received data without SOP")
    end

endfunction
  
  
  // AXI Slave Monitor
 
  function void slave_write(slave_seq_item t);
    if(is_write)
        compare_write(t);
    else
        compare_read(t);

  endfunction

  task fifo_read_w(input int start_ptr,input int end_ptr);
    rd_ptr = start_ptr;

    while(rd_ptr <= end_ptr) begin
        rd_data = fifo_mem[rd_ptr];
        // Give one FIFO word to decoder
        decoder_write(rd_data);
        rd_ptr++;
    end

    empty = (wr_ptr == rd_ptr);
    full  = ((wr_ptr-rd_ptr) == 4096);

  endtask
  
  task fifo_read_r(input int start_ptr);
    rd_ptr = start_ptr;
    rd_data = fifo_mem[rd_ptr];
    // Give one FIFO word to decoder
    decoder_read(rd_data);
    rd_ptr++;
    
    empty = (wr_ptr == rd_ptr);
    full  = ((wr_ptr-rd_ptr) == 4096);

  endtask
  
  
  task decoder_write(bit [127:0] fifo_word);
    
    static bit [1151:0] wr_packet;
    static int word_cnt_w;

    wr_packet[1151 - (word_cnt_w*128) -:128] = fifo_word;

    word_cnt++;

    if(fifo_word[7:0] == EOP) begin

      bit [1095:0] actual_w_packet;

        actual_w_packet = wr_packet[1151 -: 1096];// last 55 bits are 0

        decode_w_packet(actual_w_packet);

        wr_packet   = '0;
        word_cnt_w = 0;

    end

  endtask
  
  task decoder_read(bit [127:0] fifo_word);

    bit [127:0] rd_packet;

    rd_packet = fifo_word;

    if(fifo_word[7:0] == EOP) begin

      bit [79:0] actual_r_packet;

      actual_r_packet = rd_packet[127:47];

      decode_r_packet(actual_packet);

      rd_packet   = '0;
        
    end

  endtask
  
  
  task decode_w_packet(bit [1095:0] pkt);
    
    // Decode fields
    bit [7:0] sop;
    bit [3:0] txn_id;
    bit [31:0] addr;
    bit [3:0] len;
    bit [2:0] size;
    bit [1:0] burst;
    bit [1:0] lock;
    bit [1:0] cache; 
    bit [2:0] prot;
    bit [3:0] strobe;
    bit [1023:0] data;
    bit [7:0] eop;
    
    sop    = pkt[1095 -: 8];
    txn_id = pkt[1087 -: 4];
    addr   = pkt[1083 -: 32];
    len    = pkt[1051 -: 4];
    size   = pkt[1047 -: 3];
    burst  = pkt[1044 -: 2];
    lock   = pkt[1042 -: 2]; 
    cache  = pkt[1040 -: 2];
    prot   = pkt[1038 -: 3];
    strobe = pkt[1035 -: 4];
    data   = pkt[1031 -: 1024];
    eop    = pkt[7:0];

    // Check SOP/EOP
    if(sop != SOP)
      `uvm_error("DECODER","Invalid SOP")
    if(eop != EOP)
      `uvm_error("DECODER","Invalid EOP")
      
    // Determine Packet Type
    
      exp_write_pkt_t write_pkt;
      
      write_pkt.txn_id = txn_id;
      write_pkt.addr   = addr;
      write_pkt.len    = len;
      write_pkt.size   = size;
      write_pkt.burst  = burst;
      write_pkt.lock   = lock;
      write_pkt.cache  = cache;
      write_pkt.prot   = prot;
      write_pkt.strobe = strobe;
      write_pkt.data   = data;
      exp_write_q.push_back(write_pkt);

  endtask
  
  task decode_r_packet(bit [79:0] pkt);
    
    // Decode fields
    bit [7:0] sop;
    bit [3:0] txn_id;
    bit [31:0] addr;
    bit [3:0] len;
    bit [2:0] size;
    bit [1:0] burst;
    bit [1:0] lock;
    bit [1:0] cache; 
    bit [2:0] prot;
    bit [3:0] strobe;
    bit [7:0] data;
    bit [7:0] eop;
    
    sop    = pkt[79 -: 8];   
    txn_id = pkt[71 -: 4];     
    addr   = pkt[67 -: 32];   
    len    = pkt[35 -: 4];    
    size   = pkt[31 -: 3];
    burst  = pkt[28 -: 2];     
    lock   = pkt[26 -: 2];     
	cache  = pkt[24 -: 2];      
	prot   = pkt[22 -: 3];     
	strobe = pkt[19 -: 4];      
	data   = pkt[15 -: 8];      
	eop    = pkt[7:0];         

    // Check SOP/EOP
    if(sop != SOP)
      `uvm_error("DECODER","Invalid SOP")
    if(eop != EOP)
      `uvm_error("DECODER","Invalid EOP")
      
    // Determine Packet Type
    
      exp_read_pkt_t read_pkt;
      
      read_pkt.txn_id = txn_id;
      read_pkt.addr   = addr;
      read_pkt.len    = len;
      read_pkt.size   = size;
      read_pkt.burst  = burst;
      read_pkt.lock   = lock;
      read_pkt.cache  = cache;
      read_pkt.prot   = prot;
      read_pkt.strobe = strobe;
      read_pkt.data   = data;
      exp_read_q.push_back(read_pkt);

  endtask
  
  task run_phase(uvm_phase phase);

    forever begin

        // Wait until complete packet is available
      wait(pkt_start_q.size() > 0 && pkt_end_q.size() > 0);

        int start_ptr;
        int end_ptr;

        start_ptr = pkt_start_q.pop_front();
        end_ptr   = pkt_end_q.pop_front();
        if(start_ptr == end_ptr)begin
            is_write=0;
        	fifo_read_r(start_ptr);
        end
        else begin
            is_write = 1;
            fifo_read_w(start_ptr,end_ptr);
        end
        is_write=0;

    end

  endtask

endclass

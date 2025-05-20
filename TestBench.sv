`include "uvm_macros.svh"
 import uvm_pkg::*;


//                                            Active Agent 

class uart_config extends uvm_object;
  `uvm_object_utils(uart_config)
  
  function new(string name = "uart_config");
    super.new(name);
  endfunction
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
endclass

//                                          Transaction 


class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)

   function new(string name = "transaction");
    super.new(name);
  endfunction
  
         logic tx_start, rx_start;
         logic rst;
    rand logic [7:0] tx_data;
    rand logic [16:0] baud;
    rand logic [3:0] length; 
    rand logic parity_type, parity_en;
         logic stop2;
         logic tx_done, rx_done, tx_err, rx_err;
         logic [7:0] rx_out;
  

  
  constraint baud_c { baud inside {4800,9600,14400,19200,38400,57600}; }
  constraint length_c { length inside {5,6,7,8}; }

 

endclass 


//                                       Generation  

class  generation extends uvm_sequence#(transaction);
  `uvm_object_utils(generation)
  
  transaction tr;

  function new(string name = "generation");
    super.new(name);
  endfunction
 
  virtual task body();
    repeat(5)
      begin
     
        tr = transaction::type_id::create("tr");
        
        start_item(tr);
        
        assert(tr.randomize());
        tr.length    = 8;  
        tr.tx_start  = 1'b1;
        tr.rx_start  = 1'b1;
        tr.parity_en = 1'b1;
        tr.stop2     = 1'b0;
       
       
        `uvm_info("GEN", $sformatf("tx_data: %0d , baud :%0d ,length : %0d , parity_type : %0d , parity_en :%0d", tr.tx_data, tr.baud ,tr.length, tr.parity_type, tr.parity_en), UVM_NONE);
        
        finish_item(tr);     
      
      end
  endtask 
  
endclass

///                                          Driver    

class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  virtual uart_if vif;
  transaction tr;
  
  
  function new(input string path = "drv", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
 virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     tr = transaction::type_id::create("tr");
      
   if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif)) 
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  
  
  task reset_dut();

    repeat(5) 
    begin
    vif.rst      <= 1'b1;  
    vif.tx_start <= 1'b0;
    vif.rx_start <= 1'b0;
    vif.tx_data  <= 8'h00;
    vif.baud     <= 16'h0;
    vif.length   <= 4'h0;
    vif.parity_type <= 1'b0;
    vif.parity_en   <= 1'b0;
    vif.stop2  <= 1'b0;
   `uvm_info("DRV", "System Reset : Start of Simulation", UVM_MEDIUM);
    @(posedge vif.clk);
      end
  endtask
  
  task drive();
    reset_dut();
   forever begin
     
         seq_item_port.get_next_item(tr);
     
                                             
                            vif.rst         <= 1'b0;
                            vif.tx_start    <= tr.tx_start;
                            vif.rx_start    <= tr.rx_start;
                            vif.tx_data     <= tr.tx_data;
                            vif.baud        <= tr.baud;
                            vif.length      <= tr.length;
                            vif.parity_type <= tr.parity_type;
                            vif.parity_en   <= tr.parity_en;
                            vif.stop2       <= tr.stop2;
     
     
     `uvm_info("DRV", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d", tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data), UVM_NONE);
                           
     @(posedge vif.clk); 
     @(posedge vif.tx_done);
      @(negedge vif.rx_done);
                     
     
       seq_item_port.item_done();
    end
  endtask  

  virtual task run_phase(uvm_phase phase);
    drive();
  endtask

  
endclass

///                                       Monitor

class mon extends uvm_monitor;
`uvm_component_utils(mon)

uvm_analysis_port#(transaction) send;
transaction tr;
virtual uart_if vif;

    function new(input string inst = "mon", uvm_component parent = null);
    super.new(inst,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    send = new("send", this);
      if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
        `uvm_error("MON","Unable to access Interface");
    endfunction
    
    
    virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if(vif.rst)
        begin
          tr.rst = 1'b1;
        
          `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
       
          send.write(tr);
        end
      else
         begin
        
           @(posedge vif.tx_done);
        
         tr.rst         = 1'b0;
         tr.tx_start    = vif.tx_start;
         tr.rx_start    = vif.rx_start;
         tr.tx_data     = vif.tx_data;
         tr.baud        = vif.baud;
         tr.length      = vif.length;
         tr.parity_type = vif.parity_type;
         tr.parity_en   = vif.parity_en;
         tr.stop2       = vif.stop2;
        
           @(negedge vif.rx_done);
         
         tr.rx_out      = vif.rx_out;
           
           `uvm_info("MON", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d RX_DATA:%0d", tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data, tr.rx_out), UVM_NONE);
          
           send.write(tr);
         end
    
    
    end
   endtask 
   
endclass
//                                          Scoreboard 

class sco extends uvm_scoreboard;
`uvm_component_utils(sco)

  uvm_analysis_imp#(transaction,sco) recv;
 
  bit [31:0] arr[32] = '{default:0};
  bit [31:0] addr    = 0;
  bit [31:0] data_rd = 0;
 
    function new(input string inst = "sco", uvm_component parent = null);
    super.new(inst,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
    endfunction
    
  
  virtual function void write(transaction tr);
    `uvm_info("SCO", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d RX_DATA:%0d", tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data, tr.rx_out), UVM_NONE);
    if(tr.rst == 1'b1)
      `uvm_info("SCO", "System Reset", UVM_NONE)
    else if(tr.tx_data == tr.rx_out)
      `uvm_info("SCO", "Test Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE)
    $display("----------------------------------------------------------------");
    endfunction

endclass


///                                      Agent 
                  
                  
class agent extends uvm_agent;
`uvm_component_utils(agent)
  
  uart_config cfg;

function new(input string inst = "agent", uvm_component parent = null);
super.new(inst,parent);
endfunction

 driver d;
 uvm_sequencer#(transaction) seqr;
 mon m;


virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
   cfg =  uart_config::type_id::create("cfg"); 
   m = mon::type_id::create("m",this);
  
  if(cfg.is_active == UVM_ACTIVE)
   begin   
   d = driver::type_id::create("d",this);
   seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
   end
  
  
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
  if(cfg.is_active == UVM_ACTIVE) begin  
    d.seq_item_port.connect(seqr.seq_item_export);
  end
endfunction

endclass

///                                    Enviroment 

class env extends uvm_env;
`uvm_component_utils(env)

function new(input string inst = "env", uvm_component c);
super.new(inst,c);
endfunction

agent a;
sco s;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  a = agent::type_id::create("a",this);
  s = sco::type_id::create("s", this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
 a.m.send.connect(s.recv);
endfunction

endclass

///                                     Test 

class test extends uvm_test;
`uvm_component_utils(test)

function new(input string inst = "test", uvm_component c);
super.new(inst,c);
endfunction


env e;
generation gen;

  
  
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  
   e       = env::type_id::create("env",this);
   gen     =generation::type_id::create("gen",this);
   
  
endfunction

virtual task run_phase(uvm_phase phase);

phase.raise_objection(this);
gen.start(e.a.seqr);

#20;
phase.drop_objection(this);

endtask
endclass

//                                        TestBench 


module tb;
  
  
  uart_if vif();
 
  
  uart_top dut (.clk(vif.clk), .rst(vif.rst), .tx_start(vif.tx_start), .rx_start(vif.rx_start), .tx_data(vif.tx_data), .baud(vif.baud), .length(vif.length), .parity_type(vif.parity_type), .parity_en(vif.parity_en),.stop2(vif.stop2),.tx_done(vif.tx_done), .rx_done(vif.rx_done), .tx_err(vif.tx_err), .rx_err(vif.rx_err), .rx_out(vif.rx_out));
  
  initial begin
    vif.clk <= 0;
  end

  always #10 vif.clk <= ~vif.clk;

  
  
  initial begin
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
    run_test("test");
   end
  
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  
endmodule

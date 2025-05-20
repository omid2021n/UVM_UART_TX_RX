
`timescale 1ns / 1ps
​
//                                   Clock generator
​
​
module clk_gen(
input clk, rst,
input [16:0] baud,
output reg tx_clk, rx_clk
);
​
int rx_max =0, tx_max = 0;
int rx_count = 0 , tx_count = 0;
​
​
always@(posedge clk) begin
        if(rst)begin
            rx_max <= 0;
            tx_max <= 0;    
            end
        else begin      
            case(baud)
                4800 :  begin
                          rx_max <=11'd651;
                          tx_max <=14'd10416;   
                        end
                9600  : begin
                          rx_max <=11'd325;
                          tx_max <=14'd5208;
                        end
                14400 : begin 
                          rx_max <=11'd217;
                          tx_max <=14'd3472;
                         end
                19200 : begin 
                          rx_max <=11'd163;
                          tx_max <=14'd2604;
                        end
                38400: begin
                          rx_max <=11'd81;
                          tx_max <=14'd1302;
                        end
                57600 : begin 
                          rx_max <=11'd54;
                          tx_max <=14'd868; 
                        end                         
                115200: begin 
                          rx_max <=11'd27;
                          tx_max <=14'd434; 
                        end
                128000: begin 
                          rx_max <=11'd24;
                          tx_max <=14'd392; 
                        end
                 default: begin 
                          rx_max <=11'd325;
                          tx_max <=14'd5208;    
                         end
            endcase
        end
    end
​
//                                          Rx clk 
  
always@(posedge clk)
begin

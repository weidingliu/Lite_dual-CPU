`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/08 21:47:15
// Design Name: 
// Module Name: alu_fu_ex_mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu_fu_ex_mem(
input wire clk,
    input wire rest,
    input wire[`RegAddrBus] ex_wd,
	input wire ex_wreg,
	input wire[`RegBus] ex_wdata, 
	
    input wire [5:0] stop,
   
    
    input wire                   flush,

    output reg[`RegAddrBus] mem_wd,
	output reg mem_wreg,
	output reg[`RegBus] mem_wdata

    );
    always @(posedge clk) begin 
        if(rest==`RstEnable) begin 
            mem_wd<=`NOPRegAddr;
            mem_wreg<=`WriteDisable;
            mem_wdata<=`ZeroWord;
            
        end
        else if(flush==1'b1) begin 
             mem_wd<=`NOPRegAddr;
            mem_wreg<=`WriteDisable;
            mem_wdata<=`ZeroWord;
            
        end
        else if (stop[3]==`Stop&& stop[4]==`NoStop) begin 
            mem_wd<=`NOPRegAddr;
            mem_wreg<=`WriteDisable;
            mem_wdata<=`ZeroWord;
            
        end

        else if (stop[3]==`NoStop)  begin
         mem_wd<=ex_wd;
         mem_wreg<=ex_wreg;
         mem_wdata<=ex_wdata;   

        end

        else begin 

        
        end
    end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/08 21:47:43
// Design Name: 
// Module Name: alu_fu_mem_wb
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


module alu_fu_mem_wb(
 input wire clk,
    input wire rest,
    input wire[`RegAddrBus] mem_wd_o,
	input wire mem_wreg_o,
	input wire[`RegBus] mem_wdata_o,
	//
	
	
	input wire [5:0] stop,

	input wire flush,
	
	output reg[`RegAddrBus] wb_wd_o,
	output reg wb_wreg_o,
	output reg[`RegBus] wb_wdata_o

    );
    always@(posedge clk) begin 
        if(rest==`RstEnable)   begin
            wb_wd_o<= `NOPRegAddr;
            wb_wreg_o<= `WriteDisable;
            wb_wdata_o<=`ZeroWord;

        end  
        else if(flush ==1'b1) begin 
            wb_wd_o<= `NOPRegAddr;
            wb_wreg_o<= `WriteDisable;
            wb_wdata_o<=`ZeroWord;
        end
        else if (stop[4]==`Stop&&stop[5]==`NoStop)begin 
            wb_wd_o<= `NOPRegAddr;
            wb_wreg_o<= `WriteDisable;
            wb_wdata_o<=`ZeroWord;
        end
        else if(stop[4]==`NoStop) begin 
            wb_wd_o<= mem_wd_o;
            wb_wreg_o<=mem_wreg_o;
            wb_wdata_o<=mem_wdata_o; 

        end
        else begin 
        
        end
    end
endmodule

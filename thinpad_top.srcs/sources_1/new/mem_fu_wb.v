`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/17 15:24:01
// Design Name: 
// Module Name: mem_fu_wb
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


module mem_fu_wb(
    input wire clk,
    input wire rst,
    input wire [5:0] stop,
    input wire flush,
    
    input wire wb_valid_i,
    input wire[`RegAddrBus]      wb_wd_i,
	input wire                   wb_wreg_i,
	input wire [`RegBus]           wb_data_i,
	
    output reg[`RegAddrBus]      wb_wd,
	output reg                   wb_wreg,
	output reg [`RegBus]           wb_data,
	output reg wb_valid
    );
     always @(posedge clk) begin
        if(rst==`RstEnable) begin
            wb_wd<=`NOPRegAddr;
            wb_wreg<=`WriteDisable;
            wb_data<=`ZeroWord;
            wb_valid<=1'b0;

        end    
        else if(flush==1'b1) begin 

            wb_wd<=`NOPRegAddr;
            wb_wreg<=`WriteDisable;
            wb_data<=`ZeroWord;
            wb_valid<=1'b0;
        end
      /*  else if (stop[]==`Stop&&stop[5]==`NoStop)begin 
            wb_wd<=`NOPRegAddr;
            wb_wreg<=`WriteDisable;
            wb_data<=`ZeroWord;
            wb_valid<=1'b0;
        end*/
        else if(stop[5]==`NoStop) begin 
            if(wb_valid_i==1'b1) begin 
                wb_wd<=wb_wd_i;
                wb_wreg<=wb_wreg_i;
                wb_data<=wb_data_i;
                wb_valid<=wb_valid_i;
            end
            else begin 
                wb_wd<=`NOPRegAddr;
            wb_wreg<=`WriteDisable;
            wb_data<=`ZeroWord;
            wb_valid<=1'b0;
            end
            
        end
        else begin 
            
        end
    end
    
    
endmodule

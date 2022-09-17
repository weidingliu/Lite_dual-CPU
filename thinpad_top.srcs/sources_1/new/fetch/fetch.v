`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/21 11:09:04
// Design Name: 
// Module Name: fetch
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

//`include "defines.v"
module fetch(
    input wire clk,
    input wire rst,
    input wire [`InstAddrBus] npc,
    output reg  [`InstAddrBus] pc,
    output reg inst_req
    );
    always @(posedge clk) begin 
        if(rst==`RstEnable) begin
            pc<=32'h00000000;
            inst_req<=1'b1;
        end
        else begin 
            
            pc<=npc;
            inst_req<=1'b0;
        end
    end
    
    
endmodule

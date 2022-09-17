`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/04 11:02:59
// Design Name: 
// Module Name: if_id
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


module IF_ID(
    input wire rest,
    input wire clk,
    input wire is_single,
    input wire[`InstAddrBus] if_pc1,
    input wire[`InstBus] if_inst1,
    input wire[`InstAddrBus] if_pc2,
    input wire[`InstBus] if_inst2,
    
    input wire inst_flush,
    input wire cache_data_valid,
    
    input wire [5:0] stop,
    input wire flush,

    output reg is_single_o,
    
    output reg[`InstAddrBus] id_pc1,
    output reg[`InstBus] id_inst1, 

    output reg[`InstAddrBus] id_pc2,
    output reg[`InstBus] id_inst2,
    
    output reg inst_valid
    );
    always @(posedge clk) begin
        if(rest==`RstEnable) begin
            id_pc1<=`ZeroWord;
            id_inst1<=`ZeroWord;
            id_pc2<=`ZeroWord;
            id_inst2<=`ZeroWord;
            is_single_o<=1'b0;
            
            inst_valid<=`InValid;
            
        end
        else if(flush==1'b1) begin 
            id_pc1<=`ZeroWord;
            id_inst1<=`ZeroWord;
            id_pc2<=`ZeroWord;
            id_inst2<=`ZeroWord;
            is_single_o<=1'b0;
            
            inst_valid<=`InValid;
        end
        else if(inst_flush==1'b1) begin 
            id_pc1<=`ZeroWord;
            id_inst1<=`ZeroWord;
            id_pc2<=`ZeroWord;
            id_inst2<=`ZeroWord;
            is_single_o<=1'b0;
            
            inst_valid<=`InValid;
        end
        else if(stop[1]==`Stop && stop[2]==`NoStop) begin
            id_pc1<=`ZeroWord;
            id_inst1<=`ZeroWord;
            id_pc2<=`ZeroWord;
            id_inst2<=`ZeroWord;
            is_single_o<=1'b0;
            
            inst_valid<=`InValid;
        end
        else if (stop[1]==`NoStop && cache_data_valid==`Valid)begin
            if(is_single==1'b1) begin 
                id_pc1<=if_pc1;
                id_inst1<=if_inst1;
                id_pc2<=`ZeroWord;
                id_inst2<=`ZeroWord;
                is_single_o<=1'b1;
                
                inst_valid<=`Valid;
            end
            else begin 
                id_pc1<=if_pc1;
                id_inst1<=if_inst1;
                id_pc2<=if_pc2;
                id_inst2<=if_inst2;
                is_single_o<=1'b0;
                
                inst_valid<=`Valid;
            end
            
        end
        else begin 
            //ÔÝÍ£È¡Ö¸
            inst_valid<=`InValid;
        end
    end
    
    
endmodule

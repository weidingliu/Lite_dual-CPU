`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/08 16:40:36
// Design Name: 
// Module Name: id_alu_exe
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


module id_alu_exe(
    input wire clk,
    input wire rest,
    input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
    input wire [5:0] stop,
    input wire fu_valid,//是否使用这个fu
   // input wire id_is_in_delayslot,
   // input wire[`RegBus] id_link_addr,
   // input wire next_in_delayslot,
   // input wire[`RegBus] inst_i,
    
    input wire flush,
    input wire[`RegBus] link_addr_i,
    output reg[`RegBus] link_addr_o,
    
    output reg[`AluOpBus]         aluop_o,
	output reg[`AluSelBus]        alusel_o,
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	
	input wire next_in_delaysolt,
	output reg is_in_delaysolt,
	
	input wire buffer_flush_i,
	output reg buffer_flush_o
	//output reg ex_is_in_delayslot,
	//output reg [`RegBus]ex_link_addr,
	//output reg is_in_delayslot_o,
	//output reg[`RegBus] inst_o,
	

    );
    always @(posedge clk) begin
        if(rest==`RstEnable) begin
            aluop_o<=`EXE_NOP_OP;
            alusel_o<=`EXE_RES_NOP;
            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            link_addr_o<=`ZeroWord;
            
            is_in_delaysolt<= `NotInDelaySlot;
            buffer_flush_o<=1'b0;
            /*
            inst_o<=`ZeroWord;

	        ex_link_addr <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
	        is_in_delayslot_o <= `NotInDelaySlot;	*/
        end    
        else if(flush==1'b1) begin 
            aluop_o<=`EXE_NOP_OP;
            alusel_o<=`EXE_RES_NOP;
            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            link_addr_o<=`ZeroWord;
            is_in_delaysolt<= `NotInDelaySlot;
            buffer_flush_o<=1'b0;
           /*
            inst_o<=`ZeroWord;

	        ex_link_addr <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
	        is_in_delayslot_o <= `NotInDelaySlot;
	        ex_link_addr <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;*/
        end
        else if (stop[2]==`Stop&&stop[3]==`NoStop) begin 
            aluop_o<=`EXE_NOP_OP;
            alusel_o<=`EXE_RES_NOP;
            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            link_addr_o<=`ZeroWord;
            is_in_delaysolt<= `NotInDelaySlot;
            buffer_flush_o<=1'b0;
            //inst_o<=`ZeroWord;
        end
        else if(stop[2]==`Stop) begin 
        
        end
        
        else if(fu_valid==1'b0) begin 
            aluop_o<=`EXE_NOP_OP;
            alusel_o<=`EXE_RES_NOP;
            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            link_addr_o<=`ZeroWord;
            is_in_delaysolt<= next_in_delaysolt;
            buffer_flush_o<=buffer_flush_i;
        end
        else if (stop[2]==`NoStop&&fu_valid==1'b1)begin
            aluop_o<=aluop_i;
            alusel_o<=alusel_i;
            reg1_o<= reg1_i;
            reg2_o<=reg2_i;
            wd_o<=wd_i;
            wreg_o<=wreg_i;
            link_addr_o<=link_addr_i;
            is_in_delaysolt<= next_in_delaysolt;
            buffer_flush_o<=buffer_flush_i;
            /*ex_link_addr<=id_link_addr;
            ex_is_in_delayslot<=id_is_in_delayslot;
            is_in_delayslot_o<=next_in_delayslot;
            inst_o<=inst_i;*/

        end
        else begin 
        
        end
    end
endmodule

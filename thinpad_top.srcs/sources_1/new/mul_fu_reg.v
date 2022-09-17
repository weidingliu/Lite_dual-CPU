`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/11 12:35:08
// Design Name: 
// Module Name: mul_fu_reg
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
`include"defines.v"

module mul_fu_reg(
    input wire clk,
    input wire rst,
    input wire[`AluOpBus]         aluop_i,
    
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
    input wire[1:0]is_busy,
    input wire[2:0]mul_fu_state,
    

	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg wb_valid,//指示乘法是否结束
	
	output wire [31:0]wdata_o,
	input wire [63:0] p
    );
    reg [31:0]A;
    reg [31:0]B;
    reg [63:0] hilo_temp;
    reg [`AluOpBus]aluop_o;
    reg [`RegBus]  reg1_temp,reg2_temp;
    
    always @ (*) begin
		if(rst == `RstEnable) begin
			hilo_temp = {`ZeroWord,`ZeroWord};
		end 

		else if ((aluop_o == `EXE_MULT_OP) || (aluop_o == `EXE_MUL_OP))begin
			if(reg1_temp[31] ^ reg2_temp[31] == 1'b1) begin
				hilo_temp = ~p + 1;
			end else begin
			  hilo_temp = p;
			end
		end 
		else begin
				hilo_temp = p;
		end
	end
    assign wdata_o=hilo_temp[31:0];
    
        //取得乘法操作的操作数，如果是有符号除法且操作数是负数，那么取反加一
    always @(*) begin 
         A = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
	    B = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;
    end
    
    always @(posedge clk) begin
        if(rst==`RstEnable) begin

            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            wb_valid<=1'b0;
            //内部操作数保存
            aluop_o<=`EXE_NOP_OP;
            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            /*
            inst_o<=`ZeroWord;

	        ex_link_addr <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
	        is_in_delayslot_o <= `NotInDelaySlot;	*/
        end    
        else if(flush==1'b1) begin 

            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            wb_valid<=1'b0;
            
            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            aluop_o<=`EXE_NOP_OP;
           /*
            inst_o<=`ZeroWord;

	        ex_link_addr <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
	        is_in_delayslot_o <= `NotInDelaySlot;
	        ex_link_addr <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;*/
        end
        else if (stop[2]==`Stop&&stop[3]==`NoStop) begin 

            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            wb_valid<=1'b0;
            
            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            aluop_o<=`EXE_NOP_OP;
            //inst_o<=`ZeroWord;
        end
        else if(is_busy[0]==1'b1 && mul_fu_state[0]!=1'b1) begin 
            if(mul_fu_state[1]==1'b1) begin 
                wb_valid<=1'b1;
            end
            else begin 
                wb_valid<=1'b0;
            end
        end
        else if(fu_valid==1'b0) begin 

            reg1_o<=`ZeroWord;
            reg2_o<=`ZeroWord;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            wb_valid<=1'b0;
            
            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            aluop_o<=`EXE_NOP_OP;
        end
        else if (stop[2]==`NoStop&&fu_valid==1'b1)begin

            reg1_o<= A;
            reg2_o<=B;
            wd_o<=wd_i;
            wreg_o<=wreg_i;
            wb_valid<=1'b0;
            
            reg1_temp<=reg1_i;
            reg2_temp<=reg2_i;
            aluop_o<=aluop_i;
            /*ex_link_addr<=id_link_addr;
            ex_is_in_delayslot<=id_is_in_delayslot;
            is_in_delayslot_o<=next_in_delayslot;
            inst_o<=inst_i;*/

        end
        else begin 
        
        end
    end
    
    
endmodule

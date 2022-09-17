`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/31 14:41:02
// Design Name: 
// Module Name: id_issue
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


module id_issue(
    input wire rst,
    input wire clk,
    input wire flush,
    
    input wire [5:0]stop,
    
    /////////////////第一条指令////////////////////
	input wire[`AluOpBus]         aluop1_i,
	input wire[`AluSelBus]        alusel1_i,
    input wire                    reg1_read_i,
	input wire                    reg2_read_i,     
	input wire[`RegAddrBus]       reg1_addr_i,
	input wire[`RegAddrBus]       reg2_addr_i,
	input wire[`RegAddrBus]       wd1_i,
	input wire                    wreg1_i,
	input wire[`RegBus]	imm1_i,
	input wire is_alu1_i,
	input wire is_mul1_i,
	input wire is_jb1_i,
	input wire is_mem1_i,
	
	/////////////////////第二条指令//////////////////
	input wire[`AluOpBus]         aluop2_i,
	input wire[`AluSelBus]        alusel2_i,
    input wire                    reg3_read_i,
	input wire                    reg4_read_i,     
	input wire[`RegAddrBus]       reg3_addr_i,
	input wire[`RegAddrBus]       reg4_addr_i,
	input wire[`RegAddrBus]       wd2_i,
	input wire                    wreg2_i,
	input wire[`RegBus]	imm2_i,
	input wire is_alu2_i,
	input wire is_mul2_i,
	input wire is_jb2_i,
	input wire is_mem2_i,
    
	
    /////////////////第一条指令////////////////////
	output reg[`AluOpBus]         aluop1_o,
	output reg[`AluSelBus]        alusel1_o,
    output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o,
	output reg[`RegAddrBus]       wd1_o,
	output reg                    wreg1_o,
	output reg[`RegBus]	imm1,
	output reg is_alu1,
	output reg is_mul1,
	output reg is_jb1,
	output reg is_mem1,
	/////////////////////第二条指令//////////////////
	output reg[`AluOpBus]         aluop2_o,
	output reg[`AluSelBus]        alusel2_o,
    output reg                    reg3_read_o,
	output reg                    reg4_read_o,     
	output reg[`RegAddrBus]       reg3_addr_o,
	output reg[`RegAddrBus]       reg4_addr_o,
	output reg[`RegAddrBus]       wd2_o,
	output reg                    wreg2_o,
	output reg[`RegBus]	imm2,
	output reg is_alu2,
	output reg is_mul2,
	output reg is_jb2,
	output reg is_mem2,
	
	//与inst buffer
	input wire is_single_issue,
	input wire issue_finish,
	
	output reg issue_finish_o,
	output reg is_single_issue_o,
	
	input wire [`InstBus]		issue_inst1_i,
    input wire [`InstBus]		issue_inst2_i,
    input wire [`InstAddrBus] issue_inst1_addr_i,
    input wire [`InstAddrBus]	issue_inst2_addr_i,
    output reg [`InstBus]		issue_inst1_o,
    output reg [`InstBus]		issue_inst2_o,
    output reg [`InstAddrBus] issue_inst1_addr_o,
    output reg [`InstAddrBus]	issue_inst2_addr_o
    );
    
    
    //assign next_valid1=ready_go &&current_valid &&issue_finish;
    //assign next_valid2=ready_go &&current_valid &&issue_finish;
    always @(posedge clk) begin 
        if(rst==`RstEnable||flush==1'b1) begin 
            aluop1_o <= `EXE_NOP_OP;
			alusel1_o <= `EXE_RES_NOP;
			wd1_o <= `NOPRegAddr;
			wreg1_o <= `WriteDisable;

			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr; //表示不选中任何寄存器
			reg2_addr_o <= `NOPRegAddr;
			imm1 <= 32'h0;	
			
			is_alu1<=1'b0;
			is_jb1<=1'b0;
			is_mem1<=1'b0;
			is_mul1<=1'b0;
			
			aluop2_o <= `EXE_NOP_OP;
			alusel2_o <= `EXE_RES_NOP;
			wd2_o <= `NOPRegAddr;
			wreg2_o <= `WriteDisable;

			reg3_read_o <= 1'b0;
			reg4_read_o <= 1'b0;
			reg3_addr_o <= `NOPRegAddr; //表示不选中任何寄存器
			reg4_addr_o <= `NOPRegAddr;
			imm2 <= 32'h0;	
			
			is_alu2<=1'b0;
			is_jb2<=1'b0;
			is_mem2<=1'b0;
			is_mul2<=1'b0;
			
			issue_finish_o<=1'b0;
			is_single_issue_o<=`Dual_issue;
			
			issue_inst1_o<=`ZeroWord;
            issue_inst2_o<=`ZeroWord;
            issue_inst1_addr_o<=`ZeroWord;
            issue_inst2_addr_o<=`ZeroWord;
        end
        else if(stop[2]==`Stop&&stop[3]==`NoStop) begin 
            aluop1_o <= `EXE_NOP_OP;
			alusel1_o <= `EXE_RES_NOP;
			wd1_o <= `NOPRegAddr;
			wreg1_o <= `WriteDisable;

			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr; //表示不选中任何寄存器
			reg2_addr_o <= `NOPRegAddr;
			imm1 <= 32'h0;	
			
			is_alu1<=1'b0;
			is_jb1<=1'b0;
			is_mem1<=1'b0;
			is_mul1<=1'b0;
			
			aluop2_o <= `EXE_NOP_OP;
			alusel2_o <= `EXE_RES_NOP;
			wd2_o <= `NOPRegAddr;
			wreg2_o <= `WriteDisable;

			reg3_read_o <= 1'b0;
			reg4_read_o <= 1'b0;
			reg3_addr_o <= `NOPRegAddr; //表示不选中任何寄存器
			reg4_addr_o <= `NOPRegAddr;
			imm2 <= 32'h0;	
			
			is_alu2<=1'b0;
			is_jb2<=1'b0;
			is_mem2<=1'b0;
			is_mul2<=1'b0;
			
			issue_finish_o<=1'b0;
			is_single_issue_o<=`Dual_issue;
			
			issue_inst1_o<=`ZeroWord;
            issue_inst2_o<=`ZeroWord;
            issue_inst1_addr_o<=`ZeroWord;
            issue_inst2_addr_o<=`ZeroWord;
        end
        else if(stop[2]==`Stop) begin 
        
        end
        else begin 
           issue_finish_o<=issue_finish;
           is_single_issue_o=is_single_issue;
           if(issue_finish==1'b1) begin 
               
               if(is_single_issue==`single_issue) begin 
                    /////////////////第一条指令////////////////////
	               aluop1_o<=aluop1_i;
	               alusel1_o<=alusel1_i;
                   reg1_read_o<=reg1_read_i;
	               reg2_read_o<=reg2_read_i;     
	               reg1_addr_o<=reg1_addr_i;
	               reg2_addr_o<=reg2_addr_i;
	               wd1_o<=wd1_i;
	               wreg1_o<=wreg1_i;
	               imm1<=imm1_i;
	               is_alu1<=is_alu1_i;
	               is_mul1<=is_mul1_i;
	               is_jb1<=is_jb1_i;
	               is_mem1<=is_mem1_i;
	               
	               aluop2_o <= `EXE_NOP_OP;
			       alusel2_o <= `EXE_RES_NOP;
			       wd2_o <= `NOPRegAddr;
			       wreg2_o <= `WriteDisable;

			       reg3_read_o <= 1'b0;
			       reg4_read_o <= 1'b0;
			       reg3_addr_o <= `NOPRegAddr; //表示不选中任何寄存器
			       reg4_addr_o <= `NOPRegAddr;
			       imm2 <= 32'h0;	
			
			       is_alu2<=1'b0;
			       is_jb2<=1'b0;
			       is_mem2<=1'b0;
			       is_mul2<=1'b0;
			       
			       issue_inst1_o<=issue_inst1_i;
                   issue_inst2_o<=`ZeroWord;
                   issue_inst1_addr_o<=issue_inst1_addr_i;
                   issue_inst2_addr_o<=`ZeroWord;
               end
               else begin 
                   /////////////////第一条指令////////////////////
	               aluop1_o<=aluop1_i;
	               alusel1_o<=alusel1_i;
                   reg1_read_o<=reg1_read_i;
	               reg2_read_o<=reg2_read_i;     
	               reg1_addr_o<=reg1_addr_i;
	               reg2_addr_o<=reg2_addr_i;
	               wd1_o<=wd1_i;
	               wreg1_o<=wreg1_i;
	               imm1<=imm1_i;
	               is_alu1<=is_alu1_i;
	               is_mul1<=is_mul1_i;
	               is_jb1<=is_jb1_i;
	               is_mem1<=is_mem1_i;
	/////////////////////第二条指令//////////////////
	               aluop2_o<=aluop2_i;
	               alusel2_o<=alusel2_i;
                   reg3_read_o<=reg3_read_i;
	               reg4_read_o<=reg4_read_i;     
	               reg3_addr_o<=reg3_addr_i;
	               reg4_addr_o<=reg4_addr_i;
	               wd2_o<=wd2_i;
	               wreg2_o<=wreg2_i;
	               imm2<=imm2_i;
	               is_alu2<=is_alu2_i;
	               is_mul2<=is_mul2_i;
	               is_jb2<=is_jb2_i;
	               is_mem2<=is_mem2_i;
	               
	               issue_inst1_o<=issue_inst1_i;
                   issue_inst2_o<=issue_inst2_i;
                   issue_inst1_addr_o<=issue_inst1_addr_i;
                   issue_inst2_addr_o<=issue_inst2_addr_i;
               end
           
           end
            else begin 
               aluop1_o <= `EXE_NOP_OP;
			alusel1_o <= `EXE_RES_NOP;
			wd1_o <= `NOPRegAddr;
			wreg1_o <= `WriteDisable;

			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr; //表示不选中任何寄存器
			reg2_addr_o <= `NOPRegAddr;
			imm1 <= 32'h0;	
			
			is_alu1<=1'b0;
			is_jb1<=1'b0;
			is_mem1<=1'b0;
			is_mul1<=1'b0;
			
			aluop2_o <= `EXE_NOP_OP;
			alusel2_o <= `EXE_RES_NOP;
			wd2_o <= `NOPRegAddr;
			wreg2_o <= `WriteDisable;

			reg3_read_o <= 1'b0;
			reg4_read_o <= 1'b0;
			reg3_addr_o <= `NOPRegAddr; //表示不选中任何寄存器
			reg4_addr_o <= `NOPRegAddr;
			imm2 <= 32'h0;	
			
			is_alu2<=1'b0;
			is_jb2<=1'b0;
			is_mem2<=1'b0;
			is_mul2<=1'b0;
			
			issue_finish_o<=1'b0;
			is_single_issue_o<=`Dual_issue;
			
			issue_inst1_o<=`ZeroWord;
            issue_inst2_o<=`ZeroWord;
            issue_inst1_addr_o<=`ZeroWord;
            issue_inst2_addr_o<=`ZeroWord;
           end
        end
        
    end
    
    
endmodule

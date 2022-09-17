`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/05 09:22:33
// Design Name: 
// Module Name: Decode
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


module Decode(
    input wire rst,
    //与FIFO的交互信号
    input wire [`InstBus]		issue_inst1_o,
    input wire [`InstBus]		issue_inst2_o,
    input wire [`InstAddrBus] issue_inst1_addr_o,
    input wire [`InstAddrBus]	issue_inst2_addr_o,
    
    input wire issue_ok,//FIFO是否接受发射
    
    output reg is_single_issue,//表示是否发射单条指令，高位发射单条指令
    output reg issue_finish,//表示发射指令是否完成,高位有效
    

    input wire [5:0]stop,
    /*
    //alu_fu数据旁路
     //处于执行阶段的指令要写入的目的寄存器信息
	input wire					ex_wreg_i,
	input wire[`RegBus]			ex_wdata_i,
	input wire[`RegAddrBus]     ex_wd_i,
	
	//处于访存阶段的指令要写入的目的寄存器信息
	input wire					mem_wreg_i,
	input wire[`RegBus]			mem_wdata_i,
	input wire[`RegAddrBus]    mem_wd_i,*/
	
    //mul_fu信息
    input wire					mul_wreg_i,
	input wire[`RegBus]			mul_wdata_i,
	input wire[`RegAddrBus]    mul_wd_i,
	//mem_fu信息
    input wire					m_wreg_i,
	
	input wire[`RegAddrBus]    m_wd_i,
    /*
    //送到执行阶段的信息
    
	///////alu_fu输入//////////////
	output reg[`AluOpBus]         alu_aluop_o,
	output reg[`AluSelBus]        alu_alusel_o,
	output reg[`RegBus]           alu_reg1_o,
	output reg[`RegBus]           alu_reg2_o,
	output reg[`RegAddrBus]      alu_wd_o,
	output reg                    alu_wreg_o,
	output reg alu_valid,
	
	//////////mul_fu///////////////
	output reg[`AluOpBus]         mul_aluop_o,
	output reg[`AluSelBus]        mul_alusel_o,
	output reg[`RegBus]           mul_reg1_o,
	output reg[`RegBus]           mul_reg2_o,
	output reg[`RegAddrBus]      mul_wd_o,
	output reg                    mul_wreg_o,
	output reg mul_valid,
	//////////mem_fu///////
	output reg[`AluOpBus]         mem_aluop_o,
	output reg[`AluSelBus]        mem_alusel_o,
	output reg[`RegBus]           mem_reg1_o,
	output reg[`RegBus]           mem_reg2_o,
	output reg[`RegAddrBus]      mem_wd_o,
	output reg                    mem_wreg_o,
	output reg mem_valid,
	output reg [`InstBus]inst,*/
	/*
	//regfile相关信号
	output wire                    reg1_read_o,
	output wire                    reg2_read_o,     
	output wire[`RegAddrBus]       reg1_addr_o,
	output wire[`RegAddrBus]       reg2_addr_o,
	output wire                    reg3_read_o,
	output wire                    reg4_read_o,     
	output wire[`RegAddrBus]       reg3_addr_o,
	output wire[`RegAddrBus]       reg4_addr_o,
	
	input wire [`RegBus]           reg1_data_i,
	input wire [`RegBus]           reg2_data_i,
	input wire [`RegBus]           reg3_data_i,
	input wire [`RegBus]           reg4_data_i,*/
	
	//fu状态
	input wire [1:0]is_busy,

	/*
	//jump_branch
	output reg[`RegBus] branch_addr,
	output reg next_in_delaysolt,
	output reg[`RegBus] link_addr,
	output reg branch_flag,
	output reg buffer_flush,*/
	
	input wire is_delaysolt,//是否单独发射延迟槽指令
	input wire buffer_flush,
	
	output wire[`AluOpBus]         aluop1_o,
	output wire[`AluSelBus]        alusel1_o,
	output wire                    reg1_read_o,
	output wire                    reg2_read_o,     
	output wire[`RegAddrBus]       reg1_addr_o,
	output wire[`RegAddrBus]       reg2_addr_o,

	output wire[`RegAddrBus]       wd1_o,
	output wire                    wreg1_o,
	output wire[`RegBus]	imm1,
    output wire is_alu1,
    output wire is_mul1,
    output wire is_jb1,
    output wire is_mem1,
	/////////////////////第二条指令//////////////////
	output wire[`AluOpBus]         aluop2_o,
	output wire[`AluSelBus]        alusel2_o,
	output wire                    reg3_read_o,
	output wire                    reg4_read_o,     
	output wire[`RegAddrBus]       reg3_addr_o,
	output wire[`RegAddrBus]       reg4_addr_o,
	output wire[`RegAddrBus]       wd2_o,
	output wire                    wreg2_o,
	output wire[`RegBus]	imm2,
	output wire is_alu2,
	output wire is_mul2,
	output wire is_jb2,
	output wire is_mem2,
	
    output wire mem_req,
    output wire mul_req,
    
    input wire [`RegAddrBus]       id2_wd1_o,
    input wire                    id2_wreg1_o,
    input wire [`RegAddrBus]       id2_wd2_o,
    input wire                    id2_wreg2_o
    );
    assign mem_req=((issue_finish==1'b1&&is_mem1==1'b1)||(issue_finish==1'b1 && is_mem2 ==1'b1 &&is_single_issue==  `Dual_issue))? 1'b1:1'b0;
    assign mul_req=((issue_finish==1'b1&&is_mul1==1'b1)||(issue_finish==1'b1 && is_mul2 ==1'b1 &&is_single_issue==  `Dual_issue))? 1'b1:1'b0;
    /*
    /////////////////第一条指令////////////////////
	wire[`AluOpBus]         aluop1_o;
	wire[`AluSelBus]        alusel1_o;
	reg[`RegBus]           reg1_o;
	reg[`RegBus]           reg2_o;
	wire[`RegAddrBus]       wd1_o;
	wire                    wreg1_o;
	/////////////////////第二条指令//////////////////
	wire[`AluOpBus]         aluop2_o;
	wire[`AluSelBus]        alusel2_o;
	reg[`RegBus]           reg3_o;
	reg[`RegBus]           reg4_o;
	wire[`RegAddrBus]       wd2_o;
	wire                    wreg2_o;*/
    /*
    wire[`RegBus] branch_addr1;
	wire next_in_delaysolt1;
	wire[`RegBus] link_addr1;
	wire branch_flag1;
	wire[`RegBus] branch_addr2;
	wire next_in_delaysolt2;
	wire[`RegBus] link_addr2;
	wire branch_flag2;
    */
    /*wire[`RegBus]	imm1,imm2;
    wire is_alu1,is_mul1,is_jb1,is_mem1,is_alu2,is_mul2,is_jb2,is_mem2;*/

    sub_decode sub_decode1(
        .rst(rst),
    
        .inst_i(issue_inst1_o),
        
	//送到regfile的信息
	    .reg1_read_o(reg1_read_o),
	    .reg2_read_o(reg2_read_o),     
	    .reg1_addr_o(reg1_addr_o),
	    .reg2_addr_o(reg2_addr_o), 	      
	
	//送到执行阶段的信息
	    .aluop_o(aluop1_o),//操作码
	    .alusel_o(alusel1_o),//操作片选信号
	    
	    .wd_o(wd1_o),//写寄存器号
	    .wreg_o(wreg1_o),//写寄存器使能
	/////////////////////////////////
	    .is_alu(is_alu1),//alu类指令
	    .is_mul(is_mul1),//乘法指令
	    .is_jb(is_jb1),//分支跳转指令
	    .is_mem(is_mem1),//访存指令
	
	   
	    .imm(imm1)
    );
    
    sub_decode sub_decode0(
        .rst(rst),
        .inst_i(issue_inst2_o),
        
	//送到regfile的信息
	    .reg1_read_o(reg3_read_o),
	    .reg2_read_o(reg4_read_o),     
	    .reg1_addr_o(reg3_addr_o),
	    .reg2_addr_o(reg4_addr_o), 	      
	
	//送到执行阶段的信息
	    .aluop_o(aluop2_o),//操作码
	    .alusel_o(alusel2_o),//操作片选信号

	    .wd_o(wd2_o),//写寄存器号
	    .wreg_o(wreg2_o),//写寄存器使能
	/////////////////////////////////
	    .is_alu(is_alu2),//alu类指令
	    .is_mul(is_mul2),//乘法指令
	    .is_jb(is_jb2),//分支跳转指令
	    .is_mem(is_mem2),//访存指令
	
	    
	    
	    .imm(imm2)
    );
    /*
    Branch_addr bd0(
        .rst(rst),
    
        .inst_i(issue_inst1_o),
        .pc_i(issue_inst1_addr_o),
    
	    .reg1_o(reg1_o),//源操作数1
	    .reg2_o(reg2_o),//源操作数2
	
	    .branch_addr(branch_addr1),
	    .next_in_delaysolt(next_in_delaysolt1),
	    .link_addr(link_addr1),
	    .branch_flag(branch_flag1)
    );
    
    Branch_addr bd1(
        .rst(rst),
    
        .inst_i(issue_inst2_o),
        .pc_i(issue_inst2_addr_o),
    
	    .reg1_o(reg3_o),//源操作数1
	    .reg2_o(reg4_o),//源操作数2
	
	    .branch_addr(branch_addr2),
	    .next_in_delaysolt(next_in_delaysolt2),
	    .link_addr(link_addr2),
	    .branch_flag(branch_flag2)
    );
    
    
    //reg1输出
     	always @ (*) begin
			
		if(rst == `RstEnable) begin
			reg1_o = `ZeroWord;	
			
		end 

		else begin  
		reg1_o = `ZeroWord;	
		if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o)) begin
			reg1_o = ex_wdata_i; 
		end 
		else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o = mem_wdata_i; 			
	  end 
	  else if(reg1_read_o == 1'b1) begin
	  	reg1_o = reg1_data_i;
	  end 
	  else if(reg1_read_o == 1'b0) begin
	  	reg1_o = imm1;
	  end 
	  else begin
	    reg1_o = `ZeroWord;
	  end
	  end
	end
	

	//reg2输出
always @ (*) begin
			
		if(rst == `RstEnable) begin
			reg2_o = `ZeroWord;
		end 

		else begin  
		reg2_o = `ZeroWord;
		if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o)) begin
			reg2_o = ex_wdata_i; 
		end 
		else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o = mem_wdata_i;			
	  end 
	  else if(reg2_read_o == 1'b1) begin
	  	reg2_o = reg2_data_i;
	  end 
	  else if(reg2_read_o == 1'b0) begin
	  	reg2_o = imm1;
	  end 
	  else begin
	    reg2_o = `ZeroWord;
	  end
	  end
	end
   
       //reg3输出
     	always @ (*) begin
			
		if(rst == `RstEnable) begin
			reg3_o = `ZeroWord;	
			
		end 

		else begin 
		reg3_o = `ZeroWord;	
		if((reg3_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg3_addr_o)) begin
			reg3_o = ex_wdata_i; 
		end 
		else if((reg3_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg3_addr_o)) begin
			reg3_o = mem_wdata_i; 			
	  end 
	  else if(reg3_read_o == 1'b1) begin
	  	reg3_o = reg3_data_i;
	  end 
	  else if(reg3_read_o == 1'b0) begin
	  	reg3_o = imm2;
	  end 
	  else begin
	    reg3_o = `ZeroWord;
	  end
	  
	  end
	end
	

	//reg4输出
always @ (*) begin
			
		if(rst == `RstEnable) begin
			reg4_o = `ZeroWord;
		end 

		else begin  
		reg4_o = `ZeroWord;
		if((reg4_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg4_addr_o)) begin
			reg4_o = ex_wdata_i; 
		end 
		else if((reg4_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg4_addr_o)) begin
			reg4_o = mem_wdata_i;			
	  end 
	  else if(reg4_read_o == 1'b1) begin
	  	reg4_o = reg4_data_i;
	  end 
	  else if(reg4_read_o == 1'b0) begin
	  	reg4_o = imm2;
	  end 
	  else begin
	    reg4_o = `ZeroWord;
	  end
	  end
	end*/
	/////////////////////////////////////////////生成输出////////////////////////////////////////////
	
    //结构相关或者两条指令之间存在WAW、RAW相关时单发射
    always @(*) begin 
        if(rst == `RstEnable) begin
			is_single_issue=`Dual_issue;
		end
		else begin 
		    if((wd2_o==wd1_o)&&wreg1_o==`WriteEnable&& wreg2_o==`WriteEnable) begin //WAW相关
		        is_single_issue=`Single_issue;
		    end
		    else if((is_mul1==1'b1&&is_mul2==1'b1)||(is_mem1==1'b1&&is_mem2==1'b1)||(is_alu1==is_alu2)) begin //争用乘法fu或者mem_fu/alu_fu
		        is_single_issue=`Single_issue;
		    end
		    else if((wd1_o==reg3_addr_o && reg3_read_o==`ReadEnable && wreg1_o==`WriteEnable)||(wd1_o==reg4_addr_o&& reg4_read_o==`ReadEnable && wreg1_o==`WriteEnable)) begin 
		        is_single_issue=`Single_issue;
		    end
		    else if((wd2_o==reg1_addr_o && reg1_read_o==`ReadEnable && wreg2_o==`WriteEnable)||(wd2_o==reg2_addr_o&& reg2_read_o==`ReadEnable && wreg2_o==`WriteEnable)) begin
		        is_single_issue=`Single_issue;
		    end
		    ////////mul或者 mem的fu忙
		   else if(is_mul1==1'b0&&is_mul2==1'b1&&is_busy[0]==1'b1) begin //第二条指令请求mul_fu失败
		        is_single_issue=`Single_issue;
		    end
		    else if(is_mem1==1'b0&&is_mem2==1'b1&&is_busy[1]==1'b1) begin //第二条指令需求mem_fu
		        is_single_issue=`Single_issue;
		    end
		    /*else if() begin //第二条指令等待mem返回数据，阻塞一条指令
		        is_single_issue=`Single_issue;
		    end*/
		    
		    else if(is_busy[0]==1'b1 && (((reg4_read_o == 1'b1) && (mul_wreg_i == 1'b1) 
								&& (mul_wd_i == reg4_addr_o))||((reg3_read_o == 1'b1) && (mul_wreg_i == 1'b1) 
								&& (mul_wd_i == reg3_addr_o)))) begin //第二条指令数据需要等待mul_fu返回数据,阻塞一条指令
		        is_single_issue=`Single_issue;
		    end
		    else if(is_busy[1]==1'b1 && (((reg4_read_o == 1'b1) && (m_wreg_i == 1'b1) 
								&& (m_wd_i == reg4_addr_o))||((reg3_read_o == 1'b1) && (m_wreg_i == 1'b1) 
								&& (m_wd_i == reg3_addr_o)))) begin //第二条指令数据需要等待mul_fu返回数据,阻塞一条指令
		        is_single_issue=`Single_issue;
		    end
		    else if(is_delaysolt==`InDelaySlot) begin 
		        is_single_issue=`Single_issue;
		    end
		    else begin 
		        is_single_issue=`Dual_issue;
		    end
		end
    end
    //生成发射成功信号
    always @(*) begin 
        if(rst == `RstEnable||stop[2]==`Stop) begin //指令buffer内指令数量不足，或者流水线暂停，则不发射指令
            issue_finish=1'b0;
        end
        else if(buffer_flush==1'b1) begin 
            if(is_delaysolt==`InDelaySlot) begin //发射还在buffer中的延迟槽指令
                issue_finish=1'b1;
            end
            else begin 
                issue_finish=1'b0;
            end
        end
        else if(issue_ok==1'b0) begin 
            issue_finish=1'b0;
        end
        else if((reg1_read_o == 1'b1&& id2_wreg1_o == 1'b1&&(reg1_addr_o==id2_wd1_o))||
            (reg1_read_o == 1'b1&& id2_wreg2_o == 1'b1&&(reg1_addr_o==id2_wd2_o))||
            (reg2_read_o == 1'b1&& id2_wreg1_o == 1'b1&&(reg2_addr_o==id2_wd1_o))||
            (reg2_read_o == 1'b1&& id2_wreg2_o == 1'b1&&(reg2_addr_o==id2_wd2_o)) ) begin
                issue_finish=1'b0;
            end 
        else if(is_busy[0]==1'b1) begin 
            if(is_mul1==1'b1) begin //mul_fu忙阻塞
                issue_finish=1'b0;
            end
            else if((((reg1_read_o == 1'b1) && (mul_wreg_i == 1'b1) 
								&& (mul_wd_i == reg1_addr_o))||((reg2_read_o == 1'b1) && (mul_wreg_i == 1'b1) 
								&& (mul_wd_i == reg2_addr_o))))begin //第一条指令等待mul_fu返回数据，阻塞该指令与后续指令
                issue_finish=1'b0;
            end
            
            else begin 
                issue_finish=1'b1;
            end
        end
        else if(is_busy[1]==1'b1) begin //mem_fu阻塞
            if(is_mem1==1'b1) begin //mul_fu忙阻塞
                issue_finish=1'b0;
            end
            else if((((reg1_read_o == 1'b1) && (m_wreg_i == 1'b1) 
								&& (m_wd_i == reg1_addr_o))||((reg2_read_o == 1'b1) && (m_wreg_i == 1'b1) 
								&& (m_wd_i == reg2_addr_o))))begin //第一条指令等待mem_fu返回数据，阻塞该指令与后续指令
                issue_finish=1'b0;
            end
            else begin 
                issue_finish=1'b1;
            end
        end
        else begin 
            issue_finish=1'b1;
        end
    end
    /*
    /////alu_fu
    always @(*) begin 
        if(rst == `RstEnable||issue_finish==1'b0||stop[2]==`Stop) begin 
	        
	        alu_aluop_o=`EXE_NOP_OP;
            alu_alusel_o=`EXE_RES_NOP;
            alu_reg1_o=`ZeroWord;
            alu_reg2_o=`ZeroWord;
            alu_wd_o=`NOPRegAddr;
            alu_wreg_o=`WriteDisable;
            
            alu_valid=1'b0;
        end
        else begin 
            if(issue_finish==1'b1 && is_alu1==1'b1) begin 
                alu_aluop_o=aluop1_o;
                alu_alusel_o=alusel1_o;
                alu_reg1_o=reg1_o;
                alu_reg2_o=reg2_o;
                alu_wd_o=wd1_o;
                alu_wreg_o=wreg1_o;
                alu_valid=1'b1;
            end
            else if(issue_finish==1'b1 && is_alu2==1'b1 &&is_single_issue==`Dual_issue)begin 
                alu_aluop_o=aluop2_o;
                alu_alusel_o=alusel2_o;
                alu_reg1_o=reg3_o;
                alu_reg2_o=reg4_o;
                alu_wd_o=wd2_o;
                alu_wreg_o=wreg2_o;
                alu_valid=1'b1;
            end
            else begin 
                alu_aluop_o=`EXE_NOP_OP;
                alu_alusel_o=`EXE_RES_NOP;
                alu_reg1_o=`ZeroWord;
                alu_reg2_o=`ZeroWord;
                alu_wd_o=`NOPRegAddr;
                alu_wreg_o=`WriteDisable;
                alu_valid=1'b0;
            end
        end
    end
    
    /////mul_fu
    always @(*) begin 
        if(rst == `RstEnable||issue_finish==1'b0||stop[2]==`Stop) begin 
	        
	        mul_aluop_o=`EXE_NOP_OP;
            mul_alusel_o=`EXE_RES_NOP;
            mul_reg1_o=`ZeroWord;
            mul_reg2_o=`ZeroWord;
            mul_wd_o=`NOPRegAddr;
            mul_wreg_o=`WriteDisable;
            
            mul_valid=1'b0;
        end
        else begin 
            if(issue_finish==1'b1 && is_mul1==1'b1) begin 
                mul_aluop_o=aluop1_o;
                mul_alusel_o=alusel1_o;
                mul_reg1_o=reg1_o;
                mul_reg2_o=reg2_o;
                mul_wd_o=wd1_o;
                mul_wreg_o=wreg1_o;
                mul_valid=1'b1;
            end
            else if(issue_finish==1'b1 && is_mul2==1'b1 &&is_single_issue==`Dual_issue)begin 
                mul_aluop_o=aluop2_o;
                mul_alusel_o=alusel2_o;
                mul_reg1_o=reg3_o;
                mul_reg2_o=reg4_o;
                mul_wd_o=wd2_o;
                mul_wreg_o=wreg2_o;
                mul_valid=1'b1;
            end
            else begin 
                mul_aluop_o=`EXE_NOP_OP;
                mul_alusel_o=`EXE_RES_NOP;
                mul_reg1_o=`ZeroWord;
                mul_reg2_o=`ZeroWord;
                mul_wd_o=`NOPRegAddr;
                mul_wreg_o=`WriteDisable;
                mul_valid=1'b0;
            end
        end
    end
    ///////mem_fu
        always @(*) begin 
        if(rst == `RstEnable||issue_finish==1'b0||stop[2]==`Stop) begin 
	        
	        mem_aluop_o=`EXE_NOP_OP;
            mem_alusel_o=`EXE_RES_NOP;
            mem_reg1_o=`ZeroWord;
            mem_reg2_o=`ZeroWord;
            mem_wd_o=`NOPRegAddr;
            mem_wreg_o=`WriteDisable;
            inst=`ZeroWord;
            
            mem_valid=1'b0;
        end
        else begin 
            if(issue_finish==1'b1 && is_mem1==1'b1) begin 
                mem_aluop_o=aluop1_o;
                mem_alusel_o=alusel1_o;
                mem_reg1_o=reg1_o;
                mem_reg2_o=reg2_o;
                mem_wd_o=wd1_o;
                mem_wreg_o=wreg1_o;
                mem_valid=1'b1;
                
                inst=issue_inst1_o;
            end
            else if(issue_finish==1'b1 && is_mem2==1'b1 &&is_single_issue==`Dual_issue)begin 
                mem_aluop_o=aluop2_o;
                mem_alusel_o=alusel2_o;
                mem_reg1_o=reg3_o;
                mem_reg2_o=reg4_o;
                mem_wd_o=wd2_o;
                mem_wreg_o=wreg2_o;
                mem_valid=1'b1;
                
                inst=issue_inst2_o;
            end
            else begin 
                mem_aluop_o=`EXE_NOP_OP;
                mem_alusel_o=`EXE_RES_NOP;
                mem_reg1_o=`ZeroWord;
                mem_reg2_o=`ZeroWord;
                mem_wd_o=`NOPRegAddr;
                mem_wreg_o=`WriteDisable;
                inst=`ZeroWord;
            
                mem_valid=1'b0;
            end
        end
    end
    
    
    always @(*) begin 
        if(rst == `RstEnable||stop[2]==`Stop||issue_finish==1'b0) begin 
            link_addr= `ZeroWord;
			branch_addr = `ZeroWord;
			branch_flag = `NotBranch;
			next_in_delaysolt = `NotInDelaySlot;
			buffer_flush=1'b0;
        end
        else begin 
            link_addr= `ZeroWord;
			branch_addr = `ZeroWord;
			branch_flag = `NotBranch;
			next_in_delaysolt = `NotInDelaySlot;
			buffer_flush=1'b0;
            if(branch_flag1==`Branch) begin 
                link_addr=link_addr1;
                branch_addr=branch_addr1;
                if(issue_finish==1'b1&&is_single_issue==`Dual_issue) begin //双发射时已经发射出了延迟槽指令
                    next_in_delaysolt = `NotInDelaySlot;
                    branch_flag=branch_flag1;
                    buffer_flush=1'b1;
                end
                else if(issue_finish==1'b1&&is_single_issue==`Single_issue) begin 
                    next_in_delaysolt = `InDelaySlot;
                    branch_flag=branch_flag1;
                    buffer_flush=1'b1;
                end
                
            end
            else if(branch_flag2==`Branch) begin 
                link_addr=link_addr2;
                branch_addr=branch_addr2;
                if(issue_finish==1'b1&&is_single_issue==`Dual_issue) begin 
                    next_in_delaysolt = `InDelaySlot;
                    branch_flag=branch_flag2;
                    buffer_flush=1'b1;
                end
                else if(issue_finish==1'b1&&is_single_issue==`Single_issue) begin //第二条指令是分支跳转指令，并且不发射第二条指令，此时不嫩跳转
                    next_in_delaysolt = `NotInDelaySlot;
                    branch_flag=`NotBranch;
                end
            end
            else begin 
                if(is_jb1==1'b1) begin 
                    link_addr=link_addr1;
                end
                else if(is_jb2==1'b1) begin 
                    link_addr=link_addr2;
                end
                else begin 
                    link_addr= `ZeroWord;
                end
                
			    branch_addr = `ZeroWord;
			    branch_flag = `NotBranch;
			    next_in_delaysolt = `NotInDelaySlot;
			    buffer_flush=1'b0;
            end
            
        end
    end*/
    
    
    
endmodule

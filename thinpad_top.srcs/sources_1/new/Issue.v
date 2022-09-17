`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/31 14:42:48
// Design Name: 
// Module Name: Issue
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


module Issue(
    input wire rst,
    input wire [5:0]stop,
    
    input wire [`InstBus]		issue_inst1_o,
    input wire [`InstBus]		issue_inst2_o,
    input wire [`InstAddrBus] issue_inst1_addr_o,
    input wire [`InstAddrBus]	issue_inst2_addr_o,
    input wire issue_finish,
    input wire is_single_issue,
    //regfile相关信号
	input wire                    reg1_read_o,
	input wire                    reg2_read_o,     
	input wire[`RegAddrBus]       reg1_addr_o,
	input wire[`RegAddrBus]       reg2_addr_o,
	input wire                    reg3_read_o,
	input wire                    reg4_read_o,     
	input wire[`RegAddrBus]       reg3_addr_o,
	input wire[`RegAddrBus]       reg4_addr_o,
	
	input wire [`RegBus]           reg1_data_i,
	input wire [`RegBus]           reg2_data_i,
	input wire [`RegBus]           reg3_data_i,
	input wire [`RegBus]           reg4_data_i,
	
	/////////////////第一条指令////////////////////
	input wire[`AluOpBus]         aluop1_o,
	input wire[`AluSelBus]        alusel1_o,

	input wire[`RegAddrBus]       wd1_o,
	input wire                    wreg1_o,
	input wire[`RegBus]	imm1,
	input wire is_alu1,
	input wire is_mul1,
	input wire is_jb1,
	input wire is_mem1,
	/////////////////////第二条指令//////////////////
	input wire[`AluOpBus]         aluop2_o,
	input wire[`AluSelBus]        alusel2_o,

	input wire[`RegAddrBus]       wd2_o,
	input wire                    wreg2_o,
	input wire[`RegBus]	imm2,
	input wire is_alu2,
	input wire is_mul2,
	input wire is_jb2,
	input wire is_mem2,
	
	
	 //alu_fu数据旁路
     //处于执行阶段的指令要写入的目的寄存器信息
	input wire					ex_wreg_i,
	input wire[`RegBus]			ex_wdata_i,
	input wire[`RegAddrBus]     ex_wd_i,
	
	//处于访存阶段的指令要写入的目的寄存器信息
	input wire					mem_wreg_i,
	input wire[`RegBus]			mem_wdata_i,
	input wire[`RegAddrBus]    mem_wd_i,
	
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
	output reg [`InstBus]inst,
	
	//jump_branch
	output reg[`RegBus] branch_addr,
	output reg next_in_delaysolt,
	output reg[`RegBus] link_addr,
	output reg branch_flag,
	output reg buffer_flush
    );
    
    wire[`RegBus] branch_addr1;
	wire next_in_delaysolt1;
	wire[`RegBus] link_addr1;
	wire branch_flag1;
	wire[`RegBus] branch_addr2;
	wire next_in_delaysolt2;
	wire[`RegBus] link_addr2;
	wire branch_flag2;
	
	reg[`RegBus]           reg1_o;
	reg[`RegBus]           reg2_o;
    reg[`RegBus]           reg3_o;
	reg[`RegBus]           reg4_o;
    
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
		/*else if(pre_inst_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  reg1_load_dependence=1'b1;						
		end */
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
		/*else if(pre_inst_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stopreq_forreg2 <= `Stop;			
		end */
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
		/*else if(pre_inst_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  reg1_load_dependence=1'b1;						
		end */
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
		/*else if(pre_inst_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stopreq_forreg2 <= `Stop;			
		end */
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
	end
    
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
    end
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/17 15:23:41
// Design Name: 
// Module Name: mem_fu_ex
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


module mem_fu_ex(
    input wire clk,
    input wire rst,
    
    input wire [`InstBus]		inst,//访存指令
    input wire [`AluOpBus]         aluop_i,//操作码
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,//存储指令的写入数据
	input wire[`RegAddrBus]      wd_i,//写寄存器号
	input wire                    wreg_i,//写使能
	input wire fu_valid,//mem_fu是否启动
	
	input wire flush,//流水线冲刷
	//mem_fu的状态
    input wire[1:0]is_busy,
    //input wire[2:0]mem_fu_state,
    //流水线暂停
    input wire [5:0] stop,
	//与存储管理单元的交互信号
	output reg data_req_i, //CPU请求数据，低位有效
    output wire[31:0] virtual_addr,//虚拟地址，待实现TLB
    output reg [`RegBus] write_data,//写数据
    output reg cpu_we,//读写信号，1位写，0位读
	output reg [3:0]sel,//字节使能信号
	input wire [`RegBus]mem_data_i,//存储单元送入的数据
	
	input wire mem_ready,//用于指示访存数据准备完毕
	
	//到wb
	output wire[`RegAddrBus]      wb_wd,
	output wire                   wb_wreg,
	output reg [`RegBus]           wb_data,
	output reg wb_valid
    );
    (* max_fanout = "200" *)reg[`RegBus]           reg1_temp;
	(* max_fanout = "200" *)reg[`RegBus]           reg2_temp;
    reg [`InstBus]		inst_temp;
    reg [`RegAddrBus]      wd_temp;
    reg wreg_temp;
    reg [`AluOpBus]         aluop_temp;
     //mem_addr传递到访存阶段，是加载、存储指令对应的存储器地址
    assign virtual_addr = reg1_temp + {{16{inst_temp[15]}},inst_temp[15:0]};
    assign wb_wd=wd_temp;
    assign wb_wreg=wreg_temp;
    
    
    always @(posedge clk) begin
        if(rst==`RstEnable) begin
            //内部操作数保存
            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            wd_temp<=`NOPRegAddr;
            wreg_temp<=`WriteDisable;
            
            inst_temp<=`ZeroWord;
            
            aluop_temp<=`EXE_NOP_OP;

            /*
            inst_o<=`ZeroWord;

	        ex_link_addr <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
	        is_in_delayslot_o <= `NotInDelaySlot;	*/
        end    
        else if(flush==1'b1) begin 

            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            wd_temp<=`NOPRegAddr;
            wreg_temp<=`WriteDisable;
            
            inst_temp<=`ZeroWord;
            
            aluop_temp<=`EXE_NOP_OP;
        end
        
        else if (stop[2]==`Stop&&stop[3]==`NoStop) begin 

            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            wd_temp<=`NOPRegAddr;
            wreg_temp<=`WriteDisable;
            
            inst_temp<=`ZeroWord;
            
            aluop_temp<=`EXE_NOP_OP;
        end
        else if(stop[2]==`Stop) begin 
        
        end
        
        else if(fu_valid==1'b0) begin 

            reg1_temp<=`ZeroWord;
            reg2_temp<=`ZeroWord;
            wd_temp<=`NOPRegAddr;
            wreg_temp<=`WriteDisable;
            
            inst_temp<=`ZeroWord;
            
            aluop_temp<=`EXE_NOP_OP;
        end
        else if (stop[2]==`NoStop&&fu_valid==1'b1)begin

            reg1_temp<=reg1_i;
            reg2_temp<=reg2_i;
            wd_temp<=wd_i;
            wreg_temp<=wreg_i;
            
            inst_temp<=inst;
            
            aluop_temp<=aluop_i;
            /*ex_link_addr<=id_link_addr;
            ex_is_in_delayslot<=id_is_in_delayslot;
            is_in_delayslot_o<=next_in_delayslot;
            inst_o<=inst_i;*/

        end
        else begin 
        
        end
    end
    always @(*) begin 
        if(rst==`RstEnable) begin 
            wb_valid<=1'b0;
        end
        else begin 
            if(is_busy[1]==1'b1 && mem_ready==`MEMready) begin 
                wb_valid<=1'b1;
            end
            /*else if(is_busy[1]==1'b1 && mem_fu_state[0]==1'b1 && mem_ready==`MEMready) begin 
             
                wb_valid<=1'b1;
            end*/
            else begin 
                wb_valid<=1'b0;
            end
        end
    end
    
    
    always @(*) begin 
        if(rst==`RstEnable) begin 
            data_req_i=1'b1;
            write_data=`ZeroWord;
            cpu_we=`WriteDisable;
            sel = 4'b1111;
            wb_data=`ZeroWord;
            
        end
        
        else begin 
            data_req_i=1'b1;
            write_data=`ZeroWord;
            cpu_we=`WriteDisable;
            sel = 4'b1111;
		    wb_data=`ZeroWord;
			case (aluop_temp)

				`EXE_LB_OP:		begin
					
					cpu_we = `WriteDisable;
					data_req_i=1'b0;
					
					case (virtual_addr[1:0])
						2'b00:	begin
							wb_data = {{24{mem_data_i[7]}},mem_data_i[7:0]};
							//mem_sel_o <= 4'b0001;
							sel = 4'b0000;
						end
						2'b01:	begin
							wb_data = {{24{mem_data_i[15]}},mem_data_i[15:8]};
							//mem_sel_o <= 4'b0010;
							sel = 4'b0000;
							
						end
						2'b10:	begin
							wb_data = {{24{mem_data_i[23]}},mem_data_i[23:16]};
							//mem_sel_o <= 4'b0100;
							sel = 4'b0000;
						end
						2'b11:	begin
							wb_data = {{24{mem_data_i[31]}},mem_data_i[31:24]};
							//mem_sel_o <= 4'b1000;
							sel = 4'b0000;
						end
						default:	begin
							wb_data = `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP:		begin
					
					cpu_we = `WriteDisable;
					data_req_i = 1'b0;
					case (virtual_addr[1:0])
						2'b00:	begin
							wb_data = {{24{1'b0}},mem_data_i[7:0]};
							sel = 4'b0111;
						end
						2'b01:	begin
							wb_data = {{24{1'b0}},mem_data_i[15:8]};
							sel = 4'b1011;
						end
						2'b10:	begin
							wb_data = {{24{1'b0}},mem_data_i[23:16]};
							sel = 4'b1101;
						end
						2'b11:	begin
							wb_data = {{24{1'b0}},mem_data_i[31:24]};
							sel = 4'b1110;
						end
						default:	begin
							wb_data = `ZeroWord;
						end
					endcase				
				end
				`EXE_LH_OP:		begin
					
					cpu_we = `WriteDisable;
					data_req_i = 1'b0;
					case (virtual_addr[1:0])
						2'b00:	begin
							wb_data = {{16{mem_data_i[31]}},mem_data_i[31:16]};
							sel = 4'b0011;
						end
						2'b10:	begin
							wb_data = {{16{mem_data_i[15]}},mem_data_i[15:0]};
							sel = 4'b1100;
						end
						default:	begin
							wb_data = `ZeroWord;
						end
					endcase					
				end
				`EXE_LHU_OP:		begin
					cpu_we = `WriteDisable;
					data_req_i = 1'b0;
					case (virtual_addr[1:0])
						2'b00:	begin
							wb_data = {{16{1'b0}},mem_data_i[31:16]};
							sel = 4'b0011;
						end
						2'b10:	begin
							wb_data = {{16{1'b0}},mem_data_i[15:0]};
							sel = 4'b1100;
						end
						default:	begin
							wb_data = `ZeroWord;
						end
					endcase				
				end
				`EXE_LW_OP:		begin
                   /* if(mem_data_i[31:12]==32'hab6f7) begin 
                        wb_data={20'h0,mem_data_i[11:0]};
                    end
                    else begin 
                        wb_data = mem_data_i;
                    end*/
					wb_data = mem_data_i;
					//wb_data={20'h0,mem_data_i[11:0]};
					sel = 4'b0000;
					cpu_we = `WriteDisable;
					data_req_i = 1'b0;
					
				end
				
				`EXE_SB_OP:		begin
					
					cpu_we = `WriteEnable;
					write_data = {reg2_temp[7:0],reg2_temp[7:0],reg2_temp[7:0],reg2_temp[7:0]};
					data_req_i = 1'b0;
					
					case (virtual_addr[1:0])
						2'b00:	begin
						    sel = 4'b0111;
								
						end
						2'b01:	begin
							sel = 4'b1011;
						end
						2'b10:	begin
							
							sel = 4'b1101;
						end
						2'b11:	begin
							sel = 4'b1110;
							
						end
						default:	begin
							sel = 4'b1111;
						end
					endcase				
				end
				
				`EXE_SW_OP:		begin
					
					cpu_we = `WriteEnable;
					write_data = reg2_temp;
					sel = 4'b0000;	
					data_req_i = 1'b0;	
						
				end
				
				default:		begin
          //什么也不做
                
				end
			endcase							
        end
    end
    
    
    
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/08 20:50:32
// Design Name: 
// Module Name: alu
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


module alu(
    input wire rest,//使能信号
    
    //id_exe端 输入的信号
    input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	
	input wire [`RegBus]link_addr,
	//input wire[`RegBus] inst_i,
	
	
	//input wire [`RegBus] link_addr,//写回寄存器的地址
	
	//执行结果
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o

    
    );
    reg[`RegBus] logout;//逻辑运算
    reg[`RegBus] shiftout;//移位结果
    reg[`RegBus]arithmeticres;//算术运算

    
    wire[`RegBus] reg2_i_mux;
	wire[`RegBus] reg1_i_not;	
	wire[`RegBus] result_sum;
	wire ov_sum;
	wire reg1_eq_reg2;
	wire reg1_lt_reg2;
	

	
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
											 (aluop_i == `EXE_SLT_OP) || (aluop_i == `EXE_TLT_OP) ||
	                       (aluop_i == `EXE_TLTI_OP) || (aluop_i == `EXE_TGE_OP) ||
	                       (aluop_i == `EXE_TGEI_OP)) 
											 ? (~reg2_i)+1 : reg2_i;

	assign result_sum = reg1_i + reg2_i_mux;										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  
									
	assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)  || (aluop_i == `EXE_TLT_OP) ||
	                       (aluop_i == `EXE_TLTI_OP) || (aluop_i == `EXE_TGE_OP) ||
	                       (aluop_i == `EXE_TGEI_OP))?
												 ((reg1_i[31] && !reg2_i[31]) || 
												 (!reg1_i[31] && !reg2_i[31] && result_sum[31])||
			                   (reg1_i[31] && reg2_i[31] && result_sum[31]))
			                   :	(reg1_i < reg2_i);
  
    assign reg1_i_not = ~reg1_i;
    

    //生成运算结果
    always @(*) begin 
        if(rest==`RstEnable) begin
            logout=`ZeroWord;        
        end
        else begin
            case(aluop_i)      
                `EXE_OR_OP: begin //或
                    logout=reg1_i | reg2_i;
                end
                `EXE_AND_OP: begin //与
                    logout=reg1_i & reg2_i;
                end
                `EXE_NOR_OP: begin  //或非
                    logout=~(reg1_i | reg2_i);
                end
                `EXE_XOR_OP: begin  //异或
                    logout=reg1_i ^ reg2_i;
                end
                default: begin
                    logout=`ZeroWord; 
                end
            
            endcase  
        end
    end
    
    always @ (*) begin  //移位操作
        if(rest==`RstEnable) begin 
            shiftout=`ZeroWord;
        end
        else begin 
            case(aluop_i)
                `EXE_SLL_OP: begin   //逻辑左移
                    shiftout=reg2_i<<reg1_i[4:0];
                end
                `EXE_SRL_OP: begin   //逻辑右移
                    shiftout=reg2_i>>reg1_i[4:0];
                end
                `EXE_SRA_OP: begin //算数右移
                    shiftout=({32{reg2_i[31]}}<<(6'd32-{1'b0,reg1_i[4:0]}))| reg2_i>>reg1_i[4:0];
                end
                default: begin 
                    shiftout=`ZeroWord;
                end
            endcase
        
        end
    end
  																			

  always @ (*) begin
		if(rest == `RstEnable) begin
			arithmeticres = `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLT_OP, `EXE_SLTU_OP:		begin
					arithmeticres = reg1_lt_reg2 ;
				end
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP:		begin
					arithmeticres = result_sum; 
				end
				`EXE_SUB_OP, `EXE_SUBU_OP:		begin
					arithmeticres = result_sum; 
				end		
				
				default:				begin
					arithmeticres = `ZeroWord;
				end
			endcase
		end
	end
	

   always @ (*) begin 
   //设置结果写会寄存器的地址以及写使能信号
       wd_o=wd_i;
       if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
	 	    wreg_o = `WriteDisable;
	 	    
	    end 
	    else begin
	      wreg_o = wreg_i;
	      
	   end
       case(alusel_i)
           `EXE_RES_LOGIC: begin 
               wdata_o=logout; //向输出端口写入要输出的逻辑运算结果
           end
           `EXE_RES_SHIFT: begin
               wdata_o=shiftout; //输出移位结果
           end

           `EXE_RES_ARITHMETIC:	begin
	 		    wdata_o = arithmeticres;
	 	   end
	 	   `EXE_RES_JUMP_BRANCH:begin 
	 	       wdata_o = link_addr;
	 	   end
           default: begin 
                 wdata_o=`ZeroWord;         
           end
       endcase
   end
    
endmodule

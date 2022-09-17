`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/05 09:22:56
// Design Name: 
// Module Name: sub_decode
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


module sub_decode(
    input wire rst,
    
    input wire [`InstBus]inst_i,

    
	//送到regfile的信息
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	//送到执行阶段的信息
	output reg[`AluOpBus]         aluop_o,//操作码
	output reg[`AluSelBus]        alusel_o,//操作片选信号
	/*output reg[`RegBus]           reg1_o,//源操作数1
	output reg[`RegBus]           reg2_o,//源操作数2*/
	output reg[`RegAddrBus]       wd_o,//写寄存器号
	output reg                    wreg_o,//写寄存器使能
	/////////////////////////////////
	output reg is_alu,//alu类指令
	output reg is_mul,//乘法指令
	output reg is_jb,//分支跳转指令
	output reg is_mem,//访存指令
	
	
	
	output reg[`RegBus]	imm
    );
     wire[5:0] op = inst_i[31:26]; //op 
  wire[4:0] op2 = inst_i[10:6];//R-type的sa字段
  wire[5:0] op3 = inst_i[5:0];//R-type的funt字段
  wire[4:0] op4 = inst_i[20:16];//rt字段
  

  
  //wire[`RegBus] pc_plus_8;
 //wire[`RegBus] pc_plus_4;
  //wire[`RegBus] imm_sll2_signedext;  
  
 
  
  always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o = `EXE_NOP_OP;
			alusel_o = `EXE_RES_NOP;
			wd_o = `NOPRegAddr;
			wreg_o = `WriteDisable;

			reg1_read_o = 1'b0;
			reg2_read_o = 1'b0;
			reg1_addr_o = `NOPRegAddr; //表示不选中任何寄存器
			reg2_addr_o = `NOPRegAddr;
			imm = 32'h0;	
			
			is_alu=1'b0;
			is_jb=1'b0;
			is_mem=1'b0;
			is_mul=1'b0;


	  end 
	  else begin
			aluop_o = `EXE_NOP_OP;
			alusel_o= `EXE_RES_NOP;
			wd_o = inst_i[15:11];
			wreg_o = `WriteDisable;
 
			reg1_read_o = 1'b0;
			reg2_read_o = 1'b0;
			reg1_addr_o = inst_i[25:21];
			reg2_addr_o = inst_i[20:16];		
			imm = `ZeroWord;		
			
			is_alu=1'b0;
			is_jb=1'b0;
			is_mem=1'b0;
			is_mul=1'b0;

		  case (op)
		  	`EXE_ORI:			begin                        //ORI指令
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_OR_OP;
		  		alusel_o = `EXE_RES_LOGIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {16'h0, inst_i[15:0]};	//拓展操作数	
				wd_o = inst_i[20:16];
				is_alu=1'b1;
				
		  	end 	
		  	
		  	`EXE_SPECIAL_INST: begin //分析special类型指令
		  	    case(op2)
		  	        5'b00000: begin //表示是普通的逻辑运算指令
		  	            case(op3)
		  	                
		  	                `EXE_AND: begin 
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_AND_OP;
		  		                alusel_o = `EXE_RES_LOGIC;

		  		                reg1_read_o = 1'b1;	
		  		                reg2_read_o = 1'b1;	
		  		                is_alu=1'b1;
		  	                end
		  	                `EXE_OR: begin 
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_OR_OP;
		  		                alusel_o = `EXE_RES_LOGIC;

		  		                reg1_read_o = 1'b1;	
		  		                reg2_read_o = 1'b1;
		  		                is_alu=1'b1;
		  	                end
		  	                `EXE_XOR: begin 
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_XOR_OP;
		  		                alusel_o = `EXE_RES_LOGIC;

		  		                reg1_read_o = 1'b1;	
		  		                reg2_read_o = 1'b1;
		  		                is_alu=1'b1;
		  	                end
		  	                `EXE_NOR: begin
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_NOR_OP;
		  		                alusel_o = `EXE_RES_LOGIC;

		  		                reg1_read_o = 1'b1;	
		  		                reg2_read_o = 1'b1;
		  		                is_alu=1'b1;
		  	                end
		  	                `EXE_SLLV: begin 
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_SLL_OP;
		  		                alusel_o = `EXE_RES_SHIFT;

		  		                reg1_read_o = 1'b1;	
		  		                reg2_read_o = 1'b1;
		  		                is_alu=1'b1;
		  	                end
		  	                `EXE_SRLV: begin
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_SRL_OP;
		  		                alusel_o = `EXE_RES_SHIFT;

		  		                reg1_read_o = 1'b1;	
		  		                reg2_read_o = 1'b1;
		  		                is_alu=1'b1;
		  	                end 
		  	                `EXE_SRAV: begin 
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_SRA_OP;
		  		                alusel_o = `EXE_RES_SHIFT;

		  		                reg1_read_o = 1'b1;	
		  		                reg2_read_o = 1'b1;
		  		                is_alu=1'b1;
		  	                end
		  	                `EXE_SYNC: begin 
		  	                    wreg_o=`WriteEnable;
		  	                    aluop_o = `EXE_NOP_OP;
		  		                alusel_o = `EXE_RES_NOP;

		  		                reg1_read_o = 1'b0;	
		  		                reg2_read_o = 1'b1;
		  		                is_alu=1'b1;
		  	                end


		
		  	                `EXE_SLT: begin
							    wreg_o = `WriteEnable;		
								aluop_o = `EXE_SLT_OP;
		  						alusel_o = `EXE_RES_ARITHMETIC;		
		  						reg1_read_o = 1'b1;	
		  						reg2_read_o = 1'b1;
		  						is_alu=1'b1;

								end

								`EXE_SLTU: begin
									wreg_o = `WriteEnable;		
									aluop_o = `EXE_SLTU_OP;
		  						    alusel_o = `EXE_RES_ARITHMETIC;		
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b1;
		  						    is_alu=1'b1;

								end
								`EXE_ADD: begin
									wreg_o = `WriteEnable;		
									aluop_o = `EXE_ADD_OP;
		  						    alusel_o = `EXE_RES_ARITHMETIC;		
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b1;
		  						    is_alu=1'b1;

								end
								`EXE_ADDU: begin
									wreg_o = `WriteEnable;		
									aluop_o = `EXE_ADDU_OP;
		  						    alusel_o = `EXE_RES_ARITHMETIC;		
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b1;
		  						    is_alu=1'b1;

								end
								`EXE_SUB: begin
									wreg_o = `WriteEnable;		
									aluop_o = `EXE_SUB_OP;
		  						    alusel_o = `EXE_RES_ARITHMETIC;		
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b1;
		  						    is_alu=1'b1;

								end
								`EXE_SUBU: begin
									wreg_o = `WriteEnable;		
									aluop_o = `EXE_SUBU_OP;
		  						    alusel_o = `EXE_RES_ARITHMETIC;		
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b1;
		  						    is_alu=1'b1;

								end
								`EXE_MULT: begin
									wreg_o = `WriteDisable;		
									aluop_o = `EXE_MULT_OP;
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b1; 
		  						    is_mul=1'b1;

								end
								`EXE_MULTU: begin
									wreg_o = `WriteDisable;		
									aluop_o = `EXE_MULTU_OP;
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b1; 
		  						    is_mul=1'b1;

								end 
								`EXE_DIV: begin 
								    is_alu=1'b1;
								end
								`EXE_JR: begin
									wreg_o = `WriteDisable;		
									aluop_o = `EXE_JR_OP;
		  						    alusel_o = `EXE_RES_JUMP_BRANCH;   
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b0;
		  						    is_jb=1'b1;
		  						    
		  						    /*link_addr <= `ZeroWord;
		  						
			            	        branch_addr <= reg1_o;
			            	        branch_flag<= `Branch;
			           
			                        next_in_delaysolt <= `InDelaySlot;
			                        instvalid <= `InstValid;	*/
								end
								`EXE_JALR: begin
									wreg_o = `WriteEnable;		
									aluop_o = `EXE_JALR_OP;
		  						    alusel_o = `EXE_RES_JUMP_BRANCH;   
		  						    reg1_read_o = 1'b1;	
		  						    reg2_read_o = 1'b0;
		  						    wd_o = inst_i[15:11];
		  						    is_jb=1'b1;
		  						    is_alu=1'b1;//表示需要使用alu_fu存储link_addr
		  						  /*  link_addr <= pc_plus_8;
		  						
			            	        branch_addr <= reg1_o;
			            	        branch_flag<= `Branch;
			           
			                        next_in_delaysolt <= `InDelaySlot;
			                        instvalid <= `InstValid;	*/
								end
								

		  	                default: begin 
		  	                
		  	                end
		  	                endcase
		  	        end
		  	        default:  begin 
		  	        
		  	        end
		  	    endcase

		  	end
		  	`EXE_ANDI: begin 
		  	    wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_AND_OP;
		  		alusel_o = `EXE_RES_LOGIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {16'h0, inst_i[15:0]};	//拓展操作数	
				wd_o = inst_i[20:16];
				is_alu=1'b1;
		  	end		
		  	`EXE_XORI: begin
		  	    wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_XOR_OP;
		  		alusel_o = `EXE_RES_LOGIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {16'h0, inst_i[15:0]};	//拓展操作数	
				wd_o = inst_i[20:16];
				is_alu=1'b1;
		  	end		
		  	`EXE_LUI: begin
		  	     wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_OR_OP;
		  		alusel_o = `EXE_RES_LOGIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {inst_i[15:0],16'h0};	//右拓展操作数	
				wd_o = inst_i[20:16];
				is_alu=1'b1;
		  	end		

		  	`EXE_SLTI:			begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_SLT_OP;
		  		alusel_o = `EXE_RES_ARITHMETIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {{16{inst_i[15]}}, inst_i[15:0]};		
				wd_o = inst_i[20:16];		  	
				is_alu=1'b1;
				end
			`EXE_SLTIU:			begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_SLTU_OP;
		  		alusel_o = `EXE_RES_ARITHMETIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {{16{inst_i[15]}}, inst_i[15:0]};		
				wd_o = inst_i[20:16];		  	
				is_alu=1'b1;
				end
			`EXE_ADDI:			begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_ADDI_OP;
		  		alusel_o = `EXE_RES_ARITHMETIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {{16{inst_i[15]}}, inst_i[15:0]};		
				wd_o = inst_i[20:16];		  	
				is_alu=1'b1;
				end
			`EXE_ADDIU:			begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_ADDIU_OP;
		  		alusel_o = `EXE_RES_ARITHMETIC; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				imm = {{16{inst_i[15]}}, inst_i[15:0]};		
				wd_o = inst_i[20:16];		  	
				is_alu=1'b1;
				end
			  `EXE_J:			begin
		  		wreg_o = `WriteDisable;		
		  		aluop_o = `EXE_J_OP;
		  		alusel_o = `EXE_RES_JUMP_BRANCH; 
		  		reg1_read_o = 1'b0;	
		  		reg2_read_o = 1'b0;
		  		is_jb=1'b1;
		  		/*link_addr <= `ZeroWord;
			    branch_addr <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag <= `Branch;
			    next_in_delaysolt <= `InDelaySlot;		  	
			    instvalid <= `InstValid;*/
				end
				`EXE_JAL:			begin
		  		    wreg_o = `WriteEnable;		
		  		    aluop_o = `EXE_JAL_OP;
		  		    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  		    reg1_read_o = 1'b0;	
		  		    reg2_read_o = 1'b0;
		  		    wd_o = 5'b11111;	
		  		    is_jb=1'b1;
		  		    is_alu=1'b1;//表示需要使用alu_fu存储link_addr
		  		  /*  link_addr <= pc_plus_8 ;
			        branch_addr <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			        branch_flag <= `Branch;
			        next_in_delaysolt <= `InDelaySlot;		  	
			        instvalid <= `InstValid;	*/
				end
				`EXE_BEQ:			begin
		  		    wreg_o = `WriteDisable;		
		  		    aluop_o = `EXE_BEQ_OP;
		  		    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  		    reg1_read_o = 1'b1;	
		  		    reg2_read_o = 1'b1;
		  		    is_jb=1'b1;
		  		    /*instvalid <= `InstValid;	
		  		    if(reg1_o == reg2_o) begin
			    	    branch_addr <= pc_plus_4 + imm_sll2_signedext;
			    	    branch_flag <= `Branch;
			    	    next_in_delaysolt <= `InDelaySlot;		  	
			        end*/
				end
				`EXE_BGTZ:			begin
		  		    wreg_o = `WriteDisable;		
		  		    aluop_o = `EXE_BGTZ_OP;
		  		    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  		    reg1_read_o = 1'b1;	
		  		    reg2_read_o = 1'b0;
		  		    is_jb=1'b1;
		  		/*instvalid <= `InstValid;	
		  		if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
			    	branch_addr <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag <= `Branch;
			    	next_in_delaysolt <= `InDelaySlot;		  	
			    end*/
				end
				`EXE_BLEZ:			begin
		  		    wreg_o = `WriteDisable;		
		  		    aluop_o = `EXE_BLEZ_OP;
		  		    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  		    reg1_read_o = 1'b1;	
		  		    reg2_read_o = 1'b0;
		  		    is_jb=1'b1;
		  		   /* instvalid <= `InstValid;	
		  		    if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
			    	    branch_addr <= pc_plus_4 + imm_sll2_signedext;
			    	    branch_flag <= `Branch;
			    	    next_in_delaysolt <= `InDelaySlot;		  	
			        end*/
				end
				`EXE_BNE:			begin
		  		    wreg_o = `WriteDisable;		
		  		    aluop_o = `EXE_BLEZ_OP;
		  		    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  		    reg1_read_o = 1'b1;	
		  		    reg2_read_o = 1'b1;
		  		    is_jb=1'b1;
		  		   /* instvalid <= `InstValid;	
		  		    if(reg1_o != reg2_o) begin
			    	    branch_addr <= pc_plus_4 + imm_sll2_signedext;
			    	    branch_flag <= `Branch;
			    	    next_in_delaysolt <= `InDelaySlot;		  	
			       end*/
				end
				
				`EXE_LB:			begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_LB_OP;
		  		alusel_o = `EXE_RES_LOAD_STORE; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				wd_o = inst_i[20:16]; 
				is_mem=1'b1;
				end
				`EXE_LBU:			begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_LBU_OP;
		  		alusel_o = `EXE_RES_LOAD_STORE; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				wd_o = inst_i[20:16]; 
				is_mem=1'b1;
				end

					
				
				`EXE_LW:			begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_LW_OP;
		  		alusel_o = `EXE_RES_LOAD_STORE; 
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b0;	  	
				wd_o = inst_i[20:16]; 
				is_mem=1'b1;
				end
				
				`EXE_SB:			begin
		  		wreg_o = `WriteDisable;		
		  		aluop_o = `EXE_SB_OP;
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b1; 

		  		alusel_o = `EXE_RES_LOAD_STORE; 
		  		is_mem=1'b1;
				end
				
				`EXE_SW:			begin
		  		wreg_o = `WriteDisable;		
		  		aluop_o = `EXE_SW_OP;
		  		reg1_read_o = 1'b1;	
		  		reg2_read_o = 1'b1; 
		  		
		  		alusel_o = `EXE_RES_LOAD_STORE; 
		  		is_mem=1'b1;
				end
			`EXE_REGIMM_INST:		begin
					case (op4)
						`EXE_BGEZ:	begin
							wreg_o = `WriteDisable;		
							aluop_o = `EXE_BGEZ_OP;
		  				    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  				    reg1_read_o = 1'b1;	
		  				    reg2_read_o = 1'b0;
		  				    
		  				    is_jb=1'b1;
						end
						`EXE_BGEZAL:		begin
							wreg_o = `WriteEnable;		
							aluop_o = `EXE_BGEZAL_OP;
		  				    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  				    reg1_read_o = 1'b1;	
		  				    reg2_read_o = 1'b0;
		  				    
		  				    wd_o = 5'b11111;  
		  				    is_jb=1'b1;
		  				    is_alu=1'b1;
						end
						`EXE_BLTZ:		begin
						    wreg_o = `WriteDisable;		
						    aluop_o = `EXE_BGEZAL_OP;
		  				    alusel_o = `EXE_RES_JUMP_BRANCH; 
		  				    reg1_read_o = 1'b1;	
		  				    reg2_read_o = 1'b0;
		  				    is_jb=1'b1;

						end
						endcase
			end

				
			`EXE_SPECIAL2_INST:		begin
					case ( op3 )

						`EXE_MUL:		begin
							wreg_o = `WriteEnable;		
							aluop_o = `EXE_MUL_OP;
		  				    alusel_o = `EXE_RES_MUL; 
		  				    reg1_read_o = 1'b1;	
		  				    reg2_read_o = 1'b1;	
		  				    is_mul=1'b1;			
						end
						default:	begin
						end
					endcase      //SPECIAL_INST2 case
				end	
								
		    default:		begin
		    
		    end
		  endcase		  //case op		
		  	 if (inst_i[31:21] == 11'b00000000000) begin
		  	    if (op3 == `EXE_SLL) begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_SLL_OP;
		  		alusel_o = `EXE_RES_SHIFT; 
		  		reg1_read_o = 1'b0;	
		  		reg2_read_o = 1'b1;	  	
				imm[4:0] = inst_i[10:6];		
				wd_o = inst_i[15:11];
				is_alu=1'b1;
				end 
				else if ( op3 == `EXE_SRL ) begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_SRL_OP;
		  		alusel_o = `EXE_RES_SHIFT; 
		  		reg1_read_o = 1'b0;	
		  		reg2_read_o = 1'b1;	  	
				imm[4:0] = inst_i[10:6];		
				wd_o = inst_i[15:11];
				is_alu=1'b1;
				end 
				else if ( op3 == `EXE_SRA ) begin
		  		wreg_o = `WriteEnable;		
		  		aluop_o = `EXE_SRA_OP;
		  		alusel_o = `EXE_RES_SHIFT; 
		  		reg1_read_o = 1'b0;	
		  		reg2_read_o = 1'b1;	  	
				imm[4:0] = inst_i[10:6];		
				wd_o = inst_i[15:11];
				is_alu=1'b1;
				end
			end		  
		end   //if

		   
	end   //always
/*	
 	always @ (*) begin
			
		if(rst == `RstEnable) begin
			reg1_o = `ZeroWord;	
			reg1_load_dependence=1'b0;
		end 
		else if(pre_inst_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  reg1_load_dependence=1'b1;						
		end 
		else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i; 
		end 
		else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i; 			
	  end 
	  else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end 
	  else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end 
	  else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	

	
always @ (*) begin
			
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end 
		else if(pre_inst_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stopreq_forreg2 <= `Stop;			
		end 
		else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i; 
		end 
		else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;			
	  end 
	  else if(reg2_read_o == 1'b1) begin
	  	reg2_o <= reg2_data_i;
	  end 
	  else if(reg2_read_o == 1'b0) begin
	  	reg2_o <= imm;
	  end 
	  else begin
	    reg2_o <= `ZeroWord;
	  end
	end

  */
    
endmodule

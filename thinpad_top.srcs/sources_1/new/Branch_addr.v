`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/13 18:19:37
// Design Name: 
// Module Name: Branch_addr
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
////生成分支跳转地址的目标pc与link_addr

module Branch_addr(
    input wire rst,
    
    input wire [`InstBus]inst_i,
    input wire [`InstAddrBus]pc_i,
    
	input wire[`RegBus]           reg1_o,//源操作数1
	input wire[`RegBus]           reg2_o,//源操作数2
	
	output reg [`RegBus] branch_addr,
	output reg next_in_delaysolt,
	output reg[`RegBus] link_addr,
	output reg branch_flag
    );
   wire[5:0] op = inst_i[31:26]; //op 
  wire[4:0] op2 = inst_i[10:6];//R-type的sa字段
  wire[5:0] op3 = inst_i[5:0];//R-type的funt字段
wire[4:0] op4 = inst_i[20:16];//rt字段
    
    
   wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;
  wire[`RegBus] imm_sll2_signedext; 
  assign pc_plus_8 = pc_i + 8;
  assign pc_plus_4 = pc_i +4;
  assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  
    
    
    always @(*) begin 
        if (rst == `RstEnable) begin
            link_addr= `ZeroWord;
			branch_addr = `ZeroWord;
			branch_flag = `NotBranch;
			next_in_delaysolt = `NotInDelaySlot;
        end
        else begin 
            link_addr= `ZeroWord;
			branch_addr = `ZeroWord;
			branch_flag = `NotBranch;
			next_in_delaysolt = `NotInDelaySlot;
			case (op)
		  	`EXE_REGIMM_INST:		begin
					case (op4)
						`EXE_BGEZ:	begin
		  				    if(reg1_o[31] == 1'b0) begin
			    			    branch_addr = pc_plus_4 + imm_sll2_signedext;
			    			    branch_flag = `Branch;
			    			    next_in_delaysolt = `InDelaySlot;		  	
			   			    end
						end
						`EXE_BGEZAL:		begin
		  				    link_addr = pc_plus_8; 
		  				    if(reg1_o[31] == 1'b0) begin
			    			  branch_addr = pc_plus_4 + imm_sll2_signedext;
			    			  branch_flag = `Branch;
			    			  next_in_delaysolt= `InDelaySlot;
			   			   end
						end
						`EXE_BLTZ:		begin

		  				    if(reg1_o[31] == 1'b1) begin
			    			  branch_addr = pc_plus_4 + imm_sll2_signedext;
			    			  branch_flag = `Branch;
			    			  next_in_delaysolt = `InDelaySlot;		  	
			   			   end
						end
						endcase
				end
		  	`EXE_SPECIAL_INST: begin //分析special类型指令
		  	    case(op2)
		  	        5'b00000: begin 
		  	            case(op3)

								`EXE_JR: begin

		  						    link_addr = `ZeroWord;
		  						
			            	        branch_addr = reg1_o;
			            	        branch_flag= `Branch;
			           
			                        next_in_delaysolt = `InDelaySlot;

								end
								`EXE_JALR: begin
		  						    link_addr = pc_plus_8;
		  						
			            	        branch_addr = reg1_o;
			            	        branch_flag= `Branch;
			           
			                        next_in_delaysolt = `InDelaySlot;
								end
		  	                default: begin 
		  	                
		  	                end
		  	                endcase
		  	        end
		  	        default:  begin 
		  	        
		  	        end
		  	    endcase

		  	end

			`EXE_J:			begin

		  		link_addr = `ZeroWord;
			    branch_addr = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag = `Branch;
			    next_in_delaysolt = `InDelaySlot;		  	

				end
				`EXE_JAL:			begin
		  		    link_addr = pc_plus_8;
			        branch_addr = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			        branch_flag = `Branch;
			        next_in_delaysolt = `InDelaySlot;		  	

				end
				`EXE_BEQ:			begin
		  		    if(reg1_o == reg2_o) begin
			    	    branch_addr = pc_plus_4 + imm_sll2_signedext;
			    	    branch_flag = `Branch;
			    	    next_in_delaysolt = `InDelaySlot;		  	
			        end
				end
				`EXE_BGTZ:			begin
		  		if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
			    	branch_addr = pc_plus_4 + imm_sll2_signedext;
			    	branch_flag = `Branch;
			    	next_in_delaysolt = `InDelaySlot;		  	
			    end
				end
				`EXE_BLEZ:			begin

		  		    if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
			    	    branch_addr = pc_plus_4 + imm_sll2_signedext;
			    	    branch_flag = `Branch;
			    	    next_in_delaysolt = `InDelaySlot;		  	
			        end
				end
				`EXE_BNE:			begin

		  		    if(reg1_o != reg2_o) begin
			    	    branch_addr = pc_plus_4 + imm_sll2_signedext;
			    	    branch_flag = `Branch;
			    	    next_in_delaysolt = `InDelaySlot;		  	
			       end
				end
			
		    default:			begin
		    
		    end
		  endcase		  //case op		
            
        end
    end
    
    
    
endmodule

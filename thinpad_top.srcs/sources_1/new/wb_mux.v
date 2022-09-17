`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/11 14:37:41
// Design Name: 
// Module Name: wb_mux
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
////选择fu的结果进行输出

module wb_mux(
    input wire rst,
    //alu_fu结果写回
    input wire[`RegAddrBus] alu_wb_wd_o,
	input wire alu_wb_wreg_o,
	input wire[`RegBus] alu_wb_wdata_o,
	//mul_fu结果写回
	input wire mul_data_valid,
	input wire[`RegAddrBus] mul_wb_wd_o,
	input wire mul_wb_wreg_o,
	input wire[`RegBus] mul_wb_wdata_o, 
	//mem_fu结果写回
	input wire mem_data_valid,
	input wire[`RegAddrBus] mem_wb_wd_o,
	input wire mem_wb_wreg_o,
	input wire[`RegBus] mem_wb_wdata_o,
	
	output reg[`RegAddrBus] wd1_o,
	output reg wreg1_o,
	output reg[`RegBus] wdata1_o,  
	
	output reg[`RegAddrBus] wd2_o,
	output reg wreg2_o,
	output reg[`RegBus] wdata2_o
    );
    always @(*) begin 
        if(rst==`RstEnable) begin 
            wd1_o= `NOPRegAddr;
            wreg1_o= `WriteDisable;
            wdata1_o=`ZeroWord;
            
            wd2_o= `NOPRegAddr;
            wreg2_o= `WriteDisable;
            wdata2_o=`ZeroWord;
        end
        else begin 
            wd1_o= `NOPRegAddr;
            wreg1_o= `WriteDisable;
            wdata1_o=`ZeroWord;
            
            wd2_o= `NOPRegAddr;
            wreg2_o= `WriteDisable;
            wdata2_o=`ZeroWord;
            
            if(alu_wb_wd_o!=`NOPRegAddr) begin 
                wd1_o=alu_wb_wd_o;
                wreg1_o=alu_wb_wreg_o;
                wdata1_o=alu_wb_wdata_o;
            end
            if(mul_data_valid==1'b1)begin 
                wd2_o=mul_wb_wd_o;
                wreg2_o=mul_wb_wreg_o;
                wdata2_o=mul_wb_wdata_o;
            end
            if(mem_data_valid==1'b1) begin 
                if(mul_data_valid==1'b1 && alu_wb_wd_o==`NOPRegAddr) begin 
                    wd1_o=mem_wb_wd_o;
                    wreg1_o=mem_wb_wreg_o;
                    wdata1_o=mem_wb_wdata_o;
                end
                else begin 
                    wd2_o=mem_wb_wd_o;
                    wreg2_o=mem_wb_wreg_o;
                    wdata2_o=mem_wb_wdata_o;
                end
            end
            else begin 
            
            end
        end
    end
    
    
    
endmodule

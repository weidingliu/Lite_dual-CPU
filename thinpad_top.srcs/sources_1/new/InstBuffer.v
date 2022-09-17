`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/05 09:38:58
// Design Name: 
// Module Name: InstBuffer
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
`include "defines.v"

module InstBuffer(
    input wire rst,
    input wire clk,
    input wire flush,
    input wire next_in_delaysolt,//分支发生时,延迟槽指令是否还在buffer中
    //issue
    input wire is_single_issue,//表示是否发射单条指令，高位发射单条指令
    input wire issue_finish,//表示发射指令是否完成,高位有效
    
    output wire [`InstBus]		issue_inst1_o,
    output wire [`InstBus]		issue_inst2_o,
    output wire [`InstAddrBus] issue_inst1_addr_o,
    output wire [`InstAddrBus]	issue_inst2_addr_o,
    
    output wire issue_ok,//FIFO是否接受发射
    
    //fetch阶段送来的数据
    input wire [`InstBus]		fetch_inst1_i,
    input wire [`InstBus]		fetch_inst2_i,
    input wire [`InstAddrBus] fetch_inst1_addr_i,
    input wire [`InstAddrBus]	fetch_inst2_addr_i,
    input wire is_single_fetch,//表示cache是否输出单条指令
    input wire inst_valid,//表示if_+id寄存器输出是否有效
    
    input buffer_flush,//分支时清空instbuffer
    
    output wire buffer_full//表示instbuffer是否装满
    );

    //队列
    reg [`InstBus]FIFO_data[`InstBufferSize-1:0];
    reg [`InstAddrBus]FIFO_addr[`InstBufferSize-1:0];
    //头尾指针
    reg [`InstBufferSizelog2-1:0]tail;//当前正在写入的数据位置
    reg [`InstBufferSizelog2-1:0]head;//最后需要写入数据位置的后一位
    reg [`InstBufferSize-1:0]FIFO_valid;//buffer中的数据是否有效（高电平有效）
    
    
    //队列首尾指针的维护
    always @(posedge clk) begin 
        //pop
        if(rst==`RstEnable||flush==1'b1||buffer_flush==1'b1) begin

            head<=`InstBufferSizelog2'h0;
            FIFO_valid<=`InstBufferSize'h0;

        end
        else begin 

            if(issue_finish==`Valid &&is_single_issue==`single_issue ) begin 
                FIFO_valid[head]<=`InValid;
                FIFO_data[head]<=`ZeroWord;
                FIFO_addr[head]<=`ZeroWord;
                head<=head+`InstBufferSizelog2'h1;
            end
            else if(issue_finish==`Valid &&is_single_issue==`dual_issue) begin 
                FIFO_valid[head]<=`InValid;
                FIFO_data[head]<=`ZeroWord;
                FIFO_addr[head]<=`ZeroWord;
                FIFO_valid[head+`InstBufferSizelog2'h1]<=`InValid;
                FIFO_data[head+`InstBufferSizelog2'h1]<=`ZeroWord;
                FIFO_addr[head+`InstBufferSizelog2'h1]<=`ZeroWord;
                head<=head+`InstBufferSizelog2'h2;
            end
            else begin 
            
            end
        end
        //push
        if(rst==`RstEnable||flush==1'b1||buffer_flush==1'b1) begin 
            tail<=`InstBufferSizelog2'h0;

        end
        else begin 
            if(inst_valid==`Valid &&is_single_fetch==`single_issue) begin 
                FIFO_valid[tail]<=`Valid;
                tail<=tail+`InstBufferSizelog2'h1;
            end
            else if(inst_valid==`Valid &&is_single_fetch==`dual_issue) begin 
                FIFO_valid[tail]<=`Valid;
                FIFO_valid[tail+`InstBufferSizelog2'h1]<=`Valid;
                tail<=tail+`InstBufferSizelog2'h2;
            end
            else begin 
            
            end
        end
    end
    //写数据
    always @(posedge clk) begin 
        if(inst_valid==`Valid &&is_single_fetch==`single_issue) begin 
             FIFO_data[tail]<=fetch_inst1_i;
             FIFO_addr[tail]<=fetch_inst1_addr_i;
        end
        else if(inst_valid==`Valid &&is_single_fetch==`dual_issue) begin 
            FIFO_data[tail]<=fetch_inst1_i;
            FIFO_addr[tail]<=fetch_inst1_addr_i;
            FIFO_data[tail+`InstBufferSizelog2'h1]<=fetch_inst2_i;
            FIFO_addr[tail+`InstBufferSizelog2'h1]<=fetch_inst2_addr_i;
        end
        
    end
    
    assign issue_inst1_o= FIFO_data[head];
                                                                        
    assign issue_inst2_o=FIFO_data[head+`InstBufferSizelog2'h1];
    assign issue_inst1_addr_o= FIFO_addr[head];
    assign issue_inst2_addr_o= FIFO_addr[head+`InstBufferSizelog2'h1];
     
    assign issue_ok = FIFO_valid[head+`InstBufferSizelog2'h2];
    
	assign buffer_full = FIFO_valid[tail+`InstBufferSizelog2'h6];
endmodule

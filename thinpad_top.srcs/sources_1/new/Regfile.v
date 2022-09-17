`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/06 21:49:07
// Design Name: 
// Module Name: Regfile
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


module Regfile(
    input wire rest,
    input wire clk,
    //写信号1
    input wire[`RegAddrBus] waddr1,
    input wire[`InstBus] wdata1,
    input wire we1,
    //写信号2
    input wire[`RegAddrBus] waddr2,
    input wire[`InstBus] wdata2,
    input wire we2,
    //读信号，分为两套I/O，输出两个寄存器的值
    input wire[`RegAddrBus] raddr1,
    input wire re1,
    input wire[`RegAddrBus] raddr2,
    input wire re2,
    input wire[`RegAddrBus] raddr3,
    input wire re3,
    input wire[`RegAddrBus] raddr4,
    input wire re4,
    /*
    //解决数据相关问题
    // 执行阶段数据前推
    input wire ex_wreg,
    input wire[`RegBus] ex_data,
    input wire[`RegAddrBus] ex_addr,
    //访存数据前推
    input wire mem_wreg,
    input wire[`RegBus] mem_data,
    input wire[`RegAddrBus] mem_addr,*/
    
    output reg[`InstBus] data1,
    output reg[`InstBus] data2,
    output reg[`InstBus] data3,
    output reg[`InstBus] data4

    );
    
    reg[`RegBus] regs[0:`RegNum-1];
    //写阶段
    always @(posedge clk) begin 
         if (rest==`RestDisable)begin
            if((we1==`WriteEnable) && (waddr1!=`RegNumLog2'h0 ) ) begin
                regs[waddr1]<=wdata1;
            end
            if((we2==`WriteEnable) && (waddr2!=`RegNumLog2'h0 ) ) begin
                regs[waddr2]<=wdata2;
            end
        end
        else begin
            regs[0]<=`ZeroWord;        
        end
    end
    //读阶段,第一个寄存器
    always @(* )begin 
        if (rest==`RstEnable)begin
            data1<=`ZeroWord;
        end
        /*
        //******先判断更近的数据相关性*****
        //前推执行阶段数据
        else if((re1==`ReadEnable)&&(ex_wreg==`WriteEnable)&&(raddr1==ex_addr)) begin 
            data1<=ex_data;
        end
        //前推访存阶段数据
        else if((re1==`ReadEnable)&&(mem_wreg==`WriteEnable)&&(raddr1==mem_addr)) begin 
            data1<=mem_data;
        end*/
        //前推回写阶段数据
        else if((raddr1==waddr1)&&(we1==`WriteEnable)&&(re1==`ReadEnable))begin
            data1<=wdata1;
        end
        else if((raddr1==waddr2)&&(we2==`WriteEnable)&&(re1==`ReadEnable))begin
            data1<=wdata2;
        end
        
        else if (re1==`ReadEnable) begin
            data1<=regs[raddr1];
        end
        else begin 
            data1<=`ZeroWord;
        end
    end
    //读阶段,第二个寄存器
    always @(* )begin 
        if (rest==`RstEnable)begin
            data2<=`ZeroWord;
        end
        /*
        //前推执行阶段数据
        else if((re2==`ReadEnable)&&(ex_wreg==`WriteEnable)&&(raddr2==ex_addr)) begin //判断是否存在数据相关
            data2<=ex_data;
        end
        //前推访存阶段数据
        else if((re2==`ReadEnable)&&(mem_wreg==`WriteEnable)&&(raddr2==mem_addr)) begin 
            data2<=mem_data;
        end*/
        //前推回写阶段数据
        else if((raddr2==waddr1)&&(we1==`WriteEnable)&&(re2==`ReadEnable))begin
            data2<=wdata1;
        end
        else if((raddr2==waddr2)&&(we2==`WriteEnable)&&(re2==`ReadEnable))begin
            data2<=wdata2;
        end
        
        else if (re2==`ReadEnable) begin
            data2<=regs[raddr2];
        end
        else begin 
            data2<=`ZeroWord;
        end
        //$display("now rom inst is %h %h %h %h",regs[0],regs[1],regs[2],regs[3]);
    end
    //读阶段,第三个寄存器
    always @(* )begin 
        if (rest==`RstEnable)begin
            data3<=`ZeroWord;
        end
        /*
        //******先判断更近的数据相关性*****
        //前推执行阶段数据
        else if((re1==`ReadEnable)&&(ex_wreg==`WriteEnable)&&(raddr1==ex_addr)) begin 
            data1<=ex_data;
        end
        //前推访存阶段数据
        else if((re1==`ReadEnable)&&(mem_wreg==`WriteEnable)&&(raddr1==mem_addr)) begin 
            data1<=mem_data;
        end*/
        //前推回写阶段数据
        else if((raddr3==waddr1)&&(we1==`WriteEnable)&&(re3==`ReadEnable))begin
            data3<=wdata1;
        end
        else if((raddr3==waddr2)&&(we2==`WriteEnable)&&(re3==`ReadEnable))begin
            data3<=wdata2;
        end
        
        else if (re3==`ReadEnable) begin
            data3<=regs[raddr3];
        end
        else begin 
            data3<=`ZeroWord;
        end
    end
    //读阶段,第四个寄存器
    always @(* )begin 
        if (rest==`RstEnable)begin
            data4<=`ZeroWord;
        end
        /*
        //******先判断更近的数据相关性*****
        //前推执行阶段数据
        else if((re1==`ReadEnable)&&(ex_wreg==`WriteEnable)&&(raddr1==ex_addr)) begin 
            data1<=ex_data;
        end
        //前推访存阶段数据
        else if((re1==`ReadEnable)&&(mem_wreg==`WriteEnable)&&(raddr1==mem_addr)) begin 
            data1<=mem_data;
        end*/
        //前推回写阶段数据
        else if((raddr4==waddr1)&&(we1==`WriteEnable)&&(re4==`ReadEnable))begin
            data4<=wdata1;
        end
        else if((raddr4==waddr2)&&(we2==`WriteEnable)&&(re4==`ReadEnable))begin
            data4<=wdata2;
        end
        
        else if (re4==`ReadEnable) begin
            data4<=regs[raddr4];
        end
        else begin 
            data4<=`ZeroWord;
        end
    end
endmodule

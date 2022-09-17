`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/17 19:33:58
// Design Name: 
// Module Name: mem_ctrl
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


`define RstEnable 1'b1  //复位有效信号
`define RestDisable 1'b0// 复位信号无效
`define ZeroWord 32'h0000 //一个字的零信号
`define MEMready 1'b1
`define MEMNoready 1'b0

`define start 3'b000
`define read 3'b001
`define end_state 3'b010
`define write 3'b011
module mem_ctrl(
    input wire clk,
    input wire rst,
    input wire [31:0] cpu_addr,//CPU传递的地址
    input wire [31:0] ram_data,//ram返回的信号
    input wire [7:0] uart_data_i,
    input wire [31:0] cpu_data,
    input wire uart_ready_i,

    input wire we,
    input wire not_ce,
    input wire ram_ready,
    //读取指令rom的数据
    input wire [31:0] rom_data,
    output wire [31:0] rom_addr,
    output reg is_rom_data,
    
    output wire [31:0] data,

    output wire ram_ce,
    output wire ready,
    output reg rxd_clear,
    input wire tsd_busy,
    output reg [7:0]uart_data_o,
    output reg txd_start,
    
    input wire cache_stop,
    output wire stop_req,//流水线暂停
    //写rom
    output wire [31:0]rom_data_o,
    output wire is_write_rom,
    output reg is_clearn_inst, 
    output reg relive//指示是否进入保持pc时间
    );
    reg [31:0] uart_data;//0xBFD003F8
    reg [31:0] uart_sign;//0xBFD003FC
    reg temp1_busy;
    reg rom_ready;
    wire ce;
    reg [2:0]state;
    reg [2:0]next_state;
    
    reg stopreq;
    assign stop_req=(stopreq==`Stop||cache_stop==`Stop)? `Stop:`NoStop;
    assign rom_data_o=cpu_data;
    assign ce=~not_ce;
    always @(*) begin //表示是否从rom中取数据
        if(rst==`RstEnable) begin 
            is_rom_data=1'b0;
        end
        else begin 
            if(cpu_addr[31:20]<=12'h803&&cpu_addr[31:20]>=12'h800) begin 
                is_rom_data=1'b1;
            end
            else begin 
                is_rom_data=1'b0;
            end
        end
    end
    
    
    always @ (posedge clk) begin //状态机
        if( rst==`RstEnable ) begin 
            state<=`start;
        end
        else begin 
            state<=next_state;
        end
    end
    /*always @(*) begin 
        if(rst==`RstEnable) begin 
            rom_ready=`MEMready;
        end
        else begin 
            if(is_rom_data==1'b1 && state==`start&&we==1'b0) begin 
                rom_ready=`MEMNoready;
            end
            else if(state==`read) begin 
                rom_ready=`MEMready;
            end
            else begin 
                rom_ready=`MEMready;
            end
        end
    end
    always @(*) begin 
        if(rst==`RstEnable) begin 
            next_state=`start;
        end
        else begin 
            if(is_rom_data==1'b1&& state==`start&&we==1'b0) begin 
                next_state=`read;
            end
            else if(state==`read) begin 
                next_state=`start;
            end 
            else begin 
                next_state=`start;
            end
        end
    end*/
     always @(*) begin 
        if(rst==`RstEnable) begin 
            rom_ready=`MEMNoready;
            is_clearn_inst=1'b0;
            relive=1'b0;
            
            stopreq=`NoStop;
        end
        else begin 
            rom_ready=`MEMNoready;
            stopreq=`NoStop;
            if(is_rom_data==1'b1 && state==`start&&we==1'b0) begin //read
                rom_ready=`MEMready;
                is_clearn_inst=1'b1;
                relive=1'b0;
                
                stopreq=`Stop;
            end
            else if(is_rom_data==1'b1 && state==`start&&we==1'b1) begin //write
                rom_ready=`MEMNoready;
                is_clearn_inst=1'b1;
                relive=1'b0;
                
                stopreq=`Stop;
            end
            else if(state==`read) begin //////////////
                rom_ready=`MEMNoready;
                is_clearn_inst=1'b1;
                relive=1'b1;
                
                stopreq=`Stop;
            end
            else if(state==`write) begin /////////////////
                rom_ready=`MEMNoready;
                is_clearn_inst=1'b1;
                relive=1'b1;
                
                stopreq=`Stop;
            end
            else if(state==`end_state) begin 
                rom_ready=`MEMready;
                is_clearn_inst=1'b0;
                relive=1'b0;
                
                stopreq=`NoStop;
            end
            else begin 
                rom_ready=`MEMNoready;
                is_clearn_inst=1'b0;
                relive=1'b0;
                
               stopreq=`NoStop;
            end
        end
    end
    always @(*) begin 
        if(rst==`RstEnable) begin 
            next_state=`start;
        end
        else begin 
            if(is_rom_data==1'b1&& state==`start&&we==1'b0) begin 
                next_state=`read;
            end
            else if(is_rom_data==1'b1&& state==`start&&we==1'b1) begin 
                next_state=`write;
            end
            else if(state==`read) begin 
                next_state=`end_state;
            end 
            else if(state==`write) begin 
                next_state=`end_state;
            end
            else if(state==`end_state) begin 
                next_state=`start;
            end 
            else begin 
                next_state=`start;
            end
        end
    end
    assign is_write_rom=((we==1'b1)&&(is_rom_data==1'b1))? 1'b1:1'b0;
    
    assign rom_addr=cpu_addr;
    
    assign data=(cpu_addr==32'hBFD003F8)? uart_data:(cpu_addr==32'hBFD003FC)? uart_sign:(is_rom_data==1'b1)? rom_data:ram_data;

    assign ram_ce=((cpu_addr==32'hBFD003F8)||(cpu_addr==32'hBFD003FC)||(is_rom_data==1'b1))? 1'b1:not_ce;
    
    assign ready=(((ram_ready==`MEMready)||(rom_ready==`MEMready))||(cpu_addr==32'hBFD003F8)||(cpu_addr==32'hBFD003FC))? `MEMready:`MEMNoready;
    

    always @(posedge clk) begin 
        if(rst==`RstEnable) begin 
            uart_data<=`ZeroWord;
            uart_sign<=32'h00000001;
            rxd_clear<=1'b0;
            
            temp1_busy<=1'b0;
 
        end
        else begin 
           temp1_busy<=tsd_busy;

           if(uart_ready_i==`MEMready) begin 
               uart_data[7:0]<=uart_data_i;
               uart_sign<=32'h00000002;
           end
           
           if(cpu_addr==32'hBFD003F8&&ce==1'b1&&we==1'b0) begin //读串口
               rxd_clear<=1'b1;
               
           end
           else begin 
               rxd_clear<=1'b0;
           end
           if(rxd_clear==1'b1) begin 
               uart_sign<=32'h00000001;
           end
           if(cpu_addr==32'hBFD003F8&&ce==1'b1&&we==1'b1&&tsd_busy==1'b0) begin //写串口
               txd_start<=1'b1;
               uart_data_o<=cpu_data[7:0];
               uart_sign<=32'h00000000;
           end
           else begin 
               txd_start<=1'b0;
           end
           if((temp1_busy==1'b1)&&(tsd_busy==1'b0)) begin 
               uart_sign<=32'h00000001;
           end
        end
    end
    
    
endmodule


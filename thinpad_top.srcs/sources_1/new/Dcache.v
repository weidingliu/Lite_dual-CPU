`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/21 11:09:04
// Design Name: 
// Module Name: fetch
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
//////////////////////////////////////////////////////////////////////////////////写直达版cache
`include "defines.v"


module Dcache(
    input wire clk,
     input wire rst,
     input wire data_req_i, //CPU请求数据，低位有效
     input  wire[`RegBus] virtual_addr,//虚拟地址，待实现TLB
     input wire [`RegBus] write_data,
     input wire cpu_we,//读写信号，1位写，0位读
     output wire [19:0] ram_addr,
     //input wire ram_ready,
     input wire [`cache_lineBus]ram_data_i,//sram中取出的一行数据
     output reg cache_hit_o,//cache命中，高位有效
     output reg data_valid_o,//读出数据是否有效，高位有效
     output reg[31:0]data1,//读出数据的端口1
     output reg [31:0] data2,//读出数据的端口2
     output reg stopreq,
     output reg ce,
     output reg we,
     //与sram控制器的握手信号
     input wire write_finish,
     input wire read_finish,
     output reg addr_valid,//地址是否有效
     //写回一行数据
     output wire [`cache_lineBus]write_back_data,
     //是否输出单个数据,高位有效
     output reg is_single,
     //字节写使能信号
     input wire [3:0]sel,
     //在暂停流水时，cache内部的状态机也要重置，高位有效
     input wire cache_flush
    );
    wire [31:0]addr;//不对虚拟地址进行转换，需要使用物理地址时使用信号切片进行转换
    assign addr=virtual_addr;
   // wire [6:0]group_addr1;
   // wire [6:0]group_addr2;
    wire [`cache_lineBus]ram_data;
    //状态机定义
    reg[2:0] state;
    reg[2:0] next_state;
    //
    reg[31:0] way0_data;
    reg[31:0] way1_data;
    
    //reg[127:0] dirt_reg[1:0];//脏位，用于指示cache数据是否被写入
    reg [127:0] valid_reg[1:0];//cache行有效位
    reg[127:0] lru_reg;//为0表时way0最近没有用过，为1表示way1最近没有用过
    wire [6:0]group_addr;//
    wire [19:0]tag_way0;
    wire [19:0]tag_way1;
    
    reg tagv_way0_ena;//cache存储器使能
    reg tagv_way1_ena;
    reg tagv_way0_wea;//cache内部写使能
    reg tagv_way1_wea;
    wire [19:0]trgv_way0_out;
    wire [19:0]trgv_way0_in;
    wire [19:0]trgv_way1_out;
    wire [19:0]trgv_way1_in;
    reg hit_way0;
    reg hit_way1;
    
    wire lru_pik=lru_reg[group_addr];
    
    wire [31:0] way0_bank0;
    wire [31:0] way0_bank1;
    wire [31:0] way0_bank2;
    wire [31:0] way0_bank3;
    wire [31:0] way0_bank4;
    wire [31:0] way0_bank5;
    wire [31:0] way0_bank6;
    wire [31:0] way0_bank7;
    wire [31:0] way1_bank0;
    wire [31:0] way1_bank1;
    wire [31:0] way1_bank2;
    wire [31:0] way1_bank3;
    wire [31:0] way1_bank4;
    wire [31:0] way1_bank5;
    wire [31:0] way1_bank6;
    wire [31:0] way1_bank7;
    
    wire [31:0]addr2;
    reg [`cache_lineBus] write_temp;
    
    //assign ram_addr=(state==`Write_ram)? ((lru_reg[group_addr]==1'b0)? {tag_way0[9:0],group_addr,3'b000}:{tag_way1[9:0],group_addr,3'b000}):addr[21:2];
    assign ram_addr={addr[21:5],3'b000};
    assign group_addr=addr[11:5];//组地址传递
    //组地址传递
    //assign group_addr1=addr[11:5];////////////////////
    //assign addr2=addr+4'h4;//第二条数据地址
    //assign group_addr2=addr2[11:5];
    
    //assign is_same_line=(group_addr1==group_addr2)?1'b1:1'b0;
    
    assign tag_way0=trgv_way0_out;//取出way0的tag
    assign tag_way1=trgv_way1_out;//取出way1的tag
    assign trgv_way0_in=addr[31:12];
    assign trgv_way1_in=addr[31:12];
    
    //assign write_back_data=(lru_reg[group_addr]==1'b0)? {way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0}:{way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0}; 
    assign write_back_data=(state==`Write_data)? ram_data:write_temp;
    assign ram_data=(state==`Write_data &&cpu_we==1'b0)? ram_data_i://读未命中
                    //写未命中
                    (state==`Write_data && cpu_we==1'b1 && sel==4'b0000)? {ram_data_i[255:32],write_data}:
                    (state==`Write_data && cpu_we==1'b1 && sel==4'b1110)? {ram_data_i[255:8],write_data[7:0]}:
                    (state==`Write_data && cpu_we==1'b1 && sel==4'b1101)? {ram_data_i[255:16],write_data[7:0],ram_data_i[7:0]}:
                    (state==`Write_data && cpu_we==1'b1 && sel==4'b1011)? {ram_data_i[255:24],write_data[7:0],ram_data_i[15:0]}:
                    (state==`Write_data && cpu_we==1'b1 && sel==4'b0111)? {ram_data_i[255:32],write_data[7:0],ram_data_i[23:0]}:
                    //写命中
                    (state==`Scanf_cache && cpu_we==1'b1 )? write_temp:
                    256'b0;
                    
    always @(*) begin //生成写命中时写入的数据
        if(rst==`RstEnable) begin 
            write_temp=256'h0;
        end 
        else begin 
            write_temp=256'h0;
            if(state==`Scanf_cache && hit_way0==`hit) begin //way0写命中
                case(addr[4:2])
                    3'b000: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,write_data};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0[31:8],write_data[7:0]};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0[31:16],write_data[7:0],way0_bank0[7:0]};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0[31:24],write_data[7:0],way0_bank0[15:0]};
                            end
                            4'b0111: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,write_data[7:0],way0_bank0[23:0]};
                            end
                        
                        endcase
                    end
                    3'b001: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,write_data,way0_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1[31:8],write_data[7:0],way0_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1[31:16],write_data[7:0],way0_bank1[7:0],way0_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1[31:24],write_data[7:0],way0_bank1[15:0],way0_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,write_data[7:0],way0_bank1[23:0],way0_bank0};
                            end
                        
                        endcase
                    end
                    3'b010: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,write_data,way0_bank1,way0_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2[31:8],write_data[7:0],way0_bank1,way0_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2[31:16],write_data[7:0],way0_bank2[7:0],way0_bank1,way0_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2[31:24],write_data[7:0],way0_bank2[15:0],way0_bank1,way0_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,write_data[7:0],way0_bank2[23:0],way0_bank1,way0_bank0};
                            end
                        
                        endcase
                    end
                    3'b011: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,write_data,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3[31:8],write_data[7:0],way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3[31:16],write_data[7:0],way0_bank3[7:0],way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3[31:24],write_data[7:0],way0_bank3[15:0],way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4,write_data[7:0],way0_bank3[23:0],way0_bank2,way0_bank1,way0_bank0};
                            end
                        
                        endcase
                    end
                    3'b100: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,write_data,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4[31:8],write_data[7:0],way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4[31:16],write_data[7:0],way0_bank4[7:0],way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,way0_bank4[31:24],write_data[7:0],way0_bank4[15:0],way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5,write_data[7:0],way0_bank4[23:0],way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                        
                        endcase
                    end
                    3'b101: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way0_bank7,way0_bank6,write_data,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5[31:8],write_data[7:0],way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5[31:16],write_data[7:0],way0_bank5[7:0],way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7,way0_bank6,way0_bank5[31:24],write_data[7:0],way0_bank5[15:0],way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way0_bank7,way0_bank6,write_data[7:0],way0_bank5[23:0],way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                        
                        endcase
                    end
                    3'b110: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way0_bank7,write_data,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7,way0_bank6[31:8],write_data[7:0],way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7,way0_bank6[31:16],write_data[7:0],way0_bank6[7:0],way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7,way0_bank6[31:24],write_data[7:0],way0_bank6[15:0],way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way0_bank7,write_data[7:0],way0_bank6[23:0],way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                        
                        endcase
                    end
                    3'b111: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={write_data,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way0_bank7[31:8],write_data[7:0],way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way0_bank7[31:16],write_data[7:0],way0_bank7[7:0],way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way0_bank7[31:24],write_data[7:0],way0_bank7[15:0],way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                            4'b0111: begin 
                                write_temp={write_data[7:0],way0_bank7[23:0],way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0};
                            end
                        
                        endcase
                    end
                endcase
            end
            else if(state==`Scanf_cache && hit_way1==`hit) begin //way1写命中
                case(addr[4:2])
                    3'b000: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,write_data};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0[31:8],write_data[7:0]};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0[31:16],write_data[7:0],way1_bank0[7:0]};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0[31:24],write_data[7:0],way1_bank0[15:0]};
                            end
                            4'b0111: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,write_data[7:0],way1_bank0[23:0]};
                            end
                        
                        endcase
                    end
                    3'b001: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,write_data,way1_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1[31:8],write_data[7:0],way1_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1[31:16],write_data[7:0],way1_bank1[7:0],way1_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1[31:24],write_data[7:0],way1_bank1[15:0],way1_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,write_data[7:0],way1_bank1[23:0],way1_bank0};
                            end
                        
                        endcase
                    end
                    3'b010: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,write_data,way1_bank1,way1_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2[31:8],write_data[7:0],way1_bank1,way1_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2[31:16],write_data[7:0],way1_bank2[7:0],way1_bank1,way1_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2[31:24],write_data[7:0],way1_bank2[15:0],way1_bank1,way1_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,write_data[7:0],way1_bank2[23:0],way1_bank1,way1_bank0};
                            end
                        
                        endcase
                    end
                    3'b011: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,write_data,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3[31:8],write_data[7:0],way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3[31:16],write_data[7:0],way1_bank3[7:0],way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3[31:24],write_data[7:0],way1_bank3[15:0],way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4,write_data[7:0],way1_bank3[23:0],way1_bank2,way1_bank1,way1_bank0};
                            end
                        
                        endcase
                    end
                    3'b100: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,write_data,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4[31:8],write_data[7:0],way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4[31:16],write_data[7:0],way1_bank4[7:0],way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,way1_bank4[31:24],write_data[7:0],way1_bank4[15:0],way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5,write_data[7:0],way1_bank4[23:0],way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                        
                        endcase
                    end
                    3'b101: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way1_bank7,way1_bank6,write_data,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5[31:8],write_data[7:0],way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5[31:16],write_data[7:0],way1_bank5[7:0],way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7,way1_bank6,way1_bank5[31:24],write_data[7:0],way1_bank5[15:0],way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way1_bank7,way1_bank6,write_data[7:0],way1_bank5[23:0],way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                        
                        endcase
                    end
                    3'b110: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={way1_bank7,write_data,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7,way1_bank6[31:8],write_data[7:0],way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7,way1_bank6[31:16],write_data[7:0],way1_bank6[7:0],way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7,way1_bank6[31:24],write_data[7:0],way1_bank6[15:0],way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b0111: begin 
                                write_temp={way1_bank7,write_data[7:0],way1_bank6[23:0],way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                        
                        endcase
                    end
                    3'b111: begin 
                        case(sel)
                            4'b0000: begin 
                                write_temp={write_data,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1110: begin 
                                write_temp={way1_bank7[31:8],write_data[7:0],way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1101: begin 
                                write_temp={way1_bank7[31:16],write_data[7:0],way1_bank7[7:0],way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b1011: begin 
                                write_temp={way1_bank7[31:24],write_data[7:0],way1_bank7[15:0],way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                            4'b0111: begin 
                                write_temp={write_data[7:0],way1_bank7[23:0],way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0};
                            end
                        
                        endcase
                    end
                endcase
            end
            
            else begin 
                write_temp=(lru_reg[group_addr]==1'b1)? {way0_bank7,way0_bank6,way0_bank5,way0_bank4,way0_bank3,way0_bank2,way0_bank1,way0_bank0}:{way1_bank7,way1_bank6,way1_bank5,way1_bank4,way1_bank3,way1_bank2,way1_bank1,way1_bank0}; 
            end
        end
    end
    
    //状态转换
    always @(posedge clk) begin 
        if(rst==`RstEnable) begin 
            state<=`Look_UP;
        end
        else begin 
            state<=next_state;
        end
    end
    //更新LRU
    always @(posedge clk) begin 
        if(rst==`RstEnable) begin 
            lru_reg<=0;
        end
        else if(hit_way0==`hit) begin 
            lru_reg[group_addr]<=1'b1;
        end
        else if(hit_way1==`hit) begin 
            lru_reg[group_addr]<=1'b0;
        end
        else if(state==`Write_data && data_valid_o==`Data_valid && cache_hit_o==`miss_hit) begin 
            lru_reg[group_addr]<=~lru_reg[group_addr];//可以改进
        end
        else begin 
        
        end
    end
    //更新有效标志位
    always@(posedge clk) begin 
        if(rst==`RstEnable) begin 
            valid_reg[0]<=128'h0000_0000_0000_0000_0000_0000_0000_0000;
            valid_reg[1]<=128'h0000_0000_0000_0000_0000_0000_0000_0000;
        end
        else begin 
            if(state==`Write_data) begin
                valid_reg[lru_reg[group_addr]][group_addr]<=1'b1;
            end 
            else begin 
            
            end
        end
    end
    /*always @(posedge clk) begin 
         if(rst==`RstEnable) begin 
            dirt_reg[0]<=0;
            dirt_reg[1]<=0;
        end
        else begin 
            if(state==`Write_data && cpu_we==1'b0) begin //读未命中
                dirt_reg[lru_reg[group_addr]][group_addr]=1'b0;
            end
            else if(state==`Write_data && cpu_we==1'b1) begin //写未命中
                dirt_reg[lru_reg[group_addr]][group_addr]=1'b1;
            end
            else if(state==`Scanf_cache&& cache_hit_o==`hit&&cpu_we==1'b1) begin //写命中
                dirt_reg[hit_way1][group_addr]=1'b1;
            end
            else begin 
            
            end
        end
    end*/
    
    
       //判断way0是否命中
    always @(*) begin 
        if(rst==`RstEnable) begin 
            hit_way0=`miss_hit;
        end
        else begin 
            hit_way0=`miss_hit;
            
            if(valid_reg[0][group_addr]==`cache_way_valid) begin 
                if(tag_way0==addr[31:12]) begin //////////////////////////////////////////////////////////////////////////////////////////
                    hit_way0=`hit;
                    
                end
                else begin 
                    hit_way0=`miss_hit;
                end
            end
            else begin 
                hit_way0=`miss_hit;
                
            end
        end
    end
    //判断way1是否命中
    always @(*) begin 
        if(rst==`RstEnable) begin 
            hit_way1=`miss_hit;
            
        end
        else begin 
            hit_way1=`miss_hit;
            
            if(valid_reg[1][group_addr]==`cache_way_valid) begin 
                if(tag_way1==addr[31:12]) begin //////////////////////////////////////////////////////////////////////////////////////////
                    hit_way1=`hit;
                end
                else begin 
                    hit_way1=`miss_hit;
                end
            end
            else begin 
                hit_way1=`miss_hit;
            end
        end
    end
    
    //输出信号生成，组合逻辑
    always @(*) begin 
        if(rst==`RstEnable) begin 
            data_valid_o=   `Data_invalid;
            
            cache_hit_o=`miss_hit;
            stopreq=`NoStop;
            tagv_way0_ena=1'b0;
            tagv_way1_ena=1'b0;
            tagv_way0_wea=1'b0;
            tagv_way1_wea=1'b0;
            
            ce=`ChipDisable;
            we=1'b0;
            
            addr_valid=1'b0;
        end
        else begin 
            data_valid_o=   `Data_invalid;
            
            cache_hit_o=`miss_hit;
            stopreq=`NoStop;
            tagv_way0_ena=1'b0;
            tagv_way1_ena=1'b0;
            tagv_way0_wea=1'b0;
            tagv_way1_wea=1'b0;
            
            ce=`ChipDisable;
            we=1'b0;
            addr_valid=1'b0;
            case(state) 
                `Look_UP: begin 
                    if(data_req_i==1'b1) begin 
                        data_valid_o=   `Data_invalid;
                        
                        cache_hit_o=`miss_hit;
                        stopreq=`NoStop;
                        tagv_way0_ena=1'b0;
                        tagv_way1_ena=1'b0;
                        tagv_way0_wea=1'b0;
                        tagv_way1_wea=1'b0;
                    end
                    else begin //开始读取cache行
                        data_valid_o=`Data_invalid;
                        
                        cache_hit_o=`miss_hit;
                        stopreq=`Stop;
                        tagv_way0_ena=1'b1;
                        tagv_way1_ena=1'b1;
                        tagv_way0_wea=1'b0;
                        tagv_way1_wea=1'b0;
                        
                    end
                end
                `Scanf_cache: begin 
                    tagv_way0_ena=1'b1;
                    tagv_way1_ena=1'b1;
                    tagv_way0_wea=1'b0;
                    tagv_way1_wea=1'b0;  
                    if(hit_way0==`hit||hit_way1==`hit) begin //命中cache
                        if(cpu_we==1'b0) begin 
                            stopreq=`NoStop;
                            data_valid_o=`Data_valid;
                        end
                        else begin 
                            stopreq=`Stop;
                            data_valid_o=`Data_invalid;
                        end
                        cache_hit_o=`hit;
                        if(cpu_we==1'b1&& hit_way0==`hit) begin 
                            tagv_way0_ena=1'b1;
                            tagv_way1_ena=1'b0;
                            tagv_way0_wea=1'b1;
                            tagv_way1_wea=1'b0;
                        end
                        else if(cpu_we==1'b1&& hit_way1==`hit) begin 
                            tagv_way0_ena=1'b0;
                            tagv_way1_ena=1'b1;
                            tagv_way0_wea=1'b0;
                            tagv_way1_wea=1'b1;
                        end
                        else begin 
                        
                        end
                        
                    end
                    else begin //cache命中失败
                        data_valid_o=`Data_invalid;
                        
                        cache_hit_o=`miss_hit;
                        stopreq=`Stop;
                        
                    end
                    
                end
                `Miss_hit: begin 
                    data_valid_o=`Data_invalid;
                    cache_hit_o=`miss_hit;
                    stopreq=`Stop;
                    ce=`ChipEnable;
                    
                   
                    we=1'b0;
                    addr_valid=1'b1;
                  
                end 
                `Write_ram: begin 
                    
                    if(write_finish==1'b1) begin 
                        data_valid_o=`Data_valid;
                    
                        stopreq=`NoStop;
                    end
                    else begin 
                        data_valid_o=`Data_invalid;
                    
                        stopreq=`Stop;
                    end
                    ce=`ChipEnable;
                    
                    
                    we=1'b1;
                    addr_valid=1'b1;
                end
                `Write_data: begin 
                    if(cpu_we==1'b1) begin 
                        data_valid_o=`Data_invalid;
                        stopreq=`Stop;
                    end
                    else begin 
                        data_valid_o=`Data_valid;
                        stopreq=`NoStop;
                    end
                    
                    cache_hit_o=`miss_hit;
                    
                    if(lru_reg[group_addr]==1'b0) begin 
                        tagv_way0_ena=1'b1;
                        tagv_way1_ena=1'b0;
                        tagv_way0_wea=1'b1;
                        tagv_way1_wea=1'b0;
                    end
                    else if(lru_reg[group_addr]==1'b1) begin 
                        tagv_way0_ena=1'b0;
                        tagv_way1_ena=1'b1;
                        tagv_way0_wea=1'b0;
                        tagv_way1_wea=1'b1;
                    end
                    else begin 
                        tagv_way0_ena=1'b1;
                        tagv_way1_ena=1'b0;
                        tagv_way0_wea=1'b1;
                        tagv_way1_wea=1'b0;
                    end
                    
                end
            endcase
        end
    end
    
    
    always @(*) begin //生成data1输出,当命中时
      if(rst==`RstEnable) begin 
            data1=`ZeroWord;
            data2=`ZeroWord;
            is_single=1'b0;
        end
      else if(state==`Scanf_cache&&hit_way0==`hit)begin   
            data1=`ZeroWord;
            data2=`ZeroWord;
            is_single=1'b0;
            case(addr[4:2])/////////////////////////////////////////////
                        3'b000: begin 
                            data1=way0_bank0;
                            data2=way0_bank1;
                        end
                        3'b001:begin 
                            data1=way0_bank1;
                            data2=way0_bank2;
                        end
                        3'b010: begin 
                            data1=way0_bank2;
                            data2=way0_bank3;
                        end
                        3'b011: begin 
                            data1=way0_bank3;
                            data2=way0_bank4;
                        end
                        3'b100: begin 
                            data1=way0_bank4;
                            data2=way0_bank5;
                        end
                        3'b101: begin 
                            data1=way0_bank5;
                            data2=way0_bank6;
                        end
                        3'b110: begin 
                            data1=way0_bank6;
                            data2=way0_bank7;
                        end
                        3'b111:  begin 
                            data1=way0_bank7;
                            is_single=1'b1;
                        end
                        default: begin 
                            data1=`ZeroWord;
                            data2=`ZeroWord;
                            is_single=1'b0;
                        end
                    endcase
         end
         else if(state==`Scanf_cache&&hit_way1==`hit) begin 
             data1=`ZeroWord;
             data2=`ZeroWord;
             is_single=1'b0;
            case(addr[4:2])/////////////////////////////////////////////
                        3'b000: begin 
                            data1=way1_bank0;
                            data2=way1_bank1;
                        end
                        3'b001:begin 
                            data1=way1_bank1;
                            data2=way1_bank2;
                        end
                        3'b010: begin 
                            data1=way1_bank2;
                            data2=way1_bank3;
                        end
                        3'b011: begin 
                            data1=way1_bank3;
                            data2=way1_bank4;
                        end
                        3'b100: begin 
                            data1=way1_bank4;
                            data2=way1_bank5;
                        end
                        3'b101: begin 
                            data1=way1_bank5;
                            data2=way1_bank6;
                        end
                        3'b110: begin 
                            data1=way1_bank6;
                            data2=way1_bank7;
                        end
                        3'b111:  begin 
                            data1=way1_bank7;
                            is_single=1'b1;
                        end
                        default: begin 
                            data1=`ZeroWord;
                            data2=`ZeroWord;
                            is_single=1'b0;
                        end
                    endcase
         end
         else if(data_valid_o==`Data_valid && cache_hit_o==`miss_hit) begin 
                  data1=`ZeroWord;
                  data2=`ZeroWord;
                  is_single=1'b0;
                  case(addr[4:2])/////////////////////////////////////////////
                        3'b000: begin 
                            data1=ram_data[32*1-1:0*32];
                            data2=ram_data[32*2-1:1*32];
                        end
                        3'b001:begin 
                            data1=ram_data[32*2-1:1*32];
                            data2=ram_data[32*3-1:2*32];
                        end
                        3'b010: begin 
                            data1=ram_data[32*3-1:2*32];
                            data2=ram_data[32*4-1:3*32];
                        end
                        3'b011: begin 
                            data1=ram_data[32*4-1:3*32];
                            data2=ram_data[32*5-1:4*32];
                        end
                        3'b100: begin 
                            data1=ram_data[32*5-1:4*32];
                            data2=ram_data[32*6-1:5*32];
                        end
                        3'b101: begin 
                            data1=ram_data[32*6-1:5*32];
                            data2=ram_data[32*7-1:6*32];
                        end
                        3'b110: begin 
                            data1=ram_data[32*7-1:6*32];
                            data2=ram_data[32*8-1:7*32];
                        end
                        3'b111:  begin 
                            data1=ram_data[32*8-1:7*32];
                            is_single=1'b1;
                        end
                        default: begin 
                            data1=`ZeroWord;
                            data2=`ZeroWord;
                            is_single=1'b0;
                        end
                    endcase
             
         end
         else begin 
             data1=`ZeroWord;
             data2=`ZeroWord;
             is_single=1'b0;
         end                   
    end                        
    /*always @(*) begin //生成data1输出,当way1命中时
        if(rst==`RstEnable) begin 
            data=`ZeroWord;
        end
        
        
         else begin 
             data=`ZeroWord;
         end
    end*/
     
    
     //next_state生成，组合逻辑
    always @(*) begin 
        if(rst==`RstEnable) begin 
            next_state=`Look_UP;
        end
        else begin 
            
        if(cache_flush==1'b1) begin //重置状态机
            next_state=`Look_UP;
        end
        else begin 
            case(state) 
                `Look_UP: begin 
                    if(data_req_i==1'b0) begin 
                        next_state=`Scanf_cache;
                    end
                    else begin
                        next_state=`Look_UP;
                    end
                end
                `Scanf_cache: begin 
                     if(hit_way0==`hit||hit_way1==`hit) begin /////////////////////////////////////////////////////////////////////
                         if(cpu_we==1'b1) begin 
                             next_state=`Write_ram;
                         end
                         else begin 
                             next_state=`Look_UP;
                         end
                         
                     end
                    /* else if(dirt_reg[lru_reg[group_addr]][group_addr]==1'b1)begin 
                         next_state=`Write_ram;
                     end*/
                     else begin
                         next_state=`Miss_hit;
                     end
                 end
                 `Write_ram: begin 
                     if(write_finish==1'b1) begin 
                         next_state=`Look_UP;
                     end
                     else begin 
                         next_state=`Write_ram;
                     end
                 end
                 `Miss_hit: begin 
                     if(read_finish==1'b0) begin 
                         next_state=`Miss_hit;
                     end

                     else begin 
                        next_state=`Write_data;
                     end
                  end
                     
                 `Write_data:  begin 
                     if(cpu_we==1'b1) begin 
                         next_state=`Write_ram;
                     end
                      else begin 
                          next_state=`Look_UP;
                      end
                 end
                 
            endcase
        end
        end
    end
    TAGV_ram tagv_way0(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(trgv_way0_in),
    .douta(trgv_way0_out)
    );
    TAGV_ram tagv_way1(
     .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(trgv_way1_in),
    .douta(trgv_way1_out)
    );
    doublebank_ram way0_bank0_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*1-1:0*32]),
    .douta(way0_bank0)
    );
    doublebank_ram way0_bank1_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*2-1:1*32]),
    .douta(way0_bank1)
    );
    doublebank_ram way0_bank2_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*3-1:2*32]),
    .douta(way0_bank2)
    );
    doublebank_ram way0_bank3_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*4-1:3*32]),
    .douta(way0_bank3)
    );
    doublebank_ram way0_bank4_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*5-1:4*32]),
    .douta(way0_bank4)
    );
    doublebank_ram way0_bank5_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*6-1:5*32]),
    .douta(way0_bank5)
    );
    doublebank_ram way0_bank6_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*7-1:6*32]),
    .douta(way0_bank6)
    );
    doublebank_ram way0_bank7_ram(
    .clka(clk),
    .ena(tagv_way0_ena),
    .wea(tagv_way0_wea),
    .addra(group_addr),
    .dina(ram_data[32*8-1:7*32]),
    .douta(way0_bank7)
    );
    doublebank_ram way1_bank0_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*1-1:0*32]),
    .douta(way1_bank0)
    );
    doublebank_ram way1_bank1_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*2-1:1*32]),
    .douta(way1_bank1)
    );
    doublebank_ram way1_bank2_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*3-1:2*32]),
    .douta(way1_bank2)
    );
    doublebank_ram way1_bank3_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*4-1:3*32]),
    .douta(way1_bank3)
    );
    doublebank_ram way1_bank4_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*5-1:4*32]),
    .douta(way1_bank4)
    );
    doublebank_ram way1_bank5_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*6-1:5*32]),
    .douta(way1_bank5)
    );
    doublebank_ram way1_bank6_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*7-1:6*32]),
    .douta(way1_bank6)
    );
    doublebank_ram way1_bank7_ram(
    .clka(clk),
    .ena(tagv_way1_ena),
    .wea(tagv_way1_wea),
    .addra(group_addr),
    .dina(ram_data[32*8-1:7*32]),
    .douta(way1_bank7)
    );
    
    
endmodule
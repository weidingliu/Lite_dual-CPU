`timescale 1ns / 1ps
module tb;

wire clk_50M, clk_11M0592;

reg clock_btn = 0;         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
reg reset_btn = 0;         //BTN6手动复位按钮开关，带消抖电路，按下时为1

reg[3:0]  touch_btn;  //BTN1~BTN4，按钮开关，按下时为1
reg[31:0] dip_sw;     //32位拨码开关，拨到“ON”时为1

wire[15:0] leds;       //16位LED，输出时1点亮
wire[7:0]  dpy0;       //数码管低位信号，包括小数点，输出1点亮
wire[7:0]  dpy1;       //数码管高位信号，包括小数点，输出1点亮

wire txd;  //直连串口发送端
wire rxd;  //直连串口接收端

wire[31:0] base_ram_data; //BaseRAM数据，低8位与CPLD串口控制器共享
wire[19:0] base_ram_addr; //BaseRAM地址
wire[3:0] base_ram_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
wire base_ram_ce_n;       //BaseRAM片选，低有效
wire base_ram_oe_n;       //BaseRAM读使能，低有效
wire base_ram_we_n;       //BaseRAM写使能，低有效

wire[31:0] ext_ram_data; //ExtRAM数据
wire[19:0] ext_ram_addr; //ExtRAM地址
wire[3:0] ext_ram_be_n;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
wire ext_ram_ce_n;       //ExtRAM片选，低有效
wire ext_ram_oe_n;       //ExtRAM读使能，低有效
wire ext_ram_we_n;       //ExtRAM写使能，低有效

wire [22:0]flash_a;      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
wire [15:0]flash_d;      //Flash数据
wire flash_rp_n;         //Flash复位信号，低有效
wire flash_vpen;         //Flash写保护信号，低电平时不能擦除、烧写
wire flash_ce_n;         //Flash片选信号，低有效
wire flash_oe_n;         //Flash读使能信号，低有效
wire flash_we_n;         //Flash写使能信号，低有效
wire flash_byte_n;       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

//Windows需要注意路径分隔符的转义，例如"D:\\foo\\bar.bin"
parameter BASE_RAM_INIT_FILE = "D:\\nscscc2021_single\\nscscc2021\\fpga_template_gbk_v1.00\\sram\\lab2.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
parameter EXT_RAM_INIT_FILE = "D:\\nscscc2021_single\\nscscc2021\\fpga_template_gbk_v1.00\\sram\\data_ram.bin";   //ExtRAM初始化文件，请修改为实际的绝对路径
parameter FLASH_INIT_FILE = "/tmp/kernel.elf";    //Flash初始化文件，请修改为实际的绝对路径

assign rxd = 1'b1; //idle state

initial begin 
    //在这里可以自定义测试输入序列，例如：
    dip_sw = 32'h2;
    touch_btn = 0;
    reset_btn = 1;
    #100;
    reset_btn = 0;
    for (integer i = 0; i < 20; i = i+1) begin
        #100; //等待100ns
        clock_btn = 1; //按下手工时钟按钮
        #100; //等待100ns
        clock_btn = 0; //松开手工时钟按钮
    end
end

// 待测试用户设计
thinpad_top dut(
    .clk_50M(clk_50M),
    .clk_11M0592(clk_11M0592),
    .clock_btn(clock_btn),
    .reset_btn(reset_btn),
    .touch_btn(touch_btn),
    .dip_sw(dip_sw),
    .leds(leds),
    .dpy1(dpy1),
    .dpy0(dpy0),
    .txd(txd),
    .rxd(rxd),
    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    .base_ram_be_n(base_ram_be_n),
    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),
    .ext_ram_be_n(ext_ram_be_n),
    .flash_d(flash_d),
    .flash_a(flash_a),
    .flash_rp_n(flash_rp_n),
    .flash_vpen(flash_vpen),
    .flash_oe_n(flash_oe_n),
    .flash_ce_n(flash_ce_n),
    .flash_byte_n(flash_byte_n),
    .flash_we_n(flash_we_n)
);
// 时钟源
clock osc(
    .clk_11M0592(clk_11M0592),
    .clk_50M    (clk_50M)
);

// BaseRAM 仿真模型
sram_model base1(/*autoinst*/
            .DataIO(base_ram_data[15:0]),
            .Address(base_ram_addr[19:0]),
            .OE_n(base_ram_oe_n),
            .CE_n(base_ram_ce_n),
            .WE_n(base_ram_we_n),
            .LB_n(base_ram_be_n[0]),
            .UB_n(base_ram_be_n[1]));
sram_model base2(/*autoinst*/
            .DataIO(base_ram_data[31:16]),
            .Address(base_ram_addr[19:0]),
            .OE_n(base_ram_oe_n),
            .CE_n(base_ram_ce_n),
            .WE_n(base_ram_we_n),
            .LB_n(base_ram_be_n[2]),
            .UB_n(base_ram_be_n[3]));
// ExtRAM 仿真模型
sram_model ext1(/*autoinst*/
            .DataIO(ext_ram_data[15:0]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[0]),
            .UB_n(ext_ram_be_n[1]));
sram_model ext2(/*autoinst*/
            .DataIO(ext_ram_data[31:16]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[2]),
            .UB_n(ext_ram_be_n[3]));
// Flash 仿真模型
x28fxxxp30 #(.FILENAME_MEM(FLASH_INIT_FILE)) flash(
    .A(flash_a[1+:22]), 
    .DQ(flash_d), 
    .W_N(flash_we_n),    // Write Enable 
    .G_N(flash_oe_n),    // Output Enable
    .E_N(flash_ce_n),    // Chip Enable
    .L_N(1'b0),    // Latch Enable
    .K(1'b0),      // Clock
    .WP_N(flash_vpen),   // Write Protect
    .RP_N(flash_rp_n),   // Reset/Power-Down
    .VDD('d3300), 
    .VDDQ('d3300), 
    .VPP('d1800), 
    .Info(1'b1));

initial begin 
    wait(flash_byte_n == 1'b0);
    $display("8-bit Flash interface is not supported in simulation!");
    $display("Please tie flash_byte_n to high");
    $stop;
end

// 从文件加载 BaseRAM
initial begin 
    reg [31:0] tmp_array[0:10000];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open BaseRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("BaseRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        base1.mem_array0[i] = tmp_array[i][24+:8];
        base1.mem_array1[i] = tmp_array[i][16+:8];
        base2.mem_array0[i] = tmp_array[i][8+:8];
        base2.mem_array1[i] = tmp_array[i][0+:8];
       
       /*base1.mem_array0[i] = tmp_array[i][0+:8];
        base1.mem_array1[i] = tmp_array[i][8+:8];
        base2.mem_array0[i] = tmp_array[i][16+:8];
        base2.mem_array1[i] = tmp_array[i][24+:8];*/
    end
end

// 从文件加载 ExtRAM
initial begin 
    reg [31:0] tmp_array[0:10000];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open ExtRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("ExtRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        ext1.mem_array0[i] = tmp_array[i][24+:8];
        ext1.mem_array1[i] = tmp_array[i][16+:8];
        ext2.mem_array0[i] = tmp_array[i][8+:8];
        ext2.mem_array1[i] = tmp_array[i][0+:8];
    end
end
/*

reg [255:0]write_data;
wire [255:0] read_data;
reg [19:0] addr;
reg [31:0] virtual_addr;
reg we,addr_valid;
reg cpu_we,data_req;
wire write_finish,read_finish;
reg [31:0] write_data1;
reg [3:0]sel;
initial begin 
#200
    data_req=1'b0;
    virtual_addr=32'h00000000;
    cpu_we=1'b0;
    sel=4'b0000;
    //#220 data_req=1'b1;
#260
data_req=1'b0;
    virtual_addr=32'h0000001f;
    cpu_we=1'b0;
    sel=4'b0000;
    #40 virtual_addr=32'h00000004;
    #40 virtual_addr=32'h0000001f;
    cpu_we=1'b1;
    write_data1=32'hffffffff;
    #40 virtual_addr=32'h0000001f;
    cpu_we=1'b0;
    #40 virtual_addr=32'h0000101f;
    //#260 virtual_addr=32'h0000201f;
    //#260 virtual_addr=32'h0000001f;
end
icache cache(
      .clk(clk_50M),
     .rst(reset_btn),
     .data_req_i(data_req), //CPU请求数据，低位有效
     .virtual_addr(virtual_addr),//虚拟地址，待实现TLB
     .write_data(write_data1),
     .cpu_we(cpu_we),//读写信号，1位写，0位读
     .ram_addr(addr),
     //input wire ram_ready,
     .ram_data_i(read_data),//sram中取出的一行数据
     .cache_hit_o(),//cache命中，高位有效
     .data_valid_o(),//读出数据是否有效，高位有效
     .data1(),//读出数据的端口1
     .data2(),//读出数据的端口2
     .stopreq(),
     .ce(addr_valid),
    .we(we),
     //与sram控制器的握手信号
     .write_finish(write_finish),
     .read_finish(read_finish),
     .addr_valid(addr_valid),//地址是否有效
     //写回一行数据
     .write_back_data(write_data),
     //是否输出单个数据,高位有效
     .is_single(),
     //字节写使能信号
     .sel(sel)
);



isram_ctrl carl(
    .clk(clk_50M),
     .rst(reset_btn),
    
     .write_data(write_data),//cache替换出的数据
     .addr(addr),//写或者读地址
     .we(we),//读写信号，1为写，0为读
     
     //握手信号
     .addr_valid(addr_valid),//输入地址有效,高有效
     .write_finish(write_finish),//写回数据完成,高有效
     .read_finish(read_finish),//读取数据完成，高有效
     //读出的数据
     .read_data(read_data),//读取的数据
     //发送给sram的信号
    .data(ext_ram_data),//双向数据传输端口
    .ram_ce(ext_ram_ce_n),//ram片选信号，低有效
    .ram_oe(ext_ram_oe_n),//读使能，低有效
    .ram_we(ext_ram_we_n),//写使能，低有效
    .ram_addr(ext_ram_addr),//读写数据地址
    .ram_sel(ext_ram_be_n)//字节片选信号，0有效
);*/

wire [31:0]po,po1,po2;
assign po={ext2.mem_array1[3],ext2.mem_array0[3],ext1.mem_array1[3],ext1.mem_array0[3]};
assign po1={ext2.mem_array1[1],ext2.mem_array0[1],ext1.mem_array1[1],ext1.mem_array0[1]};
assign po2={ext2.mem_array1[0],ext2.mem_array0[0],ext1.mem_array1[0],ext1.mem_array0[0]};
initial begin 
    #17000000 dut.mem_ctrl.uart_data=32'h00000054;
    dut.mem_ctrl.uart_sign=32'h00000002;
end
endmodule

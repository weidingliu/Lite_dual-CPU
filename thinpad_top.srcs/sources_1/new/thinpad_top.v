`default_nettype none
`include "defines.v"
module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );
wire [`cache_lineBus] inst_read_data,inst_write_data;
wire inst_read_finish,inst_write_finish,inst_addr_valid,we;
wire [19:0] inst_addr;
wire sram_flush;

wire [`cache_lineBus] ram_read_data,dcache_write_data;
wire ram_read_finish,ram_write_finish,ram_addr_valid,ram_we;
wire [19:0] ram_addr;
wire dsram_flush;

wire ram_data_req_i;//CPU请求数据，低位有效
wire[`RegBus] ram_virtual_addr;//虚拟地址，待实现TLB
wire [`RegBus] ram_write_data;//写数据
wire ram_cpu_we;//读写信号，1位写，0位读
wire [3:0]sel;//字节使能信号
wire [`RegBus]mem_data_i;//存储单元送入的数据
wire [31:0] mem_data_o;
wire dcache_valid,ready,dcache_req,data_valid,dcache_stop;

wire [31:0] read_rom_addr,mem_rom_data;
  wire [31:0] read_rom_data;
  wire is_rom_data;
  wire [31:0] inst;
  wire is_write_rom;
  wire [31:0] write_rom_data;
  wire base_ram_oe,base_ram_we;
  wire is_clearn_inst;
  wire relive;
  wire [19:0] inst_addr2;
  wire base_ram_ce;
  wire mem_stop;
  
  assign base_ram_ce_n=(is_rom_data==1'b1)? 1'b0:base_ram_ce;


  assign base_ram_addr=((is_rom_data==1'b1)&&(is_clearn_inst==1'b1))? read_rom_addr[22:2]:inst_addr2;
  assign base_ram_be_n=(is_rom_data==1'b0)?4'b0000:sel;
 // assign mem_rom_data=(is_write_rom==1'b1)? write_rom_data:32'bz;
  assign base_ram_data=(is_write_rom==1'b1)? write_rom_data:32'bz;//////////////
//assign base_ram_data=(is_rom_data==1'b1)?  mem_rom_data:inst;
  
  assign base_ram_oe_n=(is_write_rom==1'b1)?1'b1:(is_rom_data==1'b1)?1'b0:base_ram_oe;
  assign base_ram_we_n=(is_write_rom==1'b1)?1'b0:base_ram_we;
  //assign base_ram_oe_n=base_ram_oe;
  //assign base_ram_we_n=base_ram_we;
  //assign inst=((is_rom_data==1'b1)&&(is_clearn_inst==1'b1))? 32'b0:base_ram_data;
  //assign inst_read_data=((is_rom_data==1'b1)&&(is_clearn_inst==1'b1))? 32'b0:base_ram_data;
  //assign inst=(is_rom_data==1'b1)? 32'b0:~base_ram_oe_n? base_ram_data:32'bz;////////////////
  assign read_rom_data=~base_ram_oe_n? base_ram_data:32'bz;

MIPS mips(
 .rst(reset_btn),
    .clk(clk_50M),
    
    .is_rom_data(is_rom_data),
    .relive(relive),
    
    
    //与指令sram
    .addr(inst_addr),
    .read_data(inst_read_data),
    .write_data(inst_write_data),
    .write_finish(inst_write_finish),
    .read_finish(inst_read_finish),
    .addr_valid(inst_addr_valid),
    .cpu_we(we),
    .isram_flush(sram_flush),
    
    //送入arm
    .ram_data_req_i(ram_data_req_i), //CPU请求数据，低位有效
    .ram_virtual_addr(ram_virtual_addr),//虚拟地址，待实现TLB
    .ram_write_data(ram_write_data),//写数据
    .ram_cpu_we(ram_cpu_we),//读写信号，1位写，0位读
	.sel(sel),//字节使能信号
	.mem_data_i(mem_data_i),//存储单元送入的数据
    .ready(ready),
    .cache_stop(mem_stop)
);
mem_ctrl mem_ctrl(
     .clk(clk_50M),
      .rst(reset_btn),
      .cpu_addr(ram_virtual_addr),//CPU传递的地址
      .ram_data(mem_data_o),//ram返回的信号
      .uart_data_i(ext_uart_rx),
      .cpu_data(ram_write_data),
      .uart_ready_i(ext_uart_ready),

      .we(ram_cpu_we),
      .not_ce(ram_data_req_i),
      .ram_ready(data_valid),
      .data(mem_data_i),//ram_data
      .ready(ready),//访存是否结束，高有效
      //读rom
     .rom_data(read_rom_data),
    .rom_addr(read_rom_addr),
    .is_rom_data(is_rom_data),
      
    .ram_ce(dcache_req),
    
    .cache_stop(dcache_stop),//cache的暂停信号
    .stop_req(mem_stop),
    
    .rxd_clear(ext_uart_clear),
    .tsd_busy(ext_uart_busy),
    .uart_data_o(ext_uart_tx),
    .txd_start(ext_uart_start),
    //写rom
    .rom_data_o(write_rom_data),
    .is_write_rom(is_write_rom),
    .is_clearn_inst(is_clearn_inst),
    .relive(relive)


);

Dcache Dcache(
     .clk(clk_50M),
     .rst(reset_btn),
     .data_req_i(dcache_req), //CPU请求数据，低位有效
     .virtual_addr(ram_virtual_addr),//虚拟地址，待实现TLB
     .write_data(ram_write_data),
     .cpu_we(ram_cpu_we),//读写信号，1位写，0位读
     .ram_addr(ram_addr),
     //input wire ram_ready,
     .ram_data_i(ram_read_data),//sram中取出的一行数据
     .cache_hit_o(),//cache命中，高位有效
     .data_valid_o(data_valid),//读出数据是否有效，高位有效
     .data1(mem_data_o),//读出数据的端口1
     .data2(),//读出数据的端口2
     //.stopreq(dcache_valid),
     .stopreq(dcache_stop),
     .we(ram_we),
     //与sram控制器的握手信号
     .write_finish(ram_write_finish),
     .read_finish(ram_read_finish),
     .addr_valid(ram_addr_valid),//地址是否有效
     //写回一行数据
     .write_back_data(dcache_write_data),
     //是否输出单个数据,高位有效
     .is_single(),
     //字节写使能信号
     .sel(sel),
     //重置信号
     .cache_flush()

);

dsram_ctrl dsram_carl(
    .clk(clk_50M),
     .rst(reset_btn),
    
     .write_data(dcache_write_data),//cache替换出的数据
     .addr(ram_addr),//写或者读地址
     .we(ram_we),//读写信号，1为写，0为读
     .sram_flush(dsram_flush),//sram状态机重置
     
     //握手信号
     .addr_valid(ram_addr_valid),//输入地址有效,高有效
     .write_finish(ram_write_finish),//写回数据完成,高有效
     .read_finish(ram_read_finish),//读取数据完成，高有效
     //读出的数据
     .read_data(ram_read_data),//读取的数据
     //发送给sram的信号
    .data(ext_ram_data),//双向数据传输端口
    .ram_ce(ext_ram_ce_n),//ram片选信号，低有效
    .ram_oe(ext_ram_oe_n),//读使能，低有效
    .ram_we(ext_ram_we_n),//写使能，低有效
    .ram_addr(ext_ram_addr),//读写数据地址
    .ram_sel(ext_ram_be_n)//字节片选信号，0有效
);

isram_ctrl isram_carl(
    .clk(clk_50M),
     .rst(reset_btn),
    
     .write_data(inst_write_data),//cache替换出的数据
     .addr(inst_addr),//写或者读地址
     .we(we),//读写信号，1为写，0为读
     .sram_flush(sram_flush),//sram状态机重置
     
     //握手信号
     .addr_valid(inst_addr_valid),//输入地址有效,高有效
     .write_finish(inst_write_finish),//写回数据完成,高有效
     .read_finish(inst_read_finish),//读取数据完成，高有效
     //读出的数据
     .read_data(inst_read_data),//读取的数据
     //发送给sram的信号
    .data(base_ram_data),//双向数据传输端口
    .ram_ce(base_ram_ce),//ram片选信号，低有效
    .ram_oe(base_ram_oe),//读使能，低有效
    .ram_we(base_ram_we),//写使能，低有效
    .ram_addr(inst_addr2),//读写数据地址
    .ram_sel()//字节片选信号，0有效
);



reg reset_of_clk10M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end

always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        // Your Code
    end
    else begin
        // Your Code
    end
end

// 不使用内存、串口时，禁用其使能信号
/*assign base_ram_ce_n = 1'b1;
assign base_ram_oe_n = 1'b1;
assign base_ram_we_n = 1'b1;

assign ext_ram_ce_n = 1'b1;
assign ext_ram_oe_n = 1'b1;
assign ext_ram_we_n = 1'b1;*/

// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

reg[15:0] led_bits;
assign leds = led_bits;

always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //复位按下，设置LED为初始值
        led_bits <= 16'h1;
    end
    else begin //每次按下时钟按钮，LED循环左移
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//直连串口接收发送演示，从直连串口收到的数据再发送出去
/*wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;
    
assign number = ext_uart_buffer;*/

wire [7:0] ext_uart_rx;
wire  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
wire ext_uart_start, ext_uart_avai;

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_50M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );

/*assign ext_uart_clear = ext_uart_ready; //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中
always @(posedge clk_50M) begin //接收到缓冲区ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //将缓冲区ext_uart_buffer发送出去
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end
*/
async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_50M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //横坐标
    .vdata(),      //纵坐标
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */
ila_0 ila(
.clk(clk_50M),

.probe0(mips.Regfile.regs[17]),
.probe1(mips.Decode.issue_inst1_o),
.probe2(base_ram_addr),
.probe3(mem_data_i),
//.probe4(base_ram_oe_n),
.probe4(mips.Decode.issue_inst2_o),
.probe5(mips.Regfile.regs[4]),
.probe6(mem_ctrl.cpu_data)
);
endmodule

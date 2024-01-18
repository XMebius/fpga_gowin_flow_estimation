 
//`define COLOR_IN

module top(
	input            clk          ,    // 27m
	input            rst_n        ,
// ov5640                         
	inout            cam_scl      ,          //cmos i2c clock
	inout            cam_sda      ,          //cmos i2c data
	input            cam_vsync    ,        //cmos vsync
	input            cam_href     ,         //cmos hsync refrence,data valid
	input            cam_pclk     ,         //cmos pxiel clock
    output           cam_xclk     ,         //cmos externl clock 
	input   [7:0]    cam_data     ,           //cmos data
	output           cam_rst_n    ,        //cmos reset 
	output           cam_pwdn     ,         //cmos power down
// HDMI TX           
    output           O_tmds_clk_p ,
    output           O_tmds_clk_n ,
    output     [2:0] O_tmds_data_p,//{r,g,b}
    output     [2:0] O_tmds_data_n,
// LED	             
	output     [3:0] state_led    ,
// DDR3              
	output [14-1:0]  O_ddr_addr   ,       //ROW_WIDTH=14
	output [3-1:0]   O_ddr_ba     ,       //BANK_WIDTH=3
	output           O_ddr_cs_n   ,
	output           O_ddr_ras_n  ,
	output           O_ddr_cas_n  ,
	output           O_ddr_we_n   ,
	output           O_ddr_clk    ,
	output           O_ddr_clk_n  ,
	output           O_ddr_cke    ,
	output           O_ddr_odt    ,
	output           O_ddr_reset_n,
	output [2-1:0]   O_ddr_dqm    ,         //DM_WIDTH=2
	inout [16-1:0]   IO_ddr_dq    ,         //DQ_WIDTH=16
	inout [2-1:0]    IO_ddr_dqs   ,        //DQS_WIDTH=2
	inout [2-1:0]    IO_ddr_dqs_n       //DQS_WIDTH=2  
);

//memory interface
wire                   memory_clk         ;
wire                   dma_clk         	  ;
wire                   DDR_pll_lock           ;
wire                   cmd_ready          ;
wire[2:0]              cmd                ;
wire                   cmd_en             ;
wire[5:0]              app_burst_number   ;
wire[ADDR_WIDTH-1:0]   addr               ;
wire                   wr_data_rdy        ;
wire                   wr_data_en         ;//
wire                   wr_data_end        ;//
wire[DATA_WIDTH-1:0]   wr_data            ;   
wire[DATA_WIDTH/8-1:0] wr_data_mask       ;   
wire                   rd_data_valid      ;  
wire                   rd_data_end        ;//unused 
wire[DATA_WIDTH-1:0]   rd_data            ;   
wire                   init_calib_complete;

//According to IP parameters to choose
`define	USE_THREE_FRAME_BUFFER
//
//=========================================================
//SRAM parameters
parameter ADDR_WIDTH          = 28;    //存储单元是byte，总容量=2^27*16bit = 2Gbit,增加1位rank地址，{rank[0],bank[2:0],row[13:0],cloumn[9:0]}
parameter DATA_WIDTH          = 128;   //与生成DDR3IP有关，此ddr3 2Gbit, x16， 时钟比例1:4 ，则固定128bit
parameter WR_VIDEO_WIDTH      = 16;    //写视频数据位宽  
parameter RD_VIDEO_WIDTH      = 32;    //读视频数据位宽 

////////// 图像缩放控制参数,很重要,只需要改这里就可以控制输出分辨率了
parameter INPUT_VIDEO_WIDTH   = 640;   // 输入视频宽度
parameter INPUT_VIDEO_HIGTH   = 480;   // 输入视频高度
parameter OUTPUT_VIDEO_WIDTH  = 640;   // 输出视频宽度
parameter OUTPUT_VIDEO_HIGTH  = 480;   // 输出视频高度

wire video_clk;         //video pixel clock
wire serial_clk;
wire TMDS_DDR_pll_lock;
wire hdmi4_rst_n;
assign hdmi4_rst_n = rst_n & TMDS_DDR_pll_lock;

//wire[15:0] 						write_data;
wire        cam_init_done;
wire        ov5640_vs  ;   
wire        ov5640_de  ;  
wire [23:0] ov5640_data;	

wire [23:0] color_video_rgb;
wire        color_video_de ;
wire        color_video_vs ;

wire        vtc_hs_out ;
wire        vtc_vs_out ;
wire        vtc_de_out ;
wire [7:0] vtc_rgb_out;
wire        vtc_req_out;

assign cam_xclk = cmos_clk;
assign cam_pwdn = 1'b0;
assign cam_rst_n = 1'b1;
assign hdmi_hpd = 1;

//状态指示灯
// assign state_led[3] = 
assign state_led[2] = lcd_vs_cnt[4];
assign state_led[1] = rst_n; //复位指示灯
assign state_led[0] = init_calib_complete; //DDR3初始化指示灯

reg [4:0] lcd_vs_cnt;
always@(posedge vtc_vs_out) lcd_vs_cnt <= lcd_vs_cnt + 1;

wire                      out_Video_can_read; 
wire [WR_VIDEO_WIDTH-1:0] out_Video_Frame_data;

wire        video_scale_data_vs  ; 
wire        video_scale_data_de  ;
wire [23:0] video_scale_data_out ;
wire [23:0] scaler_fifo_rdout_out;
wire [23:0] gray_data_in = video_scale_data_out;
wire [7:0]  gray_data_o;
wire [7:0]  sp_data_o;
wire empty            ;
wire o_vid_fifo_read  ;

`ifdef COLOR_IN
wire        scaler_fifo_rst_in  = color_video_vs ;
wire        scaler_fifo_wclk_in = video_clk      ;
wire        scaler_fifo_wden_in = color_video_de ;
wire [23:0] scaler_fifo_wdin_in = color_video_rgb;
wire        video_scale_vs_in   = color_video_vs ;
`else
wire        scaler_fifo_rst_in  = !cam_init_done || ov5640_vs;
wire        scaler_fifo_wclk_in = cam_pclk                   ;
wire        scaler_fifo_wden_in = ov5640_de                  ;
wire [23:0] scaler_fifo_wdin_in = ov5640_data                ;
wire        video_scale_vs_in   = ov5640_vs                  ;
`endif

wire scaler_reset        = !cam_init_done || !rst_n;
wire gray_reset = !cam_init_done || !rst_n;
wire scaler_fifo_rclk_in = video_clk       ;
wire rgb_gray_clk = video_clk;
wire scaler_fifo_rden_in = o_vid_fifo_read;
wire gray_out_de;

wire                      in_Video_Frame_clk  = scaler_fifo_rclk_in;
wire                      in_Video_Frame_vs   = !video_scale_data_vs;

wire                      gray_in_de   = video_scale_data_de;
wire                      in_Video_Frame_de   = gray_out_de;
wire [WR_VIDEO_WIDTH-1:0] in_Video_Frame_data = {8'h00,sp_data_o};

wire out_Video_Frame_clk = video_clk  ; 
wire out_Video_Frame_vs  = !vtc_vs_out; 
wire out_Video_Frame_de  = vtc_req_out; 
wire [7:0] vtc_rgb_in   = out_Video_Frame_data[7:0];

/////////////////////// 时钟 PLL
// 生成 1280*720@60Hz 视频所需的 371.25 M 串行时钟
TMDS_rPLL u_tmds_rpll(
	.clkin     (clk       ),     //input clk 
	.clkout    (serial_clk),     // 371.25 M
	.lock      (TMDS_DDR_pll_lock)     //output lock
);

defparam u_clkdiv.DIV_MODE="5"; // 5分频
defparam u_clkdiv.GSREN="false";
// 生成 1280*720@60Hz 视频所需的 74.25 M 像素时钟
CLKDIV u_clkdiv(
	.RESETN(hdmi4_rst_n),
	.HCLKIN(serial_clk ),   // 371.25 M
	.CLKOUT(video_clk  ),    // 371.25/5=74.25 M
	.CALIB (1'b1       )
);

// 生成 ov5640摄像头所需的 24 M 驱动时钟,如果你的摄像头自带了晶振,则不需要此时钟
cmos_pll u_cmos_pll(
	.clkin (clk     ),	// 27 M
	.clkout(cmos_clk)	// 24 M
);

// 生成 DDR3 所需的 400 M 驱动时钟
mem_pll u_mem_pll(
	.clkin (clk         ),	// 27 M
	.clkout(memory_clk 	),	// 400 M
	.lock  (DDR_pll_lock)
);

// 动态彩条模块	
video_block_move #(
    .H_DISP            (640      ),   //video h
    .V_DISP            (480       ),   //video v
    .VIDEO_CLK         (74250000  ),   //video clk
    .BLOCK_CLK         (100       ),   //move block clk
    .SIDE_W            (20        ),   //screen side size
    .BLOCK_W           (40        ),   //move block size
    .SCREEN_SIDE_COLOR (24'h7b7b7b),   //screen side color
    .SCREEN_BKG_COLOR  (24'hffffff),   //screen background color
    .MOVE_BLOCK_COLOR  (24'hffc0cb)    //move block color
)video_block(
    .pixel_clk(video_clk      ),
	.sys_rst_n(rst_n    ),
	.video_hs (),
	.video_vs (color_video_vs ),
	.video_de (color_video_de ),
	.video_rgb(color_video_rgb)
);

// ov5640 i2c 配置模块
ov5640_i2c #(
	.SENSOR_ADDR(8'h78),
	.DISPAY_H   (640 ),
	.DISPAY_V   (480 )
)u_ov5640_i2c(
	.clk        (clk          ),
	.reset_h    (!rst_n       ),
	.clk_div_cnt(16'd500      ),	//clk_div_cnt=clk/(5*i2c_scl)-1	
    .sensor_scl (cam_scl      ),  
    .sensor_sda (cam_sda      ),  
	.i2c_cgf_ok (cam_init_done)
);

// ov5640 数据采集模块
ov5640_rx #(
	.RGB_TYPE(1)	//0-->RGB565  1-->RGB888
)u_ov5640_rx(
    .rstn_i      (rst_n || cam_init_done),
	.cmos_clk_i  (),//cmos senseor clock.
	.cmos_pclk_i (cam_pclk   ),//input pixel clock.
	.cmos_href_i (cam_href   ),//input pixel hs signal.
	.cmos_vsync_i(cam_vsync  ),//input pixel vs signal.
	.cmos_data_i (cam_data   ),//data.
	.cmos_xclk_o (           ),//output clock to cmos sensor.如果你的摄像头自带晶振，则此信号不需要
    .rgb_o       (ov5640_data),
    .de_o        (ov5640_de  ),
    .vs_o        (ov5640_vs  ),
    .hs_o        ()
);

// 数据缓冲 FIFO
resize_fifo u_resize_fifo(
    .Data(scaler_fifo_wdin_in), //input [23:0] Data
    .WrReset(scaler_fifo_rst_in), //input Reset
    .RdReset(scaler_fifo_rst_in), //input Reset
    .WrClk(scaler_fifo_wclk_in), //input WrClk
    .RdClk(scaler_fifo_rclk_in), //input RdClk
    .WrEn(scaler_fifo_wden_in), //input WrEn
    .RdEn(scaler_fifo_rden_in), //input RdEn
    .Q(scaler_fifo_rdout_out), //output [23:0] Q
    .Empty(empty), //output Empty
    .Full() //output Full
);

// 图像缩放模块
helai_video_scale #(
	.DATA_WIDTH         (8 ),		//Width of input/output data
	.CHANNELS           (3 ),		//Number of channels of DATA_WIDTH, for color images
	.DISCARD_CNT_WIDTH  (8 ),		//Width of inputDiscardCnt
	.INPUT_X_RES_WIDTH  (11),		//Widths of input/output resolution control signals
	.INPUT_Y_RES_WIDTH  (11),
	.OUTPUT_X_RES_WIDTH (11),
	.OUTPUT_Y_RES_WIDTH (11),
	.FRACTION_BITS      (8 ),		//Number of bits for fractional component of coefficients.
	.SCALE_INT_BITS     (8 ),		//Width of integer component of scaling factor. The maximum input data width to
	.SCALE_FRAC_BITS    (14),		//Width of fractional component of scaling factor
	.BUFFER_SIZE        (4 )		//Depth of RFIFO	
)u_helai_video_scale(
	.clk             (scaler_fifo_rclk_in  ),
	.rst             (scaler_reset         ),
	.i_vid_data      (scaler_fifo_rdout_out), 
	.i_vid_de        (~empty               ),
	.o_vid_fifo_read (o_vid_fifo_read      ),
	.i_vid_vs        (video_scale_vs_in    ),
	.o_vout_data     (video_scale_data_out ),
	.o_vout_de       (video_scale_data_de  ),			//latency of 4 clock cycles after nextDout is asserted
	.o_vout_vs       (video_scale_data_vs  ),
	.i_vout_read     (1),
	.i_discard_cnt   (0),	//Number of input pixels to discard before processing data. Used for clipping
	.i_src_image_x   (INPUT_VIDEO_WIDTH-1 ),			//Resolution of input data minus 1
	.i_src_image_y   (INPUT_VIDEO_HIGTH-1 ),
	.i_des_image_x   (OUTPUT_VIDEO_WIDTH-1),			//Resolution of output data minus 1
	.i_des_image_y   (OUTPUT_VIDEO_HIGTH-1),
	.i_scaler_x_ratio(32'h4000 * (INPUT_VIDEO_WIDTH-1) / (OUTPUT_VIDEO_WIDTH-1)-1),				//Scaling factors. Input resolution scaled up by 1/xScale. Format Q SCALE_INT_BITS.SCALE_FRAC_BITS
	.i_scaler_y_ratio(32'h4000 * (INPUT_VIDEO_HIGTH-1) / (OUTPUT_VIDEO_HIGTH-1)-1),				//Scaling factors. Input resolution scaled up by 1/yScale. Format Q SCALE_INT_BITS.SCALE_FRAC_BITS
	.i_left_offset   (0),			//Integer/fraction of input pixel to offset output data horizontally right. Format Q OUTPUT_X_RES_WIDTH.SCALE_FRAC_BITS
	.i_top_offset    (0),		//Fraction of input pixel to offset data vertically down. Format Q0.SCALE_FRAC_BITS
	.i_scaler_type   (0)		//Use nearest neighbor resize instead of bilinear
);

RGB2Gray u_rgb_gray(
    .I_clk(rgb_gray_clk),
    .I_reset_p(gray_reset),
    .I_pixel_data_valid(gray_in_de),    // [23:0]
    .I_pixel_data_RGB(gray_data_in),
    .O_pixel_data_valid(gray_out_de),
    .O_pixel_data_Gray(gray_data_o)     // [7:0]
);


 //开辟Gowin_SP并存入
//top_sp u_top_sp(
//    .clk(video_clk),
//    .reset(rst_n),
//    .pixel_data(gray_data_o),  // 像素数据输入
//    .pixel_valid(gray_out_de),  // 像素数据有效信号
//    .current_dout(sp_data_o)  // 当前活跃模块的数据输出
//);

//Gowin_SP u_sp(
//    .dout(sp_data_o), 
//    .clk(video_clk), 
//    .oce(1'b1), 
//    .ce(1'b1), 
//    .reset(rst_n), 
//    .wre(gray_out_de),
//    .ad(11'd0), 
//    .din(gray_data_o)
//);
//wire [7:0] pro_o;
//image_processor u_pro(
//    .clk(video_clk),
//    .reset(rst_n),
//    .pixel_data(gray_data_o),
//    .pixel_valid(gray_out_de),
//    .pixel_out(pro_o)
//);
// 初始化RAM模块
// reg [7:0] addrA = 0, addrB = 0;
// //reg weA = 1;
// always@(posedge video_clk) begin
//     addrB = addrA;
//     addrA = addrA + 1; 
// end
dsp #(
    .DATA_WIDTH(8),
    .ADDRESS_WIDTH(8)
) dut (
    .clk(video_clk),
    .dataA(gray_data_o),
    .dataB(8'd0), // B端不写入
    // .addrA(addrA),
    // .addrB(addrB),
    .weA(1'b1),
    .weB(1'b0), // B端不写入
    .qA(qA),
    .qB(sp_data_o)
);


// 视频缓存模块,直接调用的 ideo_Frame_Buffer IP核
Video_Frame_Buffer_Top u_Video_Frame_Buffer( 
    .I_rst_n              (init_calib_complete ),//rst_n            ),
    .I_dma_clk            (dma_clk          ),   //sram_clk         ),
`ifdef USE_THREE_FRAME_BUFFER 
    .I_wr_halt            (1'd0             ), //1:halt,  0:no halt
    .I_rd_halt            (1'd0             ), //1:halt,  0:no halt
`endif
    // video data input             
    .I_vin0_clk           (in_Video_Frame_clk ),
    .I_vin0_vs_n          (in_Video_Frame_vs  ),//只接收负极性
    .I_vin0_de            (in_Video_Frame_de  ),
    .I_vin0_data          (in_Video_Frame_data),    // [15:0]
    .O_vin0_fifo_full     (),
    // video data output            
    .I_vout0_clk          (out_Video_Frame_clk ),
    .I_vout0_vs_n         (out_Video_Frame_vs  ),//只接收负极性
    .I_vout0_de           (out_Video_Frame_de  ),
    .O_vout0_den          (out_Video_can_read  ),
    .O_vout0_data         (out_Video_Frame_data),
    .O_vout0_fifo_empty   (),
    // ddr write request
    .I_cmd_ready          (cmd_ready          ),
    .O_cmd                (cmd                ),//0:write;  1:read
    .O_cmd_en             (cmd_en             ),
    .O_app_burst_number   (app_burst_number   ),
    .O_addr               (addr               ),//[ADDR_WIDTH-1:0]
    .I_wr_data_rdy        (wr_data_rdy        ),
    .O_wr_data_en         (wr_data_en         ),//
    .O_wr_data_end        (wr_data_end        ),//
    .O_wr_data            (wr_data            ),//[DATA_WIDTH-1:0]
    .O_wr_data_mask       (wr_data_mask       ),
    .I_rd_data_valid      (rd_data_valid      ),
    .I_rd_data_end        (rd_data_end        ),//unused 
    .I_rd_data            (rd_data            ),//[DATA_WIDTH-1:0]
    .I_init_calib_complete(init_calib_complete)
); 

// DDR3控制器模块,直接调用的 DDR3_Memory_Interface IP核
DDR3MI u_DDR3MI(
    .clk                (video_clk          ),
    .memory_clk         (memory_clk         ),
    .pll_lock           (DDR_pll_lock           ),
    .rst_n              (rst_n              ), //rst_n
    .app_burst_number   (app_burst_number   ),
    .cmd_ready          (cmd_ready          ),
    .cmd                (cmd                ),
    .cmd_en             (cmd_en             ),
    .addr               (addr               ),
    .wr_data_rdy        (wr_data_rdy        ),
    .wr_data            (wr_data            ),
    .wr_data_en         (wr_data_en         ),
    .wr_data_end        (wr_data_end        ),
    .wr_data_mask       (wr_data_mask       ),
    .rd_data            (rd_data            ),
    .rd_data_valid      (rd_data_valid      ),
    .rd_data_end        (rd_data_end        ),
    .sr_req             (1'b0               ),
    .ref_req            (1'b0               ),
    .sr_ack             (                   ),
    .ref_ack            (                   ),
    .init_calib_complete(init_calib_complete),
    .clk_out            (dma_clk            ),
    .burst              (1'b1               ),
    // mem interface
    .ddr_rst            (                   ),
    .O_ddr_addr         (O_ddr_addr         ),
    .O_ddr_ba           (O_ddr_ba           ),
    .O_ddr_cs_n         (O_ddr_cs_n         ),
    .O_ddr_ras_n        (O_ddr_ras_n        ),
    .O_ddr_cas_n        (O_ddr_cas_n        ),
    .O_ddr_we_n         (O_ddr_we_n         ),
    .O_ddr_clk          (O_ddr_clk          ),
    .O_ddr_clk_n        (O_ddr_clk_n        ),
    .O_ddr_cke          (O_ddr_cke          ),
    .O_ddr_odt          (O_ddr_odt          ),
    .O_ddr_reset_n      (O_ddr_reset_n      ),
    .O_ddr_dqm          (O_ddr_dqm          ),
    .IO_ddr_dq          (IO_ddr_dq          ),
    .IO_ddr_dqs         (IO_ddr_dqs         ),
    .IO_ddr_dqs_n       (IO_ddr_dqs_n       )
);

// 输出视频时序模块, VGA时序,分辨率在模块内部自定义
video_timing_control video_timing(
	.i_clk     (video_clk  ),	
	.i_rst_n   (rst_n      ), 
	.i_start_x (0          ),
	.i_start_y (0          ),
	.i_disp_h  (OUTPUT_VIDEO_WIDTH),
	.i_disp_v  (OUTPUT_VIDEO_HIGTH),
	.i_rgb     (vtc_rgb_in ),
    .i_Video_can_read(out_Video_can_read),
	.o_hs      (vtc_hs_out ),
	.o_vs      (vtc_vs_out ),
	.o_de      (vtc_de_out ),
	.o_rgb     (vtc_rgb_out),
	.o_data_req(vtc_req_out)
);

// HDMI输出模块,直接调用的 DVI_TX IP核
DVI_TX_Top u_HDMI_TX(
    .I_rst_n       (hdmi4_rst_n       ),  //asynchronous reset, low active
    .I_serial_clk  (serial_clk        ),
    .I_rgb_clk     (video_clk         ),  //pixel clock
    .I_rgb_vs      (vtc_vs_out        ), 
    .I_rgb_hs      (vtc_hs_out        ),    
    .I_rgb_de      (vtc_de_out        ), 
    .I_rgb_r       (vtc_rgb_out[ 7: 0]),  //tp0_data_r
    .I_rgb_g       (vtc_rgb_out[ 7: 0]),  
    .I_rgb_b       (vtc_rgb_out[ 7: 0]),  
    .O_tmds_clk_p  (O_tmds_clk_p      ),
    .O_tmds_clk_n  (O_tmds_clk_n      ),
    .O_tmds_data_p (O_tmds_data_p     ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n     )
);

endmodule
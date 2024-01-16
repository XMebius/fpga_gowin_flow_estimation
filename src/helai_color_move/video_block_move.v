module video_block_move #(
    parameter H_DISP            = 1920      ,   //video h
    parameter V_DISP            = 1080      ,   //video v
    parameter VIDEO_CLK         = 148500000 ,   //video clk
    parameter BLOCK_CLK         = 100       ,   //move block clk
    parameter SIDE_W            = 40        ,   //screen side size
    parameter BLOCK_W           = 80        ,   //move block size
    parameter SCREEN_SIDE_COLOR = 24'h7b7b7b,   //screen side color
    parameter SCREEN_BKG_COLOR  = 24'hffffff,   //screen background color
    parameter MOVE_BLOCK_COLOR  = 24'hffc0cb    //move block color
)(
    input         pixel_clk,
	input         sys_rst_n,
	output 		  video_hs ,
	output 		  video_vs ,
	output 		  video_de ,
	output [23:0] video_rgb
);

//*****************************************************
//**                    main code
//*****************************************************

//wire define
wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;

video_timing_color #(
	.VIDEO_H       (H_DISP),
	.VIDEO_V       (V_DISP),
	.VIDEO_START_X (0   ),
	.VIDEO_START_Y (0   )
)u_video_timing_color(
	.i_clk     (pixel_clk   ),	
	.i_rst_n   (sys_rst_n   ), 
	.i_rgb     (pixel_data_w),
	.o_hs      (video_hs    ),
	.o_vs      (video_vs    ),
	.o_de      (video_de    ),
	.o_rgb     (video_rgb   ),
	.o_data_req(),
	.o_h_dis   (),
	.o_v_dis   (),
	.o_x_pos   (pixel_xpos_w),
	.o_y_pos   (pixel_ypos_w)
);

//Àý»¯RGBÊý¾ÝÏÔÊ¾Ä£¿é
rgb_display #(
    .H_DISP           (H_DISP           ),   //video h
    .V_DISP           (V_DISP           ),   //video v
    .VIDEO_CLK        (VIDEO_CLK        ),   //video clk
    .BLOCK_CLK        (BLOCK_CLK        ),   //move block clk
    .SIDE_W           (SIDE_W           ),   //screen side size
    .BLOCK_W          (BLOCK_W          ),   //move block size
    .SCREEN_SIDE_COLOR(SCREEN_SIDE_COLOR),   //screen side color
    .SCREEN_BKG_COLOR (SCREEN_BKG_COLOR ),   //screen background color
    .MOVE_BLOCK_COLOR (MOVE_BLOCK_COLOR )    //move block color
)
u_rgb_display(
    .pixel_clk      (pixel_clk   ),
    .sys_rst_n      (sys_rst_n   ),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
);

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/02 21:00:10
// Design Name: 
// Module Name: ov5640_i2c
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


module ov5640_i2c #(
	parameter SENSOR_ADDR = 8'h78,
	parameter DISPAY_H    = 1280 ,
	parameter DISPAY_V    = 720  
)(
	input         clk        ,
	input         reset_h    ,
	input  [15:0] clk_div_cnt,	//clk_div_cnt=clk/(5*i2c_scl)-1	
    inout         sensor_scl ,  
    inout         sensor_sda ,  
	output        i2c_cgf_ok 
);
	
wire [9:0]   lut_index;
wire [31:0]  lut_data ; 
	
i2c_config i2c_config_ov5640(
	.rst            (reset_h        ),
	.clk            (clk            ),
	.clk_div_cnt    (16'd500        ),
	.i2c_addr_2byte (1'b1           ),
	.lut_index      (lut_index      ),
	.lut_dev_addr   (lut_data[31:24]),
	.lut_reg_addr   (lut_data[23:8] ),
	.lut_reg_data   (lut_data[7:0]  ),
	.error          (               ),
	.done           (i2c_cgf_ok     ),
	.i2c_scl        (sensor_scl     ),
	.i2c_sda        (sensor_sda     )
);

ov5640_reg_cfg #(
	.SENSOR_ADDR(SENSOR_ADDR),
	.DISPAY_H   (DISPAY_H   ),
	.DISPAY_V   (DISPAY_V   )
)
u_ov5640_reg_cfg(
	.lut_index(lut_index),   //Look-up table address
	.lut_data (lut_data )    //Device address (8bit I2C address), register address, register data
);	
	
	
	
	
	
	
	
	
endmodule

//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta-4 Education
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Thu Jan 18 19:59:30 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Integer_Division_Top your_instance_name(
		.clk(clk_i), //input clk
		.rstn(rstn_i), //input rstn
		.dividend(dividend_i), //input [7:0] dividend
		.divisor(divisor_i), //input [7:0] divisor
		.remainder(remainder_o), //output [7:0] remainder
		.quotient(quotient_o) //output [7:0] quotient
	);

//--------Copy end-------------------

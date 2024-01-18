//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta-4 Education
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Thu Jan 18 20:18:29 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Complex_Multiplier_Top your_instance_name(
		.ce(ce_i), //input ce
		.clk(clk_i), //input clk
		.reset(reset_i), //input reset
		.real1(real1_i), //input [7:0] real1
		.real2(real2_i), //input [7:0] real2
		.imag1(imag1_i), //input [7:0] imag1
		.imag2(imag2_i), //input [7:0] imag2
		.realo(realo_o), //output [18:0] realo
		.imago(imago_o) //output [18:0] imago
	);

//--------Copy end-------------------

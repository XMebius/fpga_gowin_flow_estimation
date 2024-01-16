//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta-6
//Part Number: GW2A-LV18PG484C7/I6
//Device: GW2A-18
//Device Version: C
//Created Time: Tue Nov 14 16:47:50 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	resize_fifo your_instance_name(
		.Data(Data_i), //input [23:0] Data
		.WrReset(WrReset_i), //input WrReset
		.RdReset(RdReset_i), //input RdReset
		.WrClk(WrClk_i), //input WrClk
		.RdClk(RdClk_i), //input RdClk
		.WrEn(WrEn_i), //input WrEn
		.RdEn(RdEn_i), //input RdEn
		.Q(Q_o), //output [23:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);

//--------Copy end-------------------

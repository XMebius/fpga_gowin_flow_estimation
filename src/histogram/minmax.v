`timescale 1ns/1ps
module minmax#(parameter DW = 8
      )(
      input                      pixelclk,
      input                      reset_n,
      input [DW-1:0]    din,//gray--8
      input                      i_hsync,
      input                      i_vsync,
      input                      i_de,
  
  output reg [DW-1:0]gray_max,//gray max out
  output reg  [DW-1:0]gray_min//gray min out
   );
 
reg [DW-1:0]gray_maxr;//gray max
reg [DW-1:0]gray_minr;//gray min
 
//reg  [7:0] gray_r;
reg        vsync_r;
reg de_r;
 
wire       vsync_pos = (i_vsync&(!vsync_r));//frame start
wire       vsync_neg = (!i_vsync&vsync_r);  //frame end
 
always @(posedge pixelclk) begin
  de_r <= i_de;
  vsync_r<=i_vsync;
end
 
always @(posedge pixelclk or negedge reset_n)begin
  if(!reset_n) begin
    gray_maxr<= 8'd0;
gray_minr<= 8'd255;
  end  
  else begin
    if(i_vsync ==1'b1 && i_de ==1'b1) begin
  gray_maxr<= (gray_maxr>din)?gray_maxr:din;
  gray_minr<= (din>gray_minr)?gray_minr:din;    
end
else if(vsync_neg == 1'b1)begin
  gray_max<= gray_maxr;
  gray_min<= gray_minr;
  gray_maxr<= 8'd0;
  gray_minr<= 8'd255;
end
else begin
  gray_max<= gray_max;
  gray_min<= gray_min;
  gray_maxr<= gray_maxr;
  gray_minr<= gray_minr;
end
  end
end
 
 
endmodule
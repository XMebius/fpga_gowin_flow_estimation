module hist_Stretch#(
      parameter DW = 24
      )(
      input                      pixelclk,
      input                      reset_n,
      input [DW-1:0]    din,//gray888
      input                      i_hsync,
      input                      i_vsync,
      input                      i_de,
  
  output [DW-1:0]dout,//gray out
      output                     o_hsync,
      output                     o_vsync,
      output                     o_de
   );
   
wire [7:0] gray = din[7:0];//gray--8bit
reg  [7:0] gray_r;
reg        vsync_r;
reg        hsync_r;
reg        de_r;
 
wire [7:0]gray_max;//gray max
wire [7:0]gray_min;//gray min
 
wire       vsync_pos = (i_vsync&(!vsync_r));//frame start
wire       vsync_neg = (!i_vsync&vsync_r);  //frame end
assign dout = {gray_r,gray_r,gray_r};
assign o_hsync = hsync_r;
assign o_vsync = vsync_r;
assign o_de = de_r;
 
always @(posedge pixelclk) begin
  vsync_r <= i_vsync;
  hsync_r <= i_hsync;
  de_r <= i_de;
end
 
always @(posedge pixelclk or negedge reset_n)begin
  if(reset_n == 1'b0) begin
gray_r<=0;
  end
  else begin
if(i_de ==1'b1) begin
  if(gray>gray_max)
    gray_r<=8'd255;
  else if(gray<gray_min)
    gray_r<=8'd255;
  else
    //gray_r<=255*(gray-gray_min)/(gray_max-gray_min);
gray_r <=STRETCH(gray,gray_min,gray_max);
end
  end
end
 
minmax#(.DW(8)
      )Uminmax(
      .pixelclk(pixelclk),
      .reset_n(reset_n),
      .din(gray),//gray--8
      .i_hsync(i_hsync),
      .i_vsync(i_vsync),
      .i_de(i_de),
  
  .gray_max(gray_max),//gray max out
  .gray_min(gray_min)//gray min out
   );  
 
function [7:0] STRETCH;
          input [7:0] gray,gray_min,gray_max;
  begin
//    STRETCH = 100*(gray-gray_min)/(gray_max-gray_min);
    STRETCH = 8'd125;
  end
endfunction   
   
endmodule
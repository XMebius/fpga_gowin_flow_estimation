module top_sp(
    input clk,  // 主时钟
    input reset,  // 全局复位信号
    input [7:0] pixel_data,  // 像素数据输入
    input pixel_valid,  // 像素数据有效信号
    output [7:0] current_dout  // 当前活跃模块的数据输出
);

wire [10:0] addr;
wire [7:0] data_in;
wire [7:0] dout0, dout1, dout2, dout3;
reg [1:0] current_module = 2'b00;
reg [13:0] pixel_count = 14'd0;
reg reset_next_module = 1'b0;

// 生成单独的复位信号
wire reset0, reset1, reset2, reset3;
assign reset0 = (current_module == 2'b11) && reset_next_module;
assign reset1 = (current_module == 2'b00) && reset_next_module;
assign reset2 = (current_module == 2'b01) && reset_next_module;
assign reset3 = (current_module == 2'b10) && reset_next_module;

// Gowin_SP模块实例化
Gowin_SP sp0 (.dout(dout0), .clk(clk), .oce(1'b1), .ce(current_module == 2'b00), .reset(reset || reset0), .wre(pixel_valid && current_module == 2'b00), .ad(addr), .din(data_in));
Gowin_SP sp1 (.dout(dout1), .clk(clk), .oce(1'b1), .ce(current_module == 2'b01), .reset(reset || reset1), .wre(pixel_valid && current_module == 2'b01), .ad(addr), .din(data_in));
Gowin_SP sp2 (.dout(dout2), .clk(clk), .oce(1'b1), .ce(current_module == 2'b10), .reset(reset || reset2), .wre(pixel_valid && current_module == 2'b10), .ad(addr), .din(data_in));
Gowin_SP sp3 (.dout(dout3), .clk(clk), .oce(1'b1), .ce(current_module == 2'b11), .reset(reset || reset3), .wre(pixel_valid && current_module == 2'b11), .ad(addr), .din(data_in));

// 地址和数据逻辑
assign addr = pixel_count[13:0];
assign data_in = pixel_data;

// 多路选择器
assign current_dout = (current_module == 2'b00) ? dout0 :
                      (current_module == 2'b01) ? dout1 :
                      (current_module == 2'b10) ? dout2 :
                                                  dout3;

// 控制逻辑
always @(posedge clk) begin
    if (reset) begin
        pixel_count <= 14'd0;
        current_module <= 2'b00;
        reset_next_module <= 1'b0;
    end else if (pixel_valid) begin
        if (pixel_count == 14'd16383) begin
            pixel_count <= 14'd0;
            current_module <= current_module + 1;
            reset_next_module <= 1'b1;
        end else begin
            pixel_count <= pixel_count + 1;
            reset_next_module <= 1'b0;
        end
    end
end

endmodule
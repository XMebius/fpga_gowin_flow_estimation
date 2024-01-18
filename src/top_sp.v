module image_processor(
    input clk,               // 主时钟
    input reset,             // 全局复位信号
    input [7:0] pixel_data,  // 像素数据输入
    input pixel_valid,       // 像素有效信号
    output reg [7:0] pixel_out // 像素数据输出
);

// 参数定义
parameter ADDR_WIDTH = 12;  // 地址宽度，覆盖64x64图像的大小
parameter DATA_WIDTH = 8;   // 数据宽度
parameter FRAME_SIZE = 1 << ADDR_WIDTH;  // 每帧图像的像素数量

// RAM定义
reg [DATA_WIDTH-1:0] ram0 [0:FRAME_SIZE-1];
reg [DATA_WIDTH-1:0] ram1 [0:FRAME_SIZE-1];

// 控制和状态变量
reg [ADDR_WIDTH-1:0] addr = 0;
reg [1:0] current_frame = 0;  // 当前帧（0或1）
reg mode = 1;  // 0为存储模式, 1为输出模式

// 存储和输出逻辑
always @(posedge clk or posedge reset) begin
    if (reset) begin
        addr <= 0;
        current_frame <= 0;
        mode <= 0;  // 初始模式为存储模式
    end else if (mode == 0 && pixel_valid) begin  // 存储模式
        if (current_frame == 0) begin
            ram0[addr] <= pixel_data;
        end else begin
            ram1[addr] <= pixel_data;
        end

        if (addr == FRAME_SIZE-1) begin
            current_frame <= ~current_frame;  // 切换到下一帧
            addr <= 0;
            mode <= 1;  // 切换到输出模式
        end else begin
            addr <= addr + 1;
        end
    end else if (mode == 1) begin  // 输出模式
        //pixel_out <= (current_frame == 0) ? ram0[addr] : ram1[addr];
        pixel_out<=8'b11111111;
        if (addr == FRAME_SIZE-1) begin
            addr <= 0;
            mode <= 0;  // 切换回存储模式
        end else begin
            addr <= addr + 1;
        end
    end
end

endmodule

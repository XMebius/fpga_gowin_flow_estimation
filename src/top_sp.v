//Dual port RAM
module dsp #(
    parameter DATA_WIDTH    = 8,
    parameter ADDRESS_WIDTH = 8
)(
    input  wire                       clk  ,
    input  wire [(DATA_WIDTH-1):0]    dataA, 
    input  wire [(DATA_WIDTH-1):0]    dataB,
    input  wire                       weA  , 
    input  wire                       weB  , 
    output reg [(DATA_WIDTH-1):0]     qA   , 
    output reg [(DATA_WIDTH-1):0]     qB   
);
// 声明两个额外的寄存器用于延迟
reg [ADDRESS_WIDTH-1:0] addrB_delayed1, addrB_delayed2;

reg [ADDRESS_WIDTH - 1:0] addrA = 0, addrB = 0;
parameter frame_size = 2**ADDRESS_WIDTH;
// Declare the RAM variable
reg [DATA_WIDTH-1:0] ram[2**ADDRESS_WIDTH-1:0];

 // 最大最小像素值变量
reg [DATA_WIDTH-1:0] max_pixel = 0, min_pixel = 0;
reg [DATA_WIDTH-1:0] max_pixel_next = 0, min_pixel_next = 255;
reg frame_complete = 0;

always @(posedge clk) begin
    // 更新延迟寄存器
    addrB_delayed1 <= addrB;
    addrB_delayed2 <= addrB_delayed1;


end

//Port A
always @ (posedge clk) begin
    if (weA) begin
        ram[addrA] <= dataA;
        qA <= dataA;

        // 获取当前帧的最大最小像素
        if(dataA > max_pixel_next) max_pixel_next <= dataA;
        if(dataA < min_pixel_next) min_pixel_next <= dataA;

    end
    else qA <= ram[addrA]; 

    // Increment addrA
    if (addrA ==  frame_size - 1) begin
        addrA <= 0;
        frame_complete <= 1;    // 第一帧结束

        max_pixel <= max_pixel_next;
        min_pixel <= min_pixel_next;
        
        max_pixel_next <= 0;    // 重置
        min_pixel_next <= {DATA_WIDTH{1'b1}};
    end else if (addrB == frame_size - 1) begin 
        addrB <= 0;
    end
    else begin
        addrB <= addrA;
        addrA <= addrA + 1;
    end   
end 

//Port B
always @(posedge clk) begin
    if (weB) begin
        ram[addrB] <= dataB;
        qB <= dataB;
    end
    else qB <= ram[addrB];

    // 灰度拉伸（用前一帧的最大最小值）
    if (frame_complete && addrB_delayed2 < frame_size) begin
        qB <= (ram[addrB_delayed2] - min_pixel) * quo;
    end
end
wire remain;
wire [7:0] quo;
Integer_Division_Top div(
    .clk(clk),
    .rstn(1),
    .dividend((2**DATA_WIDTH)-1),
    .divisor(max_pixel - min_pixel),
    .remainder(remain),
    .quotient(quo)
);


endmodule //ramDualPort

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

reg [ADDRESS_WIDTH - 1:0] addrA = 0, addrB = 0;
parameter frame_size = 2**ADDRESS_WIDTH;
// Declare the RAM variable
reg [DATA_WIDTH-1:0] ram[2**ADDRESS_WIDTH-1:0];

//Port A
always @ (posedge clk) begin
	if (weA) begin
		ram[addrA] <= dataA;
		qA <= dataA;
	end
	else qA <= ram[addrA]; 

    // Increment addrA
    if (addrA ==  frame_size - 1) begin
        addrA <= 0;
    end else if (addrB == frame_size - 1) begin 
        addrB <= 0;
    end
    else begin
        addrB <= addrA;
        addrA <= addrA + 1;
    end   
end 

//Port B
always @ (posedge clk) begin
	if (weB) begin
		ram[addrB] <= dataB;
		qB <= dataB;
	end
	else qB <= ram[addrB];

end



endmodule //ramDualPort
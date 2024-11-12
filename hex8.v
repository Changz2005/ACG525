module hex8(
	clk,
	reset_n,

	en,
	key,
	sel,
	seg
);

    wire reset;
	input clk;	//50M
	input reset_n;

	input en;	//数码管显示使能，1使能，0关闭

    input [3:0]key;
    output [7:0] sel;//数码管位选（选择当前要显示的数码管）
	output reg [6:0] seg;//数码管段选（当前要显示的内容）
  
always@(*) 
       case(key)
			4'h0:seg = 7'b1000000;
			4'h1:seg = 7'b1111001;
			4'h2:seg = 7'b0100100;
			4'h3:seg = 7'b0110000;
			4'h4:seg = 7'b0011001;
			4'h5:seg = 7'b0010010;
			4'h6:seg = 7'b0000010;
			4'h7:seg = 7'b1111000;
			4'h8:seg = 7'b0000000;
			4'h9:seg = 7'b0010000;
			4'ha:seg = 7'b0001000;
			4'hb:seg = 7'b0000011;
			4'hc:seg = 7'b1000110;
			4'hd:seg = 7'b0100001;
			4'he:seg = 7'b0000110;
			4'hf:seg = 7'b0001110;
		endcase


assign sel=8'b10000000;

endmodule
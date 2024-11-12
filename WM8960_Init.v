module WM8960_Init(
	Clk,
	Rst_n,
    key_in0,
    key_in1,
    key,
	I2C_Init_Done,
    key_out1,
    key_out2,    
	i2c_sdat,
	i2c_sclk,
    uart_rx
);

	input Clk;
	input Rst_n;
    input key_in0; //按键S0输入
    input key_in1; //按键S1输入
    input uart_rx; 
	inout i2c_sdat;
	output i2c_sclk;
	output I2C_Init_Done;  

    output key_out1;
    output key_out2;
    output [3:0]key;
	reg [15:0]Delay_Cnt;
	reg Init_en;

	always@(posedge Clk or negedge Rst_n)
	begin
		if(!Rst_n)
			Delay_Cnt <= 16'd0;
		else if(Delay_Cnt < 16'd60000)
			Delay_Cnt <= Delay_Cnt + 8'd1;
		else
			Delay_Cnt <= Delay_Cnt;
	end	
	
	always@(posedge Clk or negedge Rst_n)
	begin
		if(!Rst_n)
			Init_en <= 1'b0;
		else if(Delay_Cnt == 16'd59999)
			Init_en <= 1'b1;
		else
			Init_en <= 1'b0;
	end

	I2C_Init_Dev I2C_Init_Dev(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.Go(Init_en),
        .key_in0(key_in0),
        .key_in1(key_in1),
        .key(key),
		.Init_Done(I2C_Init_Done),
        .key_out1(key_out1),
        .key_out2(key_out2),
		.i2c_sclk(i2c_sclk),
		.i2c_sdat(i2c_sdat),
        .uart_rx(uart_rx)
	);

endmodule

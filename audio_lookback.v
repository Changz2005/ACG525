module audio_lookback(
		input clk,                    
		input reset_n,                                   
		inout iic_0_scl,              
		inout iic_0_sda,
        input key_in0, //按键S0输入
        input key_in1, //按键S1输入
        input uart_rx,
	    output led,
        output led1,
        output led2,
		input I2S_ADCDAT,
		input I2S_ADCLRC,
		input I2S_BCLK,
		output I2S_DACDAT,
		input I2S_DACLRC,
		output I2S_MCLK,
        output sh_cp,
        output st_cp,
        output ds
);
	
	parameter DATA_WIDTH        = 32;     
	
    Gowin_PLL Gowin_PLL(
        .clkout0(I2S_MCLK), //output clkout0
        .clkin(clk) //input clkin
    );

 	wire Init_Done;
    wire key_out1;
    wire key_out2;
    wire [3:0] key;
    wire [7:0] sel;//数码管位选（选择当前要显示的数码管）
	wire [6:0] seg;//数码管段选（当前要显示的内容)

	WM8960_Init WM8960_Init(
		.Clk(clk),
		.Rst_n(reset_n),
        .key(key),
        .key_in0(key_in0),
        .key_in1(key_in1),
		.I2C_Init_Done(Init_Done),
        .key_out1(key_out1),
        .key_out2(key_out2),
		.i2c_sclk(iic_0_scl),
		.i2c_sdat(iic_0_sda),
        .uart_rx(uart_rx)
	);
    hc595_driver hc595_driver(
		.clk(clk),
		.reset_n(reset_n),
		.data({1'd1,seg,sel}),
		.s_en(1'b1),
		.sh_cp(sh_cp),
		.st_cp(st_cp),
		.ds(ds)
	);
	hex8 hex8(
        .clk(clk),
        .reset_n(reset_n),
        .en(1'b1),
        .key(key),
        .sel(sel),
        .seg(seg)
    );
    
	assign led = Init_Done;
	assign led1 = key_out1;
    assign led2 = key_out2;
	reg adcfifo_read;
	wire [DATA_WIDTH - 1:0] adcfifo_readdata;
	wire adcfifo_empty;

	reg dacfifo_write;
	reg [DATA_WIDTH - 1:0] dacfifo_writedata;
    wire [DATA_WIDTH-1:0] processed_data;
    wire processed_data_valid;
	wire dacfifo_full;
	

	always @ (posedge clk or negedge reset_n)
	begin
		if (~reset_n)
		begin
			adcfifo_read <= 1'b0;
		end
		else if (~adcfifo_empty)
		begin
			adcfifo_read <= 1'b1;
		end
		else
		begin
			adcfifo_read <= 1'b0;
		end
	end

	always @ (posedge clk or negedge reset_n)
	begin
		if(~reset_n)
			dacfifo_write <= 1'd0;
		else if(~dacfifo_full && (~adcfifo_empty)) begin
			dacfifo_write <= 1'd1;
            case(key)
                4'd11:dacfifo_writedata <= processed_data;    
                default:dacfifo_writedata <= adcfifo_readdata;
            endcase
		end
		else begin
			dacfifo_write <= 1'd0;
		end
	end

	i2s_rx 
	#(
		.DATA_WIDTH(DATA_WIDTH) 
	)i2s_rx
	(
		.reset_n(reset_n),
		.bclk(I2S_BCLK),
		.adclrc(I2S_ADCLRC),
		.adcdat(I2S_ADCDAT),
		.adcfifo_rdclk(clk),
		.adcfifo_read(adcfifo_read),
		.adcfifo_empty(adcfifo_empty),
		.adcfifo_readdata(adcfifo_readdata)
	);
	
    // 音频回声处理模块，在写入 FIFO 之前进行处理
    audio_echo
    #(

    ) audio_echo_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(adcfifo_readdata),
        .data_out(processed_data)
    );
    
	i2s_tx
	#(
		 .DATA_WIDTH(DATA_WIDTH)
	)i2s_tx
	(
		 .reset_n(reset_n),
		 .dacfifo_wrclk(clk),
		 .dacfifo_wren(dacfifo_write),
		 .dacfifo_wrdata(dacfifo_writedata),
		 .dacfifo_full(dacfifo_full),
		 .bclk(I2S_BCLK),
		 .daclrc(I2S_DACLRC),
		 .dacdat(I2S_DACDAT)
	);
    

		 
endmodule

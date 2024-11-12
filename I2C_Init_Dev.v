module I2C_Init_Dev(
	Clk,
	Rst_n,
	
	Go,
	Init_Done,
    
    key_in0,
    key_in1,
    key,
    key_out1,
    key_out2,

	i2c_sclk,
	i2c_sdat,
    uart_rx
    //sh_cp,
    //st_cp,
    //ds
);
    
    parameter Baud_Set = 3'd4;

	input Clk;
	input Rst_n;
    input uart_rx;
	input Go;
    input key_in0; //按键S0输入
    input key_in1; //按键S1输入
	output reg Init_Done;
	output reg key_out1;
    output reg key_out2;
	output i2c_sclk;
    output [3:0]key;
    //output sh_cp;
    //output st_cp;
    //output ds;
	inout i2c_sdat;
	
	wire [15:0]addr;
	reg wrreg_req;
	reg rdreg_req;
    reg [3:0]key1;
    wire [7:0]ctrl;
    wire [7:0]rx_data;
    wire rx_done;

	wire [7:0]wrdata;
	wire [7:0]rddata;
	wire RW_Done;
	wire ack;
	
	wire [7:0]lut_size;	//初始化表中需要传输的数据总数
    wire key_flag0,key_flag1;
	wire key_state0,key_state1;
	reg [7:0]cnt;	//传输次数计数器
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		cnt <= 0;
	else if(Go) 
		cnt <= 0;
	else if(cnt < lut_size)begin
		if(RW_Done && (!ack))
			cnt <= cnt + 1'b1;
		else
			cnt <= cnt;
	end
	else
		cnt <= 0;
		
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		Init_Done <= 0;
	else if(Go) 
		Init_Done <= 0;
	else if(cnt == lut_size)
		Init_Done <= 1;

	reg [1:0]state;
		
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin
		state <= 0;
		wrreg_req <= 1'b0;
	end
	else if(cnt < lut_size)begin
		case(state)
			0:
				if(Go)
					state <= 1;
				else
					state <= 0;
			
			1:
				begin
					wrreg_req <= 1'b1;
					state <= 2;
				end
				
			2:
				begin
					wrreg_req <= 1'b0;
					if(RW_Done)
						state <= 1;
					else
						state <= 2;
				end
				
			default:state <= 0;
		endcase
	end
	else
		state <= 0;

	wire [15:0]lut;
	wire [7:0]dev_id;
   
    key_filter key_filter0(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.key_in(key_in0),
		.key_flag(key_flag0),
		.key_state(key_state0)
	);
    key_filter key_filter1(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.key_in(key_in1),
		.key_flag(key_flag1),
		.key_state(key_state1)
	);
    
    reg key1_increment;
    reg key2_increment;
    always@(posedge Clk or negedge key_in0)
    if(!key_in0)
        key_out1 <= 0;
    else    
        key_out1 <= 1;

    always@(posedge Clk or negedge key_in1)
    if(!key_in1)
        key_out2 <= 0;
    else    
        key_out2 <= 1;


    always@(posedge Clk )
	if(key_flag0 && !key_state0)
    begin
        key1_increment=1;
	end
    else begin 
        key1_increment=0;
    end
    
    always@(posedge Clk )
    if(key_flag1 && !key_state1)
    begin
        key2_increment=1;
	end
    else  
	begin	
        key2_increment=0;
    end

    
	always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)
        begin   
            if(key1>15)
                key1 <= 4'b0000;// 复位时初始化为 0
            else    
                key1 <=key1;
        end
    else if (key1_increment )
        key1 <= key1 + 1'b1;  // 如果递增且在最大值以下
    else if (key2_increment && key1 > 0)
        key1 <= key1 - 1'b1;  // 如果递减且在最小值以上
    else if(feature)
        key1<=key2;
    

    assign key =key1;
    
    reg [3:0]key2;
    wire feature;

    always@(posedge Clk)
    begin   
        case(ctrl)
            8'd0:key2<=4'd0; //0x00
            8'd1:key2<=4'd1; //0x01
            8'd2:key2<=4'd2; //0x02
            8'd3:key2<=4'd3; //0x03
            8'd4:key2<=4'd4; //0x04
            8'd5:key2<=4'd5; //0x05
            8'd6:key2<=4'd6; //0x06
            8'd7:key2<=4'd7; //0x07
            8'd8:key2<=4'd8; //0x08
            8'd9:key2<=4'd9; //0x09
            8'd10:key2<=4'd10; //0x0A
            8'd11:key2<=4'd11; //0x0B
            default:key2<=4'd0;
        endcase
    end
	wm8960_init_table wm8960_init_table(
		.dev_id(dev_id),
		.lut_size(lut_size),
        .key(key),
		.addr(cnt),
		.clk(Clk),
		.q(lut)
	);
     uart_cmd uart_cmd(
        .Clk(Clk),
        .Reset_n(Rst_n),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .ctrl(ctrl)
    );

    uart_byte_rx uart_byte_rx(
        .Clk(Clk),
        .Reset_n(Rst_n),
        .Baud_Set(Baud_Set),
        .uart_rx(uart_rx),
        .Data(rx_data),
        .feature(feature),
        .Rx_Done(rx_done)  
    ); 
    
	assign addr = lut[15:8];
	assign wrdata = lut[7:0];
	
	i2c_control i2c_control(
		.Clk(Clk),
		.Rst_n(Rst_n),
		.wrreg_req(wrreg_req),
		.rdreg_req(0),
		.addr(addr),
		.addr_mode(0),
		.wrdata(wrdata),
		.rddata(rddata),
		.device_id(dev_id),
		.RW_Done(RW_Done),
		.ack(ack),		
		.i2c_sclk(i2c_sclk),
		.i2c_sdat(i2c_sdat)
	);

endmodule

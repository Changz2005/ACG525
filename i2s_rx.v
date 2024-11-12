module i2s_rx
#(
    parameter DATA_WIDTH        = 32     //left+right = 16 +16 =32 
)
(
    input reset_n,
    input bclk,
    input adclrc,
    input adcdat,   
    input adcfifo_rdclk,
    input adcfifo_read,
    output adcfifo_empty,
    output [DATA_WIDTH - 1:0] adcfifo_readdata
);
 
parameter state_idle        = 2'd0;   //空闲状态
parameter state_left_data   = 2'd1;   //采集左通道数据
parameter state_right_data  = 2'd2;   //采集右通道数据
parameter state_fifo_write  = 2'd3;   //FIFO的写数据状态

reg [1:0] state;
reg [7:0] bit_cnt;      //位计数
reg [DATA_WIDTH - 1:0] reg_wrfifo_data; 

reg adcfifo_write;    //FIFO的写使能信号
reg [DATA_WIDTH - 1:0] adcfifo_writedata;    //写入FIFO中的数据
//检测adclrc的下降沿，标志着采集数据左通道数据，上升沿标志采集右通道数据

reg adclrc_nege;
reg adclrc_pose;

reg adclrc_r0;
reg adclrc_r1;
reg adcdat_r0;
reg adcdat_r1;
always @(posedge bclk) begin
    adclrc_r0 <= adclrc;
    adclrc_r1 <= adclrc_r0;
    adcdat_r0 <= adcdat;
	 adcdat_r1 <= adcdat_r0;
end

always@(posedge bclk or negedge reset_n)
if(~reset_n) begin
	adclrc_nege <= 1'd0;
	adclrc_pose <= 1'd0;
end
else begin
	adclrc_nege <= adclrc_r1 & (!adclrc_r0);
	adclrc_pose <= (!adclrc_r1) & adclrc_r0;
end


always@(posedge bclk or negedge reset_n)
if(~reset_n)
begin
    state <= state_idle;
    bit_cnt <= 8'd0;
    reg_wrfifo_data <= 0;
    adcfifo_write <= 0;
    adcfifo_writedata <= 0;
end
else begin
    case(state)
        state_idle:
        begin
            adcfifo_write <= 1'd0;
            if(adclrc_nege)
            begin
                bit_cnt <= DATA_WIDTH - 1;
                state <= state_left_data;
            end
        end

        state_left_data:
        begin
            if(bit_cnt == (DATA_WIDTH/2 - 1)) //左通道数据采集完成
            begin
                if(adclrc_pose)        //进入左通道采集数据
                begin
                    state <= state_right_data;
                end
            end
            else 
            begin
                bit_cnt <= bit_cnt - 1'd1;
                reg_wrfifo_data[bit_cnt] = adcdat_r1;
            end
        end

        state_right_data:
        begin
            if(bit_cnt == 5'd0)         //32位数据采集完成
            begin
                reg_wrfifo_data[bit_cnt] = adcdat_r1;
                state <= state_fifo_write;
            end
            else begin
                bit_cnt <= bit_cnt - 1'd1;
                reg_wrfifo_data[bit_cnt] = adcdat_r1;
                state <= state_right_data;
            end
        end

        state_fifo_write:
        begin
            adcfifo_write <= 1'd1;
            adcfifo_writedata <= reg_wrfifo_data;
            state <= state_idle;
        end

        default: state <= state_idle;

    endcase
end

async_fifo #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(8),
	.FULL_AHEAD(1),
	.SHOWAHEAD_EN(0)
)adc_fifo
(
	.reset(~reset_n),
	//fifo wr
	.wrclk(bclk),
	.wren(adcfifo_write),
	.wrdata(adcfifo_writedata),
	.full(adcfifo_full),
	.almost_full(),
	.wrusedw(),
	//fifo rd
	.rdclk(adcfifo_rdclk),
	.rden(adcfifo_read),
	.rddata(adcfifo_readdata),
	.empty(adcfifo_empty),
	.rdusedw()
);

endmodule
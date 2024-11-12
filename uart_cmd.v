`timescale 1ns/1ns

module uart_cmd(
    Clk,
    Reset_n,
    rx_data,
    rx_done,
    ctrl
);
    
    input Clk;
    input Reset_n;
    input [7:0]rx_data;
    input rx_done;
    output reg[7:0]ctrl;
    
    reg [7:0] data_str [7:0];
    always@(posedge Clk)
    if(rx_done)begin
        data_str[7] <= #1 rx_data;
        data_str[6] <= #1 data_str[7];
        data_str[5] <= #1 data_str[6];
        data_str[4] <= #1 data_str[5];
        data_str[3] <= #1 data_str[4];
        data_str[2] <= #1 data_str[3];
        data_str[1] <= #1 data_str[2];
        data_str[0] <= #1 data_str[1];        
    end
    
    reg r_rx_done;
    always@(posedge Clk)
        r_rx_done <= rx_done;
    
    always@(posedge Clk or negedge Reset_n)
    if(!Reset_n) begin
        ctrl <= #1 0;
    end else if(r_rx_done)begin
        if((data_str[0] == 8'h55) && (data_str[1] == 8'hA5) && (data_str[7] == 8'hF0))begin
            ctrl <= #1 data_str[6];
        end
    end    
    
endmodule

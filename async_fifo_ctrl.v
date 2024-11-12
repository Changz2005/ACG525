module async_fifo_ctrl #(
  parameter DATA_WIDTH = 16,
  parameter ADDR_WIDTH = 16,
  parameter FULL_AHEAD = 1
)
(
  input                       reset,
  //fifo wr
  input                       wrclk,
  input                       wren,
  input      [DATA_WIDTH-1:0] wrdata,
  output reg                  full,
  output reg                  almost_full,
  output     [ADDR_WIDTH:0]   wrusedw,
  //fifo rd
  input                       rdclk,
  input                       rden,
  output     [DATA_WIDTH-1:0] rddata,
  output                      empty,
  output     [ADDR_WIDTH:0]   rdusedw,
  //ram
  input      [DATA_WIDTH-1:0] ram_dout,
  output     [ADDR_WIDTH-1:0] ram_wraddr,
  output     [ADDR_WIDTH-1:0] ram_rdaddr,
  output     [DATA_WIDTH-1:0] ram_din,
  output                      ram_wren
);

reg  [ADDR_WIDTH:0] wr_pntr;
wire [ADDR_WIDTH:0] wr_pntr_next;
wire [ADDR_WIDTH:0] wr_pntr_gray;
reg  [ADDR_WIDTH:0] wr_pntr_gray_reg;
reg  [ADDR_WIDTH:0] rdside_wr_pntr_gray;
reg  [ADDR_WIDTH:0] rdside_wr_pntr_gray_dly1;
wire [ADDR_WIDTH:0] rdside_wr_pntr_bin;

reg  [ADDR_WIDTH:0] rd_pntr;
wire [ADDR_WIDTH:0] rd_pntr_next;
wire [ADDR_WIDTH:0] rd_pntr_gray;
reg  [ADDR_WIDTH:0] rd_pntr_gray_reg;
reg  [ADDR_WIDTH:0] wrside_rd_pntr_gray;
reg  [ADDR_WIDTH:0] wrside_rd_pntr_gray_dly1;
wire [ADDR_WIDTH:0] wrside_rd_pntr_bin;

wire [ADDR_WIDTH:0] almost_full_threshold;

reg                 empty_pre;
reg                 empty_pre_dly1;

assign  rddata     = ram_dout;
assign  ram_din    = wrdata;
assign  ram_wren   = wren && !full;
assign  ram_wraddr = wr_pntr[ADDR_WIDTH-1:0];
assign  ram_rdaddr = rd_pntr_next[ADDR_WIDTH-1:0];

assign  almost_full_threshold = {1'b1,{ADDR_WIDTH{1'b0}}} - FULL_AHEAD[ADDR_WIDTH:0];

assign wr_pntr_next = wr_pntr + (~full & wren);
assign rd_pntr_next = rd_pntr + (~empty & rden);

always@(posedge wrclk or posedge reset)
  if(reset)
    wr_pntr <= 'd0;
  else
    wr_pntr <= wr_pntr_next;

always@(posedge rdclk or posedge reset)
  if(reset)
    rd_pntr <= 'd0;
  else
    rd_pntr <= rd_pntr_next;

//bin2gary
assign wr_pntr_gray = wr_pntr[ADDR_WIDTH:0] ^ {1'b0,wr_pntr[ADDR_WIDTH:1]};
assign rd_pntr_gray = rd_pntr[ADDR_WIDTH:0] ^ {1'b0,rd_pntr[ADDR_WIDTH:1]};

always@(posedge wrclk or posedge reset)
  if(reset)
    wr_pntr_gray_reg <= 'd0;
  else
    wr_pntr_gray_reg <= wr_pntr_gray;

always@(posedge rdclk or posedge reset)
  if(reset)
    rd_pntr_gray_reg <= 'd0;
  else
    rd_pntr_gray_reg <= rd_pntr_gray;

//wrside  ---->  rdside
always@(posedge rdclk)
begin
  rdside_wr_pntr_gray <= wr_pntr_gray_reg;
  rdside_wr_pntr_gray_dly1 <= rdside_wr_pntr_gray;
end

//rdside  ---->  wrside
always@(posedge wrclk)
begin
  wrside_rd_pntr_gray <= rd_pntr_gray_reg;
  wrside_rd_pntr_gray_dly1 <= wrside_rd_pntr_gray;
end

//gary2bin,rdside
assign rdside_wr_pntr_bin[ADDR_WIDTH] = rdside_wr_pntr_gray_dly1[ADDR_WIDTH];

genvar i;
generate
  for(i = 0; i < ADDR_WIDTH; i = i + 1) begin : gray2bin_inst0
    assign rdside_wr_pntr_bin[i] = rdside_wr_pntr_bin[i+1] ^ rdside_wr_pntr_gray_dly1[i];
  end
endgenerate

//gary2bin,wrside
assign wrside_rd_pntr_bin[ADDR_WIDTH] = wrside_rd_pntr_gray_dly1[ADDR_WIDTH];

genvar j;
generate
  for(j = 0; j < ADDR_WIDTH; j = j + 1) begin : gray2bin_inst1
    assign wrside_rd_pntr_bin[j] = wrside_rd_pntr_bin[j+1] ^ wrside_rd_pntr_gray_dly1[j];
  end
endgenerate

assign rdusedw = rdside_wr_pntr_bin - rd_pntr;
assign wrusedw = wr_pntr - wrside_rd_pntr_bin;

always@(posedge rdclk or posedge reset)
begin
  if(reset)
    empty_pre <= 1'b1;
  else
    empty_pre <= (rdside_wr_pntr_bin[ADDR_WIDTH:0] == rd_pntr_next[ADDR_WIDTH:0]);
end

always@(posedge rdclk or posedge reset)
begin
  if(reset)
    empty_pre_dly1 <= 1'b1;
  else
    empty_pre_dly1 <= empty_pre;
end

assign empty = empty_pre | empty_pre_dly1 ;

always@(posedge wrclk or posedge reset)
begin
  if(reset)
    full <= 1'b0;
  else
    full <= ( wrside_rd_pntr_bin[ADDR_WIDTH] != wr_pntr_next[ADDR_WIDTH] ) &&
            ( wrside_rd_pntr_bin[ADDR_WIDTH-1:0] == wr_pntr_next[ADDR_WIDTH-1:0]);
end

//when almost_empty is not asserted, there are no less than FULL_AHEAD words can to be write into FIFO.
always@(posedge wrclk or posedge reset)
begin
  if(reset)
    almost_full <= 1'b0;
  else
    almost_full <= ((wr_pntr_next[ADDR_WIDTH:0] - wrside_rd_pntr_bin[ADDR_WIDTH:0] ) >= almost_full_threshold);
end


endmodule
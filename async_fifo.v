module async_fifo #(
  parameter DATA_WIDTH   = 16,
  parameter ADDR_WIDTH   = 16,
  parameter FULL_AHEAD   = 1,
  parameter SHOWAHEAD_EN = 0
)
(
  input                    reset,
  //fifo wr
  input                    wrclk,
  input                    wren,
  input   [DATA_WIDTH-1:0] wrdata,
  output                   full,
  output                   almost_full,
  output  [ADDR_WIDTH:0]   wrusedw,
  //fifo rd
  input                    rdclk,
  input                    rden,
  output  [DATA_WIDTH-1:0] rddata,
  output                   empty,
  output  [ADDR_WIDTH:0]   rdusedw
);

wire  [DATA_WIDTH-1:0] ram_dout;
wire  [ADDR_WIDTH-1:0] ram_wraddr;
wire  [ADDR_WIDTH-1:0] ram_rdaddr;
wire  [DATA_WIDTH-1:0] ram_din;
wire                   ram_wren;

wire  [DATA_WIDTH-1:0] rddata_tmp;
reg   [DATA_WIDTH-1:0] rddata_tmp_latch;

always@(posedge rdclk or posedge reset)
  if(reset)
    rddata_tmp_latch <= 'd0;
  else if(rden)
    rddata_tmp_latch <= rddata_tmp;

generate
  if(SHOWAHEAD_EN) begin: inst0
  //
    assign rddata = rddata_tmp;
  //
  end
  else begin: inst1
  //
    assign rddata = rddata_tmp_latch;
  //
  end
endgenerate

async_fifo_ctrl #(
  .DATA_WIDTH (DATA_WIDTH ),
  .ADDR_WIDTH (ADDR_WIDTH ),
  .FULL_AHEAD (FULL_AHEAD )
)async_fifo_ctrl_inst
(
  .reset       (reset       ),
  //fifo wr
  .wrclk       (wrclk       ),
  .wren        (wren        ),
  .wrdata      (wrdata      ),
  .full        (full        ),
  .almost_full (almost_full ),
  .wrusedw     (wrusedw     ),
  //fifo rd
  .rdclk       (rdclk       ),
  .rden        (rden        ),
  .rddata      (rddata_tmp  ),
  .empty       (empty       ),
  .rdusedw     (rdusedw     ),
  //ram
  .ram_dout    (ram_dout    ),
  .ram_wraddr  (ram_wraddr  ),
  .ram_rdaddr  (ram_rdaddr  ),
  .ram_din     (ram_din     ),
  .ram_wren    (ram_wren    )
);

dpram #(
  .DATA_WIDTH (DATA_WIDTH ),
  .ADDR_WIDTH (ADDR_WIDTH )
)dpram_inst
(
  .wrclock   (wrclk      ),
  .wren      (ram_wren   ),
  .wraddress (ram_wraddr ),
  .data      (ram_din    ),
  .rdclock   (rdclk      ),
  .rden      (1'b1       ),
  .rdaddress (ram_rdaddr ),
  .q         (ram_dout   )
);


endmodule
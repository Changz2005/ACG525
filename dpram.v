module dpram #(
  parameter DATA_WIDTH = 16,
  parameter ADDR_WIDTH = 16
)
(
  input                    wrclock,
  input                    wren,
  input  [ADDR_WIDTH-1:0]  wraddress,
  input  [DATA_WIDTH-1:0]  data,
  input                    rdclock,
  input                    rden,
  input  [ADDR_WIDTH-1:0]  rdaddress,
  output [DATA_WIDTH-1:0]  q
);

reg [DATA_WIDTH-1:0] q_wire;

assign q = q_wire;

generate
  if(ADDR_WIDTH>5) begin : use_bram
  //
   (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
  always@(posedge wrclock)
    if(wren)
      ram[wraddress] <= data;

  always@(posedge rdclock)
    if(rden)
      q_wire <= ram[rdaddress];
  //
  end
  else begin : use_dram
  //
  (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
  always@(posedge wrclock)
    if(wren)
      ram[wraddress] <= data;

  always@(posedge rdclock)
    if(rden)
      q_wire <= ram[rdaddress];
  //
  end
endgenerate


endmodule

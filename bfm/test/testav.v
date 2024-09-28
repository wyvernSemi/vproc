
`timescale 1 ns / 10 ps

// ---------------------------------------------------------
// ---------------------------------------------------------

module testavm
#(parameter
  CLKPERIOD                   = 10,
  STOPCOUNT                   = 200,
  FINISH                      = 0,
  VCD_DUMP                    = 0
);

wire                   [31:0] av_address;
wire                    [3:0] av_byteenable;
wire                          av_write;
wire                   [31:0] av_writedata;
wire                          av_read;
wire                   [31:0] av_readdata;
wire                          av_readdatavalid;

wire                          nreset;

reg                           clk;
integer                       count;
reg                    [31:0] irq;

// Genereate a reset
assign nreset                 = (count >= 10) ? 1'b1 : 1'b0;

// -------------------------------------------
//  Clock generation
// -------------------------------------------

initial
begin
  // If enabled, dump all the signals to a VCD file
  if (VCD_DUMP != 0)
  begin
    $dumpfile("waves.vcd");
    $dumpvars(0, testavm);
  end

  clk                           = 1'b1;
  count                         = 0;

  forever # (CLKPERIOD/2) clk   = ~clk;
end

// -------------------------------------------
// Synchronous process
// -------------------------------------------

always @(clk)
begin
  irq                         <= 32'h0;

  count                       <= count + 1;

  if (count == STOPCOUNT)
  begin
    if (FINISH != 0)
    begin
      $finish;
    end
    else
    begin
      $stop;
    end
  end
end

  avbfm
  #(.NODE(0)) avvp
  (
    .clk                      (clk),

    .av_address               (av_address),
    .av_byteenable            (av_byteenable),
    .av_write                 (av_write),
    .av_writedata             (av_writedata),
    .av_read                  (av_read),
    .av_readdata              (av_readdata),
    .av_readdatavalid         (av_readdatavalid),

    .irq                      (irq)
  );

  mem_model mem
  (
   .clk                       (clk),
   .rst_n                     (nreset),

   .address                   (av_address),
   .byteenable                (av_byteenable),
   .write                     (av_write),
   .writedata                 (av_writedata),
   .read                      (av_read),
   .readdata                  (av_readdata),
   .readdatavalid             (av_readdatavalid),

    // Unused ports

   .rx_waitrequest            (),
   .rx_burstcount             (12'h0),
   .rx_address                (32'h0),
   .rx_read                   (1'b0),
   .rx_readdata               (),
   .rx_readdatavalid          (),

   .tx_waitrequest            (),
   .tx_burstcount             (12'h0),
   .tx_address                (32'h0),
   .tx_write                  (1'b0),
   .tx_writedata              (32'h0),

   .wr_port_valid             (1'b0),
   .wr_port_data              (32'h0),
   .wr_port_addr              (32'h0)
  );

endmodule



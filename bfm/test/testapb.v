// =============================================================
//
// Top level test environment for Verilog APB BFM VProc wrapper
//
// Copyright (c) 2024 Simon Southwell. Confidential
//
// This file is part of VProc.
//
// VProc is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// VProc is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with VProc. If not, see <http://www.gnu.org/licenses/>.
//
// =============================================================

`timescale 1 ns / 10 ps

// ---------------------------------------------------------
// APB test bench
// ---------------------------------------------------------

module testapb
#(parameter
  CLKPERIOD                   = 10,
  STOPCOUNT                   = 200,
  FINISH                      = 0,
  VCD_DUMP                    = 0
);

localparam                    ADDRWIDTH = 32;
localparam                    DATAWIDTH = 32;

wire                          pselx;

wire          [ADDRWIDTH-1:0] paddr;
wire          [DATAWIDTH-1:0] pwdata;
wire                          pwrite;
wire                          penable;

wire        [DATAWIDTH/8-1:0] pstrb;
wire                    [2:0] pprot;

wire          [DATAWIDTH-1:0] prdata;
wire                          pready;
wire                          pslverr;

wire                          nreset;

reg                           clk;
integer                       count;
reg                    [31:0] irq;

// Generate a reset
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
    $dumpvars(0, testapb);
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

// -------------------------------------------
// Instantiation of VProc
// -------------------------------------------

  apbbfm
  #(.NODE(0)) vp
  (
    .pclk                     (clk),
    .presetn                  (nreset),

    .pselx                    (pselx),

    .paddr                    (paddr),
    .pwdata                   (pwdata),
    .pwrite                   (pwrite),
    .penable                  (penable),

    .pstrb                    (pstrb),
    .pprot                    (pprot),

    .prdata                   (prdata),
    .pready                   (pready),
    .pslverr                  (pslverr),

    .irq                      (irq)
  );

// -------------------------------------------
// Instantiation of mem_model
// -------------------------------------------

  mem_model_apb mem
  (
    .pclk                     (clk),
    .presetn                  (nreset),

    .psel                     (pselx),

    .paddr                    (paddr),
    .pwdata                   (pwdata),
    .pwrite                   (pwrite),
    .penable                  (penable),

    .pstrb                    (pstrb),
    .pprot                    (pprot),

    .prdata                   (prdata),
    .pready                   (pready),
    .pslverr                  (pslverr)
  );

endmodule



// =============================================================
//
// Top level test environment for Verilog AHB BFM VProc wrapper
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
// AHB test bench
// ---------------------------------------------------------

module testahb
#(parameter
  CLKPERIOD                   = 10,
  STOPCOUNT                   = 200,
  FINISH                      = 0,
  VCD_DUMP                    = 0
);

localparam                    ADDRWIDTH = 32;
localparam                    DATAWIDTH = 32;

wire                          hsel;
wire [ADDRWIDTH-1:0]          haddr;
wire [DATAWIDTH-1:0]          hwdata;
wire                          hwrite;
wire [2:0]                    hburst;
wire [2:0]                    hsize;
wire [1:0]                    htrans;
wire                          hmastlock;
wire [DATAWIDTH/8-1:0]        hwstrb;
wire [DATAWIDTH-1:0]          hrdata;
wire                          hready;
wire                          hresp;

wire                          nreset;

reg                           clk;
integer                       count;
reg                    [31:0] irq;

// Genereate a reset
assign nreset                 = (count >= 10) ? 1'b1 : 1'b0;

// -------------------------------------------
// Combinatorial logic
// -------------------------------------------

assign hsel                   = 1'b1;

// -------------------------------------------
//  Clock generation
// -------------------------------------------

initial
begin
  // If enabled, dump all the signals to a VCD file
  if (VCD_DUMP != 0)
  begin
    $dumpfile("waves.vcd");
    $dumpvars(0, testahb);
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

  ahbbfm
  #(.NODE(0)) ahbvp
  (
    .hclk                     (clk),
    .hresetn                  (nreset),

    .haddr                    (haddr),
    .hwdata                   (hwdata),
    .hwrite                   (hwrite),
    .hburst                   (hburst),
    .hsize                    (hsize),
    .htrans                   (htrans),
    .hmastlock                (hmastlock),
    .hwstrb                   (hwstrb),

    .hrdata                   (hrdata),
    .hready                   (hready),
    .hresp                    (hresp),

    .irq                      (irq)
  );

// -------------------------------------------
// Instantiation of mem_model
// -------------------------------------------

  mem_model_ahb mem
  (
    .hclk                     (clk),
    .hresetn                  (nreset),
   
    .hsel                     (hsel),    
    .haddr                    (haddr),
    .hwdata                   (hwdata),
    .hwrite                   (hwrite),
    .hburst                   (hburst),
    .hsize                    (hsize),
    .htrans                   (htrans),
    .hmastlock                (hmastlock),
    .hwstrb                   (hwstrb),

    .hrdata                   (hrdata),
    .hready                   (hready),
    .hresp                    (hresp)

  );

endmodule



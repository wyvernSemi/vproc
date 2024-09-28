// =============================================================
//
// Top level test environment for Verilog AXI BFM VProc wrapper
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

module testaxi
#(parameter CLKPERIOD = 10,
            STOPCOUNT = 200,
            FINISH    = 0,
            VCD_DUMP  = 0);

reg                           clk;
integer                       count;

wire [31:0]                   awaddr;
wire                          awvalid;
wire                          awready;
wire  [7:0]                   awlen;
wire  [1:0]                   awburst;
wire  [2:0]                   awprot;

wire [31:0]                   wdata;
wire                          wvalid;
wire                          wready;
wire                          wlast;
wire  [3:0]                   wstrb;

wire                          bvalid;
wire                          bready;

wire [31:0]                   araddr;
wire                          arvalid;
wire                          arready;
wire  [7:0]                   arlen;
wire  [2:0]                   arprot;

wire [31:0]                   rdata;
wire                          rvalid;
wire                          rready;

reg  [31:0]                   irq;

// ---------------------------------------------------------
// Combinatorial logic
// ---------------------------------------------------------

wire        nreset            = (count >= 10);

// ---------------------------------------------------------
// Generate a clock
// ---------------------------------------------------------
initial
begin
  // If enabled, dump all the signals to a VCD file
  if (VCD_DUMP != 0)
  begin
    $dumpfile("waves.vcd");
    $dumpvars(0, testaxi);
  end

  clk                         = 1'b1;
  count                       = 0;
  irq                         = 0;

  forever # (CLKPERIOD/2) clk = ~clk;
end

// ---------------------------------------------------------
// Simulation control
// ---------------------------------------------------------

always @(posedge clk)
begin
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

// ---------------------------------------------------------
// AXI bust functional model
// ---------------------------------------------------------

  axi4bfm
  #(.NODE(0)) axivp
  (
    .clk                      (clk),

    .awaddr                   (awaddr),
    .awvalid                  (awvalid),
    .awready                  (awready),
    .awprot                   (awprot),
    .awlen                    (awlen),

    .wdata                    (wdata),
    .wvalid                   (wvalid),
    .wready                   (wready),
    .wlast                    (wlast),
    .wstrb                    (wstrb),

    .bvalid                   (bvalid),
    .bready                   (bready),

    .araddr                   (araddr),
    .arvalid                  (arvalid),
    .arready                  (arready),
    .arprot                   (arprot),
    .arlen                    (arlen),

    .rdata                    (rdata),
    .rvalid                   (rvalid),
    .rready                   (rready),

    .irq                      (irq)
  );

// ---------------------------------------------------------
// Memory model
// ---------------------------------------------------------

  mem_model_axi mem
  (
    .clk                      (clk),
    .nreset                   (nreset),

    .awaddr                   (awaddr),
    .awvalid                  (awvalid),
    .awready                  (awready),
    .awburst                  (2'b01),
    .awsize                   (3'b010),
    .awlen                    (awlen),
    .awid                     (4'h0),

    .wdata                    (wdata),
    .wvalid                   (wvalid),
    .wready                   (wready),
    .wstrb                    (wstrb),

    .bvalid                   (bvalid),
    .bready                   (bready),
    .bid                      (),

    .araddr                   (araddr),
    .arvalid                  (arvalid),
    .arready                  (arready),
    .arburst                  (2'b01),
    .arsize                   (3'b010),
    .arlen                    (arlen),
    .arid                     (4'h0),

    .rdata                    (rdata),
    .rvalid                   (rvalid),
    .rready                   (rready),
    .rlast                    (),
    .rid                      ()
  );

endmodule


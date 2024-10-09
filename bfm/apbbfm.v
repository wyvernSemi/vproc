// ====================================================================
//
// Verilog APB bus functional model (BFM) wrapper for VProc.
//
// Copyright (c) 2024 Simon Southwell.
//
// Implements minimal compliant initiator interface at 32-bits wide.
// Also has a vectored irq input.
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
// ====================================================================


module apbbfm
# (parameter
    ADDRWIDTH                 = 32, // For future proofing. Do not change.
    DATAWIDTH                 = 32, // For future proofing. Do not change.
    IRQWIDTH                  = 32, // Range 1 to 32
    NODE                      = 0
)
(
    input                     pclk,
    input                     presetn,

    // Master PSEL. Decode paddr externally for each individual completer
    output                    pselx,

    output    [ADDRWIDTH-1:0] paddr,
    output    [DATAWIDTH-1:0] pwdata,
    output                    pwrite,
    output                    penable,

    output  [DATAWIDTH/8-1:0] pstrb,
    output              [2:0] pprot,

    input     [DATAWIDTH-1:0] prdata,
    input                     pready,
    input                     pslverr,

    input     [IRQWIDTH-1:0]  irq

);

// -----------------------------------------
// Signals declarations for VProc
// -----------------------------------------

wire                          update;
wire                          rd;
wire          [ADDRWIDTH-1:0] addr;
wire                          we;
wire        [DATAWIDTH/8-1:0] be;
wire                          wrack;
wire          [DATAWIDTH-1:0] dataout;

wire          [DATAWIDTH-1:0] datain;
wire                          rdack;

reg           [DATAWIDTH-1:0] prdata_int;
reg                           pready_int;

reg                           data_phase;
reg                           updateresp;

// -----------------------------------------
// Combinatorial logic
// -----------------------------------------

// Fixed protection status
assign pprot                  = 3'b010; // Normal, insecure and data access

// Pass through write enable, byte enables, address and output data directly from VProc
assign pwrite                 = we;
assign paddr                  = addr;
assign pwdata                 = dataout;
assign pstrb                  = be;

// Assert global PSEL when reading or writing
assign pselx                  = rd | we;

// Assert PENABLE if ot selected or in data phase
assign penable                = ~pselx | data_phase;

// Input data directlay from PRDATA
assign datain                 = prdata_int;

// Acknowledge reads or writes when PREADY asserted
assign rdack                  = rd & pready_int;
assign wrack                  = we & pready_int;

// -----------------------------------------
// Initial block
// -----------------------------------------
initial
begin
  updateresp                  = 1'b0;
end

// -----------------------------------------
// Synchronous process
// -----------------------------------------

always @(posedge pclk or negedge presetn)
begin
  if (presetn == 1'b0)
  begin
    data_phase                <= 1'b0;
  end
  else
  begin
    // Data phase is set on PSEL if no PREADY (address phase), 
    // and cleared again when PREADY asserted (data phase and data returned).
    data_phase                <= (data_phase | pselx) & ~(pselx & pready_int);
  end
end

// For verilator, sample the inputs on the negative edge of the clock.
// All other simulators pass straight through.
`ifdef VERILATOR
always @(negedge pclk)
`else
always @(*)
`endif
begin
  prdata_int                  <= prdata;
  pready_int                  <= pready;
end

// -----------------------------------------
// Delta cycle process
// -----------------------------------------

always @(update)
begin
  // Place any delta cycle processing logic before next line
  updateresp                  <= ~updateresp;
end

// -----------------------------------------
//  VProc instantiation
// -----------------------------------------

  VProc
    #(
      .BURST_ADDR_INCR        (4),
      .INT_WIDTH              (IRQWIDTH)
    ) vp
    (
      .Clk                    (pclk),

      // Bus
      .Addr                   (addr),
      .DataOut                (dataout),
      .WE                     (we),
      .BE                     (be),
      .WRAck                  (wrack),
      .DataIn                 (datain),
      .RD                     (rd),
      .RDAck                  (rdack),

      // Interrupts
      .Interrupt              (irq),

      // Delta cycle control
      .Update                 (update),
      .UpdateResponse         (updateresp),

      .Node                   (NODE[3:0])
  );

endmodule
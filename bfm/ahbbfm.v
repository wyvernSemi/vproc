// ====================================================================
//
// Verilog AHB bus functional model (BFM) wrapper for VProc.
//
// Copyright (c) 2024 Simon Southwell.
//
// Implements minimal compliant manager interface at 32-bits wide.
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

`include "ahbbfm_defs.vh"

module ahbbfm
# (parameter
    ADDRWIDTH                    = 32, // For future proofing. Do not change.
    DATAWIDTH                    = 32, // For future proofing. Do not change.
    IRQWIDTH                     = 32, // Range 1 to 32
    NODE                         = 0
)
(
    input                        hclk,
    input                        hresetn,

    output     [ADDRWIDTH-1:0]   haddr,
    output     [DATAWIDTH-1:0]   hwdata,
    output                       hwrite,
    output     [2:0]             hburst,
    output     [2:0]             hsize,
    output reg [1:0]             htrans,
    output                       hmastlock,
    output     [DATAWIDTH/8-1:0] hwstrb,

    input      [DATAWIDTH-1:0]   hrdata,
    input                        hready,
    input                        hresp,

    input      [IRQWIDTH-1:0]    irq

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

wire                   [11:0] burst;
wire                          burstfirst;
wire                          burstlast;

reg                           updateresp;
reg           [DATAWIDTH-1:0] wdata_phase;
reg                           rd_active;
reg           [ADDRWIDTH-1:0] burstaddr;

// -----------------------------------------
// Combinatorial logic
// -----------------------------------------

// Fixed signalling
assign hmastlock              = 1'b0;
assign hsize                  = `AHB_BFM_SIZE_WORD;

// HBurst set to INCR when bursting, else SINGLE
assign hburst                 = |burst ? `AHB_BFM_BURST_INCR : `AHB_BFM_BURST_SINGLE;
assign hwrite                 = we;

// HADDR, when not IDLE, is either straight from VProc addr output or,
// for read bursts, switches to the aligned burstaddr after the first command.
// When IDLE, make X.
assign haddr                  = (htrans != `AHB_BFM_TRANS_IDLE) ? (~rd_active ? addr : burstaddr) : {ADDRWIDTH{1'bx}};

// HWDATA is the phase aligned data from VProc
assign hwdata                 = wdata_phase;

// Write strobe is direct from VProc when writing, else force to X
assign hwstrb                 = hwrite ? be : {DATAWIDTH/8{1'bx}};

// VProc data input is straight from HRDATA
assign datain                 = hrdata;

// Write acknowledge whe writing and HREADY
assign wrack                  = we & hready;

// Acknowledge read when reading, HREADY and either not the first command or bursting and data is returned.
assign rdack                  = rd & hready & (htrans != `AHB_BFM_TRANS_NONSEQ || (|burst && rd_active));

// Process for HTRANS
always @(*)
begin
    // Default HTRANS to idle.
    htrans                    <= `AHB_BFM_TRANS_IDLE;
    
    // If writing, first command is a NONSEQ (not bursting or first burst),
    // and subsequent commands in a burst are SEQ
    if (we)
    begin
      if (burst == 0 || burstfirst == 1'b1)
      begin
        htrans                <= `AHB_BFM_TRANS_NONSEQ;
      end
      else if (burstfirst != 1'b1)
      begin
        htrans                <= `AHB_BFM_TRANS_SEQ;
      end
    end

    // If reading, first command is a NONSEQ (rd_active clear) else
    // subsequent burst commands are SEQ
    if (rd)
    begin
      if (rd_active != 1'b1)
      begin
        htrans                <= `AHB_BFM_TRANS_NONSEQ;
      end
      else if (burst != 0 && burstlast != 1'b1)
      begin
        htrans                <= `AHB_BFM_TRANS_SEQ;
      end
    end
end

// -----------------------------------------
// Initial block
// -----------------------------------------
initial
begin
  updateresp                  = 1'b0;
  rd_active                   = 1'b0;
end

// ---------------------------------------
// Synchronous process
// ---------------------------------------

always @(posedge hclk or negedge hresetn)
begin
  if (hresetn == 1'b0)
  begin
    rd_active                 <= 1'b0;
  end
  else
  begin

    // Whilst writing, offset the output data by a cycle, else make X
    if (we & hready)
      wdata_phase             <= dataout;
    else
      wdata_phase             <= {DATAWIDTH{1'bx}};

    // A read is active after a non idle read is ouput, and cleared on the VProc read acknowledge
    // when not a burst or on a read acknowledge when last data of a burst.
    rd_active                 <= (rd_active & ~(rdack & (~|burst | burstlast))) | (~hwrite & |htrans);

    // If reading, latch haddr + 4 on the first cycle, and then increment by 4, to align
    // the address to AHB protocols (VProc will hold the first address until the data is returned).
    if (rd)
    begin
      if (~rd_active)
        burstaddr             <= haddr + 4;
      else
        if (hready)
          burstaddr           <= burstaddr + 4;
    end
  end
end

// -----------------------------------------
// Delta cycle process
// -----------------------------------------

always @(update)
begin
  // Place any delta cycle processing logic before next line
  updateresp                  <= ~updateresp;
end

// ---------------------------------------
//  VProc instantiation
// ---------------------------------------

  VProc
    #(
      .BURST_ADDR_INCR        (4),
      .INT_WIDTH              (IRQWIDTH)
    ) vp
    (
      .Clk                    (hclk),

      // Bus
      .Addr                   (addr),
      .DataOut                (dataout),
      .WE                     (we),
      .BE                     (be),
      .WRAck                  (wrack),
      .DataIn                 (datain),
      .RD                     (rd),
      .RDAck                  (rdack),

      .Burst                  (burst),
      .BurstFirst             (burstfirst),
      .BurstLast              (burstlast),

      // Interrupts
      .Interrupt              (irq),

      // Delta cycle control
      .Update                 (update),
      .UpdateResponse         (updateresp),

      .Node                   (NODE[3:0])
  );

endmodule
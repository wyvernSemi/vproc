// ====================================================================
//
// SystemVerilog side Virtual Processor, for running host
// programs as control in simulation.
//
// Copyright (c) 2025 Simon Southwell.
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

`include "f_VProc.v"
`include "f_VProc64.v"

// ============================================================
// vproc2 module
// ============================================================

module vproc2
#(parameter                            ARCH_WIDTH      = 32,
                                       INT_WIDTH       = 32,
                                       NODE            = 0,
                                       BURST_ADDR_INCR = 1,
                                       DISABLE_DELTA   = 0
)
(
    // Clock
    input                              clk,

    // Bus interface
    output     [ARCH_WIDTH-1:0]        addr,
    output     [ARCH_WIDTH/8-1:0]      be,
    output                             wr,
    output                             rd,
    output     [ARCH_WIDTH-1:0]        data_out,
    input      [ARCH_WIDTH-1:0]        data_in,
    input                              wrack,
    input                              rdack,

    // Interrupt
    input    [INT_WIDTH-1:0]           irq,

    // Delta cycle control
    output                             update,
    input                              update_response,

    // Burst count and flags
    output     [11:0]                  burst,
    output                             burst_first,
    output                             burst_last
);

localparam NODE_WIDTH                  = 4;

initial
begin
  if (ARCH_WIDTH !== 32 && ARCH_WIDTH !== 64)
  begin
    $display("NODE%d: ERROR : ARCH_WIDTH size of %d not supported. Must be 32 or 64.", NODE, ARCH_WIDTH);
    $finish;
  end

  if (NODE >= (1 << NODE_WIDTH))
  begin
    $display("NODE%d: ERROR : NODE number of %d too big. Maximum is %d", NODE, NODE, (1<< NODE_WIDTH)-1);
    $finish;
  end

end

generate
if (ARCH_WIDTH == 32)
begin

// For 32-bit VProc, if byte enables not enabled, set port to all 1's
`ifndef VPROC_BYTE_ENABLE
assign be                              = {ARCH_WIDTH/8{1'b1}};
`endif

// For 32-bit VProc, if burst interface not enabled, flag all
// accesses as first/last
`ifndef VPROC_BURST_IF
assign burst                            =  12'h0;
assign burst_first                      =  rd | wr;
assign burst_last                       =  rd | wr;
`endif

   // ---------------------------------------------------------
   // Virtual Processor 32-bit
   // ---------------------------------------------------------

  VProc   #(
              .INT_WIDTH               (INT_WIDTH),
              .NODE_WIDTH              (NODE_WIDTH),
              .DISABLE_DELTA           (DISABLE_DELTA),
              .BURST_ADDR_INCR         (BURST_ADDR_INCR)
            ) vp32
            (
              .Clk                     (clk),
              .Addr                    (addr),
              .WE                      (wr),
              .RD                      (rd),

`ifdef VPROC_BYTE_ENABLE
              .BE                      (be),
`endif

`ifdef VPROC_BURST_IF
              .Burst                   (burst),
              .BurstFirst              (burst_first),
              .BurstLast               (burst_last),
`endif

              .DataOut                 (data_out),
              .DataIn                  (data_in),
              .WRAck                   (wrack),
              .RDAck                   (rdack),
              .Interrupt               (irq),
              .Update                  (update),
              .UpdateResponse          (update_response),
              .Node                    (NODE[NODE_WIDTH-1:0])
            );
end
else
begin

   // ---------------------------------------------------------
   // Virtual Processor 64-bit
   // ---------------------------------------------------------

  VProc64  #(
              .INT_WIDTH               (INT_WIDTH),
              .NODE                    (NODE),
              .DISABLE_DELTA           (DISABLE_DELTA),
              .BURST_ADDR_INCR         (BURST_ADDR_INCR)
            ) vp64
            (
              .Clk                     (clk),
              .Addr                    (addr),
              .WE                      (wr),
              .RD                      (rd),
              .BE                      (be),

              .Burst                   (burst),
              .BurstFirst              (burst_first),
              .BurstLast               (burst_last),

              .DataOut                 (data_out),
              .DataIn                  (data_in),
              .WRAck                   (wrack),
              .RDAck                   (rdack),
              .Interrupt               (irq),
              .Update                  (update),
              .UpdateResponse          (update_response)
            );
end

endgenerate

endmodule

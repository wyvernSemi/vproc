/*
 * Top level demonstration test environment for VProc
 *
 * Copyright (c) 2004-2024 Simon Southwell.
 *
 * This file is part of VProc.
 *
 * VProc is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * VProc is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with VProc. If not, see <http://www.gnu.org/licenses/>.
 *
 */

`include "vprocdefs.vh"

// ---------------------------------------------------------
// Local definitions
// ---------------------------------------------------------

`define       CLKPERIOD      (2 * `NSEC)
`define       TIMEOUTCOUNT   1000
                             
`define       INTWIDTH       3
`define       NODEWIDTH      32

`define       RegDel         1

// =========================================================
// Top level test module
// =========================================================

module test
#(parameter   DEBUG_STOP    = 0,
              VCD_DUMP      = 0
);

// ---------------------------------------------------------
// Local state
// ---------------------------------------------------------

reg           clk;
integer       Count;
integer       Seed;
reg           nreset_h;

// ---------------------------------------------------------
// Signals
// ---------------------------------------------------------

wire [31:0]   VPAddr;
wire [31:0]   VPDataOut;
wire [31:0]   VPDataIn;
wire          VPWE;
wire          VPRD;
wire          Update;

// ---------------------------------------------------------
// Combinatorial logic
// ---------------------------------------------------------

// Generate reset signals
wire #`RegDel nreset = (Count > 5);
wire          reset_irq = nreset & ~nreset_h;

// Memory chip select in segment 0xa
wire CS1 = (VPAddr[31:28] == 4'ha) ? 1'b1 : 1'b0;
wire CS2 = (VPAddr[31:28] == 4'hb) ? 1'b1 : 1'b0;

wire        irq1      = (Count > 54 && Count < 60) ? 1'b1 : 1'b0;
wire [31:0] Interrupt = {30'h0, irq1, nreset};

 // ---------------------------------------------------------
 // Virtual Processor 0
 // ---------------------------------------------------------

 VProc    #(.INT_WIDTH          (`INTWIDTH),
            .NODE_WIDTH         (`NODEWIDTH)
           ) vp1
           (.Clk                (clk),
            .Addr               (VPAddr),
            .WE                 (VPWE),
            .RD                 (VPRD),

`ifdef VPROC_BURST_IF
            .Burst              (),
            .BurstFirst         (),
            .BurstLast          (),
`endif
            .DataOut            (VPDataOut),
            .DataIn             (VPDataIn),
            .WRAck              (VPWE),
            .RDAck              (VPRD),
            .Interrupt          (Interrupt[`INTWIDTH-1:0]),
            .Update             (Update),
            .UpdateResponse     (Update),
            .Node               (0)
           );

 // ---------------------------------------------------------
 // Memory
 // ---------------------------------------------------------

 Mem m     (.clk                (clk),
            .DI                 (VPDataOut),
            .DO                 (VPDataIn),
            .WE                 (VPWE),
            .A                  (VPAddr[9:0]),
            .CS                 (CS1)
           );

// ---------------------------------------------------------
// Initialise state and generate a clock
// ---------------------------------------------------------
initial
begin
    // If enabled, dump all the signals to a VCD file
    if (VCD_DUMP != 0)
    begin
      $dumpfile("waves.vcd");
      $dumpvars(0, test);
    end

    // Initialise local state
    clk         = 1;
    Seed        = 32'h00250864;

    #0         // Ensure first x->1 clock edge is complete before initialisation
    Count      = 0;

    // Stop the simulation when debugging to allow a debugger to connect
    if (DEBUG_STOP != 0)
    begin
      $display("\n***********************************************");
      $display("* Stopping simulation for debugger attachment *");
      $display("***********************************************\n");
      $stop;
    end

    // Generate a clock
    forever #(`CLKPERIOD/2) clk = ~clk;
end

// ---------------------------------------------------------
// Simulation control and interrupt generation process
// ---------------------------------------------------------

always @(posedge clk)
begin
    // Generate delayed version of reset
    nreset_h <= #`RegDel nreset;

    // Increment count and stop if reached stop count
    Count      = Count + 1;
    if (Count == `TIMEOUTCOUNT || (VPWE == 1'b1 && VPAddr[31:28] == 4'hb))
    begin
        if (Count == `TIMEOUTCOUNT)
        begin
          $display("***ERROR: Simulation timed out");
        end
        else
        begin
          $display("\n--- Simulation completed ---\n");
        end
        
        $stop;
    end
end

`ifdef VCS
always @(negedge clk)
begin
    if (Count == (`TIMEOUTCOUNT/2))
    begin
       $save("simv.snapshot");
    end
end
`endif

endmodule

// =========================================================
// Simple 1K word memory model
// =========================================================

module Mem (
    input         clk,
    input         WE,
    input         CS,
    input  [31:0] DI,
    input   [9:0] A,
    output [31:0] DO
);

reg [31:0] Mem [0:1023];

assign #1 DO   = Mem[A];

always @(posedge clk)
begin
    if (WE && CS)
    begin
      Mem[A] <= DI;
    end
end

endmodule

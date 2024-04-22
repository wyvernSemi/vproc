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

// =========================================================
// Top level test module
// =========================================================

module test
#(parameter   DEBUG_STOP    = 0,
              FINISH        = 0,
              VCD_DUMP      = 0
);

// ---------------------------------------------------------
// Local state
// ---------------------------------------------------------

reg           clk;
integer       Count;
integer       Seed;
integer       Interrupt0;
integer       Interrupt1;
reg [31:0]    VPDataIn0;
reg           nreset_h;
integer       restart;

// ---------------------------------------------------------
// Signals
// ---------------------------------------------------------

wire [31:0]   VPAddr0;
wire [31:0]   VPDataOut0;
wire [31:0]   VPAddr1;
wire [31:0]   VPDataOut1;
wire [31:0]   VPDataIn1;
wire          VPWE0;
wire          VPWE1;
wire          VPRD0;
wire          VPRD1;
wire  [1:0]   Update;

// ---------------------------------------------------------
// Combinatorial logic
// ---------------------------------------------------------

// Generate reset signals
wire #`RegDel nreset = (Count > 5);
wire          reset_irq = nreset & ~nreset_h;

// Memory chip select in segment 0xa
wire CS1 = (VPAddr1[31:28] == 4'ha) ? 1'b1 : 1'b0;
wire CS2 = (VPAddr1[31:28] == 4'hb) ? 1'b1 : 1'b0;

 // ---------------------------------------------------------
 // Virtual Processor 0
 // ---------------------------------------------------------

 VProc    #(.INT_WIDTH          (`INTWIDTH),
            .NODE_WIDTH         (`NODEWIDTH)
           ) vp0
           (.Clk                (clk),
            .Addr               (VPAddr0),
            .WE                 (VPWE0),
            .RD                 (VPRD0),

`ifdef VPROC_BURST_IF
            .Burst              (),
            .BurstFirst         (),
            .BurstLast          (),
`endif
            .DataOut            (VPDataOut0),
            .DataIn             (VPDataIn0),
            .WRAck              (VPWE0),
            .RDAck              (VPRD0),
            .Interrupt          ({{(`INTWIDTH-3){1'b0}}, reset_irq, Interrupt0[1:0]}),
            .Update             (Update[0]),
            .UpdateResponse     (Update[0]),
            .Node               (0)
           );

 // ---------------------------------------------------------
 // Virtual Processor 1
 // ---------------------------------------------------------

 VProc    #(.INT_WIDTH          (`INTWIDTH),
            .NODE_WIDTH         (`NODEWIDTH)
           ) vp1
           (.Clk                (clk),
            .Addr               (VPAddr1),
            .WE                 (VPWE1),
            .RD                 (VPRD1),

`ifdef VPROC_BURST_IF
            .Burst              (),
            .BurstFirst         (),
            .BurstLast          (),
`endif
            .DataOut            (VPDataOut1),
            .DataIn             (VPDataIn1),
            .WRAck              (VPWE1),
            .RDAck              (VPRD1),
            .Interrupt          (Interrupt1[`INTWIDTH-1:0]),
            .Update             (Update[1]),
            .UpdateResponse     (Update[1]),
            .Node               (1)
           );

 // ---------------------------------------------------------
 // Memory
 // ---------------------------------------------------------

 Mem m     (.clk                (clk),
            .DI                 (VPDataOut1),
            .DO                 (VPDataIn1),
            .WE                 (VPWE1),
            .A                  (VPAddr1[9:0]),
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
    Interrupt0  = 0;
    Interrupt1  = 0;
    Seed        = 32'h00250864;

    `MINDELAY        // Ensure first x->1 clock edge is complete before initialisation
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
    if (Count == `TIMEOUTCOUNT || (VPWE1 == 1'b1 && VPAddr1[31:28] == 4'hb))
    begin
        if (Count == `TIMEOUTCOUNT)
        begin
          $display("***ERROR: Simulation timed out");
        end
        else
        begin
          $display("\n--- Simulation completed ---\n");
        end

        if (FINISH != 0)
        begin
          $finish;
        end
        else
        begin
          $stop;
        end
    end

    // Generate a new seed each clock cycle
    Seed       = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};

    // Random data input for VProc node 0
    #`RegDel
    VPDataIn0  = Seed;
    
    Interrupt1[1] = (Count >24 && Count < 34) ? 1 : 0;

    // Random interrupt for node 0
    Seed       = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};
    Interrupt0[0] = ((Seed % 16) == 0) ? 1 : 0;

    // Random interrupt for node 1
    Seed       = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};
    Interrupt1[0] <= #`RegDel ((Seed % 16) == 0) ? 1 : 0;
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

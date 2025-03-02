/*
 * Top level demonstration test environment for VProc
 *
 * Copyright (c) 2004-2025 Simon Southwell.
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

`define       CLKPERIOD          (2 * `NSEC)
`define       TIMEOUTCOUNT       1000

`define       INTWIDTH           3
`define       NODEWIDTH          32

`define       RegDel             1

// Use of defintion to set USE_VPROC64 default to fix Vivado command
// line issues on setting parameters under Windows. Other sims set the
// parameter directly.
`ifdef VPROC64_EN
`define       VPROC64_DEFAULT    1
`else
`define       VPROC64_DEFAULT    0
`endif

// =========================================================
// Top level test module
// =========================================================

module test
#(parameter   DEBUG_STOP    = 0,
              FINISH        = 0,
              VCD_DUMP      = 0,
              USE_VPROC64   = `VPROC64_DEFAULT,
              DISABLE_DELTA = 0
);

localparam ARCHSIZE = USE_VPROC64 ? 64 : 32;

// ---------------------------------------------------------
// Local state
// ---------------------------------------------------------

reg                   clk;
integer               Count;
integer               Seed;
integer               Interrupt0;
integer               Interrupt1;
reg [ARCHSIZE-1:0]    VPDataIn0;
reg                   nreset_h;
integer               restart;

// ---------------------------------------------------------
// Signals
// ---------------------------------------------------------

wire [ARCHSIZE-1:0]   VPAddr0;
wire [ARCHSIZE/8-1:0] VPBE0;
wire [ARCHSIZE-1:0]   VPDataOut0;
wire [ARCHSIZE-1:0]   VPAddr1;
wire [ARCHSIZE/8-1:0] VPBE1;
wire [ARCHSIZE-1:0]   VPDataOut1;
wire [ARCHSIZE-1:0]   VPDataIn1;


wire                  VPWE0;
wire                  VPWE1;
wire                  VPRD0;
wire                  VPRD1;
wire  [1:0]           Update;

// ---------------------------------------------------------
// Combinatorial logic
// ---------------------------------------------------------

// Generate reset signals
wire #`RegDel nreset = (Count > 5);
wire          reset_irq = nreset & ~nreset_h;

// Memory chip select in segment 0xa
wire CS1 = (VPAddr1[ARCHSIZE-1:ARCHSIZE-4] == 4'ha) ? 1'b1 : 1'b0;
wire CS2 = (VPAddr1[ARCHSIZE-1:ARCHSIZE-4] == 4'hb) ? 1'b1 : 1'b0;

 // ---------------------------------------------------------
 // Virtual Processor 0
 // ---------------------------------------------------------

 vproc2  #(
            .NODE               (0),
            .ARCH_WIDTH         (ARCHSIZE),
            .INT_WIDTH          (`INTWIDTH),
            .DISABLE_DELTA      (DISABLE_DELTA)
          ) vp0
          (
            .clk                (clk),

            .addr               (VPAddr0),
            .wr                 (VPWE0),
            .rd                 (VPRD0),
            .be                 (VPBE0),
            .data_out           (VPDataOut0),
            .data_in             (VPDataIn0),
            .wrack              (VPWE0),
            .rdack              (VPRD0),

            .burst              (),
            .burst_first        (),
            .burst_last         (),

            .irq                ({{(`INTWIDTH-3){1'b0}}, reset_irq, Interrupt0[1:0]}),
            .update             (Update[0]),
            .update_response    (Update[0])
           );

 // ---------------------------------------------------------
 // Virtual Processor 1
 // ---------------------------------------------------------

 vproc2  #(
            .NODE               (1),
            .ARCH_WIDTH         (ARCHSIZE),
            .INT_WIDTH          (`INTWIDTH),
            .BURST_ADDR_INCR    (8),
            .DISABLE_DELTA      (DISABLE_DELTA)
          ) vp1
          (
            .clk                (clk),

            .addr               (VPAddr1),
            .wr                 (VPWE1),
            .rd                 (VPRD1),
            .be                 (VPBE1),
            .data_out           (VPDataOut1),
            .data_in            (VPDataIn1),
            .wrack              (VPWE1),
            .rdack              (VPRD1),
            .irq                (Interrupt1[`INTWIDTH-1:0]),

            .burst              (),
            .burst_first        (),
            .burst_last         (),

            .update             (Update[1]),
            .update_response    (Update[1])
           );

   // ---------------------------------------------------------
   // Memory
   // ---------------------------------------------------------

   Mem #(.ARCHSIZE(ARCHSIZE)) m
             (.clk                (clk),
              .DI                 (VPDataOut1),
              .DO                 (VPDataIn1),
              .WE                 (VPWE1),
              .BE                 (VPBE1),
              .A                  (VPAddr1[12:3]),
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
    if (Count == `TIMEOUTCOUNT || (VPWE1 == 1'b1 && CS2))
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

module Mem
#(parameter ARCHSIZE      = 32)
(
    input                    clk,
    input                    WE,
    input                    CS,
    input  [ARCHSIZE-1:0]    DI,
    input  [9:0]             A,
    input  [ARCHSIZE/8-1:0]  BE,
    output [ARCHSIZE-1:0]    DO
);


reg [ARCHSIZE-1:0] Mem [0:1023];

assign #1 DO = Mem[A];

generate

  if (ARCHSIZE == 64)
    always @(posedge clk)
    begin
        if (WE && CS)
        begin
          Mem[A] <= {BE[7] ? DI[63:56] : Mem[A][63:56],
                     BE[6] ? DI[55:48] : Mem[A][55:48],
                     BE[5] ? DI[47:40] : Mem[A][47:40],
                     BE[4] ? DI[39:32] : Mem[A][39:32],
                     BE[3] ? DI[31:24] : Mem[A][31:24],
                     BE[2] ? DI[23:16] : Mem[A][23:16],
                     BE[1] ? DI[15:8]  : Mem[A][15:8],
                     BE[0] ? DI[7:0]   : Mem[A][7:0]};
        end
    end

  else

    always @(posedge clk)
    begin
        if (WE && CS)
        begin
          Mem[A] <= {BE[3] ? DI[31:24] : Mem[A][31:24],
                     BE[2] ? DI[23:16] : Mem[A][23:16],
                     BE[1] ? DI[15:8]  : Mem[A][15:8],
                     BE[0] ? DI[7:0]   : Mem[A][7:0]};
        end
    end

  endgenerate

endmodule

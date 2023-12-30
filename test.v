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

`ifdef resol_10ps
`timescale 1 ps / 10 ps
`else
`timescale 1 ps / 1 ps
`endif

`define ClkPeriod 2000
`define StopCount 100

`ifdef RegDel
`else
`define RegDel 200
`endif

module test;

reg           Clk;
integer       Count, Seed;
              
integer       Interrupt0, Interrupt1;
reg [31:0]    VPDataIn0;
reg           notReset_H;
integer       restart;
              
wire [31:0]   VPAddr0, VPDataOut0;
wire [31:0]   VPAddr1, VPDataOut1, VPDataIn1;
wire          VPWE0, VPWE1;
wire          VPRD0, VPRD1;
wire  [1:0]   Update;

// Generate reset signals
wire #`RegDel notReset = (Count > 5);
wire          ResetInt = notReset & ~notReset_H;

 // =========================================================
 // Virtual Processor 0
 // =========================================================
 VProc vp0 (.Clk                (Clk),
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
            .Interrupt          ({{(`INTWIDTH-3){1'b0}}, ResetInt, Interrupt0[1:0]}),
            .Update             (Update[0]),
            .UpdateResponse     (Update[0]),
            .Node               (0)
           );

 // =========================================================
 // Virtual Processor 1
 // =========================================================
 VProc vp1 (.Clk                (Clk),
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
            .Interrupt          (Interrupt1[`INTBITS]),
            .Update             (Update[1]),
            .UpdateResponse     (Update[1]),
            .Node               (1)
           );

 // =========================================================
 // Memory
 // =========================================================

// Memory chip select in segment 0xa
wire CS1 = (VPAddr1[31:28] == 4'ha) ? 1'b1 : 1'b0;

 Mem m     (.Clk                (Clk),
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
    Clk        = 1;
    Interrupt0 = 0;
    Interrupt1 = 0;
    Seed       = 32'h00250864;

    #0			// Ensure first x->1 clock edge is complete before initialisation
    Count      = 0;
    forever # (`ClkPeriod/2) Clk = ~Clk;
end

// ---------------------------------------------------------
// Simulation control and interrupt generation process
// ---------------------------------------------------------
always @(posedge Clk)
begin
    notReset_H <= #`RegDel notReset;
    Count      = Count + 1;
    if(Count == `StopCount)
    begin
        $stop;
    end
    Seed       = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};

    #`RegDel

    VPDataIn0  = Seed;

    Seed       = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};
    Interrupt0 = ((Seed % 16) == 0) ? 1 : 0;

    Seed       = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};
    Interrupt1 <= #`RegDel ((Seed % 16) == 0) ? 1 : 0;
end

`ifdef VCS
always @(negedge Clk)
begin
    if (Count == (`StopCount/2))
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
    input         Clk,
    input         WE,
    input         CS,
    input  [31:0] DI,
    input   [9:0] A,
    output [31:0] DO
);

reg [31:0] Mem [0:1023];

assign #1 DO   = Mem[A];

always @(posedge Clk)
begin
    if (WE && CS)
        Mem[A] <= #`RegDel DI;
end

endmodule

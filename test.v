/*
 * Top level demonstration test environment for VProc
 *
 * Copyright (c) 2004-2010 Simon Southwell. Confidential
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
 * $Id: test.v,v 1.2 2016/09/29 08:41:33 simon Exp $
 * $Source: /home/simon/CVS/src/HDL/VProc/test.v,v $
 */

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

reg Clk;
integer Count, Seed;

integer Interrupt0, Interrupt1;
reg [31:0] VPDataIn0;
reg notReset_H;
integer restart;
reg [1:0] UpdateResponse;

wire [31:0] VPAddr0, VPDataOut0;
wire [31:0] VPAddr1, VPDataOut1, VPDataIn1;
wire VPWE0, VPWE1;
wire VPRD0, VPRD1;
wire [1:0] Update;

wire #`RegDel notReset = (Count > 5);
wire ResetInt = notReset & ~notReset_H;

 VProc vp0 (Clk, VPAddr0, VPWE0, VPRD0, VPDataOut0, VPDataIn0, VPWE0, VPRD0, {ResetInt, Interrupt0[1:0]}, Update[0], UpdateResponse[0], 4'b0000);

 VProc vp1 (Clk, VPAddr1, VPWE1, VPRD1, VPDataOut1, VPDataIn1, VPWE1, VPRD1, Interrupt1[2:0], Update[1], UpdateResponse[1], 4'b0001);


wire CS1 = (VPAddr1[31:28] == 4'ha) ? 1'b1 : 1'b0;

 Mem m (Clk, VPDataOut1, VPDataIn1, VPWE1, VPAddr1[9:0], CS1);

initial
begin
   UpdateResponse = 2'b11;
end

always @(Update[0])
    UpdateResponse[0] = ~UpdateResponse[0];

always @(Update[1])
    UpdateResponse[1] = ~UpdateResponse[1];

initial
begin
    //$dumpfile("wave.vcd");
    //$dumpvars(1, test);
    Clk = 1;
    Interrupt0 = 0;
    Interrupt1 = 0;
    Seed  = 32'h00250864;
    
    #0			// Ensure first x->1 clock edge is complete before initialisation
    Count = 0;
    forever # (`ClkPeriod/2) Clk = ~Clk;
end

always @(posedge Clk)
begin
    notReset_H <= #`RegDel notReset;
    Count = Count + 1;
    if(Count == `StopCount)
    begin
        $stop;
    end
    Seed = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};

    #`RegDel

    VPDataIn0  = Seed;

    Seed = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};
    Interrupt0 = ((Seed % 16) == 0) ? 1 : 0;

    Seed = {$dist_uniform(Seed, 32'hffffffff, 32'h7fffffff)};
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

module Mem (Clk, DI, DO, WE, A, CS);
input Clk;
input WE, CS;
input [31:0] DI;
input [9:0] A;
output [31:0] DO;

reg [31:0] Mem [0:1023];

assign #1200 DO = Mem[A];

always @(posedge Clk)
begin
   if (WE && CS)
       Mem[A] <= #`RegDel DI;
end

endmodule

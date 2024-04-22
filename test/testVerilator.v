/*
 * Top level demonstration test environment for VProc
 *
 * Copyright (c) 2024 Simon Southwell.
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
 
`timescale 1ns / 10ps

//--------------------------------------------------------
// Local definitions
//--------------------------------------------------------

`define MEMSEG   16'h0000

`define SCRATCH0 32'ha0000000
`define SCRATCH1 32'ha0000004
`define SCRATCH2 32'ha0000008
`define SCRATCH3 32'ha000000c

`define INTADDR  32'h20000000

`define STOP     32'hfffffff0
`define FINISH   32'hfffffff4
`define TIMEOUT  10000

// =======================================================
// Top level test module
// =======================================================

module test 
#(parameter
            VCD_DUMP      = 0
);

reg         clk;
integer     count;
reg   [2:0] irq;
reg         updateresp;
reg  [31:0] scratch[0:3];
reg  [31:0] rdatascratch;
reg         readvalid;

wire [31:0] addr;
wire [31:0] wdata;
wire [31:0] rdata;
wire [31:0] rdatamem;
wire        write;
wire        read;

wire        update;
wire  [3:0] node = 0;

//--------------------------------------------------------
// Initial process
//--------------------------------------------------------

initial
begin
    // If enabled, dump all the signals to a VCD file
    if (VCD_DUMP != 0)
    begin
      $dumpfile("waves.vcd");
      $dumpvars(0, test);
    end
    
    clk         = 1'b1;
    count       = 0;
    irq         = 3'h0;
    updateresp  = 1'b0;
    readvalid   = 1'b0;

    forever clk = #5 ~clk;
end

//--------------------------------------------------------
// Combinatorial logic
//--------------------------------------------------------

// Chip select decode
wire memcs      = (write || read)  && addr[31:16] == `MEMSEG;
wire scratchcs  = addr >= `SCRATCH0 && addr <= `SCRATCH3;
wire intcs      = addr == `INTADDR;

// Returned data mux
assign rdata    = memcs     ? rdatamem :
                  scratchcs ? rdatascratch :
                  32'hxxxxxxxx;
                  
wire   rdack    = read & readvalid;

//--------------------------------------------------------
// Interrupt generation process
//--------------------------------------------------------

always @(posedge clk)
begin
  if (write && intcs)
  begin
    irq         <= wdata[0];
  end
end

//--------------------------------------------------------
// Simulation control process
//--------------------------------------------------------

always @(posedge clk)
begin
  count <= count + 1;

  if (write && addr == `STOP   && wdata[0])
     $stop;

  if (write && addr == `FINISH && wdata[0])
     $finish;

  if (count == `TIMEOUT-1)
  begin
    $display("***ERROR: simulation timed out");
    $stop;
  end

  readvalid <= read & ~readvalid;
end

//--------------------------------------------------------
// VProc node 0
//--------------------------------------------------------

  VProc vp (
    .Clk                     (clk),
    
    .Addr                    (addr),
    
    .WE                      (write),
    .WRAck                   (write),
    .DataOut                 (wdata),
    
    .RD                      (read),
    .RDAck                   (rdack),
    .DataIn                  (rdata),
    
    .Interrupt               (irq),
    
    .Update                  (update),
    .UpdateResponse          (updateresp),
    
    .Node                    (node)
  );

//--------------------------------------------------------
// Delta-cycle process
//--------------------------------------------------------
always @(update)
begin
  if (scratchcs)
  begin
    rdatascratch         <= scratch[addr[3:2]];
    if (write)
      scratch[addr[3:2]] <= wdata;
  end

  updateresp  <= ~updateresp;
end

 // ---------------------------------------------------------
 // Memory
 // ---------------------------------------------------------

 Mem m     (.clk                (clk),

            .CS0                (1'b0),
            .A0                 (14'h0),
            .BE0                (4'hf),
            .WE0                (1'b0),
            .DI0                (32'h0),
            .DO0                (),

            .CS1                (memcs),
            .A1                 (addr[15:2]),
            .BE1                (4'hf),
            .WE1                (write),
            .DI1                (wdata),
            .DO1                (rdatamem)
           );

endmodule

// =========================================================
// Simple dual-port synchronous memory model
// (64 KBytes by default, configurable)
// =========================================================

module Mem
#(parameter           LOG2WORDS = 14
)
(
    input                      clk,

    input                      WE0,
    input                      CS0,
    input       [3:0]          BE0,
    input      [31:0]          DI0,
    input      [LOG2WORDS-1:0] A0,
    output reg [31:0]          DO0,

    input                      WE1,
    input                      CS1,
    input       [3:0]          BE1,
    input      [31:0]          DI1,
    input      [LOG2WORDS-1:0] A1,
    output reg [31:0]          DO1
);

reg [31:0] Mem [0:(1 << LOG2WORDS)-1];

always @(posedge clk)
begin
    DO0       <= CS0 ? Mem[A0] : 32'hx;
    DO1       <= CS1 ? Mem[A1] : 32'hx;

    if (WE0 && CS0)
    begin
      Mem[A0] <= {BE0[3] ? DI0[31:24] : Mem[A0][31:24],
                  BE0[2] ? DI0[23:16] : Mem[A0][23:16],
                  BE0[1] ? DI0[15:8]  : Mem[A0][15:8],
                  BE0[0] ? DI0[7:0]   : Mem[A0][7:0]};
    end

    if (WE1 && CS1)
    begin
      Mem[A1] <= {BE1[3] ? DI1[31:24] : Mem[A1][31:24],
                  BE1[2] ? DI1[23:16] : Mem[A1][23:16],
                  BE1[1] ? DI1[15:8]  : Mem[A1][15:8],
                  BE1[0] ? DI1[7:0]   : Mem[A1][7:0]};
    end
end

endmodule


// -----------------------------------------------------------------------------
//  Title      : Test bench for RISC-V virtual processor
//  Project    : UNKNOWN
// -----------------------------------------------------------------------------
//  File       : tb.v
//  Author     : Simon Southwell
//  Created    : 2024-04-08
//  Standard   : Verilog 2001
// -----------------------------------------------------------------------------
//  Description:
//  This block defines the top level test bench for the memory model. Release
//  on asccess to VProc (github.com/wyvernSemi/vproc) located in the same
//  directory as this folder
// -----------------------------------------------------------------------------
//  Copyright (c) 2024 Simon Southwell
// -----------------------------------------------------------------------------
//
//  This is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation(), either version 3 of the License(), or
//  (at your option) any later version.
//
//  It is distributed in the hope that it will be useful(),
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this code. If not, see <http://www.gnu.org/licenses/>.
//
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

`define RESET_PERIOD    10

`define MEMSEG          4'h0
`define UARTSEG         4'h8

`define IMEM_SUBSEGMENT 4'h0
`define DMEM_SUBSEGMENT 4'h8

`define TIMERSTARTADDR  32'hAFFFFFE0
`define TIMERENDADDR    32'hAFFFFFEC

`define HALT_ADDR       32'hAFFFFFF8
`define INT_ADDR        32'hAFFFFFFC

module test
#(parameter GUI_RUN          = 0,
            CLK_FREQ_MHZ     = 100,
            USE_HARVARD      = 1,
            VCD_DUMP         = 0,
            DISABLE_DELTA    = 0,
            TIMEOUTCOUNT     = 4000,
            RISCVTEST        = 0);

// Clock, reset and simulation control state
reg            clk;
wire           reset_n;
integer        count;

// Signals between CPU and memory model
wire [31:0]    address;
wire           write;
wire [31:0]    writedata;
wire  [3:0]    byteenable;
wire           read;
wire [31:0]    readdata;
wire [31:0]    memreaddata;
wire [31:0]    romreaddata;
wire [31:0]    timreaddata;
wire [31:0]    uartreaddata;
wire [31:0]    ireaddata;

wire           iread;
wire [31:0]    iaddress;

reg            readdatavalid;
reg            ireaddatavalid;
reg            swirq;

wire           timirq;
wire  [2:0]   irq = {swirq, timirq, 1'b0};

// -----------------------------------------------
// Initialisation, clock and reset
// -----------------------------------------------

initial
begin
    // If enabled, dump all the signals to a VCD file
    if (VCD_DUMP != 0)
    begin
      $dumpfile("waves.vcd");
      $dumpvars(0, test);
    end
    
   count                               = -1;
   clk                                 = 1'b1;
   swirq                               = 1'b0;
   readdatavalid                       = 1'b0;
   ireaddatavalid                      = 1'b0;
end

// Generate a clock
always #(500/CLK_FREQ_MHZ) clk         = ~clk;

// Generate a reset signal using count
assign reset_n                         = (count >= `RESET_PERIOD) ? 1'b1 : 1'b0;

// -----------------------------------------------
// Address decode
// -----------------------------------------------

// Generate  memory chip selects
wire cs0 = iaddress[31:28] == `MEMSEG && iaddress[19:16] == `IMEM_SUBSEGMENT && iread == 1'b1                   ? 1'b1 : 1'b0;
wire cs1 =  address[31:28] == `MEMSEG &&  address[19:16] == `IMEM_SUBSEGMENT && (read == 1'b1 || write == 1'b1) ? 1'b1 : 1'b0;
wire cs4 =  address[31:28] == `MEMSEG &&  address[19:16] == `DMEM_SUBSEGMENT && (read == 1'b1 || write == 1'b1) ? 1'b1 : 1'b0;

// Generate peripheral chip selects
wire cs2 =  (read == 1'b1 || write ==1'b1) && address >= `TIMERSTARTADDR && address <= `TIMERENDADDR;
wire cs3 =  (read == 1'b1 || write ==1'b1) && address[31:28] == `UARTSEG;

// Software interrupt
wire cs5 =  write == 1'b1 && address == `INT_ADDR;

// Simulation control
wire cs6 =  write == 1'b1 && address == `HALT_ADDR;

// Amalgamate read data
assign readdata = cs2 ? timreaddata  :
                  cs3 ? uartreaddata :
                  cs4 ? memreaddata  :
                        romreaddata;

// -----------------------------------------------
// Simulation control process
// -----------------------------------------------

always @(posedge clk)
begin
  count                                <= count + 1;

  // Stop/finish the simulations of timeout or a write to the halt address
  if ((TIMEOUTCOUNT && count == TIMEOUTCOUNT) || (cs6 == 1'b1 && writedata[0]))
  begin
    if (count >= TIMEOUTCOUNT)
    begin
      $display("***ERROR: simulation timed out!");  
    end
    
    if (GUI_RUN == 0)
    begin
      $finish;
    end
    else
    begin
      $stop;
    end
  end
end

// -----------------------------------------------
// IRQ generation
// -----------------------------------------------

always @(posedge clk)
begin
  if (cs5 == 1'b1 && byteenable[0] == 1'b1)
  begin
    swirq                    <= writedata[0];
  end
end

// -----------------------------------------------
// -----------------------------------------------
always @(posedge clk)
begin
  readdatavalid            <= read  & ~readdatavalid;
  ireaddatavalid           <= iread & ~ireaddatavalid;
end

// -----------------------------------------------
// Virtual CPU
// -----------------------------------------------

 riscVsim  #(.USE_HARVARD   (USE_HARVARD),
             .DISABLE_DELTA (DISABLE_DELTA),
             .RISCVTEST     (RISCVTEST)) cpu
           (.clk               (clk),
           
            .daddress          (address),
            .dwrite            (write),
            .dwritedata        (writedata),
            .dbyteenable       (byteenable),
            .dread             (read),
            .dreaddata         (readdata),
            .dwaitrequest      (read & ~readdatavalid),
            
            .iaddress          (iaddress),
            .iread             (iread),
            .ireaddata         (ireaddata),
            .iwaitrequest      (iread & ~ireaddatavalid),
           
            .irq               (irq)
           );

 // ---------------------------------------------------------
 // ROM
 // ---------------------------------------------------------

 Mem r     (.clk                (clk),
 
            .CS0                (cs0),
            .A0                 (iaddress[15:2]),
            .BE0                (4'hf),
            .WE0                (1'b0),
            .DI0                (32'h0),
            .DO0                (ireaddata),

            .CS1                (cs1),
            .A1                 (address[15:2]),
            .BE1                (byteenable),
            .WE1                (write),
            .DI1                (writedata),
            .DO1                (romreaddata)
           );

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

            .CS1                (cs4),
            .A1                 (address[15:2]),
            .BE1                (byteenable),
            .WE1                (write),
            .DI1                (writedata),
            .DO1                (memreaddata)
           );

 // ---------------------------------------------------------
 // Timer
 // ---------------------------------------------------------
 
 mtimer #(.CLKFREQMHZ (CLK_FREQ_MHZ)) timer
           (
             .clk               (clk),
             .nreset            (reset_n),
             
             .cs                (cs2),
             .addr              (address[3:2]),
             .wr                (write),
             .wdata             (writedata),
             .rd                (read),
             .rdata             (timreaddata),
             .rvalid            (),
             
             .irq               (timirq)
           );

 // ---------------------------------------------------------
 // UART
 // ---------------------------------------------------------

  uart_model console
           (
             .clk               (clk),
             .nreset            (reset_n),
             
             .cs                (cs3),
             .addr              (address[4:0]),
             .wr                (write),
             .wdata             (writedata),
             .rd                (read),
             .rdata             (uartreaddata),
             .rvalid            ()
           );

endmodule

// =========================================================
// Simple dual-port 64K byte memory model with byte enables
// =========================================================

module Mem 
#(parameter MEMWORDS          = 16384
)
(
    input         clk,
    input         WE0,
    input         CS0,
    input   [3:0] BE0,
    input  [31:0] DI0,
    input  [13:0] A0,
    output [31:0] DO0,
    
    input         WE1,
    input         CS1,
    input   [3:0] BE1,
    input  [31:0] DI1,
    input  [13:0] A1,
    output [31:0] DO1
);

reg [31:0] Mem [0:MEMWORDS-1];

assign #1 DO0   = Mem[A0];
assign #1 DO1   = Mem[A1];

always @(posedge clk)
begin
    if (WE0 && CS0)
    begin
      Mem[A0]<= {BE0[3] ? DI0[31:24] : Mem[A0][31:24],
                 BE0[2] ? DI0[23:16] : Mem[A0][23:16],
                 BE0[1] ? DI0[15:8]  : Mem[A0][15:8],
                 BE0[0] ? DI0[7:0]   : Mem[A0][7:0]};
    end
    
    if (WE1 && CS1)
    begin
      Mem[A1]<= {BE1[3] ? DI1[31:24] : Mem[A1][31:24],
                 BE1[2] ? DI1[23:16] : Mem[A1][23:16],
                 BE1[1] ? DI1[15:8]  : Mem[A1][15:8],
                 BE1[0] ? DI1[7:0]   : Mem[A1][7:0]};
    end
end

endmodule

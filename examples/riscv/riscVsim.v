// -----------------------------------------------------------------------------
//  Title      : RISC-V virtual processor wrapper in verilog
//  Project    : UNKNOWN
// -----------------------------------------------------------------------------
//  File       : riscVsim.v
//  Author     : Simon Southwell
//  Created    : 2021-08-01
//  Standard   : Verilog 2001
// -----------------------------------------------------------------------------
//  Description:
//  This block defines the top level for verilog wrapper around the rv32_cpu ISS
//  Using VProc
// -----------------------------------------------------------------------------
//  Copyright (c) 2021 Simon Southwell
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

`timescale 1ns / 1ps

module riscVsim
 #(parameter          BE_ADDR     = 32'hAFFFFFF0,
   parameter          NODE        = 0,
   parameter          USE_HARVARD = 1)
 (
    input             clk,

    // Memory mapped master interface
    output     [31:0] daddress,
    output reg        dwrite,
    output     [31:0] dwritedata,
    output reg  [3:0] dbyteenable,
    output            dread,
    input      [31:0] dreaddata,
    input             dwaitrequest,
    
    // Interface active if USE_HARVARD is 1 and instr_access set by software
    output     [31:0] iaddress,
    output            iread,
    input      [31:0] ireaddata,
    input             iwaitrequest,
    
    input             irq
);

reg         instr_access;
reg         UpdateResponse;
wire        Update;
wire        WE;
wire        RDAck;
wire        read_int;
wire [31:0] nodenum = NODE;
wire [31:0] rd_data;

assign      iaddress = daddress;
assign      iread    = read_int &&  instr_access && USE_HARVARD;
assign      dread    = read_int && (instr_access == 1'b0 || USE_HARVARD == 0);
assign      rd_data  = dread ? dreaddata : ireaddata;
assign      RDAck    = ((dread & ~dwaitrequest) == 1'b1 || (iread & ~iwaitrequest) == 1'b1) ? 1'b1 : 1'b0;

initial
begin
  instr_access    <= 1'b0;

  UpdateResponse  <= 1'b1;
  dbyteenable     <= 4'hf;
end


  VProc vp (
            .Clk                     (clk),
            .Addr                    (daddress),
            .WE                      (WE),
            .RD                      (read_int),
            .DataOut                 (dwritedata),
            .DataIn                  (rd_data),
            .WRAck                   (WE),
            .RDAck                   (RDAck),
            .Interrupt               ({2'b00, irq}),
            .Update                  (Update),
            .UpdateResponse          (UpdateResponse),
            .Node                    (nodenum[3:0])
           );


always @(Update)
begin
  if (WE == 1'b1 && daddress == BE_ADDR)
  begin
    dbyteenable        <= dwritedata[3:0];
    instr_access       <= dwritedata[31];
    dwrite             <= 1'b0;
  end
  else
  begin
    dwrite             <= WE;
  end
  
  UpdateResponse = ~UpdateResponse;
end

endmodule
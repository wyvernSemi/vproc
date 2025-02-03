// ====================================================================
//
// Verilog Avalon bus functional model (BFM) wrapper for VProc.
//
// Copyright (c) 2024 - 2025 Simon Southwell.
//
// Implements minimal compliant manager interface at 32-bits or
// 64-bits wide. Also has a vectored irq input. Does not (yet) utilise
// VProc's burst capabilities.
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


module avbfm
# (parameter
    ADDRWIDTH                 = 32,        // For future proofing. Do not change.
    DATAWIDTH                 = ADDRWIDTH, // For future proofing. Do not change.
    IRQWIDTH                  = 32,        // Range 1 to 32
    NODE                      = 0
)
(
    input                     clk,

    // Avalon memory mapped master interface
    output    [ADDRWIDTH-1:0] av_address,
    output  [DATAWIDTH/8-1:0] av_byteenable,
    output                    av_write,
    output    [DATAWIDTH-1:0] av_writedata,
    output                    av_read,
    input     [DATAWIDTH-1:0] av_readdata,
    input                     av_readdatavalid,

    // Interrupt
    input      [IRQWIDTH-1:0] irq
);

// -----------------------------------------
// Signals declarations for VProc
// -----------------------------------------
wire                          update;
wire                          rd;
wire          [ADDRWIDTH-1:0] addr;
wire        [DATAWIDTH/8-1:0] be;
wire                          we;
wire          [DATAWIDTH-1:0] dataout;

wire          [DATAWIDTH-1:0] datain;
wire                          rdack;

reg                           rdlast;
reg                           updateresp;

// -----------------------------------------
// Combinatorial logic
// -----------------------------------------

// Pulse the Avalon read signal only for the first cycle of rd, which won't be
// deasserted until readdatavalid is asserted.
assign av_read                = rd & ~rdlast;
assign av_write               = we;
assign av_writedata           = dataout;
assign av_address             = addr;
assign av_byteenable          = be;

assign datain                 = av_readdata;
assign rdack                  = av_readdatavalid;

// -----------------------------------------
// Initial block
// -----------------------------------------
initial
begin
  updateresp                  = 1'b0;
end

// Delta cycle process
always @(update)
begin
  // Place any delta cycle processing logic before next line
  updateresp                  <= ~updateresp;
end

// -----------------------------------------
// Synchronous logic
// -----------------------------------------

always @(posedge clk)
begin
  // VProc's rd strobe delayed by a cycle
  rdlast                      <= rd & ~rdack;
end

// ---------------------------------------
//  VProc instantiation
// ---------------------------------------
generate
  if (ADDRWIDTH == 64)
  
    VProc64
      #(
        .NODE                   (NODE),
        .BURST_ADDR_INCR        (8),
        .INT_WIDTH              (IRQWIDTH)
      ) vp
      (
        .Clk                    (clk),
  
        // Bus
        .Addr                   (addr),
        .BE                     (be),
        .DataOut                (dataout),
        .WE                     (we),
        .WRAck                  (we),
        .DataIn                 (datain),
        .RD                     (rd),
        .RDAck                  (rdack),
  
        .Burst                  (),
        .BurstFirst             (),
        .BurstLast              (),
  
        // Interrupts
        .Interrupt              (irq),
  
        // Delta cycle control
        .Update                 (update),
        .UpdateResponse         (updateresp)
    );
    
  else
    VProc
      #(
        .INT_WIDTH              (IRQWIDTH)
      ) vp
      (
        .Clk                    (clk),
        
        // Bus
        .Addr                   (addr),
        .BE                     (be),
        .DataOut                (dataout),
        .WE                     (we),
        .WRAck                  (we),
        .DataIn                 (datain),
        .RD                     (rd),
        .RDAck                  (rdack),
        
        // Interrupts
        .Interrupt              (irq),
        
        // Delta cycle control
        .Update                 (update),
        .UpdateResponse         (updateresp),
        
        .Node                   (NODE[3:0])
    );
  endgenerate

endmodule 

// ====================================================================
//
// Verilog AXI bus functional model (BFM) wrapper for VProc.
//
// Copyright (c) 2024 Simon Southwell.
//
// Implements minimal compliant manager interface at 32-bits or
// 64-bits wide. Also has a 32-bit vectored irq input.
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

`ifndef VPROC_BYTE_ENABLE
`define VPROC_BYTE_ENABLE
`endif

`include "vprocdefs.vh"

module axi4bfm
#(parameter ADDRWIDTH         = 32,              // For future proofing. Do not change
            DATAWIDTH         = ADDRWIDTH,       // For future proofing. Do not change
            IRQWIDTH          = 32,              // Valid ranges => 1 to 32
            BURST_ADDR_INCR   = 1,               // Valid values => 1, 2, 4 or 8 (if ADDRWIDTH = 64)
            NODE              = 0
)
(
  input                       clk,

  // Write address channel
  output     [ADDRWIDTH-1:0]  awaddr,
  output                      awvalid,
  input                       awready,
  output               [2:0]  awprot,
  output               [7:0]  awlen,

  // Write Data channel
  output     [DATAWIDTH-1:0]  wdata,
  output                      wvalid,
  input                       wready,
  output                      wlast,
  output   [DATAWIDTH/8-1:0]  wstrb,

  // Write response channel
  input                       bvalid,
  output                      bready,

  // Read address channel
  output     [ADDRWIDTH-1:0]  araddr,
  output                      arvalid,
  input                       arready,
  output               [2:0]  arprot,
  output               [7:0]  arlen,

  // Read data/response channel
  input      [DATAWIDTH-1:0]  rdata,
  input                       rvalid,
  output                      rready,

  // Interrupt request (non-AXI side bus)
  input       [IRQWIDTH-1:0]  irq
);

// ---------------------------------------------------------
// Signal and register declarations
// ---------------------------------------------------------

// Internal versions of input signals
wire                          awready_int;
wire                          wready_int;
wire                          arready_int;
wire          [DATAWIDTH-1:0] rdata_int;
wire                          rvalid_int;
wire                          rready_int;

// Virtual processor memory mapped address port signals
wire          [DATAWIDTH-1:0] vpdataout;
wire          [ADDRWIDTH-1:0] vpaddr;
wire                          vpwe;
wire                          vprd;
wire                          vpwrack;
wire                          vprdack;
wire        [DATAWIDTH/8-1:0] vpbyteenable;
wire                   [11:0] vpburst;
wire                          vpbursteq0;
wire                          vplast;
reg                    [11:0] burstcount;

// Delta cycle signals
wire                          update;
reg                           updateresponse;

// Internal state to flag an AXI channel has been acknowleged,
// but transaction is still pending
reg                           awacked;
reg                           wacked;
reg                           aracked;

// ---------------------------------------------------------
// VERILATOR specific logic
// ---------------------------------------------------------

`ifdef VERILATOR
// When using  Verilator, register inputs on negative clock edge
// to ensure correct ready in synchronous logic.
reg                           awready_reg;
reg                           wready_reg;
reg                           arready_reg;
reg           [DATAWIDTH-1:0] rdata_reg;
reg                           rvalid_reg;

assign awready_int            = awready_reg;
assign wready_int             = wready_reg;
assign arready_int            = arready_reg;
assign rdata_int              = rdata_reg;
assign rvalid_int             = rvalid_reg;

always @(negedge clk)
begin

    awready_reg               = awready;
    wready_reg                = wready;
    arready_reg               = arready;
    rdata_reg                 = rdata;
    rvalid_reg                = rvalid;

end

`else

// Pass through inputs when not Verilator
assign awready_int            = awready;
assign wready_int             = wready;
assign bvalid_int             = bvalid;
assign arready_int            = arready;
assign rdata_int              = rdata;
assign rvalid_int             = rvalid;

`endif

// ---------------------------------------------------------
// Combinatorial logic
// ---------------------------------------------------------

// Default signalling (no protection, and write response always acknowleged)
assign awprot                 = 3'b000;
assign arprot                 = 3'b000;
assign bready                 = bvalid;

// The address/write data ports are only valid when their valid signals active,
// else driven X. This ensures external IP does not use invalid held values.
assign awaddr                 = awvalid ? vpaddr    : {ADDRWIDTH{1'bx}};
assign araddr                 = arvalid ? vpaddr    : {ADDRWIDTH{1'bx}};

// Burst
assign vpbursteq0             = vpburst == 12'h000;
assign awlen                  = ~vpbursteq0 ? vpburst[7:0] - 1 : 8'h00;
assign arlen                  = awlen;

assign wdata                  = wvalid  ? vpdataout : {DATAWIDTH{1'bx}};

// The write address and valid signals active when VProc writing,
// but only until they have been acknowledged.
assign awvalid                = vpwe & ~awacked;
assign wvalid                 = vpwe & ~wacked;

// VProc write acknowledged only once both address and write channels have
// been acknowledged. This could be if both channels acknowledged together,
// if write address acknowledged first then write data, or write data acknowledged
// first and then write address.
assign vpwrack                = (awready_int & wready_int) | (awacked & wready_int) | (awready_int & wacked);

// Write Last always signalled when data valid as only one word at a time.
assign wlast                  = wvalid & (vplast | vpbursteq0);

// Export VProc's byte enables
assign wstrb                  = vpbyteenable;

// The read address is valid when VProc RD strobe active until it has
// been acknowledged.
assign arvalid                = vprd & ~aracked;

// Read data always accepted.
assign rready                 = rvalid;
assign rready_int             = rvalid_int;

// The VProc read acknowlege comes straight from the AXI read data bus valid.
assign vprdack                = rvalid_int;

// ---------------------------------------------------------
// Initialise the internal state.
// ---------------------------------------------------------

initial
begin
  `MINDELAY
  aracked                     <= 1'b0;
  awacked                     <= 1'b0;
  wacked                      <= 1'b0;
  updateresponse              <= 1'b1;
  burstcount                  <= 12'h000;
end

// ---------------------------------------------------------
// Synchronous process to generate state to indicate acknowledged
// a channel has been acknowledged whilst the transaction is
// incomplete.
// ---------------------------------------------------------

always @(posedge clk)
begin

  // A channel is flagged as acknowledged if the VProc strobe active and the AXI
  // ready signal is active. This state is held until The entire transaction
  // is acknowledged back to VProc.

  // Read address channel
  aracked                     <= (aracked | (vprd & arready_int)) & ~(vprdack & burstcount <= 12'h000);

  // Write address channel
  awacked                     <= (awacked | (vpwe & awready_int)) & ~vpwrack;

  // Write data channel
  wacked                      <= (wacked  | (vpwe & wready_int))  & ~vpwrack;

  // If a new burst count, set the counter to the burst length
  if (arvalid == 1'b1 && burstcount == 0)
  begin
    burstcount                <= vpburst;
  end

  // If the counter is not zero, decrement the count when a word is received
  if (burstcount > 0 && rvalid == 1'b1 && rready  == 1'b1)
  begin
    burstcount                <= burstcount - 1;
  end

end

// ---------------------------------------------------------
// Delta cycle update process. Currently unused, but
// functionality can be added here, such as upgrade
// for wider bus architecture.
// ---------------------------------------------------------

always @(update)
begin
  updateresponse              <= ~updateresponse;
end

// ---------------------------------------------------------
// Virtual Processor
// ---------------------------------------------------------

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
        .Addr                   (vpaddr),
        
        .DataOut                (vpdataout),
        .WE                     (vpwe),
        .WRAck                  (vpwrack),
        
        .BE                     (vpbyteenable),
        
        .DataIn                 (rdata_int),
        .RD                     (vprd),
        .RDAck                  (vprdack),

        .Burst                  (vpburst),
        .BurstFirst             (),
        .BurstLast              (vplast),

        // Interrupts
        .Interrupt              (irq),

        // Delta cycle control
        .Update                 (update),
        .UpdateResponse         (updateresponse)
    );

  else

    VProc #(
             .INT_WIDTH         (IRQWIDTH),
             .BURST_ADDR_INCR   (BURST_ADDR_INCR)
           ) vp
           (
             .Clk               (clk),

             .Addr              (vpaddr),

             .DataOut           (vpdataout),
             .WE                (vpwe),
             .WRAck             (vpwrack),

             .BE                (vpbyteenable),

             .DataIn            (rdata_int),
             .RD                (vprd),
             .RDAck             (vprdack),

             .Burst             (vpburst),
             .BurstFirst        (),
             .BurstLast         (vplast),

             .Interrupt         (irq),

             .Update            (update),
             .UpdateResponse    (updateresponse),
             .Node              (NODE[3:0])
           );
  endgenerate

endmodule
// ====================================================================
//
// Verilog AXI bus functional model wrapper for VProc
//
// Copyright (c) 2024 Simon Southwell.
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

module axi4bfm
#(parameter ADDRWIDTH           = 32,
            DATAWIDTH           = 32,
            IRQWIDTH            = 32,
            NODE                = 0,
)
(
  input                         clk,

  // Write address channel
  output     [ADDRWIDTH-1:0]    awaddr,
  output                        awvalid,
  input                         awready,
  output               [2:0]    awprot,

  // Write Data channel
  output     [DATAWIDTH-1:0]    wdata,
  output                        wvalid,
  input                         wready,
  output                        wlast,

  // Write response channel
  input                         bvalid,
  output                        bready,

  // Read address channel
  output     [ADDRWIDTH-1:0]    araddr,
  output                        arvalid,
  input                         arready,
  output               [2:0]    arprot,

  // Read data/response channel
  input      [DATAWIDTH-1:0]    rdata,
  input                         rvalid,
  output                        rready,

  // Interrupt request (non-AXI side bus)
  input       [IRQWIDTH-1:0]    irq
);

// ---------------------------------------------------------
// Signal and register declarations
// ---------------------------------------------------------

// Virtual processor memory mapped address port signals
wire                     [31:0] VPDataOut;
wire                     [31:0] VPAddr;
wire                            VPWE;
wire                            VPRD;
wire                            VPWRAck;
wire                            VPRDAck;

// Delta cycle signals
wire                            Update;
wire                            UpdateResponse;

// Internal state to flag an AXI channel has been acknowleged,
// but transaction is still pending
reg                             awacked;
reg                             wacked;
reg                             aracked;

reg                             irqlast;

// ---------------------------------------------------------
// Combinatorial logic
// ---------------------------------------------------------

// Default signalling (no protection, and write response always acknowleged)
assign awprot                   = 3'b000;
assign arprot                   = 3'b000;
assign bready                   = bvalid;

// The address/write data ports are only valid when their valid signals active,
// else driven X. This ensures external IP does not use invalid held values.
assign awaddr                   = awvalid ? VPAddr    : {ADDRWIDTH{1'bx}};
assign araddr                   = arvalid ? VPAddr    : {ADDRWIDTH{1'bx}};
assign wdata                    = wvalid  ? VPDataOut : {DATAWIDTH{1'bx}};

// The write address and valid signals active when VProc writing,
// but only until they have been acknowledged.
assign awvalid                  = VPWE & ~awacked;
assign wvalid                   = VPWE & ~wacked;

// VProc write acknowledged only once both address and write channels have
// been acknowledged. This could be if both channels acknowledged together,
// if write address acknowledged first then write data, or write data acknowledged
// first and then write address.
assign VPWRAck                  = (awready & wready) | (awacked & wready) | (awready & wacked);

// Write Last always signalled when data valid as only one word at a time.
assign wlast                    = wvalid;

// The read address is valid when VProc RD strobe active until it has
// been acknowledged.
assign arvalid                  = VPRD & ~aracked;

// Read data always accepted.
assign rready                   = rvalid;

// The VProc read acknowlege comes straight from the AXI read data bus valid.
assign VPRDAck                  = rvalid;

// ---------------------------------------------------------
// Initialise the internal state.
// ---------------------------------------------------------

initial
begin
  aracked                       <= 1'b0;
  awacked                       <= 1'b0;
  wacked                        <= 1'b0;
  
  UpdateResponse                <= 1'b1;
  
  irqlast                       <= {IRQWIDTH{1'b0}};
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
  aracked                       <= (aracked | (VPRD & arready)) & ~VPRDAck;

  // Write address channel
  awacked                       <= (awacked | (VPWE & awready)) & ~VPWRAck;

  // Write data channel
  wacked                        <= (wacked  | (VPWE & wready))  & ~VPWRAck;
  
  // Delayed version of irq input port
  irqlast                       <= irq;
end

// ---------------------------------------------------------
// Delta cycle update process. Currently unused, but
// functionality can be added here, such as upgrade
// for wider bus architecture.
// ---------------------------------------------------------

always @(Update)
begin
  UpdateResponse                <= ~UpdateResponse;
end

// ---------------------------------------------------------
// Interrupt handling process
// ---------------------------------------------------------
always @(clk)
begin
  // So we can handle up to a 32 bit interrupt vector, will use
  // $vprocuser to pass in the IRQ value whenever it changes. This
  // also ensures single clock edge triggered interrupt signals
  // are logged with the software (and held there) and can be freely
  // mixed with level triggered interrupts.
  if (irq ^ irqlast)
  begin
    $vprocuser(NODE, irq);
  end
end


// ---------------------------------------------------------
// Virtual Processor
// ---------------------------------------------------------

  VProc vp (.Clk                (clk),

            .Addr               (VPAddr),

            .DataOut            (VPDataOut),
            .WE                 (VPWE),
            .WRAck              (VPWRAck),

            .DataIn             (rdata),
            .RD                 (VPRD),
            .RDAck              (VPRDAck),

            .Interrupt          (3'b000),

            .Update             (Update),
            .UpdateResponse     (UpdateResponse),
            .Node               (NODE)
           );

endmodule
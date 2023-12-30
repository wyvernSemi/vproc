// ====================================================================
//
// Verilog side Virtual Processor, for running host
// programs as control in simulation.
//
// Copyright (c) 2004-2024 Simon Southwell.
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

`include "vprocdefs.vh"

// ============================================================
// VProc module
// ============================================================

module VProc
(
    // Clock
    input             Clk,

    // Bus interface
    output reg [31:0] Addr,
    output reg        WE,
    output reg        RD,
    output reg [31:0] DataOut,
    input      [31:0] DataIn,
    input             WRAck,
    input             RDAck,

    // Interrupt
    input  [`INTBITS] Interrupt,

    // Delta cycle control
    output reg        Update,
    input             UpdateResponse,

`ifdef VPROC_BURST_IF
    // Burst count
    output reg [11:0] Burst,
    output reg        BurstFirst,
    output reg        BurstLast,
`endif

    // Node number
    input [`NODEBITS] Node
);

// ------------------------------------------------------------
// Register definitions
// ------------------------------------------------------------

// $vsched/$vaccess outputs
integer               VPDataOut;
integer               VPAddr;
integer               VPRW;
integer               VPTicks;

// Sampled VProc inputs
integer               DataInSamp;
integer               IntSamp;
integer               NodeI;
reg                   RdAckSamp;
reg                   WRAckSamp;

// Internal initialised flag (set after $vinit called)
reg                   Initialised;

// Internal state
integer               TickCount;
integer               BlkCount;
integer               AccIdx;

`ifndef VPROC_BURST_IF
reg [11:0]            Burst;
reg                   BurstFirst;
reg                   BurstLast;
`endif

// ------------------------------------------------------------
// Initial process
// ------------------------------------------------------------

initial
begin
    TickCount                           = 1;
    Initialised                         = 0;
    WE                                  = 0;
    RD                                  = 0;
    Update                              = 0;
    BlkCount                            = 0;

    // Don't remove delay! Needed to allow Node to be assigned
    // before the call to $vinit
    #0
    $vinit(Node);
    Initialised                         = 1;
end


// ------------------------------------------------------------
/// Main scheduler process
// ------------------------------------------------------------

always @(posedge Clk)
begin
    // Cleanly sample the inputs and make them integers
    RdAckSamp                           = RDAck;
    WRAckSamp                           = WRAck;
    IntSamp                             = {1'b0, Interrupt};
    NodeI                               = Node;
    VPTicks                             = `DELTACYCLE;

    // Wait until the VProc software is initialised for this node ($vinit called)
    // before starting accesses
    if (Initialised == 1'b1)
    begin
        // If an interrupt active, call $vsched with interrupt value
        if (IntSamp > 0)
        begin
            $vsched(NodeI, IntSamp, DataInSamp, VPDataOut, VPAddr, VPRW, VPTicks);

            // If interrupt routine returns non-zero tick, then override
            // current tick value. Otherwise, leave at present value.
            if (VPTicks > 0)
            begin
                TickCount               = VPTicks;
            end
        end

        // If tick, write or a read has completed (or in last cycle)...
        if ((RD === 1'b0 && WE        === 1'b0 && TickCount === 0) ||
            (RD === 1'b1 && RdAckSamp === 1'b1)                    ||
            (WE === 1'b1 && WRAckSamp === 1'b1))
        begin
            BurstFirst                  = 1'b0;
            BurstLast                   = 1'b0;
             
            // Loop accessing new commands until VPTicks is not a delta cycle update
            while (VPTicks < 0)
            begin
                // Clear any interrupt (already dealt with)
                IntSamp                 = 0;
                
                // Sample the data in port
                DataInSamp              = DataIn;
                
                if (BlkCount <= 1)
                begin
                    // If this is the last transfer in a burst, call $vaccess with
                    // the last data input sample.
                    if (BlkCount == 1)
                    begin
                        AccIdx          = AccIdx + 1;
`ifdef VPROC_BURST_IF
                        $vaccess(NodeI, AccIdx, DataInSamp, VPDataOut);
`endif
                    end
                
                    // Get new access command
                    $vsched(NodeI, IntSamp, DataInSamp, VPDataOut, VPAddr, VPRW, VPTicks);
                    
                    // Update the outputs
                    Burst               = VPRW[`BLKBITS];
                    WE                  = VPRW[`WEBIT];
                    RD                  = VPRW[`RDBIT];
                    Addr                = VPAddr;
                
                    // If new BlkCount is non-zero, setup burst transfer
                    if (Burst !== 0)
                    begin
                        BlkCount        = Burst;
                        BurstFirst      = 1'b1;

                        // On writes, override VPDataOut to get from burst access task $vaccess at index 0
                        if (WE)
                        begin
                            AccIdx      = 0;
`ifdef VPROC_BURST_IF 
                            $vaccess(NodeI, AccIdx, `DONTCARE, VPDataOut);
`endif
                        end
                        else
                        begin
                            // For reads, intialise index to -1, as it's pre-incremented at next $vaccess call
                            AccIdx      = -1;
                        end
                    end
                    
                    // Update DataOut port
                    DataOut             = VPDataOut;
                end
                // If a block access is valid (BlkCount is non-zero), get the next data out/send back latest sample
                else
                begin
                    AccIdx              = AccIdx + 1;
`ifdef VPROC_BURST_IF
                    $vaccess(NodeI, AccIdx, DataInSamp, VPDataOut);
`endif
                    DataOut             = VPDataOut;
                    Addr                = Addr + 1;
                    BlkCount            = BlkCount - 1;

                    if (BlkCount == 1)
                    begin
                        BurstLast       = 1'b1;
                    end

                    // When bursting, reassert non-delta VPTicks value to break out of loop.
                    VPTicks             = 0;
                end
                
                // Update current tick value with returned number (if not negative)
                if (VPTicks >= 0)
                begin
                    TickCount           = VPTicks;
                end
                
                // Flag to update externally and wait for response
                Update                  = ~Update;
                @(UpdateResponse);
            end
        end
        else
        begin
            // Count down to zero and stop
            TickCount                   = (TickCount > 0) ? TickCount - 1 : 0;
        end
    end
end

endmodule

// ====================================================================
//
// SystemVerilog side Virtual Processor 64-bit, for running host
// programs as control in simulation.
//
// Copyright (c) 2025 Simon Southwell.
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
// VProc64 module
// ============================================================

module VProc64
#(parameter                NODE            = 0,
                           INT_WIDTH       = 32,
                           BURST_ADDR_INCR = 1,
                           DISABLE_DELTA   = 0
)
(
    // Clock
    input                  Clk,

    // Bus interface
    output reg [63:0]      Addr,
    output reg  [7:0]      BE,
    output reg             WE,
    output reg             RD,
    output reg [63:0]      DataOut,
    input      [63:0]      DataIn,
    input                  WRAck,
    input                  RDAck,

    // Interrupt
    input [INT_WIDTH-1:0]  Interrupt,

    // Delta cycle control
    output reg             Update,
    input                  UpdateResponse,

    // Burst count
    output reg [11:0]      Burst,
    output reg             BurstFirst,
    output reg             BurstLast
);

// ------------------------------------------------------------
// Register definitions
// ------------------------------------------------------------

// VSched/VAccess outputs
integer                    VPDataOutLo;
integer                    VPDataOutHi;
integer                    VPAddrLo;
integer                    VPAddrHi;
integer                    VPRW;
integer                    VPTicks;

// Sampled VProc inputs
integer                    DataInLoSamp;
integer                    DataInHiSamp;
integer                    IntSamp;
integer                    IntSampLast;
reg                        RdAckSamp;
reg                        WRAckSamp;

// Internal initialised flag (set after VInit called)
reg                        Initialised;

// Internal state
integer                    TickCount;
integer                    BlkCount;
integer                    AccIdx;
integer                    AccIdx64;
integer                    LBE;

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
    IntSampLast                         = 0;
    Burst                               = 0;
    BurstFirst                          = 0;
    BurstLast                           = 0;
    RdAckSamp                           = 0;
    WRAckSamp                           = 0;
    AccIdx                              = 0;

    `VInit(NODE);
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
    IntSamp                             = Interrupt;
    VPTicks                             = `DELTACYCLE;

    // Wait until the VProc software is initialised for this node (VInit called)
    // before starting accesses
    if (Initialised == 1'b1)
    begin

        // If vector IRQ enabled, call VIirq when interrupt value changes, passing in
        // new value
        if (IntSamp != IntSampLast)
        begin
          `VIrq(NODE, IntSamp);
          IntSampLast                   <= IntSamp;
        end

        // If tick, write or a read has completed (or in last cycle)...
        if ((RD === 1'b0 && WE        === 1'b0 && TickCount === 0) ||
            (RD === 1'b1 && RdAckSamp === 1'b1)                    ||
            (WE === 1'b1 && WRAckSamp === 1'b1))
        begin
            BurstFirst                  <= 1'b0;
            BurstLast                   <= 1'b0;

            // Loop accessing new commands until VPTicks is not a delta cycle update
            while (VPTicks < 0)
            begin

                // Sample the data in port
                DataInLoSamp            = DataIn[31:0];
                DataInHiSamp            = DataIn[63:32];

                if (BlkCount <= 1)
                begin
                    // If this is the last transfer in a burst, call VAccess with
                    // the last data input sample.
                    if (BlkCount == 1)
                    begin
                        BlkCount        = 0;

                        if (RD)
                        begin
                            AccIdx      = AccIdx + 1;
                            // Icarus Verilog does not like VPI call arguments with arithmetic,
                            // so generate the index value for the two accesses for the 64-bit value.
                            AccIdx64    = AccIdx * 2;
                            `VAccess(NODE, AccIdx64, DataInLoSamp, VPDataOutLo);
                            AccIdx64    = AccIdx64 + 1;
                            `VAccess(NODE, AccIdx64, DataInHiSamp, VPDataOutHi);
                        end
                    end

                    // Get new access command
                    `VSched64(NODE,
                              DataInLoSamp, DataInHiSamp,
                              VPDataOutLo,  VPDataOutHi,
                              VPAddrLo,     VPAddrHi,
                              VPRW,
                              VPTicks);

                    // Update the outputs
                    Burst               <= VPRW[`BLKBITS];
                    WE                  <= VPRW[`WEBIT];
                    RD                  <= VPRW[`RDBIT];
                    BE                  <= VPRW[`BEBITS64];
                    LBE                 <= VPRW[`LBEBITS64];
                    Addr                <= {VPAddrHi, VPAddrLo};

                    // If new BlkCount is non-zero, setup burst transfer
                    if (VPRW[`BLKBITS] !== 0)
                    begin
                        // Flag burst as first in block
                        BurstFirst      <= 1'b1;

                        // Initialise the burst block counter with count bits
                        BlkCount        = VPRW[`BLKBITS];

                        // If a single word transfer, set the last flag
                        if (BlkCount == 1)
                        begin
                          BurstLast     <= 1'b1;
                        end

                        // On writes, override VPDataOut to get from burst access task VAccess at index 0
                        if (VPRW[`WEBIT])
                        begin
                            AccIdx      = 0;
                            `VAccess(NODE, 0, `DONTCARE, VPDataOutLo);
                            `VAccess(NODE, 1, `DONTCARE, VPDataOutHi);
                        end
                        else
                        begin
                            // For reads, intialise index to -1, as it's pre-incremented at next VAccess call
                            AccIdx      = -1;
                        end
                    end

                    // Update DataOut port
                    DataOut[31:0]       <= VPDataOutLo;
                    DataOut[63:32]      <= VPDataOutHi;
                end
                // If a block access is valid (BlkCount is non-zero), get the next data out/send back latest sample
                else
                begin
                    AccIdx              = AccIdx + 1;
                    // Icarus Verilog does not like VPI call arguments with arithmetic,
                    // so generate the index value for the two accesses for the 64-bit value.
                    AccIdx64            = AccIdx * 2;
                    `VAccess(NODE, AccIdx64, DataInLoSamp, VPDataOutLo);
                    AccIdx64            = AccIdx64 + 1;;
                    `VAccess(NODE, AccIdx64, DataInHiSamp, VPDataOutHi);

                    BlkCount            = BlkCount - 1;

                    if (BlkCount == 1)
                    begin
                        BurstLast       <= 1'b1;
                        BE              <= LBE;
                    end
                    else
                    begin
                        BE              <= 8'hff;
                    end

                    // When bursting, reassert non-delta VPTicks value to break out of loop.
                    VPTicks             = 0;

                    // Update address and data outputs
                    DataOut             <= {VPDataOutHi, VPDataOutLo};
                    Addr                <= Addr + BURST_ADDR_INCR;
                end

                // Update current tick value with returned number (if not negative)
                if (VPTicks > 0)
                begin
                    TickCount           = VPTicks - 1;
                end

                // Flag to update externally and wait for response.
                // The `MINDELAY ensures it's not updated until other outputs
                // are updated.
                Update                  <= `MINDELAY ~Update;

                if (DISABLE_DELTA == 0)
                begin
                    @(UpdateResponse);
                end
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

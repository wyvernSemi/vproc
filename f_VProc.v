/*
 * Verilog side Virtual Processor, for running host
 * programs as control in simulation.
 *
 * Copyright (c) 2004-2016 Simon Southwell. 
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
 * $Id: f_VProc.v,v 1.3 2016/10/04 15:10:42 simon Exp $
 * $Source: /home/simon/CVS/src/HDL/VProc/f_VProc.v,v $
 */

`VProcTimeScale

`define WEbit       0
`define RDbit       1
`define DeltaCycle -1

module VProc (Clk, Addr, WE, RD, DataOut, DataIn, WRAck, RDAck, Interrupt, Update, UpdateResponse, Node);

input         Clk;
input         RDAck;
input         WRAck;
input         UpdateResponse;
input   [3:0] Node; 
input   [2:0] Interrupt;
input  [31:0] DataIn;
output [31:0] Addr, DataOut;
output        WE;
output        RD;
output        Update;

integer       VPDataOut;
integer       VPAddr;
integer       VPRW;
integer       VPTicks;
integer       TickVal;

reg    [31:0] DataOut;
reg    [31:0] DataInSamp;
reg    [31:0] Addr;
reg     [2:0] IntSamp;
reg           WE;
reg           RD;
reg           RdAckSamp;
reg           WRAckSamp;
reg           Initialised;
reg           Update;

initial
begin
    TickVal      = 1;
    Initialised  = 0;
    WE           = 0;
    RD           = 0;
    Update       = 0;

    // Don't remove delay! Needed to allow Node to be assigned
    #1
    $vinit(Node);
    Initialised  = 1;
end


always @(posedge Clk)
begin
    // Cleanly sample the inputs
    DataInSamp   = DataIn;
    RdAckSamp    = RDAck;
    WRAckSamp    = WRAck; 
    IntSamp      = Interrupt;

    if (Initialised == 1'b1)
    begin
        if (IntSamp > 0)
        begin
            $vsched({28'h0000000, Node}, {29'h00000000, IntSamp}, DataInSamp, VPDataOut, VPAddr, VPRW, VPTicks);

            // If interrupt routine returns non-zero tick, then override
            // current tick value. Otherwise, leave at present value.
            if (VPTicks > 0)
            begin
                TickVal = VPTicks;
            end
        end

        // If tick, write or a read has completed...
        if ((RD === 1'b0 && WE === 1'b0 && TickVal === 0) || 
            (RD === 1'b1 && RdAckSamp === 1'b1)           ||
            (WE === 1'b1 && WRAckSamp === 1'b1))
        begin
            // Host process message scheduler called
            $vsched({28'h0000000, Node}, 32'h0, DataInSamp, VPDataOut, VPAddr, VPRW, VPTicks);

            #`RegDel 
            WE      = VPRW[`WEbit];
            RD      = VPRW[`RDbit];
            DataOut = VPDataOut;
            Addr    = VPAddr;
            Update  = ~Update;

            @(UpdateResponse);

            // Update current tick value with returned number (if not zero)
            if (VPTicks > 0)
            begin
                TickVal = VPTicks;
            end
            else if ( VPTicks < 0)
            begin
                while (VPTicks == `DeltaCycle)
                begin
                    // Resample delta input data
                    DataInSamp = DataIn;

                    $vsched({28'h0000000, Node}, 32'h0, DataInSamp, VPDataOut, VPAddr, VPRW, VPTicks);

                    WE      = VPRW[`WEbit];
                    RD      = VPRW[`RDbit];
                    DataOut = VPDataOut;
                    Addr    = VPAddr;
                    Update  = ~Update;

                    if (VPTicks >= 0)
		    begin
                        TickVal = VPTicks;
                    end

                    @(UpdateResponse);
                end
            end
        end
        else
        begin
            // Count down to zero and stop
            TickVal  = (TickVal > 0) ? TickVal - 1 : 0;
        end
    end
end

endmodule

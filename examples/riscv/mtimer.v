// ====================================================================
//
// RISC-V mtime timer to return (and compare) time in units of
// 1 microsecond.
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
module mtimer
#(parameter               MTIME_INIT       = 64'h0,
                          MTIMECMP_INIT    = 64'hffffffffffffffff,
                          CLKFREQMHZ       = 100                    // must be an integer between 1 and 1023
)
(
  input             clk,
  input             nreset,

  input             cs,
  input       [1:0] addr,
  input             wr,
  input      [31:0] wdata,
  input             rd,
  output reg [31:0] rdata,
  output reg        rvalid,

  output reg        irq
);

localparam TICKCOUNTUS = CLKFREQMHZ;

reg [63:0] mtime;
reg [63:0] mtimecmp;
reg [9:0]  count;

always @(posedge clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    rvalid                     <= 1'b0;
    irq                        <= 1'b0;
    mtime                      <= MTIME_INIT;
    mtimecmp                   <= MTIMECMP_INIT;
    count                      <= 0;
  end
  else
  begin
    // Generate IRQ output
    irq                        <= (mtime > mtimecmp) ? 1'b1 : 1'b0;

    // Update registers
    if (cs && wr)
    begin
      case(addr)
      2'b00 : mtime[31:0]      <= wdata;
      2'b01 : mtime[63:32]     <= wdata;
      2'b10 : mtimecmp[31:0]   <= wdata;
      2'b11 : mtimecmp[63:32]  <= wdata;
      endcase
    end

    // Read registers
    case (addr)
    2'b00 : rdata              <= mtime[31:0];
    2'b01 : rdata              <= mtime[63:32];
    2'b10 : rdata              <= mtimecmp[31:0];
    2'b11 : rdata              <= mtimecmp[63:32];
    endcase

    rvalid                     <= (rd & ~rvalid);

    // Increment counters
    count                      <= count + 10'd1;

    if (count == TICKCOUNTUS-1)
    begin
      count                    <= 10'd0;
      mtime                    <= mtime + 64'd1;
    end

  end
end
endmodule
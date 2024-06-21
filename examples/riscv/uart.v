// ====================================================================
//
// Model to display written data as ASCII characters to console,
// as if to a terminal via a UART
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

module uart_model
(
  input             clk,
  input             nreset,

  input             cs,
  input       [4:0] addr,
  input             wr,
  input      [31:0] wdata,
  input             rd,
  output reg [31:0] rdata,
  output reg        rvalid
);

always @(posedge clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    rvalid                     <= 1'b0;
  end
  else
  begin
    // Update registers
    if (cs && wr)
    begin
      case(addr)
      5'h00  : $write("%c", wdata[7:0]);
      default:;
      endcase
    end

    // Read registers
    case (addr)
    5'h00  : rdata             <= 32'hcc;
    5'h14  : rdata             <= 32'h20;
    default: rdata             <= 32'h0;
    endcase

    rvalid                     <= (rd & ~rvalid);
  end
end

endmodule
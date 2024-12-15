// ====================================================================
//
// SystemVerilog VProc Verilator simulation control module
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

`include "verilator_sim_ctrl.vh"

module verilator_sim_ctrl
#(parameter                  NODE             = 0,
                             CLK_PERIOD_PS    = 10000,
                             DISABLE_SIM_CTRL = 0

)
(
    input                    clk,
    output reg [31:0]        cycle_count
);

wire [31:0]                  addr;
wire [31:0]                  dataout;
reg  [31:0]                  datain;
wire                         we;
wire                         rd;

wire                         update;

// -----------------------------------------
// Initial
// -----------------------------------------

initial
begin
  cycle_count                = 0;
end

generate

if (DISABLE_SIM_CTRL == 0) begin


// -----------------------------------------
// Read process
// -----------------------------------------

  always @(negedge clk)
  begin
  
    case (addr)
      `VSC_CYC_COUNT_ADDR:
        datain                 <= cycle_count;
      `VSC_CLK_PERIOD_ADDR:
        datain                 <= CLK_PERIOD_PS;
      default:
        datain                 <= 32'h0;
    endcase
  end

// -----------------------------------------
// write process
// -----------------------------------------

  always @(posedge clk)
  begin
    cycle_count                <= cycle_count + 1;
  
    if (we)
    begin
      case (addr)
        `VSC_FINISH_ADDR: if (dataout[0]) $finish;
        default;
      endcase
    end
  end

// -----------------------------------------
//  VProc instantiation
// -----------------------------------------

  VProc
    #(
      .DISABLE_DELTA          (1)
    ) vp
    (
      .Clk                    (clk),

      // Bus
      .Addr                   (addr),
      .DataOut                (dataout),
      .WE                     (we),
      .WRAck                  (we),
      .DataIn                 (datain),
      .RD                     (rd),
      .RDAck                  (rd),
      
`ifdef VPROC_BYTE_ENABLE
      .BE                     (),
`endif

`ifdef VPROC_BURST_IF
      // Burst count
      .Burst                  (), 
      .BurstFirst             (),
      .BurstLast              (),
`endif

      // Interrupts
      .Interrupt              (0),

      // Delta cycle control
      .Update                 (update),
      .UpdateResponse         (update),

      .Node                   (NODE[3:0])
  );

end
endgenerate

endmodule
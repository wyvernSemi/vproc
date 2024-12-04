// =============================================================
//
// Top level test environment for Verilator simulation control
//
// Copyright (c) 2024 Simon Southwell. Confidential
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
// =============================================================

// ---------------------------------------------------------
// APB test bench
// ---------------------------------------------------------

module test
#(parameter
  CLKPERIODNS                 = 12,
  TIMEOUT                     = 20000000,
  DISABLE_SIM_CTRL            = 0
);

reg                           clk;
wire [31:0]                   count;

// -------------------------------------------
//  Clock generation
// -------------------------------------------

initial
begin

  clk                           = 1'b1;
  forever # (CLKPERIODNS/2 * 1ns) clk = ~clk;
end

// -------------------------------------------
// Synchronous process
// -------------------------------------------

always @(clk)
begin
  if (count == TIMEOUT)
  begin
      $display("***ERROR: simulation timed out");
      $finish;
  end
end

// -------------------------------------------
// Instantiation of simulation control
// -------------------------------------------

  verilator_sim_ctrl
  #(
     .NODE                    (0),
     .CLK_PERIOD_PS           (CLKPERIODNS*1000),
     .DISABLE_SIM_CTRL        (DISABLE_SIM_CTRL)
  ) simctrl
  (
    .clk                      (clk),
    .cycle_count              (count)
  );

endmodule



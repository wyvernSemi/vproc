-- =============================================================
--
--  Copyright (c) 2024 - 2025 Simon Southwell. All rights reserved.
--
--  Date: 29th March 2024
--
--  This file is part of the VProc package.
--
--  VProc is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  VProc is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with VProc. If not, see <http://www.gnu.org/licenses/>.
--
-- =============================================================
-- altera vhdl_input_version vhdl_2008

package vproc_pkg is

  procedure VInit (
    node : in integer
  );
  attribute foreign of VInit : procedure is "VHPIDIRECT ./VProc.so VInit";

  procedure VSched (
    node      : in  integer;
    VPDataIn  : in  integer;
    VPDataOut : out integer;
    VPAddr    : out integer;
    VPRw      : out integer;
    VPTicks   : out integer
  );
  attribute foreign of VSched : procedure is "VHPIDIRECT ./VProc.so VSched";

  procedure VProcUser (
    node      : in  integer;
    value     : in  integer
  );
  attribute foreign of VProcUser : procedure is "VHPIDIRECT ./VProc.so VProcUser";

  procedure VIrq (
    node      : in  integer;
    irq       : in  integer
  );
  attribute foreign of VIrq : procedure is "VHPIDIRECT ./VProc.so VIrq";

  procedure VAccess (
    node      : in  integer;
    idx       : in  integer;
    VPDataIn  : in  integer;
    VPDataOut : out integer
  );
  attribute foreign of VAccess : procedure is "VHPIDIRECT ./VProc.so VAccess";

end;

package body vproc_pkg is

  procedure VInit (
    node      : in integer
  ) is
  begin
    report "ERROR: foreign subprogram out_params not called";
  end;

  procedure VSched (
    node      : in  integer;
    VPDataIn  : in  integer;
    VPDataOut : out integer;
    VPAddr    : out integer;
    VPRw      : out integer;
    VPTicks   : out integer
  ) is
  begin
    report "ERROR: foreign subprogram out_params not called";
  end;

  procedure VProcUser (
    node      : in  integer;
    value     : in  integer
  ) is
  begin
    report "ERROR: foreign subprogram out_params not called";
  end;

  procedure VIrq (
    node      : in  integer;
    irq       : in  integer
  ) is
  begin
    report "ERROR: foreign subprogram out_params not called";
  end;

  procedure VAccess (
    node      : in  integer;
    idx       : in  integer;
    VPDataIn  : in  integer;
    VPDataOut : out integer
  ) is
  begin
    report "ERROR: foreign subprogram out_params not called";
  end;

end;
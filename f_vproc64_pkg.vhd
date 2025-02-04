-- =============================================================
--  
--  Copyright (c) 2025 Simon Southwell. All rights reserved.
-- 
--  Date: 3rd February 2025
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

package vproc64_pkg is

  procedure VInit (
    node : in integer
  );
  attribute foreign of VInit : procedure is "VInit VProc.so";
--attribute foreign of VInit : procedure is "VHPI VProc.so; VInit";

  procedure VSched64 (
    node          : in  integer;
    VPDataInLo    : in  integer;
    VPDataInHi    : in  integer;
    VPDataOutLo   : out integer;
    VPDataOutHi   : out integer;
    VPAddrLo      : out integer;
    VPAddrHi      : out integer;
    VPRw          : out integer;
    VPTicks       : out integer
  );
attribute foreign of VSched64 : procedure is "VSched64 VProc.so";
--attribute foreign of VSched64 : procedure is "VHPI VProc.so; VSched64";

  procedure VProcUser (
    node      : in  integer;
    value     : in  integer
  );
  attribute foreign of VProcUser : procedure is "VProcUser VProc.so";
--attribute foreign of VProcUser : procedure is "VHPI VProc.so; VProcUser";

  procedure VIrq (
    node      : in  integer;
    irq       : in  integer
  );
  attribute foreign of VIrq : procedure is "VIrq VProc.so";
--attribute foreign of VIrq : procedure is "VHPI VProc.so; VIrq";

  procedure VAccess (
    node      : in  integer;
    idx       : in  integer;
    VPDataIn  : in  integer;
    VPDataOut : out integer
  );
  attribute foreign of VAccess : procedure is "VAccess VProc.so";
--attribute foreign of VAccess : procedure is "VHPI VProc.so; VAccess";

end;

package body vproc64_pkg is

  procedure VInit (
    node      : in integer
  ) is
  begin
    report "ERROR: foreign subprogram out_params not called";
  end;

  procedure VSched64 (
    node        : in  integer;
    VPDataInLo  : in  integer;
    VPDataInHi  : in  integer;
    VPDataOutLo : out integer;
    VPDataOutHi : out integer;
    VPAddrLo    : out integer;
    VPAddrHi    : out integer;
    VPRw        : out integer;
    VPTicks     : out integer
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
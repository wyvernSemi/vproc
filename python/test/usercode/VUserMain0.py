###################################################################
# Python user test code for VProc co-simulation
#
# Copyright (c) 2024 Simon Southwell.
#
# This file is part of VProc.
#
# This code is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The code is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this code. If not, see <http://www.gnu.org/licenses/>.
#
###################################################################

import os
import sys
sys.path.append('../modules')

# Load ctypes library to get access to C domain
from ctypes import *
import pyvproc

# Define some local constants
__SIMSTOPADDR = 0xb0000000
__LONGTIME    = 0x7fffffff

# Define global variable to flag when reset deassertion interrupt
# event has occurred
seenreset = 0

# ---------------------------------------------------------------
# Interrupt callback function
# ---------------------------------------------------------------

def irqCb (irq) :
    # Get access to global variable
    global seenreset

    print("Interrupt = ", hex(irq))

    # If irq[0] is 1, flag that seen a reset deassertion
    if irq & 0x1 :
      print("  Seen reset deasserted!\n")
      seenreset = 1

    return 0

# ---------------------------------------------------------------
# Function to wrap python IRQ callback as a C function object
# ---------------------------------------------------------------

def pyIrqFuncCwrap (func) :
  cb_ftype = CFUNCTYPE(c_int, c_int)

  return cb_ftype(func)

# ---------------------------------------------------------------
# Function to wait for reset deassertion event
# ---------------------------------------------------------------

def waitForResetDeassert (vpapi, polltime = 10) :

  while seenreset == 0 :
    vpapi.tick(polltime)

# ---------------------------------------------------------------
# Function to load Python C API module
# ---------------------------------------------------------------

def loadPyModule(name = "./PyVproc.so") :

  module = CDLL(name)
  module.argtypes = [c_int32]
  module.restype  = [c_int32]

  return module

# ---------------------------------------------------------------
# Main entry point for node 0
# ---------------------------------------------------------------

def VUserMain0() :

  # Get access to global variable
  global seenreset

  # This is node 0
  node  = 0
  
  # Create an API object for node 0
  vpapi = pyvproc.PyVProcClass(node)
  
  # Register IRQ callback
  vpapi.regIrq(irqCb)

  # Wait until reset is deasserted
  waitForResetDeassert(vpapi)

  # Do some transfers with delays...
  vpapi.tick(11)
  
  # Construct some test data (addresses are word addresses)
  addr  = [0xa0001000, 0xa0001001]
  wdata = [0x12345678, 0x87654321]

  print("Writing " + hex(wdata[0]) + " to   addr " + hex(addr[0]))
  vpapi.write(addr[0], wdata[0])

  vpapi.tick(1)

  print("Writing " + hex(wdata[1]) + " to   addr " + hex(addr[1]))
  vpapi.write(addr[1], wdata[1])

  vpapi.tick(5)

  rdata = c_uint32(vpapi.read(addr[0])).value
  
  if rdata == wdata[0] :
    print("Read    " + hex(c_uint32(rdata).value) + " from addr " + hex(addr[0]))
  else :
    print("***ERROR: Read    " + hex(c_uint32(rdata).value) + " from addr " + hex(addr[0]) + ", expected " + hex(wdata[0]))
  
  vpapi.tick(3)

  rdata = c_uint32(vpapi.read(addr[1])).value
  
  if rdata == wdata[1] :
    print("Read    " + hex(c_uint32(rdata).value) + " from addr " + hex(addr[1]))
  else :
    print("***ERROR: Read    " + hex(c_uint32(rdata).value) + " from addr " + hex(addr[1]) + ", expected " + hex(wdata[1]))

  print("\nTests complete, stopping simulation\n")
  vpapi.tick(20)

  # Tell simulator to stop/finish
  vpapi.write(__SIMSTOPADDR, 1);

  # Should not get here
  while True :
    vpapi.tick(__LONGTIME)

# ###############################################################
# Only run if not imported
#
if __name__ == '__main__' :

  VUserMain0()
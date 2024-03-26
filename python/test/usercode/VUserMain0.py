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

from ctypes import *
import sys
sys.path.append('../modules')
import pyvproc

# Define some local constants
__SIMSTOPADDR = 0xb0000000
__LONGTIME    = 0x7fffffff

# Define global variable to flag when reset deassertion interrupt
# event has occurred
seenreset     = False
irq1count     = 0
previrq       = 0

# Define a global vproc API object handle so that the IRQ callback 
# can use it.
vpapi     = None

# ---------------------------------------------------------------
# Interrupt callback function
# ---------------------------------------------------------------

def irqCb (irq) :

    # Get access to global variable
    global seenreset, irq1count, previrq, vpapi

    vpapi.VPrint("Interrupt = " + hex(irq))

    # If irq[0] is 1, flag that seen a reset deassertion
    if (irq & 0x1) and not seenreset :
      vpapi.VPrint("  Seen reset deasserted!\n")
      seenreset = True
    
    # Increment a count for IRQ[1] whenever it changes
    if (irq ^ previrq) & 0x2 :
      irq1count = irq1count + 1
    
    # Remember irq vector value
    previrq = irq;

    return 0

# ---------------------------------------------------------------
# Function to wait for reset deassertion event
# ---------------------------------------------------------------

def waitForResetDeassert (vpapi, polltime = 10) :

  while seenreset == 0 :
    vpapi.tick(polltime)

# ---------------------------------------------------------------
# Main entry point for node 0
# ---------------------------------------------------------------

def VUserMain0() :

  # Get access to global variable
  global seenreset, irq1count, vpapi

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

  # Write test
  vpapi.VPrint("Writing " + hex(wdata[0]) + " to   addr " + hex(addr[0]))
  vpapi.write(addr[0], wdata[0])

  vpapi.tick(1)

  vpapi.VPrint("Writing " + hex(wdata[1]) + " to   addr " + hex(addr[1]))
  vpapi.write(addr[1], wdata[1])

  vpapi.tick(5)

  # Read Test
  rdata = vpapi.uread(addr[0])  # Unsigned value
  
  if rdata == wdata[0] :
    vpapi.VPrint("Read    " + hex(rdata) + " from addr " + hex(addr[0]))
  else :
    vpapi.VPrint("***ERROR: Read    " + hex(rdata) + " from addr " + hex(addr[0]) + ", expected " + hex(wdata[0]))
  
  vpapi.tick(3)

  rdata = vpapi.uread(addr[1])  # Unsigned value
  
  if rdata == wdata[1] :
    vpapi.VPrint("Read    " + hex(rdata) + " from addr " + hex(addr[1]))
  else :
    vpapi.VPrint("***ERROR: Read    " + hex(rdata) + " from addr " + hex(addr[1]) + ", expected " + hex(wdata[1]))
    
  vpapi.tick(1)
  
  # Burst write test
  burstWrData = [0xcafebabe, 0xdeadbeef, 0x900ddeed, 0x0badf00d]
  burstAddr   = 0xa0002000
  vpapi.VPrint("Writing burst " + str(list(map(hex, burstWrData))) + " to   addr " + hex(burstAddr))
  vpapi.burstWrite(burstAddr, burstWrData, len(burstWrData))
  
  # Burst read test
  burstRdData = vpapi.burstRead(burstAddr, 4);
  vpapi.VPrint("Read burst    " + str(list(map(hex, burstRdData))) + " from addr " + hex(burstAddr));
  
  if burstRdData != burstWrData :
    vpapi.VPrint("***ERROR: mismatch in burst read data");

  vpapi.tick(10)
  
  # Check IRQ[1] count
  if irq1count != 2 :
    vpapi.VPrint("***ERROR: Unexpected IRQ[1] count (" + str(int(irq1count)) + ")")
    
  vpapi.tick(10)
  
  vpapi.VPrint("\nTests complete, stopping simulation\n")
  
  # Tell simulator to stop/finish
  vpapi.write(__SIMSTOPADDR, 1);

  # Should not get here
  while True :
    vpapi.tick(__LONGTIME)

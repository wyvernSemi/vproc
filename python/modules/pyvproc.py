###################################################################
# Python VProc high level API class
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

# Load ctypes library to get access to C domain
from ctypes import *

class PyVProcClass :

# ---------------------------------------------------------------
# Function to load Python C API module
# ---------------------------------------------------------------

  node = -1
  api  = None

  # Constructor
  def __init__(self, nodeIn, cmodulename = "./PyVProc.so") :
    self.node = nodeIn
    self.api  = self.__loadPyModule(cmodulename)

  # Method to load Python C module
  def __loadPyModule(self, name = "./PyVProc.so") :

    module = CDLL(name)
    module.argtypes = [c_int32]
    module.restype  = [c_int32]

    return module

  # API method to write a word
  def write (self, addr, data, delta = 0) :
    self.api.PyWrite(addr, data, delta, self.node)

  # API method to read a word
  def read (self, addr,  delta = 0) :
    return self.api.PyRead(addr, delta, self.node)
    
  # API method to read a word as unsigned value
  def uread (self, addr,  delta = 0) :
    return c_uint32(self.read(addr, delta)).value

  # API method to tick for specified number of clocks
  def tick (self, ticks) :
    self.api.PyTick(ticks, self.node)
    
  # API method to do a burst write
  def burstWrite(self, addr, data, length) :
    self.api.PyBurstWrite(addr, (c_int * len(data))(*data), length, self.node)
    
  # API method to do a burst read
  def burstRead(self, addr, length) :
    data = []
    cdata = (c_int * length)(0)
    self.api.PyBurstRead(addr, cdata, length, self.node)
    for i in range(length) :
      data.append(c_uint32(cdata[i]).value)
    return data

  # API method to register a vectored interrupt callback
  def regIrq(self, irqCb) :
    cb_ftype = CFUNCTYPE(c_int, c_int)
    cb_wrap  = cb_ftype(irqCb)
    self.api.PyRegIrq(cb_wrap, self.node)
    
  def VPrint(self, printstr) :
    bytestring = printstr.encode('utf-8')
    self.api.PyPrint(c_char_p(bytestring))



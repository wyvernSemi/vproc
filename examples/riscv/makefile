###################################################################
# Makefile for Virtual Processor testcode in Modelsim
#
# Copyright (c) 2005-2024 Simon Southwell.
#
# This file is part of VProc.
#
# VProc is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VProc is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VProc. If not, see <http://www.gnu.org/licenses/>.
#
###################################################################


#------------------------------------------------------
# User overridable definitions

MAX_NUM_VPROC      = 64
USRFLAGS           =
SRCDIR             = ../../code
USRCDIR            = src
TESTDIR            = .
VOBJDIR            = $(TESTDIR)/obj

# User test source code file list
USER_C             = VUserMain0.cpp mem_vproc_api.cpp getopt.c

#------------------------------------------------------
# Settings specific to target simulator

# Get the help message from the simulator, filtered on Questa
SIMTYPE            = $(shell vsim -help | grep -i questa)

# If the SIMTYPE string is not empty, then this is Questa and a 64-bit compile,
# else assume it's ModelSim and do a 32-bit compile.
ifneq ("$(SIMTYPE)", "")
  ARCHFLAG         = -m64
else
  ARCHFLAG         = -m32
endif

# Simulator/Language specific C/C++ compile and link flags
OPTFLAG            = -g
HDLLANGUAGE        =
SIMULATOR          = -DMODELSIM
SIMINCLUDEFLAG     = -I$(MODEL_TECH)/../include -I./include
SIMFLAGSSO         = -L$(MODEL_TECH) -lmtipli -L./lib -lrv32$(LIBOS)$(LIBARCH)
POSTVPROCSOFLAGS   = $(WLIB)

# Optional Memory model definitions
MEM_C              =
MEMMODELDIR        = .

# Common flags for vsim
VPROC_TOP          = test
VLOGFLAGS          = +incdir+../ +define+VPROC_BYTE_ENABLE
VSIMFLAGS          = -pli $(VPROC_PLI) $(VPROC_TOP)

# Set OS specific variables between Linux and Windows (MinGW)
ifeq (${OSTYPE}, Linux)
  WLIB             =
else
  WLIB             = -lWs2_32
  LIBOS            = win
endif

ifeq ($(ARCHFLAG), "-m32")
  LIBARCH          = 32
else
  LIBARCH          = 64
endif

#------------------------------------------------------
# MODEL_TECH path

# Get OS type
OSTYPE:=$(shell uname)

# If run from a place where MODEL_TECH is not defined, construct from path to PLI library
ifeq ("$(MODEL_TECH)", "")
  ifeq ($(OSTYPE), Linux)
    PLILIB         = libmtipli.so
  else
    PLILIB         = mtipli.dll
  endif
  
  VSIMPATH         = $(shell which vsim)
  SIMROOT          = $(shell dirname ${VSIMPATH})/..
  PLILIBPATH       = $(shell find $(SIMROOT) -name "$(PLILIB)")
  MODEL_TECH       = $(shell dirname $(PLILIBPATH))
endif

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: verilog

# Include common build rules
include ../../test/makefile.common

# Let modelsim decide what's changed in the verilog
.PHONY: verilog
verilog: $(VPROC_PLI)
	@if [ ! -d "./work" ]; then                            \
	      vlib work;                                       \
	fi
	@vlog $(VLOGFLAGS) -f test.vc

#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

sim: verilog
	@vsim -c $(VSIMFLAGS)

run: verilog
	@vsim -c $(VSIMFLAGS) -do "run -all" -do "quit"

rungui: verilog
	@if [ -e wave.do ]; then                                         \
	    vsim -gui -gGUI_RUN=1 -do wave.do $(VSIMFLAGS) -do "run -all"; \
	else                                                             \
	    vsim -gui -gGUI_RUN=1 $(VSIMFLAGS);                            \
	fi

gui: rungui

.SILENT:
help:
	@$(info make help          Display this message)
	@$(info make               Build C/C++ and HDL code without running simulation)
	@$(info make sim           Build and run command line interactive (sim not started))
	@$(info make run           Build and run batch simulation)
	@$(info make rungui/gui    Build and run GUI simulation)
	@$(info make clean         clean previous build artefacts)

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

clean:
	@rm -rf $(VPROC_PLI) $(VLIB) $(VOBJDIR) *.wlf transcript
	@if [ -d "./work" ]; then                              \
	    rm -rf work;                                       \
	fi


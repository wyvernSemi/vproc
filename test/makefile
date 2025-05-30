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

# Target HDL language (VERILOG | VHDL)
HDL                = VERILOG

# Simulator/Language specific C/C++ compile and link flags
OPTFLAG            = -g

# User specific C/C++ compile flags
USRFLAGS           =

# User test source code file list
USER_C             = VUserMain0.c                          \
                     VUserMain1.cpp

# Location of user code and test directories
USRCDIR            = usercode
TESTDIR            = .

# Optional memory model (or other additional auxiliary code) definitions
MEM_C              =
MEMMODELDIR        = .

# Build arcgitecture target (default x64. A value of -m32 targets x86)
ARCHFLAG           = -m64

#------------------------------------------------------
# Internal variable definitions

MAX_NUM_VPROC      = 64
SRCDIR             = ../code
VOBJDIR            = $(TESTDIR)/obj

#------------------------------------------------------
# Settings specific to target simulator

SIMULATOR          = -DMODELSIM
SIMINCLUDEFLAG     = -I$(MODEL_TECH)/../include

ifeq ("$(HDL)", "VHDL")
  HDLLANGUAGE      = -DVPROC_VHDL
  HDLCMD           = vcom -quiet -2008 -work work -f files.tcl
  VSIMFLAGS        = $(VPROC_TOP)
else
  SIMFLAGSSO       = -L$(MODEL_TECH) -lmtipli
  HDLCMD           = vlog +define+VPROC_BURST_IF +define+VPROC_BYTE_INTERFACE +incdir+../ -f test.vc
  VSIMFLAGS        = -pli $(VPROC_PLI) $(VPROC_TOP)
endif

# Common logic simulator flags
VPROC_TOP          = test

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
  SIMROOT          = $(shell dirname $(VSIMPATH))/..
  PLILIBPATH       = $(shell find $(SIMROOT) -name "$(PLILIB)")
  MODEL_TECH       = $(shell dirname $(PLILIBPATH))
endif

#------------------------------------------------------
# Include common build rules
#------------------------------------------------------

include makefile.common

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: hdl

# Let the simulator decide what's changed in the HDL
.PHONY: hdl
hdl: $(VPROC_PLI)
	@if [ ! -d "./work" ]; then                            \
	      vlib work;                                       \
	fi
	@$(HDLCMD)


#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

sim: hdl
	@vsim -c $(VSIMFLAGS)

run: hdl
	@vsim -c $(VSIMFLAGS) -do "run -all" -do "quit"

rungui: hdl
	@if [ -e wave.do ]; then                               \
	    vsim -gui -do wave.do $(VSIMFLAGS) -do "run -all"; \
	else                                                   \
	    vsim -gui $(VSIMFLAGS);                            \
	fi

gui: rungui

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


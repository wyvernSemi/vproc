###################################################################
# Makefile for VProc Virtual Processor and mem_model testcode
# in Questa
#
# Copyright (c) 2024 Simon Southwell.
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

# MODEL_TECH environment variable must be set

# User C/C++ overridable flags
PLIVERSION         =
USRFLAGS           =
USER_C             = VUserMain0.c
USRCDIR            = usercode
BUSTYPE            = AVALON
HDL                = VERILOG

# User simulation overridable flags
USRSIMFLAGS        =

VPROCDIR           = ../..
TESTDIR            = $(CURDIR)
VOBJDIR            = $(TESTDIR)/obj
MEMMODELDIR        = $(CURDIR)/../../../mem_model
MEMMODELREPO       = https://github.com/wyvernSemi/mem_model.git

# VProc C source code
VPROC_C            = VSched.c VUser.c

# Memory model C source code
MEM_C              = mem.c mem_model.c

# Generated  PLI C library
VPROC_PLI          = $(TESTDIR)/VProc.so

# Get OS type
OSTYPE:=$(shell uname)

# Set OS specific variables between Linux and Windows (MSYS2/mingw-w64)
ifeq ($(OSTYPE), Linux)
  CFLAGS_SO        = -shared -lpthread -lrt -rdynamic
  CPPSTD           = -std=c++11
else
  CFLAGS_SO        = -shared -Wl,-export-all-symbols
  CPPSTD           =
endif

CFLAGS             = $(USRFLAGS)                           \
                     -I$(MEMMODELDIR)/src                  \
                     -DINCL_VLOG_MEM_MODEL                 \
                     -DMEM_MODEL_DEFAULT_ENDIAN=1          \
                     $(HDLFLAG)

# Simulation configuration

HDLFLAG            =
SIMDEFS            =

ifeq ("$(HDL)", "VHDL")
  ifeq ("$(BUSTYPE)", "AXI")
    FILELIST       = files.tcl
    SIM_TOP        = testaxi
    HDLFLAG        += -DAXI 
  else ifeq ("$(BUSTYPE)", "AHB")
    FILELIST       = files_ahb.tcl
    SIM_TOP        = testahb
    HDLFLAG        += -DAHB
  else ifeq ("$(BUSTYPE)", "APB")
    FILELIST       = files_apb.tcl
    SIM_TOP        = testapb
  else
    FILELIST       = files_av.tcl
    SIM_TOP        = testavm
  endif
  HDLFLAG          += -DVPROC_VHDL
  HDLCMD           = vcom -quiet -2008  $(SIMDEFS) -work work -f $(FILELIST)
  VSIMFLAGS        = -do "set StdArithNoWarnings 1" -do "set NumericStdNoWarnings 1" $(USRSIMFLAGS) $(SIM_TOP)
  VERIUSER         =
else
  ifeq ("$(BUSTYPE)", "AXI")
    FILELIST       = test.vc
    SIM_TOP        = testaxi
    HDLFLAG        += -DAXI
    SIMDEFS        = +define+VPROC_BURST_IF
  else ifeq ("$(BUSTYPE)", "AHB")
    FILELIST       = test_ahb.vc
    SIM_TOP        = testahb
    HDLFLAG        += -DAHB
    SIMDEFS        = +define+VPROC_BURST_IF
  else ifeq ("$(BUSTYPE)", "APB")
    FILELIST       = test_apb.vc
    SIM_TOP        = testapb
  else
    FILELIST       = test_av.vc
    SIM_TOP        = testavm
  endif
  PLIVERSION       = -DVPROC_PLI_VPI
  HDLCMD           = vlog -quiet $(SIMDEFS) +define+MEM_EN_TX_BYTEENABLE +define+VPROC_BYTE_ENABLE \
                     +incdir+../ +incdir+../../ -f $(FILELIST)
  VSIMFLAGS        = -pli $(VPROC_PLI) $(USRSIMFLAGS) $(SIM_TOP)
  VERIUSER         = $(VOBJDIR)/veriuser.o
endif

SPACE              =

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

$(VPROC_PLI):
	@make --no-print-directory             \
          -C $(VPROCDIR)/test              \
          USRFLAGS="$(CFLAGS)"             \
          USRCDIR=$(CURDIR)/$(USRCDIR)     \
          USER_C="$(USER_C)"               \
          MEMMODELDIR="$(MEMMODELDIR)/src" \
          MEM_C="$(MEM_C)"                 \
          PLIVERSION=$(PLIVERSION)         \
          TESTDIR=$(TESTDIR)

$(MEMMODELDIR):
	@git clone $(MEMMODELREPO) $(MEMMODELDIR) --recursive

# Let simulator decide what's changed in the HDL
hdl: $(VPROC_PLI)
	@if [ ! -d "./work" ]; then                            \
	      vlib work;                                       \
	fi
	@$(HDLCMD)

#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

sim: hdl
	@vsim -c -no_autoacc $(VSIMFLAGS)

run: hdl
	@vsim -c -no_autoacc $(VSIMFLAGS) -do "run -all" -do "quit"

rungui: hdl
	@if [ -e wave.do ]; then                                              \
	    vsim -gui -voptargs=+acc -do wave.do $(VSIMFLAGS) -do "run -all"; \
	else                                                                  \
	    vsim -gui -voptargs=+acc $(VSIMFLAGS);                            \
	fi

gui: rungui

help:
	@$(info make help          Display this message)
	@$(info make               Build C/C++ and HDL code without running simulation)
	@$(info make run           Build and run batch simulation)
	@$(info make rungui/gui    Build and run GUI simulation)
	@$(info make clean         clean previous build artefacts)
	@$(info $(SPACE))
	@$(info Command line options:)
	@$(info $(SPACE)  HDL=[VERILOG|VHDL] BUSTYPE=[AVALON|APB|AHB|AXI])
	@$(info $(SPACE))

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

clean:
	@make --no-print-directory -C $(VPROCDIR)/test USER_C="$(USERCODE)" TESTDIR="$(TESTDIR)" clean
	@rm -rf work transcript
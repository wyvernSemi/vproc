###################################################################
# Makefile for Verilator Simulation Control test code
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

# User C/C++ overridable flags
USRFLAGS           =
USER_C             = VUserMain0.cpp
USRCDIR            = usercode
AUX_C              = VerilatorSimCtrl.cpp
AUXDIR             = ../src

# User simulation overridable flags
USRSIMFLAGS        =

VPROCDIR           = ../..
TESTDIR            = $(CURDIR)
VOBJDIR            = $(TESTDIR)/obj

# Generated  PLI C library
VLIB               = $(TESTDIR)/libvproc.a

INCLUDEFLAGS       = -I$(CURDIR)/../src

CFLAGS             = $(USRFLAGS)                           \
                     $(INCLUDEFLAGS)                       \
                     $(HDLFLAG)

# Simulation configuration

HDLFLAG            =
FILELIST           = files.tcl
SIM_TOP            = test
SIMDEFS            = -GDISABLE_SIM_CTRL=0
WORKDIR            = work

# set to -GVCD_DUMP=1 to generate VCD ouput, or blank for none
#VCDFLAG            = --trace-fst -GDISABLE_SIM_CTRL=1
VCDFLAG            = --trace -GDISABLE_SIM_CTRL=1

# Set to --timing for delta cycle support, or blank for no delta-cycle
TIMINGFLAG         = --timing

# C++ version 20 required for Verilator
CPPSTD             = -std=c++20

SIMCFLAGS          = $(CPPSTD) -DVL_TIME_CONTEXT -Wno-attributes

# Get OS type
OSTYPE             := $(shell uname)

ifeq ($(OSTYPE), Linux)
  SIMFLAGSLD       = -Wl,-E -lrt -rdynamic
  SIMEXE           = $(WORKDIR)/V$(SIM_TOP)
else
  SIMFLAGSLD       = -Wl,-export-all-symbols
  SIMEXE             = $(WORKDIR)/V$(SIM_TOP).exe
endif

VERIMAIN           = ../src/versim.cpp

SIMFLAGS           = --cc -sv -exe $(VERIMAIN)              \
                     $(FINISHFLAG)                          \
                     $(TIMINGFLAG)                          \
                     $(VCDFLAG) $(SIMDEFS)                  \
                     $(USRSIMFLAGS)                         \
                     -Wno-INITIALDLY                        \
                     -Mdir $(WORKDIR) -Wno-WIDTH            \
                     -I.. -I$(VPROCDIR)                     \
                     --top $(SIM_TOP)                       \
                     -MAKEFLAGS "--quiet"                   \
                     -CFLAGS "$(SIMCFLAGS)"                 \
                     -LDFLAGS "$(SIMFLAGSLD)                \
                     $(VSCCODE)                             \
                     -Wl,-whole-archive -L../ -lvproc -Wl,-no-whole-archive -ldl"



#WAVEFILE           = waves.fst
WAVEFILE           = waves.vcd
WAVESAVEFILE       = wave.gtkw

SPACE              =

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: $(SIMEXE)

$(VLIB):
	@make --no-print-directory         \
          -C $(VPROCDIR)/test              \
          -f makefile.verilator            \
          USRFLAGS="$(CFLAGS)"             \
          USRCDIR=$(CURDIR)/$(USRCDIR)     \
          USER_C="$(USER_C)"               \
          AUXDIR=$(CURDIR)/$(AUXDIR)       \
          AUX_C="$(AUX_C)"                 \
          TESTDIR=$(TESTDIR)               \
          $(VLIB)

# Let simulator decide what's changed in the HDL
hdl: $(VLIB)
	@verilator -F $(FILELIST) $(SIMFLAGS)


$(SIMEXE): hdl
	@make --quiet --no-print-directory -Cwork -f V$(SIM_TOP).mk V$(SIM_TOP)

#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

run: $(SIMEXE)
	@$(SIMEXE)

rungui: $(SIMEXE)
	@$(SIMEXE)
	@if [ -e $(WAVESAVEFILE) ]; then            \
	    gtkwave -a $(WAVESAVEFILE) $(WAVEFILE); \
	else                                        \
	    gtkwave $(WAVEFILE);                    \
	fi

gui: rungui

help:
	@$(info make help          Display this message)
	@$(info make               Build C/C++ and HDL code without running simulation)
	@$(info make run           Build and run batch simulation)
	@$(info make rungui/gui    Build and run GUI simulation)
	@$(info make clean         clean previous build artefacts)
	@$(info $(SPACE))

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

clean:
	@make --no-print-directory         \
          -C $(VPROCDIR)/test              \
          -f makefile.verilator            \
          TESTDIR=$(TESTDIR)               \
          clean
	@rm -rf $(VLIB) $(VOBJDIR) waves.fst $(WORKDIR) $(WAVEFILE)
###################################################################
# Makefile for Python Virtual Processor testcode in Modelsim
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

# Flags that can be overridden by the user or external call
USRFLAGS           =
SRCDIR             = ../../code
PYSRCDIR           = ../src
TESTDIR            = .
ARCHFLAG           = -m64
OPTFLAGS           = -g
HDL                = VERILOG

# Define the maximum number of supported VProcs in the compile pli library
MAX_NUM_VPROC      = 16

# Object directory for intermediate compile files
VOBJDIR            = $(TESTDIR)/obj

# Name of the Python executable
PYEXENAME          = python3

# If PYTHONHOME environment variable not set give an error
ifeq ("$(PYTHONHOME)", "")
  $(error "PYTHONHOME environment variable not set.")
endif

# Extract the python version number in the format python.<major>.<minor#1>
# which is the name of the python libray to link.
SHELLCMD           = $(PYEXENAME) -V | awk -F"[. ]" '{print "python" $$2 "." $$3}'
PYVER              = $(shell $(SHELLCMD))

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

# VPROC C source code
VPROC_C            = VSched.c \
                     VUser.c

# Python interface C code compiled into PyVProc.so
PYTHON_C           = PythonVProc.c

# Python user main code compiled into VProc.so
USER_C             = VUserMainPy.c

# Construct list of objects for VProc.so
VOBJS              = $(addprefix $(VOBJDIR)/, $(USER_C:%.c=%.o) $(VPROC_C:%.c=%.o))

VLOGFLAGS          = +define+VPROC_BURST_IF +incdir+../..

# Generated  PLI C library
VPROC_PLI          = $(TESTDIR)/VProc.so
VLIB               = $(TESTDIR)/libvproc.a

# Python interface foreign module shared object
PYVRPOC_PLI        = $(TESTDIR)/PyVProc.so

ifeq ("$(HDL)", "VHDL")
  HDLLANGUAGE      = -DVPROC_VHDL
  HDLCMD           = vcom -quiet -2008 -work work -f files.tcl
  VSIMFLAGS        = $(VPROC_TOP)
else
  HDLLANGUAGE      =
  HDLCMD           = vlog $(VLOGFLAGS) -f test.vc
  VSIMFLAGS        = -pli $(VPROC_PLI) $(VPROC_TOP)
endif

VPROC_TOP          = test

# Set OS specific variables between Linux and Windows (MinGW)
ifeq ($(OSTYPE), Linux)
  CFLAGS_SO        = -shared -lpthread -lrt -rdynamic
else
  CFLAGS_SO        = -shared -Wl,-export-all-symbols
endif

CC                 = gcc
C++                = g++
CPPSTD             = -std=c++11
CFLAGS             = -fPIC                                 \
                     $(ARCHFLAG)                           \
                     $(OPTFLAGS)                           \
                     -D_GNU_SOURCE                         \
                     $(USRFLAGS)                           \
                     -I$(SRCDIR)                           \
                     -I$(PYSRCDIR)                         \
                     -I$(PYTHONHOME)/include/$(PYVER)      \
                     -I$(MODEL_TECH)/../include            \
                     -DVP_MAX_NODES=$(MAX_NUM_VPROC)       \
                     -DMODELSIM                            \
                     $(HDLLANGUAGE)                        \
                     -D_REENTRANT

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: $(VPROC_PLI) hdl

$(VOBJDIR)/%.o: $(SRCDIR)/%.c $(SRCDIR)/*.h
	@$(CC) -c $(CFLAGS) $< -o $@

$(VOBJDIR)/%.o: $(SRCDIR)/%.cpp $(SRCDIR)/*.h
	@$(C++)-c $(CFLAGS) $< -o $@

$(VOBJDIR)/%.o: $(PYSRCDIR)/%.c
	@$(CC) -Wno-write-strings -c $(CFLAGS) $< -o $@

$(VLIB) : $(VOBJS) $(VOBJDIR)
	@ar cr $(VLIB) $(VOBJS)

$(VOBJS): | $(VOBJDIR)

$(VOBJDIR):
	@mkdir $(VOBJDIR)

$(VPROC_PLI): $(PYVRPOC_PLI) $(VLIB)
	@$(C++) $(CPPSTD)                                      \
           $(CFLAGS_SO)                                    \
           -Wl,-whole-archive                              \
           $(CFLAGS)                                       \
           -lpthread                                       \
           -L$(MODEL_TECH)                                 \
           -lmtipli                                        \
           -L$(TESTDIR) -lvproc -l:PyVProc.so              \
           -Wl,-no-whole-archive                           \
           -o $@

$(PYVRPOC_PLI): $(PYSRCDIR)/$(PYTHON_C)
	@$(CC) -fPIC -shared -DNO_PLI_INCLUDE                  \
           $^                                              \
           -I../../code -L../../                           \
           $(ARCHFLAG)                                     \
           -I$(PYTHONHOME)/include/$(PYVER)                \
           -L$(PYTHONHOME)/lib -l$(PYVER)                  \
           -ldl                                            \
           -o $@

# Let simulator decide what's changed in the HDL
.PHONY: hdl
hdl: $(VPROC_PLI)
	@if [ ! -d "./work" ]; then                            \
	    vlib work;                                         \
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
	@rm -rf $(VPROC_PLI) $(VLIB) $(VOBJDIR) $(PYVRPOC_PLI) *.wlf wlf* work *vstf transcript


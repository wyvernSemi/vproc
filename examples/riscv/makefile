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

# Define the maximum number of supported VProcs in the compile pli library
MAX_NUM_VPROC      = 64

SRCDIR             = ../../code
USRCDIR            = src
TESTDIR            = .
VOBJDIR            = ${TESTDIR}/obj
ARCHFLAG           = -m32

# Get OS type
OSTYPE:=$(shell uname)

# If run from a place where MODEL_TECH is not defined, construct from path to PLI library
ifeq ("${MODEL_TECH}", "")
  ifeq (${OSTYPE}, Linux)
    PLILIB         = libmtipli.so
  else
    PLILIB         = mtipli.dll
  endif
  
  VSIMPATH         = $(shell which vsim)
  SIMROOT          = $(shell dirname ${VSIMPATH})/..
  PLILIBPATH       = $(shell find ${SIMROOT} -name "${PLILIB}")
  MODEL_TECH       = $(shell dirname ${PLILIBPATH})
endif

# VPROC C source code
VPROC_C            = VSched.c \
                     VUser.c

# Test user code
USER_C             = VUserMain0.cpp mem_vproc_api.cpp getopt.c

USER_CPP_BASE      = $(notdir $(filter %cpp, ${USER_C}))
USER_C_BASE        = $(notdir $(filter %c, ${USER_C}))

VOBJS              = ${addprefix ${VOBJDIR}/, ${USER_C_BASE:%.c=%.o} ${USER_CPP_BASE:%.cpp=%.o} \
                     ${VPROC_C:%.c=%.o}}

USRFLAGS           =
PLIFLAG            = -DVPROC_PLI_VPI
VLOGFLAGS          = +incdir+../

# Generated  PLI C library
VPROC_PLI          = ${TESTDIR}/VProc.so
VLIB               = ${TESTDIR}/libvproc.a

VPROC_TOP          = test

# Set OS specific variables between Linux and Windows (MinGW)
ifeq (${OSTYPE}, Linux)
  CFLAGS_SO        = -shared -lpthread -lrt -rdynamic
  CPPSTD           = -std=c++11
  WLIB             =
else
  CFLAGS_SO        = -shared -Wl,-export-all-symbols
  CPPSTD           =
  WLIB             = -lWs2_32
  LIBOS            = win
endif

ifeq (${ARCHFLAG}, "-m32")
  LIBARCH          = 32
else
  LIBARCH          = 64
endif

RV32LIB            = rv32${LIBOS}${LIBARCH}
RV32INCDIR         = ./include
RV32LIBDIR         = ./lib

CC                 = gcc
C++                = g++
CFLAGS             = -fPIC                                 \
                     ${ARCHFLAG}                           \
                     ${PLIFLAG}                            \
                     -g                                    \
                     -D_GNU_SOURCE                         \
                     ${USRFLAGS}                           \
                     -I${SRCDIR}                           \
                     -I${USRCDIR}                          \
                     -I${RV32INCDIR}                       \
                     -I${MODEL_TECH}/../include            \
                     -DVP_MAX_NODES=${MAX_NUM_VPROC}       \
                     -DMODELSIM                            \
                     -D_REENTRANT

# Common flags for vsim
VSIMFLAGS          = -pli ${VPROC_PLI} ${VPROC_TOP}

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: ${VPROC_PLI} verilog

${VOBJDIR}/%.o: ${SRCDIR}/%.c ${SRCDIR}/*.h
	@${CC} -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${SRCDIR}/%.cpp ${SRCDIR}/*.h
	@${C++}-c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${USRCDIR}/%.c
	@${CC} -Wno-write-strings -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${USRCDIR}/%.cpp
	@${C++} ${CPPSTD} -Wno-write-strings -c ${CFLAGS} $< -o $@

${VLIB} : ${VOBJS} ${VOBJDIR}
	@ar cr ${VLIB} ${VOBJS}

${VOBJS}: | ${VOBJDIR}

${VOBJDIR}:
	@mkdir ${VOBJDIR}

${VPROC_PLI}: ${VLIB} ${VOBJDIR}/veriuser.o
	@${C++} ${CPPSTD}                                      \
           ${CFLAGS_SO}                                    \
           ${CFLAGS}                                       \
           -Wl,-whole-archive                              \
           ${VOBJDIR}/veriuser.o                           \
           -L${TESTDIR} -lvproc                            \
           -L${RV32LIBDIR} -l${RV32LIB}                    \
           -Wl,-no-whole-archive                           \
           -lpthread                                       \
           ${WLIB}                                         \
           -L${MODEL_TECH} -lmtipli                        \
           -o $@

# Let modelsim decide what's changed in the verilog
.PHONY: verilog

verilog: ${VPROC_PLI}
	@if [ ! -d "./work" ]; then                            \
	      vlib work;                                       \
	fi
	@vlog ${VLOGFLAGS} -f test.vc

#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

sim: verilog
	@vsim -c ${VSIMFLAGS}

run: verilog
	@vsim -c ${VSIMFLAGS} -do "run -all" -do "quit"

rungui: verilog
	@if [ -e wave.do ]; then                                         \
	    vsim -gui -gGUI_RUN -do wave.do ${VSIMFLAGS} -do "run -all"; \
	else                                                             \
	    vsim -gui -gGUI_RUN ${VSIMFLAGS};                            \
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
	@rm -rf ${VPROC_PLI} ${VLIB} ${VOBJDIR} *.wlf transcript
	@if [ -d "./work" ]; then                              \
	    rm -rf work;                                       \
	fi


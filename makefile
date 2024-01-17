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

SRCDIR             = code
USRCDIR            = usercode
TESTDIR            = .
VOBJDIR            = ${TESTDIR}/obj
MEMMODELDIR        = .

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

# Memory model C code
MEM_C              =

# Test user code
USER_C             = VUserMain0.c VUserMain1.cpp

USER_CPP_BASE      = $(notdir $(filter %cpp, ${USER_C}))
USER_C_BASE        = $(notdir $(filter %c, ${USER_C}))
MEM_CPP_BASE       = $(notdir $(filter %cpp, ${MEM_C}))
MEM_C_BASE         = $(notdir $(filter %c, ${MEM_C}))

VOBJS              = ${addprefix ${VOBJDIR}/, ${USER_C_BASE:%.c=%.o} ${USER_CPP_BASE:%.cpp=%.o} \
                     ${VPROC_C:%.c=%.o} ${MEM_C_BASE:%.c=%.o} ${MEM_CPP_BASE:%.cpp=%.o}}

USRFLAGS           =
PLIFLAG            = -DVPROC_PLI_VPI
VLOGFLAGS          = +define+VPROC_BURST_IF

# Generated  PLI C library
VPROC_PLI          = ${TESTDIR}/VProc.so
VLIB               = ${TESTDIR}/libvproc.a

VPROC_TOP          = test

# Set OS specific variables between Linux and Windows (MinGW)
ifeq (${OSTYPE}, Linux)
  CFLAGS_SO        = -shared -lpthread -lrt -rdynamic
  CPPSTD           = -std=c++11
  MODELSIMBINDIR   = linuxaloem
else
  CFLAGS_SO        = -shared -Wl,-export-all-symbols
  CPPSTD           =
  MODELSIMBINDIR   = win32aloem
endif

CC                 = gcc
C++                = g++
ARCHFLAG           = -m32
CFLAGS             = -fPIC                                 \
                     ${ARCHFLAG}                           \
                     ${PLIFLAG}                            \
                     -g                                    \
                     -D_GNU_SOURCE                         \
                     ${USRFLAGS}                           \
                     -I${SRCDIR}                           \
                     -I${USRCDIR}                          \
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

${VOBJDIR}/%.o: ${MEMMODELDIR}/%.c ${MEMMODELDIR}/*.h
	@${CC} -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${MEMMODELDIR}/%.cpp ${MEMMODELDIR}/*.h
	@${C++} -c ${CFLAGS} $< -o $@

${VLIB} : ${VOBJS} ${VOBJDIR}
	@ar cr ${VLIB} ${VOBJS}

${VOBJS}: | ${VOBJDIR}

${VOBJDIR}:
	@mkdir ${VOBJDIR}

${VPROC_PLI}: ${VLIB} ${VOBJDIR}/veriuser.o
	@${C++} ${CPPSTD}                                      \
           ${CFLAGS_SO}                                    \
           -Wl,-whole-archive                              \
           ${CFLAGS}                                       \
           ${VOBJDIR}/veriuser.o                           \
           -lpthread                                       \
           -L${MODEL_TECH}                                 \
           -lmtipli                                        \
           -L${TESTDIR} -lvproc                            \
           -Wl,-no-whole-archive                           \
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
	@if [ -e wave.do ]; then                               \
	    vsim -gui -do wave.do ${VSIMFLAGS} -do "run -all"; \
	else                                                   \
	    vsim -gui ${VSIMFLAGS};                            \
	fi

gui: rungui

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

clean:
	@rm -rf ${VPROC_PLI} ${VLIB} ${VOBJDIR} *.wlf transcript
	@if [ -d "./work" ]; then                              \
	    vdel -all;                                         \
	fi


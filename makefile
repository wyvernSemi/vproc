###################################################################
# Makefile for Virtual Processor testcode in Modelsim
#
# Copyright (c) 2005-2023 Simon Southwell.
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

# $MODELSIM and MODEL_TECH environment variables must be set

# Define the maximum number of supported VProcs in the compile pli library
MAX_NUM_VPROC   = 64

SRCDIR          = code
USRCDIR         = usercode
TESTDIR         = .
VOBJDIR         = ${TESTDIR}/obj
MEMMODELDIR     = .

SIM             = RivieraPro

# VPROC C source code
VPROC_C         = VSched.c VUser.c veriuser.c

# Memory model C code
MEM_C           =

# Test user code
USER_C          = VUserMain0.c VUserMain1.c

USER_CPP_BASE   = $(notdir $(filter %cpp, ${USER_C}))
USER_C_BASE     = $(notdir $(filter %c, ${USER_C}))
MEM_CPP_BASE    = $(notdir $(filter %cpp, ${MEM_C}))
MEM_C_BASE      = $(notdir $(filter %c, ${MEM_C}))

VOBJS           = ${addprefix ${VOBJDIR}/, ${USER_C_BASE:%.c=%.o} ${USER_CPP_BASE:%.cpp=%.o} \
                  ${VPROC_C:%.c=%.o} ${MEM_C_BASE:%.c=%.o} ${MEM_CPP_BASE:%.cpp=%.o}}

USRFLAGS        =

ifeq ("${SIM}", "ActiveHDL")
  ALDECDIR         =  /c/Aldec/Active-HDL-13-x64
  ARCHFLAGS        = -m64 -I${ALDECDIR}/pli/Include -L${ALDECDIR}/pli/Lib -l:aldecpli.lib
else
  ALDECDIR         =  /c/Aldec/Riviera-PRO-2022.10-x64
  ARCHFLAGS        = -m64 -I${ALDECDIR}/interfaces/include -L${ALDECDIR}/interfaces/lib -l:aldecpli.lib
endif

# Generated  PLI C library
VPROC_PLI       = ${TESTDIR}/VProc.so
VLIB            = ${TESTDIR}/libvproc.a

VPROC_TOP       = test

# Get OS type
OSTYPE:=$(shell uname)

# Set OS specific variables between Linux and Windows (MinGW)
ifeq (${OSTYPE}, Linux)
  CFLAGS_SO        = -shared -lpthread -lrt -rdynamic
  WLIB             =
else
  CFLAGS_SO        = -shared -Wl,-export-all-symbols
  WLIB             = -lWs2_32
endif

CC              = gcc
C++             = g++
CPPSTD          = -std=c++11
CFLAGS          = ${ARCHFLAGS}                          \
                  -g                                    \
                  ${USRFLAGS}                           \
                  -I${SRCDIR}                           \
                  -I${USRCDIR}                          \
                  -DVP_MAX_NODES=${MAX_NUM_VPROC}

# Command flags for vsim
VLOGFLAGS = -msg 0
VSIMFLAGS = +access +r -pli ${VPROC_PLI} ${VPROC_TOP}

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: ${VPROC_PLI}

${VOBJDIR}/%.o: ${SRCDIR}/%.c
	@${CC} -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${USRCDIR}/%.c
	@${CC} -Wno-write-strings -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${USRCDIR}/%.cpp
	@${C++} ${CPPSTD} -Wno-write-strings -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${MEMMODELDIR}/%.c ${MEMMODELDIR}/*.h
	@${CC} -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${MEMMODELDIR}/%.cpp ${MEMMODELDIR}/*.h
	@${C++} ${CPPSTD} -c ${CFLAGS} $< -o $@

${VLIB} : ${VOBJS} ${VOBJDIR}
	@ar cr ${VLIB} ${VOBJS}

${VOBJS}: | ${VOBJDIR}

${VOBJDIR}:
	@mkdir ${VOBJDIR}

${VPROC_PLI}: ${VLIB} ${VOBJDIR}/veriuser.o
	@${C++} ${CPPSTD}                                  \
           ${CFLAGS_SO}                                \
           -Wl,-whole-archive                          \
           ${CFLAGS}                                   \
           -lpthread                                   \
           -L${TESTDIR} -lvproc                        \
           -Wl,-no-whole-archive                       \
           ${WLIB}                                     \
           -o $@

# Let the simulator decide what's changed in the verilog
.PHONY: verilog

verilog: ${VPROC_PLI}
	@if [ ! -d "./work" ]; then                        \
	      vlib work;                                   \
	fi
	@vlog ${VLOGFLAGS} -f test.vc

#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

run: verilog
	@vsim -c ${VSIMFLAGS}

rungui: verilog
	@if [ -e wave.do ]; then                           \
	    vsim -gui -do wave.do ${VSIMFLAGS};            \
	else                                               \
	    vsim -gui ${VSIMFLAGS};                        \
	fi

gui: rungui

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

clean:
	@rm -rf ${VPROC_PLI} ${VLIB} ${VOBJS} ${VOBJDIR}/* work *.wlf vproc.rdsn vproc.rwsp* dataset.asdb compile library.cfg transcript



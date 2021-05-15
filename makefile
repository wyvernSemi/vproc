###################################################################
# Makefile for Virtual Processor testcode in Modelsim
#
# Copyright (c) 2005-2010 Simon Southwell.
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
# $Id: makefile,v 1.8 2021/05/15 07:45:17 simon Exp $
# $Source: /home/simon/CVS/src/HDL/VProc/makefile,v $
#
###################################################################

# $MODELSIM and MODEL_TECH environment variables must be set

# Define the maximum number of supported VProcs in the compile pli library
MAX_NUM_VPROC   = 64

SRCDIR          = code
USRCDIR         = usercode
VOBJDIR         = obj

# VPROC C source code
VPROC_C         = VSched.c                             \
                  VUser.c

# Test user code
USER_C          = VUserMain0.c VUserMain1.c

VOBJS           = ${addprefix ${VOBJDIR}/, ${VPROC_C:%.c=%.o}}

USRFLAGS        = 

# Generated  PLI C library
VPROC_PLI       = VProc.so
VLIB            = libvproc.a

VPROC_TOP       = test

# Get OS type
OSTYPE:=$(shell uname)

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

CC              = gcc
C++             = g++
CFLAGS          = -fPIC                                 \
                  -m32                                  \
                  -g                                    \
                  ${USRFLAGS}                           \
                  -I${SRCDIR}                           \
                  -I${USRCDIR}                          \
                  -I${MODEL_TECH}/../include            \
                  -DVP_MAX_NODES=${MAX_NUM_VPROC}       \
                  -DMODELSIM                            \
                  -D_REENTRANT

# Comman flags for vsim
VSIMFLAGS = -pli ${VPROC_PLI} ${VPROC_TOP}

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: ${VPROC_PLI} verilog

${VOBJDIR}/%.o: ${SRCDIR}/%.c
	@${CC} -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${USRCDIR}/%.c
	@${CC} -Wno-write-strings -c ${CFLAGS} $< -o $@

${VOBJDIR}/%.o: ${USRCDIR}/%.cpp
	@${C++} ${CPPSTD} -Wno-write-strings -c ${CFLAGS} $< -o $@

${VLIB} : ${VOBJS} ${VOBJDIR}
	@ar cr ${VLIB} ${VOBJS}

${VOBJS}: | ${VOBJDIR}

${VOBJDIR}:
	@mkdir ${VOBJDIR}

${VPROC_PLI}: ${VLIB} ${VOBJDIR}/veriuser.o ${USER_C:%.c=${VOBJDIR}/%.o}
	@${C++} ${CPPSTD}                                  \
           ${CFLAGS_SO}                                \
           ${CFLAGS}                                   \
           -Wl,-whole-archive                          \
           ${USER_C:%.c=${VOBJDIR}/%.o}                \
           ${VOBJDIR}/veriuser.o                       \
           -lpthread                                   \
           -L${MODEL_TECH}                             \
           -lmtipli                                    \
           -L. -lvproc                                 \
           -Wl,-no-whole-archive                       \
           -o $@

# Let modelsim decide what's changed in the verilog
.PHONY: verilog

verilog: ${VPROC_PLI}
	@if [ ! -d "./work" ]; then                        \
	      vlib work;                                   \
	fi
	@vlog -f test.vc

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
	@rm -rf ${VPROC_PLI} ${VLIB} ${VOBJS} ${VOBJDIR}/* *.wlf
	@if [ -d "./work" ]; then                           \
	    vdel -all;                                      \
	fi


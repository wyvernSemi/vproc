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
# $Id: makefile,v 1.2 2016-09-29 08:42:49 simon Exp $
# $Source: /home/simon/CVS/src/HDL/VProcThread/makefile,v $
#
###################################################################

# $MODELSIM and $MODEL_TECH environment variables must be set

SRCDIR          = ${PWD}/code
USRCDIR         = ${PWD}/usercode

# VPROC C source code
VPROC_C         = ${SRCDIR}/VSched.c                             \
                  ${SRCDIR}/VUser.c                              \
                  ${SRCDIR}/veriuser.c

# Test user code
USER_C          = VUserMain0.c VUserMain1.c

# Generated  PLI C library
VPROC_PLI       = VProc.so

VPROC_TOP       = test

# Get OS type
OSTYPE:=$(shell uname -o)

CC              = gcc
CFLAGS          = -m32 -fPIC -shared -lpthread -lrt -rdynamic   \
                  -I${SRCDIR}                                   \
                  -I${USRCDIR}                                  \
                  -I${MODELSIM}/include                         \
                  -DMODELSIM                                    \
                  -D_REENTRANT

# Comman flags for vsim
VSIMFLAGS = -pli ${VPROC_PLI} ${VPROC_TOP}

# All C source code for compilation
ALL_C           = ${USER_C:%.c=${USRCDIR}/%.c} ${VPROC_C}

all: ${VPROC_PLI} verilog

${VPROC_PLI}: ${ALL_C}
	@${CC} ${CFLAGS} ${ALL_C} ${LIBS} -o $@ 

# Let modelsim decide what's changed in the verilog
.PHONY: verilog

verilog: ${VPROC_PLI}
	@if [ ! -d "./work" ]; then                              \
          vlib work;                                             \
        fi
	@vlog -f test.vc
        
run: verilog
	@vsim -c ${VSIMFLAGS}

rungui: verilog
	@if [ -e wave.do ]; then                                 \
          vsim -gui -do wave.do ${VSIMFLAGS};                    \
        else                                                     \
          vsim -gui ${VSIMFLAGS};                                \
        fi

gui: rungui

clean:
	@rm -rf ${VPROC_PLI} *.wlf
	@if [ -d "./work" ]; then                                \
          vdel -all;                                             \
        fi


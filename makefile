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
# $Id: makefile,v 1.5 2016/10/03 13:19:09 simon Exp $
# $Source: /home/simon/CVS/src/HDL/VProc/makefile,v $
#
###################################################################

# $MODELSIM and $MODEL_TECH environment variables must be set

SRCDIR          = code
USRCDIR         = usercode
VOBJDIR         = obj

# VPROC C source code
VPROC_C         = VSched.c                             \
                  VUser.c

# Test user code
USER_C          = VUserMain0.c VUserMain1.c

VOBJS           = ${addprefix ${VOBJDIR}/, ${VPROC_C:%.c=%.o}}

# Generated  PLI C library
VPROC_PLI       = VProc.so
VLIB            = libvproc.a

VPROC_TOP       = test

# Get OS type
OSTYPE:=$(shell uname -o)

CC              = gcc
CFLAGS          = -m32 -fPIC                            \
                  -I${SRCDIR}                           \
                  -I${USRCDIR}                          \
                  -I${MODELSIM}/include                 \
                  -DMODELSIM                            \
                  -D_REENTRANT
CFLAGS_SO       = -shared -lpthread -lrt -rdynamic

# Comman flags for vsim
VSIMFLAGS = -pli ${VPROC_PLI} ${VPROC_TOP}

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: ${VPROC_PLI} verilog

${VOBJDIR}/%.o: ${SRCDIR}/%.c
	@${CC} -c ${CFLAGS} $< -o $@

${VLIB} : ${VOBJS} ${VOBJDIR}
	@ar cr ${VLIB} ${VOBJS}

${VOBJS}: | ${VOBJDIR}

${VOBJDIR}:
	@mkdir ${VOBJDIR}

${VPROC_PLI}: ${VLIB} ${VOBJDIR}/veriuser.o ${USER_C:%.c=${USRCDIR}/%.c}
	@${CC} ${CFLAGS_SO}                               \
	       ${CFLAGS}                                  \
	       ${USER_C:%.c=${USRCDIR}/%.c}               \
	       ${VOBJDIR}/veriuser.o                      \
               -Wl,-whole-archive                         \
	       -L. -lvproc                                \
	       -Wl,-no-whole-archive                      \
	       -o $@

# Let modelsim decide what's changed in the verilog
.PHONY: verilog

verilog: ${VPROC_PLI}
	@if [ ! -d "./work" ]; then                        \
          vlib work;                                       \
        fi
	@vlog -f test.vc
        
#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

run: verilog
	@vsim -c ${VSIMFLAGS}

rungui: verilog
	@if [ -e wave.do ]; then                           \
          vsim -gui -do wave.do ${VSIMFLAGS};              \
        else                                               \
          vsim -gui ${VSIMFLAGS};                          \
        fi

gui: rungui

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

clean:
	@rm -rf ${VPROC_PLI} ${VLIB} ${VOBJS} ${VOBJDIR}/veriuser.c *.wlf
	@if [ -d "./work" ]; then                           \
          vdel -all;                                        \
        fi


###################################################################
# Makefile for Virtual Processor testcode in NC Sim
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
# $Id: makefile.nc,v 1.1 2010-06-18 15:33:44 simon Exp $
# $Source: /home/simon/CVS/src/HDL/VProcThread/makefile.nc,v $
#
###################################################################

include		./MakeNc.def

USER_C          = VUserMain0.c VUserMain1.c

VPROCDIR        = ./code
USRCDIR         = ./usercode

VPROC_C         = ${VPROCDIR}/VSched.c           		\
                  ${VPROCDIR}/VUser.c

# Test specific C flags ('include' paths and any required -D definitions)
TESTCFLAGS      = -I${VPROCDIR}                        		\
                  -I${USRCDIR} -D_REENTRANT

ALL_C           = ${USER_C:%.c=${USRCDIR}/%.c} ${VPROC_C} 	\
                  ${VPROCDIR}/veriuser.c

# Define all the include code for dependency checking
ALL_H		= ${VPROCDIR}/VSched_pli.h ${VPROCDIR}/VUser.h 

VCFILES		= $(shell absvc -F test.vc)

all: ncfile.so
	ncverilog extradefs.v ${VCFILES} ${NCFLAGS} +loadpli1=ncfile:bootstrap

ncfile.so: ${ALL_C} ${ALL_H}
	gcc ${TESTCFLAGS} ${CFLAGS} ${ALL_C} -o ncfile.so

clean:
	@rm -rf INCA_libs/* *.log ncfile.so

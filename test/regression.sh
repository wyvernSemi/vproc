#!/usr/bin/bash
###################################################################
# Regression test script for Virtual Processor
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

REGRESSDIR=$PWD

LOGFILE="$REGRESSDIR/regression.log"
rm -rf $LOGFILE

OSTYPE=`uname`

MKFILEBASE="makefile.questa makefile.ica makefile.nvc makefile.ghdl"
FILTERSTR="EIO|, Warnings:|Note"

if [ "$OSTYPE" != "Linux" ]
then
  MKFILEBASE="$MKFILEBASE makefile.vivado"
fi

clear
date | tee -a $LOGFILE
echo "" | tee -a $LOGFILE

#
# Main C/C+ regression tests
#
echo "============ C/C++ regression tests ============" $'\n' | tee -a $LOGFILE
for usrcode in usercode usercodeIrq
do
  for mkfile in $MKFILEBASE "makefile.vhd ARCHFLAG=-m64" makefile.verilator
  do
   echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
   make -f $mkfile clean
   make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal"  | egrep -v "$FILTERSTR" | tee -a $LOGFILE
   make -f $mkfile clean
   echo "" | tee -a $LOGFILE
  done
done

#
# Special Verilator delta-cycle test
#
echo "============ special verilator test ============" $'\n' | tee -a $LOGFILE

echo "Running makefile.verilator with usercodeDelta ..." | tee -a $LOGFILE
make -f makefile.verilator                              \
        USRCDIR=usercodeDelta                           \
        USER_C=VUserMain0.cpp                           \
        FILELIST=files2.verilator                       \
        BURSTDEF= FINISHFLAG=                           \
        run 2>&1 | egrep -i "error|fatal" | tee -a $LOGFILE
echo "" | tee -a $LOGFILE

#
# Python regression tests
#
# Python tests
cd ../python/test

echo "=========== python regression tests ============" $'\n' | tee -a $LOGFILE
for usrcode in usercode
do
  export PYTHONPATH=$usrcode
  for mkfile in $MKFILEBASE "makefile.vhd ARCHFLAG=-m64"
  do
   echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
   make -f $mkfile clean
   make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "$FILTERSTR" | tee -a $LOGFILE
   make -f $mkfile clean
   echo "" | tee -a $LOGFILE
  done
done

#
# PCIe regression tests (if repository checked out)
#
cd $REGRESSDIR

if [ -d ../../pcievhost/verilog/test ]
then
  cd ../../pcievhost/verilog/test

  echo "============ PCIe regression tests =============" $'\n' | tee -a $LOGFILE
  for usrcode in usercode
  do
    for mkfile in makefile.questa makefile.ica
    do
     echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean
     make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "${FILTERSTR}|PCIED" | tee -a $LOGFILE
     make -f $mkfile clean
     echo "" | tee -a $LOGFILE
    done
  done
fi

#
# usbModel regression tests  (if repository checked out)
#
cd $REGRESSDIR

if [ -d ../../usbModel/model/verilog/test ]
then
  cd ../../usbModel/model/verilog/test

  echo "========== usbModel regression tests ===========" $'\n' | tee -a $LOGFILE
  for usrcode in usercode
  do
    for mkfile in makefile.questa makefile.ica
    do
     echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean
     make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "$FILTERSTR" | tee -a $LOGFILE
     make -f $mkfile clean
     echo "" | tee -a $LOGFILE
    done
  done
fi

#
# tcpIp regression tests (if repository checked out)
#

cd $REGRESSDIR

if [ -d ../../tcpIpPg/test ]
then

  cd ../../tcpIpPg/test

  echo "========== tcpIpPg regression tests ============" $'\n' | tee -a $LOGFILE
  for usrcode in src
  do
    for mkfile in makefile.questa makefile.ica
    do
     echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean 2>&1 > /dev/null
     make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "$FILTERSTR" | tee -a $LOGFILE
     make -f $mkfile clean 2>&1 > /dev/null
     echo "" | tee -a $LOGFILE
    done
  done
fi

cd $REGRESSDIR

date | tee -a $LOGFILE
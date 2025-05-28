#!/usr/bin/bash
###################################################################
# Regression test shell script for the VProc virtual processor
#
# Copyright (c) 2024-2025 Simon Southwell.
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

MKFILEBASE="makefile makefile.ica makefile.nvc makefile.ghdl"
FILTERSTR="EIO|, Warnings:|Note|Finished with no"

# Vivado not installed on Linux in local setup. Add makefile.vivado
# unconditionally if it is installed.
if [ "$OSTYPE" != "Linux" ]
then
  MAKEFILEXSIM=makefile.vivado
  MAKEFILEVER=
else
  MAKEFILEVER=makefile.verilator
fi

MKFILEBASE="$MKFILEBASE $MAKEFILEXSIM"

clear
date | tee -a $LOGFILE
echo "" | tee -a $LOGFILE

#
# Main C/C+ regression tests
#
echo "============ C/C++ regression tests ============" $'\n' | tee -a $LOGFILE
for usrcode in usercode usercodeIrq
do
  for mkfile in $MKFILEBASE "makefile HDL=VHDL" makefile.verilator
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
# BFM C/C+ regression tests
#

cd $REGRESSDIR/../bfm/test
echo "============ BFM regression tests ============" $'\n' | tee -a $LOGFILE
for usrcode in usercode 
do
  for bustype in AVALON APB AHB AXI
  do
    for mkfile in $MKFILEBASE "makefile HDL=VHDL" makefile.verilator
    do
     echo "Running $mkfile BUSTYPE=$bustype with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean
     make -f $mkfile BUSTYPE=$bustype USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal"  | egrep -v "$FILTERSTR" | tee -a $LOGFILE
     make -f $mkfile clean
     echo "" | tee -a $LOGFILE
    done
  done
done

#
# Python regression tests
#
# Python tests
cd $REGRESSDIR/../python/test

echo "=========== python regression tests ============" $'\n' | tee -a $LOGFILE
for usrcode in usercode
do
  export PYTHONPATH=$usrcode
  for mkfile in $MKFILEBASE "makefile HDL=VHDL"
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
TESTDIR=../../pcievhost/verilog/test

if [ -d $TESTDIR ]
then
  cd $TESTDIR

  echo "============ PCIe regression tests =============" $'\n' | tee -a $LOGFILE
  for usrcode in usercode
  do
    for mkfile in makefile makefile.ica makefile.verilator $MAKEFILEXSIM
    do
     echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean
     make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "${FILTERSTR}|PCIED" | tee -a $LOGFILE
     make -f $mkfile clean
     echo "" | tee -a $LOGFILE
    done
  done
else
  echo  "======= Skipping PCIe regression tests ========" $'\n' | tee -a $LOGFILE
fi

#
# usbModel Verilog regression tests  (if repository checked out)
#
cd $REGRESSDIR
TESTDIR=../../usbModel/model/verilog/test

if [ -d $TESTDIR ]
then
  cd $TESTDIR

  echo "======= usbModel Verilog regression tests =======" $'\n' | tee -a $LOGFILE
  for usrcode in usercode
  do
    for mkfile in makefile makefile.ica $MAKEFILEVER $MAKEFILEXSIM
    do
     echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean
     make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "$FILTERSTR" | tee -a $LOGFILE
     make -f $mkfile clean
     echo "" | tee -a $LOGFILE
    done
  done
else
  echo  "== Skipping usbModel Verilog regression tests ==" $'\n' | tee -a $LOGFILE
fi

#
# usbModel Verilog regression tests  (if repository checked out)
#
cd $REGRESSDIR
TESTDIR=../../usbModel/model/vhdl/test

if [ -d $TESTDIR ]
then
  cd $TESTDIR

  echo "========= usbModel VHDL regression tests ========" $'\n' | tee -a $LOGFILE

  for mkfile in makefile makefile.nvc makefile.ghdl
  do
   echo "Running $mkfile with usercode/ ..." | tee -a $LOGFILE
   make -f $mkfile clean
   make -f $mkfile run 2>&1 | egrep -i "error|fatal" | egrep -v "$FILTERSTR" | tee -a $LOGFILE
   make -f $mkfile clean
   echo "" | tee -a $LOGFILE
  done

else
  echo  "=== Skipping usbModel VHDL regression tests ===" $'\n' | tee -a $LOGFILE
fi

#
# tcpIpPg regression tests (if repository checked out)
#

cd $REGRESSDIR
TESTDIR=../../tcpIpPg/test

if [ -d $TESTDIR ]
then

  cd $TESTDIR

  echo "========== tcpIpPg regression tests ============" $'\n' | tee -a $LOGFILE
  for usrcode in src
  do
    for mkfile in $MKFILEBASE "makefile HDL=VHDL" makefile.verilator
    do
     echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean 2>&1 > /dev/null
     make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "$FILTERSTR" | tee -a $LOGFILE
     make -f $mkfile clean 2>&1 > /dev/null
     echo "" | tee -a $LOGFILE
    done
  done
else
  echo  "====== Skipping tcpIpPg regression tests ======" $'\n' | tee -a $LOGFILE
fi

#
# udpIpPg regression tests (if repository checked out)
#

cd $REGRESSDIR
TESTDIR=../../udpIpPg/test

if [ -d $TESTDIR ]
then

  cd $TESTDIR

  echo "========== udpIpPg regression tests ============" $'\n' | tee -a $LOGFILE
  for usrcode in src
  do
    for mkfile in $MKFILEBASE "makefile HDL=VHDL" makefile.verilator
    do
     echo "Running $mkfile with $usrcode/ ..." | tee -a $LOGFILE
     make -f $mkfile clean 2>&1 > /dev/null
     make -f $mkfile USRCDIR=$usrcode run 2>&1 | egrep -i "error|fatal" | egrep -v "$FILTERSTR" | tee -a $LOGFILE
     make -f $mkfile clean 2>&1 > /dev/null
     echo "" | tee -a $LOGFILE
    done
  done
else
  echo  "====== Skipping udpIpPg regression tests ======" $'\n' | tee -a $LOGFILE
fi

cd $REGRESSDIR

date | tee -a $LOGFILE
//=====================================================================
//
// VUserMianPy.c                                     Date: 2024/01/24
//
// Copyright (c) 2024 Simon Southwell.
//
// This file is part of VProc.
//
// VProc is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// VProc is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with VProc. If not, see <http://www.gnu.org/licenses/>.
//
//=====================================================================
#include "VUser.h"
#include "PythonVProc.h"

#define SLEEPFOREVER       {while(1) VTick(0x7fffffff, node);}

static void VUserMain(int node)
{
    int status = RunPython(node);

    if (status)
    {
        printf("***ERROR: RunPython(%d) returned error status %d\n", node, status);
    }

    SLEEPFOREVER;
}

void VUserMain0()  {VUserMain(0);}
void VUserMain1()  {VUserMain(1);}
void VUserMain2()  {VUserMain(2);}
void VUserMain3()  {VUserMain(3);}
void VUserMain4()  {VUserMain(4);}
void VUserMain5()  {VUserMain(5);}
void VUserMain6()  {VUserMain(6);}
void VUserMain7()  {VUserMain(7);}
void VUserMain8()  {VUserMain(8);}
void VUserMain9()  {VUserMain(9);}
void VUserMain10() {VUserMain(10);}
void VUserMain11() {VUserMain(11);}
void VUserMain12() {VUserMain(12);}
void VUserMain13() {VUserMain(13);}
void VUserMain14() {VUserMain(14);}
void VUserMain15() {VUserMain(15);}
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

#include <stdint.h>

#include "VUser.h"
#include "PythonVProc.h"

#define SLEEPFOREVER       {while(1) VTick(0x7fffffff, node);}

// In Python 64 nodes is the maximum (the default), but check this hasn't been
// overridden to a large number.
#if VP_MAX_NODES > 64
#error "**ERROR: VP_MAX_NODES > 64 is unsupported"
#endif

static uint32_t active_node = 0;

static void VUserMain(int node)
{
    if (active_node)
    {
        fprintf(stderr, "NODE%d: ***ERROR: Under Python only a single instance of VProc is supported at this time.\n", node);
    }
    else
    {
        active_node |= (uint32_t)1 << node;

        int status = RunPython(node);

        if (status)
        {
            fprintf(stderr, "***ERROR: RunPython(%d) returned error status %d\n", node, status);
        }
    }

    SLEEPFOREVER;
}

// Bindings for VUserMain<n> entry points.

void VUserMain0()  {VUserMain(0);}  void VUserMain1()  {VUserMain(1);}  void VUserMain2()  {VUserMain(2);}  void VUserMain3()  {VUserMain(3);}
void VUserMain4()  {VUserMain(4);}  void VUserMain5()  {VUserMain(5);}  void VUserMain6()  {VUserMain(6);}  void VUserMain7()  {VUserMain(7);}
void VUserMain8()  {VUserMain(8);}  void VUserMain9()  {VUserMain(9);}  void VUserMain10() {VUserMain(10);} void VUserMain11() {VUserMain(11);}
void VUserMain12() {VUserMain(12);} void VUserMain13() {VUserMain(13);} void VUserMain14() {VUserMain(14);} void VUserMain15() {VUserMain(15);}
void VUserMain16() {VUserMain(16);} void VUserMain17() {VUserMain(17);} void VUserMain18() {VUserMain(18);} void VUserMain19() {VUserMain(19);}
void VUserMain20() {VUserMain(20);} void VUserMain21() {VUserMain(21);} void VUserMain22() {VUserMain(22);} void VUserMain23() {VUserMain(23);}
void VUserMain24() {VUserMain(24);} void VUserMain25() {VUserMain(25);} void VUserMain26() {VUserMain(26);} void VUserMain27() {VUserMain(27);}
void VUserMain28() {VUserMain(28);} void VUserMain29() {VUserMain(29);} void VUserMain30() {VUserMain(30);} void VUserMain31() {VUserMain(31);}
void VUserMain32() {VUserMain(32);} void VUserMain33() {VUserMain(33);} void VUserMain34() {VUserMain(34);} void VUserMain35() {VUserMain(35);}
void VUserMain36() {VUserMain(36);} void VUserMain37() {VUserMain(37);} void VUserMain38() {VUserMain(38);} void VUserMain39() {VUserMain(39);}
void VUserMain40() {VUserMain(40);} void VUserMain41() {VUserMain(41);} void VUserMain42() {VUserMain(42);} void VUserMain43() {VUserMain(43);}
void VUserMain44() {VUserMain(44);} void VUserMain45() {VUserMain(45);} void VUserMain46() {VUserMain(46);} void VUserMain47() {VUserMain(47);}
void VUserMain48() {VUserMain(48);} void VUserMain49() {VUserMain(49);} void VUserMain50() {VUserMain(50);} void VUserMain51() {VUserMain(51);}
void VUserMain52() {VUserMain(52);} void VUserMain53() {VUserMain(53);} void VUserMain54() {VUserMain(54);} void VUserMain55() {VUserMain(55);}
void VUserMain56() {VUserMain(56);} void VUserMain57() {VUserMain(57);} void VUserMain58() {VUserMain(58);} void VUserMain59() {VUserMain(59);}
void VUserMain60() {VUserMain(60);} void VUserMain61() {VUserMain(61);} void VUserMain62() {VUserMain(62);} void VUserMain63() {VUserMain(63);}
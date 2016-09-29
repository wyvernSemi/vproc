/**************************************************************/
/* VUserMain.c                               Date: 2004/12/13 */
/*                                                            */
/* Copyright (c) 2004 Simon Southwell. All rights reserved.   */
/*                                                            */
/**************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include "VUser.h"

#define SLEEP {while(1) VTick(0x7fffffff, node);}

// VUsersMain has no calling arguments. If you want runtime configuration,
// then you'll need to read in a configuration file.

// I'm node 1
static int node = 1;

static int VInterrupt_1(void)
{
    VPrint("Node %d: VInterrupt_1()\n", node);
    return 0;
}

void VUserMain1()
{
    unsigned int num, data, addr;

    VPrint("VUserMain1(): node=%d\n", node);

    // Register function as interrupt level 1 routine
    VRegInterrupt(1, VInterrupt_1, node);

    VTick(10, node);

    // Write to memory
    addr = 0xa0000000; 
    data = 0x12345678;
    VWrite(addr, data, 0, node);
    VPrint("Node %d: wrote data %08x to addr %08x\n", node, data, addr);

    // Pause for a few ticks
    VTick(10, node);

    addr = 0xa0000010; 
    data = 0xfedcba98;
    VWrite(addr, data, 0, node);
    VPrint("Node %d: wrote data %08x to addr %08x\n", node, data, addr);

    // Pause for a few ticks
    VTick(10, node);

    // Read data back
    addr = 0xa0000000;
    data = 0xa3957571;
    VRead(addr, &data, 0, node);

    // Check data
    if (data != 0x12345678) {
        VPrint("***Error: data miscompare in node %d (%08x)\n", node, data);
        SLEEP;
    } else {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    VTick(10, node);

    // Read data back
    addr = 0xa0000010;
    data = 0;
    VRead(addr, &data, 0, node);

    // Check data
    if (data != 0xfedcba98) {
        VPrint("***Error: data miscompare in node %d (%08x)\n", node, data);
        SLEEP;
    } else {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    SLEEP;

}

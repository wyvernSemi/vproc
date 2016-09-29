/**************************************************************/
/* VUserMain.c                               Date: 2004/12/13 */
/*                                                            */
/* Copyright (c) 2004 Simon Southwell. All rights reserved.   */
/*                                                            */
/**************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include "VUser.h"

// VUsersMain has no calling arguments. If you want runtime configuration,
// then you'll need to read in a configuration file.

// I'm node 0
static int node = 0;

static int Reset = 0;

static int VInterrupt_1(void)
{
    io_printf("Node %d: VInterrupt_1()\n", node);
    return 0;
}

static int VInterrupt_4(void)
{
    io_printf("Node %d: VInterrupt_4()\n", node);
    Reset = 1;
    return 1;
}

void VUserMain0()
{
    unsigned int num, data, addr;

    //debug_io_printf("VUserMain0(): node=%d\n", node);

    // Register function as interrupt level 1 routine
    VRegInterrupt(1, VInterrupt_1, node);
    VRegInterrupt(4, VInterrupt_4, node);

    do {
        VTick(0x7fffffff, node);
    } while (!Reset);
    Reset = 0;

    srand(0x250864);

    while (1) {

        num  = rand() % 8;
        addr = (rand() << 16) | rand();

        if (num == 0) {
            VRead(addr, &data, 0, node);
            VPrint("Node %d: Read  %08x at %08x\n", node, data, addr);
        } else if (num == 1) {
            data = (rand() << 16) | rand();
            VWrite(addr, data, 0, node);
            VPrint("Node %d: Wrote %08x at %08x\n", node, data, addr);
        } else {
            VPrint("Node %d: Tick for %d cycles\n", node, num);
            VTick(num % 8, node);
        }
    }
}


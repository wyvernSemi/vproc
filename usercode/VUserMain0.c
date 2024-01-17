/**************************************************************/
/* VUserMain.c                               Date: 2004/12/13 */
/*                                                            */
/* Copyright (c) 2004-2024 Simon Southwell.                   */
/* All rights reserved.                                       */
/*                                                            */
/**************************************************************/

#include "VUser.h"

// ------------------------------------------------------------
// LOCAL STATICS
// ------------------------------------------------------------

// I'm node 0
static int node = 0;

static int Reset = 0;

// ------------------------------------------------------------
// Interrupt callback function for level 1
// ------------------------------------------------------------

static int VInterrupt_1(void)
{
    VPrint("Node %d: VInterrupt_1()\n", node);
    return 0;
}

// ------------------------------------------------------------
// Interrupt callback function for level 4
// ------------------------------------------------------------

static int VInterrupt_4(void)
{
    VPrint("Node %d: VInterrupt_4()\n", node);
    Reset = 1;
    return 1;
}

// ------------------------------------------------------------
// Interrupt callback function for vector IRQ
// ------------------------------------------------------------

static int VInterrupt_irq(int irq)
{
    VPrint("Node %d: VInterrupt_irq() irq = 0x%08x\n", node, irq);
    return 0;
}

// ------------------------------------------------------------
// VuserMainX entry point for node 0
// ------------------------------------------------------------

// VUserMainX has no calling arguments. If you want runtime configuration,
// then you'll need to read in a configuration file.

void VUserMain0()
{
    unsigned int num, data, addr;

    VPrint("VUserMain0(): node=%d\n", node);

    // Register functions as interrupt levels 1 and 4 routines
    VRegInterrupt(1, VInterrupt_1, node);
    VRegInterrupt(4, VInterrupt_4, node);
    VRegIrq      (VInterrupt_irq, node);

    do
    {
        VTick(0x7fffffff, node);
    }
    while (!Reset);
    
    Reset = 0;

    srand(0x250864);

    while (1)
    {
        num  = rand() % 8;
        addr = (rand() << 16) | rand();

        if (num == 0)
        {
            VRead(addr, &data, 0, node);
            VPrint("Node %d: Read  %08x at %08x\n", node, data, addr);
        }
        else if (num == 1)
        {
            data = (rand() << 16) | rand();
            VWrite(addr, data, 0, node);
            VPrint("Node %d: Wrote %08x at %08x\n", node, data, addr);
        }
        else
        {
            VPrint("Node %d: Tick for %d cycles\n", node, num);
            VTick(num % 8, node);
        }
    }
}


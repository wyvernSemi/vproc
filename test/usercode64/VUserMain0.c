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
// ISR for level 1
// ------------------------------------------------------------

static int VInterrupt_1(void)
{
    VPrint("Node %d: VInterrupt_1()\n", node);
    return 0;
}

// ISR for level 4
// ------------------------------------------------------------

static int VInterrupt_4(void)
{
    VPrint("Node %d: VInterrupt_4()\n", node);
    Reset = 1;
    return 1;
}

// ------------------------------------------------------------
// Interrupt callback
// ------------------------------------------------------------

static int VIrqCB (int irq)
{
    uint32_t irq_level = irq;
    
    if (irq_level == 1)
    {
        VInterrupt_1();
    }
    else if (irq_level == 4)
    {
        VInterrupt_4();
    }
    
    return 0;
}

// ------------------------------------------------------------
// VuserMainX entry point for node 0
// ------------------------------------------------------------

// VUserMainX has no calling arguments. If you want runtime configuration,
// then you'll need to read in a configuration file.

void VUserMain0()
{
    unsigned num;
    uint64_t data, addr;

    VPrint("VUserMain0(): node=%d\n", node);

    // Register IRQ callback function
    VRegIrq(VIrqCB, node);

    do
    {
        VTick(10, node);
    }
    while (!Reset);
    
    Reset = 0;

    srand(0x250864);

    while (1)
    {
        num  = rand() % 8;
        addr = ((uint64_t)rand() << 32) |  (uint64_t)rand();

        if (num == 0)
        {
            VRead64(addr, &data, 0, node);
            VPrint("Node %d: Read  %08llx at %08llx\n", node, data, addr);
        }
        else if (num == 1)
        {
            data = ((uint64_t)rand() << 32) | (uint64_t)rand();
            VWrite64(addr, data, 0, node);
            VPrint("Node %d: Wrote %08llx at %08llx\n", node, data, addr);
        }
        else
        {
            VPrint("Node %d: Tick for %d cycles\n", node, num);
            VTick(num % 8, node);
        }
    }
}


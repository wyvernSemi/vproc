/**************************************************************/
/* VUserMain.c                               Date: 2004/12/13 */
/*                                                            */
/* Copyright (c) 2004-2025 Simon Southwell.                   */
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
// ISR  function for level 1
// ------------------------------------------------------------

static int VInterrupt_1(void)
{
    VPrint("Node %d: VInterrupt_1()\n", node);
    return 0;
}

// ------------------------------------------------------------
// ISR function for level 4
// ------------------------------------------------------------

static int VInterrupt_4(void)
{
    VPrint("Node %d: VInterrupt_4()\n", node);
    Reset = 1;
    return 1;
}

// ------------------------------------------------------------
// Interrrupt callback function
// ------------------------------------------------------------

static int VInterrupt (int level)
{
    switch(level)
    {
        case 1: VInterrupt_1(); break;
        case 4: VInterrupt_4(); break;
        case 0: break;
        default:
          VPrint("***ERROR: VInterrupt(): unrecognised interrupt vector (0x%08x)\n", level);
          break;
    }
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

    // Register function for interrupt 
    VRegIrq(VInterrupt, node);

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


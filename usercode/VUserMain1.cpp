/**************************************************************/
/* VUserMain.c                               Date: 2004/12/13 */
/*                                                            */
/* Copyright (c) 2004-2024 Simon Southwell.                   */
/* All rights reserved.                                       */
/*                                                            */
/**************************************************************/

#include "VProcClass.h"

// ------------------------------------------------------------
// DEFINITIONS
// ------------------------------------------------------------

#define SLEEP {while(1) VTick(0x7fffffff, node);}

// ------------------------------------------------------------
// LOCAL STATICS
// ------------------------------------------------------------

// I'm node 1
static int node = 1;

// ------------------------------------------------------------
// Interrupt callback function for level 1
// ------------------------------------------------------------

static int VInterrupt_1(void)
{
    VPrint("Node %d: VInterrupt_1()\n", node);
    return -1;
}

// ------------------------------------------------------------
// VuserMainX entry point for node 1
// ------------------------------------------------------------

// VUserMainX has no calling arguments. If you want run time configuration,
// then you'll need to read in a configuration file.

extern "C" void VUserMain1()
{
    VProc vp1(node);

    unsigned int num, data, addr;

    VPrint("VUserMain1(): node=%d\n", node);

    // Register function as interrupt level 1 routine
    vp1.regInterrupt(1, VInterrupt_1);

    vp1.tick(10);

    // Write to memory
    addr = 0xa0000000;
    data = 0x12345678;
    vp1.write(addr, data, 0);
    VPrint("Node %d: wrote data %08x to addr %08x\n", node, data, addr);

    // Pause for a few ticks
    vp1.tick(10);

    addr = 0xa0000010;
    data = 0xfedcba98;
    vp1.write(addr, data, 0);
    VPrint("Node %d: wrote data %08x to addr %08x\n", node, data, addr);

    // Pause for a few ticks
    vp1.tick(10);

    // Read data back
    addr = 0xa0000000;
    data = 0xa3957571;
    vp1.read(addr, &data, 0);

    // Check data
    if (data != 0x12345678)
    {
        VPrint("***Error: data miscompare in node %d (%08x)\n", node, data);
        //SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    vp1.tick(10);

    // Read data back
    addr = 0xa0000010;
    data = 0;
    vp1.read(addr, &data, 0);

    // Check data
    if (data != 0xfedcba98)
    {
        VPrint("***Error: data miscompare in node %d (%08x)\n", node, data);
        //SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    uint32_t wbuf[8], rbuf[8];
    
    addr = 0xa1000020;
    
    for (int idx = 0; idx < 8; idx++)
    {
        wbuf[idx] = 0x00010000 + idx;
    }
    
    vp1.burstWrite(addr, wbuf, 8);
    VPrint("Node %d: burst wrote 8 words from addr %08x\n", node, addr);

    vp1.burstRead(addr, rbuf, 8);

    for (int idx = 0; idx < 8; idx++)
    {
        wbuf[idx] = (0x00010000 + idx);
        if (rbuf[idx] != wbuf[idx])
        {
            VPrint("***Error: burst data miscompare in node %d (%08x v %08x at index %d)\n", node, rbuf[idx], wbuf[idx], idx);
            //SLEEP;
        }
    }
    
    VPrint("Node %d: burst read 8 words from addr %08x\n", node, addr);

    SLEEP;
}

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

#define SLEEP       {while(1) VTick(0x7fffffff, node);}
#define SIMSTOPADDR 0xb0000000

// ------------------------------------------------------------
// LOCAL STATICS
// ------------------------------------------------------------

// I'm node 1
static int node = 1;

// ------------------------------------------------------------
// Interrupt callback function for vector IRQ
// ------------------------------------------------------------

static int VInterrupt_irq(int irq)
{
    VPrint("Node %d: VInterrupt_irq() irq = 0x%08x\n", node, irq);
    return 0;
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

    // Register function as irq
    VRegIrq (VInterrupt_irq, node);

    vp1.tick(10);

    // -------------------------------------------
    // Write words to memory

    addr = 0xa0000000;
    data = 0x12345678;
    vp1.write(addr, data, 0);
    VPrint("Node %d: wrote data %08x to addr %08x\n", node, data, addr);

    // Pause for a few ticks
    vp1.tick(10);

    addr = 0xa0000010;
    data = 0xfedcba98;
    vp1.writeWord(addr, data, 0);
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
        SLEEP;
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
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    // -------------------------------------------
    // Write half words to memory

    addr = 0xa0005022;
    data = 0x8fe4;

    vp1.writeHword(addr, data);

    addr += 2;
    data = 0x7e0a;
    vp1.writeHword(addr, data);

    addr -= 2;

    vp1.tick(2);

    vp1.readHword(addr, &data);
    if (data != 0x8fe4)
    {
        VPrint("***Error: halfword data miscompare in node %d (%08x)\n", node, data);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    addr += 2;

    vp1.tick(2);

    vp1.readHword(addr, &data);

    if (data != 0x7e0a)
    {
        VPrint("***Error: halfword data miscompare in node %d (%08x)\n", node, data);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    // -------------------------------------------
    // Write bytes to memory

    addr = 0xa0005033;
    data = 0x99;

    vp1.writeByte(addr, data);

    vp1.tick(1);

    addr += 1;
    data = 0x2f;
    vp1.writeByte(addr, data);

    addr -= 1;

    vp1.tick(2);

    vp1.readByte(addr, &data);
    if (data != 0x99)
    {
        VPrint("***Error: byhte data miscompare in node %d (%08x)\n", node, data);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    addr += 1;

    vp1.tick(1);

    vp1.readByte(addr, &data);

    if (data != 0x2f)
    {
        VPrint("***Error: byte data miscompare in node %d (%08x)\n", node, data);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data, addr);
    }

    // -------------------------------------------
    // Write burst data to memory

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
            SLEEP;
        }
    }

    VPrint("Node %d: burst read 8 words from addr %08x\n", node, addr);

    // Wait a bit and then stop the simulation
    vp1.tick(10);
    vp1.write(SIMSTOPADDR, 0);

    SLEEP;
}

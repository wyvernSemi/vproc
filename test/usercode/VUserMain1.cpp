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

    uint32_t num, addr;

    VPrint("VUserMain1(): node=%d\n", node);

    // Register function as irq
    VRegIrq (VInterrupt_irq, node);

    vp1.tick(10);

    // -------------------------------------------
    // Write words to memory

    addr            = 0xa0000000;
    uint32_t data32 = 0x12345678;
    vp1.write(addr, data32, 0);
    VPrint("Node %d: wrote data %08x to addr %08x\n", node, data32, addr);

    // Pause for a few ticks
    vp1.tick(10);

    addr   = 0xa0000010;
    data32 = 0xfedcba98;
    vp1.writeWord(addr, data32, 0);
    VPrint("Node %d: wrote data %08x to addr %08x\n", node, data32, addr);

    // Pause for a few ticks
    vp1.tick(10);

    // Read data back
    addr   = 0xa0000000;
    data32 = 0xa3957571;
    vp1.read(addr, &data32, 0);

    // Check data
    if (data32 != 0x12345678)
    {
        VPrint("***Error: data miscompare in node %d (%08x)\n", node, data32);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data32, addr);
    }

    vp1.tick(10);

    // Read data back
    addr   = 0xa0000010;
    data32 = 0;
    vp1.read(addr, &data32, 0);

    // Check data
    if (data32 != 0xfedcba98)
    {
        VPrint("***Error: data miscompare in node %d (%08x)\n", node, data32);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data32, addr);
    }

    // -------------------------------------------
    // Write half words to memory

    addr = 0xa0005022;
    uint16_t data16 = 0x8fe4;

    vp1.writeHword(addr, data16);

    addr += 2;
    data16 = 0x7e0a;
    vp1.writeHword(addr, data16);

    addr -= 2;

    vp1.tick(2);

    vp1.readHword(addr, &data16);
    if (data16 != 0x8fe4)
    {
        VPrint("***Error: halfword data miscompare in node %d (%08x)\n", node, data16);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data16, addr);
    }

    addr += 2;

    vp1.tick(2);

    vp1.readHword(addr, &data16);

    if (data16 != 0x7e0a)
    {
        VPrint("***Error: halfword data miscompare in node %d (%08x)\n", node, data16);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data16, addr);
    }

    // -------------------------------------------
    // Write bytes to memory

    addr         = 0xa0005033;
    uint8_t data8 = 0x99;

    vp1.writeByte(addr, data8);

    vp1.tick(1);

    addr  += 1;
    data8 = 0x2f;
    vp1.writeByte(addr, data8);

    addr -= 1;

    vp1.tick(2);

    vp1.readByte(addr, &data8);
    if (data8 != 0x99)
    {
        VPrint("***Error: byhte data miscompare in node %d (%08x)\n", node, data8);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data8, addr);
    }

    addr += 1;

    vp1.tick(1);

    vp1.readByte(addr, &data8);

    if (data8 != 0x2f)
    {
        VPrint("***Error: byte data miscompare in node %d (%08x)\n", node, data8);
        SLEEP;
    }
    else
    {
        VPrint("Node %d: read back data %08x from addr %08x\n", node, data8, addr);
    }

    // -------------------------------------------
    // Write burst data to memory

    uint32_t wbuf[32], rbuf[32];

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

    // -------------------------------------------
    // Write offset burst data to memory

    addr = 0xa1000032;

    for (int idx = 0; idx < 11; idx++)
    {
        ((uint8_t*)wbuf)[idx] = idx + 0x10;
    }

    vp1.tick(1);
    vp1.burstWriteBytes(addr, wbuf, 11);
    VPrint("Node %d: burst wrote 11 bytes from addr %08x\n", node, addr);

    vp1.tick(2);
    vp1.burstReadBytes(addr, rbuf, 11);

    for (int idx = 0; idx < 11; idx++)
    {
        if (((uint8_t*)rbuf)[idx] != ((uint8_t*)wbuf)[idx])
        {
            VPrint("***Error: burst data byte miscompare in node %d (%08x v %08x at index %d)\n", node, ((uint8_t*)rbuf)[idx], ((uint8_t*)wbuf)[idx], idx);
            SLEEP;
        }
    }

    VPrint("Node %d: burst read 11 bytes from addr %08x\n", node, addr);

    // Wait a bit and then stop the simulation
    vp1.tick(10);
    vp1.write(SIMSTOPADDR, 0);

    SLEEP;
}

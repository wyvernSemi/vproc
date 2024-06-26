/**************************************************************/
/* VUserMain.c                               Date: 2004/12/13 */
/*                                                            */
/* Copyright (c) 2004-2024 Simon Southwell.                   */
/* All rights reserved.                                       */
/*                                                            */
/**************************************************************/

#include "VProcIrqClass.h"

// ------------------------------------------------------------
// DEFINITIONS
// ------------------------------------------------------------

#define SLEEP       {while(1) vp1.tick(0x7fffffff);}
#define SIMSTOPADDR 0xb0000000

// ------------------------------------------------------------
// LOCAL STATICS
// ------------------------------------------------------------

// I'm node 1
static int node = 1;

static VProcIrqClass vp1(node);

// ------------------------------------------------------------
// Interrupt callback function for vector IRQ
// ------------------------------------------------------------

static int VInterrupt_irq(int irq)
{
    VPrint("Node %d: VInterrupt_irq() irq = 0x%08x\n", node, irq);
    vp1.updateIrqState(irq);
    return 0;
}

// ------------------------------------------------------------
// Interrupt service routines
// ------------------------------------------------------------

static void isr0 (int irq)
{
    VPrint("Entering ISR0 (0x%08x)\n", irq);

    vp1.tick(1);
    vp1.clearEdgeTriggeredIrq(0);

    VPrint("Leaving ISR0\n");
}

static void isr1 (int irq)
{
    VPrint("Entering ISR1 (0x%08x)\n", irq);

    vp1.tick(10);

    VPrint("Leaving ISR1\n");
}

// ------------------------------------------------------------
// VuserMainX entry point for node 1
// ------------------------------------------------------------

// VUserMainX has no calling arguments. If you want run time configuration,
// then you'll need to read in a configuration file.

extern "C" void VUserMain1()
{
    unsigned int num, data, addr;

    VPrint("VUserMain1(): node=%d\n", node);

    // Configure interrupts
    vp1.regIrq (VInterrupt_irq);            // Register interrupt callback function with VProc
    vp1.registerIsr(isr0, 0, true);         // Register isr0 as ISR for IRQ[0] and enable
    vp1.registerIsr(isr1, 1, true);         // Register isr1 as ISR for IRQ[0] and enable
    vp1.setIrqAsEdgeTriggered(0x00000001);  // Set IRQ[0] as an edge triggered interrupt and all others level
    vp1.enableInterrupts();                 // Enable master interrupt

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

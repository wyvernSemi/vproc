/**************************************************************/
/* VUserMain.c                               Date: 2024/04/12 */
/*                                                            */
/* Copyright (c) 2024 Simon Southwell.                        */
/* All rights reserved.                                       */
/*                                                            */
/**************************************************************/

#include "VProcClass.h"

// ------------------------------------------------------------
// DEFINITIONS
// ------------------------------------------------------------

// Define addresses
#define SCRATCH0 0xa0000000
#define SCRATCH1 0xa0000004
#define SCRATCH2 0xa0000008
#define SCRATCH3 0xa000000c

#define INTADDR  0x20000000

#define STOP     0xfffffff0
#define FINISH   0xfffffff4

// ------------------------------------------------------------
// LOCAL STATIC VARIABLES
// ------------------------------------------------------------

static int node      = 0;
static int irqchange = 0;

// ------------------------------------------------------------
// Interrupt callback function for vector IRQ
// ------------------------------------------------------------

static int irqCallback(int irq)
{
    VPrint("Node %d: irqCallback() irq = 0x%08x\n", node, irq);
    
    // Only IRQ[0] should change
    if (irq & 0x1 || irq == 0)
    {
        irqchange++;
    }

    return 0;
}

// ------------------------------------------------------------
// Main Node 0 entry point
// ------------------------------------------------------------

extern "C" void VUserMain0 ()
{
    uint32_t rdata;
    unsigned error = 0;

    // Construct VProc API object
    VProc *vp = new VProc(node);

    // Register function as irq callback
    VRegIrq (irqCallback, node);
    
    // -------------------------------
    // Word write and read tests
    // -------------------------------

    uint32_t wordaddr[2] = {0x00002000, 0x00002004};
    uint32_t worddata[2] = {0x12345678, 0x87654321};

    vp->write(wordaddr[0], worddata[0]);
    vp->write(wordaddr[1], worddata[1]);

    vp->read (wordaddr[0], &rdata);

    if (rdata !=  worddata[0])
    {
        fprintf(stderr, "***Error: mismatch at address 0x%08x. Got 0x%08x, expected 0x%08x\n", wordaddr[0], rdata, worddata[0]);
        error++;
    }

    vp->read (wordaddr[1], &rdata);

    if (rdata != worddata[1])
    {
        fprintf(stderr, "***Error: mismatch at address 0x%08x. Got 0x%08x, expected 0x%08x\n", wordaddr[1], rdata, worddata[1]);
        error++;
    }
    
    // -------------------------------
    // Delta cycle words access tests
    // -------------------------------

    vp->tick(2);

    uint32_t testdata[4] = {0xffddbb99, 0x55aa2211, 0xcafebabe, 0x900df00d};

    // Write four words to scratch registers in delta-time
    for (int idx = 0; idx < 4; idx++)
    {
        vp->write(SCRATCH0 + (idx<<2), testdata[idx], DELTA_CYCLE);
    }

    // Read scratch registers in delta time except for last access
    for (int idx = 0; idx < 4; idx++)
    {
        vp->read(SCRATCH0 + (idx<<2), &rdata, idx != 3 ? DELTA_CYCLE : 0);

        if (rdata != testdata[idx])
        {
            fprintf(stderr, "***Error: mismatch at address 0x%08x. Got 0x%08x, expected 0x%08x\n", SCRATCH0+(idx<<2), rdata, testdata[idx]);
            error++;
        }
    }

    vp->tick(3);

    // -------------------------------
    // IRQ tests
    // -------------------------------

    // Assert IRQ
    vp->write(INTADDR, 1);

    vp->tick(5);

    // Deassert IRQ
    vp->write(INTADDR, 0);

    vp->tick(5);

    // Check counted rising and falling IRQ edge
    if (irqchange != 2)
    {
        fprintf(stderr, "***Error: Unexpected IRQ change count. Got %d, expected %d\n", irqchange, 2);
        error++;
    }

    // -------------------------------
    // Finish up testing
    // -------------------------------
    
    // Flag any errors
    if (error)
    {
        fprintf(stderr, "***Error: %d error%s seen in test\n", error, (error == 1) ? "" : "s");
    }
    else
    {
        fprintf(stderr, "\n++++++++++++++++++\n"
                          "+ All Tests PASS +\n"
                          "++++++++++++++++++\n\n");
    }

    // End simulation
    vp->write(FINISH, 1);

    // Should not reach here
    vp->tick(0x7fffffff);
}
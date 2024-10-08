/**************************************************************/
/* VUserMain.c                               Date: 2004/12/13 */
/*                                                            */
/* Copyright (c) 2004-2024 Simon Southwell.                   */
/* All rights reserved.                                       */
/*                                                            */
/**************************************************************/

#include "VUser.h"

#define SLEEPFOREVER {while(1) VTick(0x7fffffff, node);}

#define DELAYRANGE 10

// ------------------------------------------------------------
// LOCAL STATICS
// ------------------------------------------------------------

// I'm node 0
static const int node = 0;

static int Reset = 0;

// ------------------------------------------------------------
// Interrupt callback function for level 1
// ------------------------------------------------------------

static int VInterrupt_1(int irq)
{
    VPrint("Node %d: VInterrupt_1 irq = 0x%08x\n", irq,node);
    return 0;
}

// ------------------------------------------------------------
// ------------------------------------------------------------

static uint32_t wordoffset (uint32_t byteenable)
{
    uint32_t be = byteenable & 0x3;

    return (be == 1 || be == 3 || be == 0xf) ? 0 :
            be == 2                          ? 1 :
           (be == 4 || be == 0xc)            ? 2 :
                                               3;
}

// ------------------------------------------------------------
// ------------------------------------------------------------

static uint32_t byte_en (uint32_t addr, unsigned isfbe)
{
    uint32_t offset = addr & 0x3;

    return  isfbe ? (0xf << offset) : offset ? (0xf >> (3 - offset)) : 0xf;
}

// ------------------------------------------------------------
// ------------------------------------------------------------

static void avwrite (uint32_t addr, uint32_t data)
{
    // Random delay between 0 and DELAYRANGE-1 cycles
    int delay = rand() % DELAYRANGE;

    VTick (delay, node);

    VWrite (addr, data, 0, node);
}

// ------------------------------------------------------------
// ------------------------------------------------------------

static void avwritebe (uint32_t addr, uint32_t data, uint32_t be)
{
    // Random delay between 0 and DELAYRANGE-1 cycles
    int delay = rand() % DELAYRANGE;

    VTick (delay, node);

    VWriteBE (addr, data, be, 0, node);
}

// ------------------------------------------------------------
// ------------------------------------------------------------
static void avwriteburst (uint32_t addr, uint32_t *data, uint32_t bytelen)
{
    // Random delay between 0 and DELAYRANGE-1 cycles
    int delay = rand() % DELAYRANGE;

    VTick (delay, node);

    uint32_t first_word_addr = addr & ~0x3;
    uint32_t end_byte_addr   = addr + bytelen -1;
    uint32_t end_word_addr   = (end_byte_addr & ~0x3) + ((end_byte_addr & 0x3) == 0x3 ? 4 : 0);
    uint32_t wordlen         = (end_word_addr - first_word_addr)/4;
    uint32_t fbe             = byte_en(addr, 1);
    uint32_t lbe             = byte_en(end_byte_addr, 0);

    VBurstWriteBE (first_word_addr, (void *)data, wordlen, fbe, lbe, node);
}

// ------------------------------------------------------------
// ------------------------------------------------------------
static void avreadburst (uint32_t addr, uint32_t *data, uint32_t bytelen)
{
    // Random delay between 0 and DELAYRANGE-1 cycles
    int delay = rand() % DELAYRANGE;

    VTick (delay, node);

    uint32_t first_word_addr = addr & ~0x3;
    uint32_t end_byte_addr   = addr + bytelen -1;
    uint32_t end_word_addr   = (end_byte_addr & ~0x3) + ((end_byte_addr & 0x3) == 0x3 ? 4 : 0);
    uint32_t wordlen         = (end_word_addr - first_word_addr)/4;

    VBurstRead(first_word_addr, data, wordlen, node);
}


// ------------------------------------------------------------
// ------------------------------------------------------------

static uint32_t avread (uint32_t addr)
{
    uint32_t data;
    // Random delay between 0 and DELAYRANGE-1 cycles
    int delay = rand() % DELAYRANGE;

    VTick (delay, node);

    VRead (addr, &data, 0, node);

    return data;
}

// ------------------------------------------------------------
// VuserMainX entry point for node 0
// ------------------------------------------------------------

// VUserMainX has no calling arguments. If you want runtime configuration,
// then you'll need to read in a configuration file.

void VUserMain0()
{
    unsigned int num, data, addr;
    int error = 0;
    uint32_t burstwdata[4]    = {0x11112222, 0x33334444, 0x55556666, 0x77778888};
    uint32_t burstrdata[4];
    uint32_t burstexpdata[4]  = {0x44110000, 0x66333344, 0x88555566, 0};
    uint32_t burstmaskdata[4] = {0xffff0000, 0xffffffff, 0xffffffff, 0};

    uint32_t testaddr[4] = {0x00000040, 0x00000084, 0x000000c0, 0x00000104};
    uint32_t testbe  [4] = {       0x3,        0xc,        0x2,        0x8};

    VPrint("VUserMain0(): node=%d\n", node);

    // Register functions as interrupt level 1 routine
    VRegUser(VInterrupt_1, node);

    VTick(10, node);

    avwritebe(testaddr[0] | wordoffset(testbe[0]), 0x12345678, testbe[0]);
    avwritebe(testaddr[1] | wordoffset(testbe[1]), 0x87654321, testbe[1]);
    avwritebe(testaddr[2] | wordoffset(testbe[2]), 0x55555555, testbe[2]);
    avwritebe(testaddr[3] | wordoffset(testbe[3]), 0xaaaaaaaa, testbe[3]);

    data = avread(testaddr[0]); VPrint("read 0x%08x from 0x%08x\n", data, testaddr[0]);
    if (data != 0x5678)
    {
        error++;
        VPrint("***ERROR: bad read from address 0x%08x. Got 0x%08x, expected 0x%08x\n", testaddr[0], data, 0x5678);
    }
    
    data = avread(testaddr[1]); VPrint("read 0x%08x from 0x%08x\n", data, testaddr[1]);
    if (data != 0x87650000)
    {
        error++;
        VPrint("***ERROR: bad read from address 0x%08x. Got 0x%08x, expected 0x%08x\n", testaddr[1], data, 0x87650000);
    }
    
    data = avread(testaddr[2]); VPrint("read 0x%08x from 0x%08x\n", data, testaddr[2]);
    if (data != 0x00005500)
    {
        error++;
        VPrint("***ERROR: bad read from address 0x%08x. Got 0x%08x, expected 0x%08x\n", testaddr[2], data, 0x00005500);
    }
    
    data = avread(testaddr[3]); VPrint("read 0x%08x from 0x%08x\n\n", data, testaddr[3]);
    if (data != 0xaa000000)
    {
        error++;
        VPrint("***ERROR: bad read from address 0x%08x. Got 0x%08x, expected 0x%08x\n", testaddr[3], data, 0xaa000000);
    }

#if defined(AXI) || defined(AHB)

    avwriteburst(0x00001002, (uint32_t*)(&((uint8_t*)burstwdata)[1]), 10);
    avreadburst (0x00001000, burstrdata, 12);
    
    for (int idx = 0; idx < 3; idx++)
    {
         if ((burstrdata[idx] & burstmaskdata[idx]) != burstexpdata[idx])
         {
             error++;
             VPrint("***ERROR: bad read from address 0x%08x. Got 0x%08x, expected 0x%08x\n",
                    0x00001000 + idx*4, burstrdata[idx] & burstmaskdata[idx], burstexpdata[idx]);
         }
         else
         {
             VPrint("read 0x%08x from 0x%08x\n", burstrdata[idx], 0x00001000 + idx*4);
         }
         
    }

#endif

   if (error)
   {
       VPrint("\n*** Finished with errors. ***\n");
   }
   else
   {
       VPrint("\nFinished with no errors.\n");
   }

    SLEEPFOREVER;
}


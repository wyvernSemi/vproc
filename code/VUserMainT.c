//=====================================================================
// VUserMain<??>.c                                     Date: dd/mm/yyyy
//
//=====================================================================
// Template for user program, using low level VProc API
//=====================================================================

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "VUser.h"

#ifdef __cpluplus
#define LINKAGE extern "C"
#else
#define LINKAGE /**/
#endif

static int node;

static int VInterrupt_1(void)
{
    return 0;
}
static int VInterrupt_2(void)
{
    return 0;
}
static int VInterrupt_3(void)
{
    return 0;
}
static int VInterrupt_4(void)
{
    return 0;
}
static int VInterrupt_5(void)
{
    return 0;
}
static int VInterrupt_6(void)
{
    return 0;
}
static int VInterrupt_7(void)
{
    return 0;
}

static int VIrqCB (int irq)
{
    return 0;

static int VUserCB (int value)
{
    return 0;
}

//=====================================================================
//
//=====================================================================

// Alter <??> for this node's number (between 0 and MAX_VPROC_NODES)
// to match node number of instantiated VProc component.
LINKAGE void VUserMain<??>(void) 
{
    // Set node number to match this node
    node = <??>;

    // Register level interrupt callback functions (delete unused interrupts)
    // *** deprecated in favour of vector irq (see below) ***
    VRegInterrupt (1, VInterrupt_1, node);
    VRegInterrupt (2, VInterrupt_2, node);
    VRegInterrupt (3, VInterrupt_3, node);
    VRegInterrupt (4, VInterrupt_4, node);
    VRegInterrupt (5, VInterrupt_5, node);
    VRegInterrupt (6, VInterrupt_6, node);
    VRegInterrupt (7, VInterrupt_7, node);
    
    // Register vectored interrupt callback function (or delete if unused)
    VRegIrq       (VIrqCB, node);
    
    // Register user callback function (or delete if unused)
    VRegUser      (VUserCB, node);

    // --- Put user specific code here ---
    // use API functions VWrite, VWriteBE, VRead, 
    // VBurstWrite, VBurstRead and VTick as required

    // -------------- end ----------------
}

//=====================================================================
// VUserMain.c                                         Date:
//
//=====================================================================
// Template for user program
//=====================================================================

#include <stdio.h>
#include <stdlib.h>
#include "VUser.h"

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

static int VUserCB (int value)
{
    return 0;
}

// Alter ?? for this node's number (between 0 and 63)
void VUserMain??(void) 
{
    // Set node number to match this node
    node = ??;

    // Register interrupt functions (delete unused interrupts)
    VRegInterrupt (1, VInterrupt_1, node);
    VRegInterrupt (2, VInterrupt_2, node);
    VRegInterrupt (3, VInterrupt_3, node);
    VRegInterrupt (4, VInterrupt_4, node);
    VRegInterrupt (5, VInterrupt_5, node);
    VRegInterrupt (6, VInterrupt_6, node);
    VRegInterrupt (7, VInterrupt_7, node);
    VRegUser      (VUserCB, node);

    // --- Put user specific code here ---

    // -------------- end ----------------
}

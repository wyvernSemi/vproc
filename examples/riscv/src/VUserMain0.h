/**************************************************************/
/* VUserMain0.h                              Date: 2021/08/01 */
/*                                                            */
/* Copyright (c) 2021 Simon Southwell. All rights reserved.   */
/*                                                            */
/**************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

extern "C" {
    
#include "VUser.h"
}

#define CFGFILENAME                        "vusermain.cfg"
#define RV32I_GETOPT_ARG_STR               "ThHdbrget:n:D:A:p:S:"
#define MAXARGS                            100
#define MEM_SIZE                           (1024*1024)
#define MEM_OFFSET                         0

// Define a sleep forever macro
#define SLEEP_FOREVER {while(1)            VTick(0x7fffffff, node);}      


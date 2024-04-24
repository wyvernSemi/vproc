/**************************************************************/
/* mem_vproc_api.h                           Date: 2024/04/23 */
/*                                                            */
/* Copyright (c) 2024 Simon Southwell. All rights reserved.   */
/*                                                            */
/**************************************************************/

#ifndef _MEM_VPROC_API_H_
#define _MEM_VPROC_API_H_

#include <cstdio>
#include <cstdlib>
#include <cstdint>

extern "C" {
#include "VUser.h"
}

// Define VProc call normal and delta values
#define NORMAL_UPDATE                           0
#define DELTA_UPDATE                            1

// Define a sensible time for a register access, in clock cycles
// Note that for the BFM, the actual length is ACCESS_LEN + 2
//#define ACCESS_LEN                              10
#define ACCESS_LEN                              2

#define HALT_ADDR                               0xAFFFFFF8

extern int      node;

extern void     write_word  (uint32_t addr, uint32_t data);
extern void     write_hword (uint32_t addr, uint32_t data);
extern void     write_byte  (uint32_t addr, uint32_t data);
extern uint32_t read_word   (uint32_t addr);
extern uint32_t read_instr  (uint32_t addr);
extern uint32_t read_hword  (uint32_t addr);
extern uint32_t read_byte   (uint32_t addr);

#endif



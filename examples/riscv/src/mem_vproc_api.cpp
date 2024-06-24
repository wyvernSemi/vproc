/**************************************************************/
/* mem_api_vproc.cpp                         Date: 2024/04/23 */
/*                                                            */
/* Copyright (c) 2024 Simon Southwell. All rights reserved.   */
/*                                                            */
/**************************************************************/
#include <cstdio>
#include <cstdlib>
#include <cstdint>

#include "mem_vproc_api.h"

void write_word(uint32_t addr, uint32_t data)
{
    VWriteBE(addr & ~0x3UL, data, 0xf, NORMAL_UPDATE, node);
    
    if (ACCESS_LEN > 0)
    {
        VTick(ACCESS_LEN, node);
    }
}

void write_hword(uint32_t addr, uint32_t data)
{
    VWriteBE(addr & ~0x3UL, data << ((addr & 0x2) * 8), 0x3 << (addr & 0x2), NORMAL_UPDATE, node);

    if (ACCESS_LEN > 0)
    {
        VTick(ACCESS_LEN, node);
    }
}

void write_byte(uint32_t addr, uint32_t data)
{
    VWriteBE (addr & ~0x3UL, data << ((addr & 0x3) * 8), 0x1 << (addr & 0x3), NORMAL_UPDATE, node);

    if (ACCESS_LEN > 0)
    {
        VTick(ACCESS_LEN, node);
    };
}

uint32_t read_instr(uint32_t addr)
{
    uint32_t word;

    VRead(addr & ~0x3, &word, NORMAL_UPDATE, node);

    if (ACCESS_LEN > 0)
    {
        VTick(ACCESS_LEN, node);
    }

    return word;
}

uint32_t read_word(uint32_t addr)
{
    uint32_t word;

    VRead(addr & ~0x3, &word, NORMAL_UPDATE, node);
    if (ACCESS_LEN > 0)
    {
        VTick(ACCESS_LEN, node);
    }

    return word;
}

uint32_t read_hword(uint32_t addr)
{
    uint32_t word;

    VRead(addr & ~0x3UL, &word, NORMAL_UPDATE, node);

    if (ACCESS_LEN > 0)
    {
        VTick(ACCESS_LEN, node);
    }

    return (word >> ((addr & 0x2UL) * 8)) & 0xffff;
}

uint32_t read_byte(uint32_t addr)
{
    uint32_t word;

    VRead(addr & ~0x3UL, &word, NORMAL_UPDATE, node);

    if (ACCESS_LEN > 0)
    {
        VTick(ACCESS_LEN, node);
    }

    return (word >> ((addr & 0x3UL) * 8)) & 0xff;
}
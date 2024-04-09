/**************************************************************/
/* mem_api_vproc.cpp                         Date: 2021/08/02 */
/*                                                            */
/* Copyright (c) 2021 Simon Southwell. All rights reserved.   */
/*                                                            */
/**************************************************************/
#include <cstdio>
#include <cstdlib>
#include <cstdint>

#include "mem_vproc_api.h"

void write_word(uint32_t addr, uint32_t data)
{
    VWrite(addr & ~0x3UL, data, NORMAL_UPDATE, node);
    VTick(ACCESS_LEN, node);
}

void write_hword(uint32_t addr, uint32_t data)
{
    VWrite(BYTE_EN_ADDR, (0x3 << (addr & 0x2)), DELTA_UPDATE, node);

    VWrite(addr & ~0x3UL, data << ((addr & 0x2) * 8), NORMAL_UPDATE, node);
    
    VWrite(BYTE_EN_ADDR, 0xf, DELTA_UPDATE, node);
        
    VTick(ACCESS_LEN, node);

}

void write_byte(uint32_t addr, uint32_t data)
{
    VWrite(BYTE_EN_ADDR, (0x1 << (addr & 0x3)), DELTA_UPDATE, node);

    VWrite(addr & ~0x3UL, data << ((addr & 0x3) * 8), NORMAL_UPDATE, node);
    
    VWrite(BYTE_EN_ADDR, 0xf, DELTA_UPDATE, node);
        
    VTick(ACCESS_LEN, node);
}

uint32_t read_word(uint32_t addr)
{
    uint32_t word;

    VRead(addr & ~0x3, &word, NORMAL_UPDATE, node);
    VTick(ACCESS_LEN, node);

    return word;
}

uint32_t read_instr(uint32_t addr)
{
    uint32_t word;
    
    VWrite(BYTE_EN_ADDR, INSTR_ACCESS, DELTA_UPDATE, node);

    VRead(addr & ~0x3, &word, NORMAL_UPDATE, node);
    
    VWrite(BYTE_EN_ADDR, 0xf, DELTA_UPDATE, node);
    
    VTick(ACCESS_LEN, node);

    return word;
}

uint32_t read_hword(uint32_t addr)
{
    uint32_t word;

    VWrite(BYTE_EN_ADDR, (0x3 << (addr & 0x2)), DELTA_UPDATE, node);

    VRead(addr & ~0x3UL, &word, NORMAL_UPDATE, node);

    VWrite(BYTE_EN_ADDR, 0xf, DELTA_UPDATE, node);

    VTick(ACCESS_LEN, node);

    return word >> ((addr & 0x2UL) * 8);
}

uint32_t read_byte(uint32_t addr)
{
    uint32_t word;

    VWrite(BYTE_EN_ADDR, (1 << (addr & 0x3)), DELTA_UPDATE, node);

    VRead(addr & ~0x3UL, &word, NORMAL_UPDATE, node);

    VWrite(BYTE_EN_ADDR, 0xf, DELTA_UPDATE, node);

    VTick(ACCESS_LEN, node);

    return word >> ((addr & 0x3UL) * 8);
}
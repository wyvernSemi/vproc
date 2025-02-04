//=====================================================================
//
// VProc64Class.h                                      Date: 2025/02/03
//
// Copyright (c) 2025 Simon Southwell.
//
// This file is part of VProc.
//
// VProc is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// VProc is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with VProc. If not, see <http://www.gnu.org/licenses/>.
//
//=====================================================================
// C++ API class wrapper for VProc64 C API
//=====================================================================

#ifndef _VPROC64CLASS_H_
#define _VPROC64CLASS_H_

extern "C"
{
#include "VUser.h"
}

class VProc64
{
public:
         // Constructor
         VProc64      (const uint32_t   nodeIn) : node(nodeIn) {};

    // API methods
    int  write        (const uint64_t   addr,     const uint64_t    data, const int      delta=0)    {return VWrite64      (addr,  data, delta,  node);};
    int  read         (const uint64_t   addr,           uint64_t   *data, const int      delta=0)    {return VRead64       (addr,  data, delta,  node);};

    int  writeByte    (const uint64_t   byteaddr, const uint8_t     data, const int      delta=0)    {return VWriteBE64    (byteaddr & ~(0x7ULL), (uint64_t)data << (8*(byteaddr&0x7ULL)), 0x1 << (byteaddr&0x7ULL), delta, node);};
    int  writeHword   (const uint64_t   byteaddr, const uint16_t    data, const int      delta=0)    {return VWriteBE64    (byteaddr & ~(0x7ULL), (uint64_t)data << (8*(byteaddr&0x6ULL)), 0x3 << (byteaddr&0x6ULL), delta, node);};
    int  writeWord    (const uint64_t   byteaddr, const uint32_t    data, const int      delta=0)    {return VWriteBE64    (byteaddr & ~(0x7ULL), (uint64_t)data << (8*(byteaddr&0x4ULL)), 0xf << (byteaddr&0x4ULL), delta, node);};
    int  writeDword   (const uint64_t   byteaddr, const uint64_t    data, const int      delta=0)    {return VWriteBE64    (byteaddr & ~(0x7ULL), (uint64_t)data,                       0xff,                  delta, node);};

    int  readByte     (const uint64_t   byteaddr,       uint8_t    *data, const int      delta=0)    { int status; uint64_t word;
                                                                                                       status = VRead64(byteaddr & ~(0x7ULL), &word, delta, node);
                                                                                                       *data  = (uint8_t)((word >> (8*(byteaddr&0x7ULL))) & 0xffULL);
                                                                                                       return status;};

    int  readHword    (const uint64_t   byteaddr,       uint16_t   *data, const int      delta=0)    { int status; uint64_t word;
                                                                                                       status = VRead(byteaddr & ~(0x7ULL), &word, delta, node);
                                                                                                       *data  = (uint16_t)((word >> (8*(byteaddr&0x6ULL))) & 0xffffULL);
                                                                                                       return status;};

    int  readWord     (const uint64_t   byteaddr,       uint32_t   *data, const int      delta=0)    { int status; uint64_t word;
                                                                                                       status = VRead(byteaddr & ~(0x7ULL), &word, delta, node);
                                                                                                       *data  = (uint32_t)((word >> (8*(byteaddr&0x4ULL))) & 0xffffffffULL);
                                                                                                       return status;};

    int  readDword    (const uint64_t   byteaddr,       uint32_t   *data, const int      delta=0)    { int status; uint64_t word;
                                                                                                       status = VRead(byteaddr & ~(0x7ULL), &word, delta, node);
                                                                                                       *data  = word ;
                                                                                                       return status;};

    int  burstWrite      (const uint64_t   addr,           void    *data, const unsigned wordlen)    {return VBurstWrite64   (addr,      data, wordlen, node);};
    int  burstRead       (const uint64_t   addr,           void    *data, const unsigned wordlen)    {return VBurstRead64    (addr,      data, wordlen, node);};
    int  tick            (const uint32_t   ticks)                                                    {return VTick           (ticks,                    node);};
    void regIrq          (const pVUserIrqCB_t func)                                                  {       VRegIrq         (func,                     node);};
    void regUser         (const pVUserCB_t func)                                                     {       VRegUser        (func,                     node);};


    int  burstWriteBytes (const uint64_t   byteaddr,       void    *data, const unsigned bytelen) {unsigned foff, loff;
                                                                                                   unsigned wlen = calcWordLen(byteaddr, bytelen, foff, loff);
                                                                                                   for (int idx  = 0; idx < bytelen; idx++)
                                                                                                       ((uint8_t*)bytebuf)[idx + (byteaddr&0x7ULL)] = ((uint8_t*)data)[idx];

                                                                                                   return VBurstWriteBE64 (byteaddr & ~(0x7ULL),
                                                                                                                           bytebuf,
                                                                                                                           wlen,
                                                                                                                           (0xff << foff) & 0xff,
                                                                                                                           0xff >> ((loff == 7) ? 0 : (7 - loff)),
                                                                                                                           node);
                                                                                                   };

    int burstReadBytes   (const uint64_t   byteaddr,       void    *data, const unsigned bytelen) {unsigned foff, loff, wlen = calcWordLen(byteaddr, bytelen, foff, loff);

                                                                                                   int status = VBurstRead64((byteaddr & ~(0x7ULL)), bytebuf, wlen, node);

                                                                                                   for (int idx  = 0; idx < bytelen; idx++)
                                                                                                       ((uint8_t*)data)[idx] = ((uint8_t*)bytebuf)[idx + (byteaddr & 0x7)];
                                                                                                   return status;
                                                                                                  };

private:

    // VProc node number this object is accessing
    unsigned node;

    // Internal byte buffer
    uint32_t bytebuf [(MAXBURSTLEN+1) * 4];

    // Calculate the required word length, and first and last offsets, for given byte length with address offset
    unsigned calcWordLen(const uint64_t byteaddr, const unsigned bytelen, unsigned &foff, unsigned &loff) {
                 loff    = (byteaddr + bytelen - 1) & 0x7ULL;
                 foff    = byteaddr & 0x7ULL;
        int      diffoff = loff - foff;
        return bytelen/8 + ((diffoff < 0) ? 1 : 0) + ((bytelen%8) ? 1 : 0);
    };
};

#endif
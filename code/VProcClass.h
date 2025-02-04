//=====================================================================
//
// VProcClass.h                                       Date: 2023/12/29
//
// Copyright (c) 2023-2024 Simon Southwell.
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
// C++ API class wrapper for VProc C API
//=====================================================================

#ifndef _VPROCCLASS_H_
#define _VPROCCLASS_H_

extern "C"
{
#include "VUser.h"
}

class VProc
{
public:
         // Constructor
         VProc        (const uint32_t   nodeIn) : node(nodeIn) {};

    // API methods
    int  write        (const uint32_t   addr,     const uint32_t    data, const int      delta=0)    {return VWrite   (addr,  data, delta,  node);};
    int  read         (const uint32_t   addr,           uint32_t   *data, const int      delta=0)    {return VRead    (addr,  data, delta,  node);};

    int  writeByte    (const uint32_t   byteaddr, const uint8_t     data, const int      delta=0)    {return VWriteBE (byteaddr & ~(0x3), (uint32_t)data << (8*(byteaddr&0x3)), 0x1 << (byteaddr&0x3), delta, node);};
    int  writeHword   (const uint32_t   byteaddr, const uint16_t    data, const int      delta=0)    {return VWriteBE (byteaddr & ~(0x3), (uint32_t)data << (8*(byteaddr&0x2)), 0x3 << (byteaddr&0x2), delta, node);};
    int  writeWord    (const uint32_t   byteaddr, const uint32_t    data, const int      delta=0)    {return VWriteBE (byteaddr & ~(0x3),           data, 0xf, delta, node);};

    int  readByte     (const uint32_t   byteaddr,       uint8_t    *data, const int      delta=0)    { int status; uint32_t word;
                                                                                                       status = VRead(byteaddr & ~(0x3), &word, delta, node);
                                                                                                       *data  = (uint8_t)((word >> (8*(byteaddr&0x3))) & 0xff);
                                                                                                       return status;};

    int  readHword    (const uint32_t   byteaddr,       uint16_t   *data, const int      delta=0)    { int status; uint32_t word;
                                                                                                       status = VRead(byteaddr & ~(0x3), &word, delta, node);
                                                                                                       *data  = (uint16_t)((word >> (8*(byteaddr&0x2))) & 0xffff);
                                                                                                       return status;};

    int  readWord     (const uint32_t   byteaddr,       uint32_t   *data, const int      delta=0)    { int status; uint32_t word;
                                                                                                       status = VRead(byteaddr & ~(0x3), &word, delta, node);
                                                                                                       *data  = word;
                                                                                                       return status;};

    int  burstWrite      (const uint32_t   addr,           void    *data, const uint32_t wordlen)    {return VBurstWrite     (addr,      data, wordlen, node);};
    int  burstRead       (const uint32_t   addr,           void    *data, const uint32_t wordlen)    {return VBurstRead      (addr,      data, wordlen, node);};
    int  tick            (const uint32_t   ticks)                                                    {return VTick           (ticks,                    node);};
    void regIrq          (const pVUserIrqCB_t func)                                                  {       VRegIrq         (func,                     node);};
    void regUser         (const pVUserCB_t func)                                                     {       VRegUser        (func,                     node);};


    int  burstWriteBytes (const uint32_t   byteaddr,       void    *data, const uint32_t bytelen) {uint32_t foff, loff;
                                                                                                   uint32_t wlen = calcWordLen(byteaddr, bytelen, foff, loff);
                                                                                                   for (int idx  = 0; idx < bytelen; idx++)
                                                                                                       ((uint8_t*)bytebuf)[idx + (byteaddr&0x3)] = ((uint8_t*)data)[idx];

                                                                                                   return VBurstWriteBE   (byteaddr & ~(0x3),
                                                                                                                           bytebuf,
                                                                                                                           wlen,
                                                                                                                           (0xf << foff) & 0xf,
                                                                                                                           0xf >> ((loff == 3) ? 0 : (3 - loff)),
                                                                                                                           node);
                                                                                                   };

    int burstReadBytes   (const uint32_t byteaddr,         void    *data, const uint32_t bytelen) {uint32_t foff, loff, wlen = calcWordLen(byteaddr, bytelen, foff, loff);

                                                                                                   int status = VBurstRead ((byteaddr & ~(0x3)), bytebuf, wlen, node);

                                                                                                   for (int idx  = 0; idx < bytelen; idx++)
                                                                                                       ((uint8_t*)data)[idx] = ((uint8_t*)bytebuf)[idx + (byteaddr & 0x3)];
                                                                                                   return status;
                                                                                                  };

private:

    // VProc node number this object is accessing
    uint32_t node;

    // Internal byte buffer
    uint32_t bytebuf [(MAXBURSTLEN+1) * 4];

    // Calculate the required word length, and first and last offsets, for given byte length with address offset
    uint32_t calcWordLen(const uint32_t byteaddr, const uint32_t bytelen, uint32_t &foff, uint32_t &loff) {
                 loff    = (byteaddr + bytelen - 1) & 0x3;
                 foff    = byteaddr & 0x3;
        int      diffoff = loff - foff;
        return bytelen/4 + ((diffoff < 0) ? 1 : 0) + ((bytelen%4) ? 1 : 0);
    };
};

#endif
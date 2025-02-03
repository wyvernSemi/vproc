//=====================================================================
//
// VProc64IrqClass.h                                   Date: 2025/02/03
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
// C++ API interrupt handling class wrapper for VProc C API
//=====================================================================

#include "VProc64Class.h"

#ifndef _VPROC64CLASS_IRQ_H_
#define _VPROC64CLASS_IRQ_H_

class VProc64IrqClass : public VProc64
{
public:
    static const int MAXINTERRUPTS = 32;

    typedef void (*pIntFunc_t) (int);

    // Constructor
    VProc64IrqClass(const unsigned node = 0) :
        VProc64{node},
        interrupt_enable(0),
        isr_enable(0),
        int_active(0),
        irq(0),
        edgeTriggered(0)
        {
            for (int idx = 0; idx < MAXINTERRUPTS; idx++)
            {
                isr[idx] = NULL;
            }
        };

    // IRQ wrapper methods

    int tick (const int ticks)
    {
        int status = 0;

        // To reduce the latency until an interrupt service, ticks are broken down
        // into single cycle ticks and processIrq() called at each iteration.
        for (int count = 0; count < ticks; count++)
        {
            processIrq();
            status |= VProc64::tick(1);
        }

        return status;
    }

    int write (const uint64_t addr, const uint64_t data, const int delta = 0)
    {
        processIrq();
        return VProc64::write(addr, data, delta);
    }

    int writeByte (const uint64_t byteaddr, const uint8_t data, const int delta = 0)
    {
        processIrq();
        return VProc64::writeByte(byteaddr, data, delta);
    }

    int writeHword (const uint64_t byteaddr, const uint16_t data, const int delta = 0)
    {
        processIrq();
        return VProc64::writeHword(byteaddr, data, delta);
    }

    int writeWord (const uint64_t byteaddr, const uint32_t data, const int delta = 0)
    {
        processIrq();
        return VProc64::writeWord(byteaddr, data, delta);
    }

    int writeDword (const uint64_t byteaddr, const uint64_t data, const int delta = 0)
    {
        processIrq();
        return VProc64::writeDword(byteaddr, data, delta);
    }

    int burstWrite(const uint64_t addr, void *data, const unsigned len)
    {
        processIrq();
        return VProc64::burstWrite(addr, data, len);
    }
    
    int burstWriteBytes(const uint64_t byteaddr, void *data, const unsigned bytelen)
    {
        processIrq();
        return VProc64::burstWriteBytes(byteaddr, data, bytelen);
    }

    int readByte (const uint64_t byteaddr, uint8_t *data, const int delta = 0)
    {
        processIrq();
        return VProc64::readByte(byteaddr, data, delta);
    }

    int readHword (const uint64_t byteaddr, uint16_t *data, const int delta = 0)
    {
        processIrq();
        return VProc64::readHword(byteaddr, data, delta);
    }

    int readWord (const uint64_t byteaddr, uint32_t *data, const int delta = 0)
    {
        processIrq();
        return VProc64::readWord(byteaddr, data, delta);
    }
    
    int readDword (const uint64_t byteaddr, uint64_t *data, const int delta = 0)
    {
        processIrq();
        return VProc64::readWord(byteaddr, data, delta);
    }

    int burstRead(const uint64_t addr, void *data, const unsigned len)
    {
        processIrq();
        return VProc64::burstRead(addr, data, len);
    }
    
    int burstReadBytes(const uint64_t byteaddr, void *data, const unsigned bytelen)
    {
        processIrq();
        return VProc64::burstReadBytes(byteaddr, data, bytelen);
    }

    // Interrupt API methods

    void enableInterrupts  (void)                   {interrupt_enable = true;}
    void disableInterrupts (void)                   {interrupt_enable = false;}
    void enableIsr         (const unsigned int_num) {if (int_num < MAXINTERRUPTS && isr[int_num] != NULL) isr_enable |=  (1 << int_num);}
    void disableIsr        (const unsigned int_num) {if (int_num < MAXINTERRUPTS && isr[int_num] != NULL) isr_enable &= ~(1 << int_num);}
    void updateIrqState    (const uint32_t newirq)  {irq = newirq;}
    void registerIsr       (const pIntFunc_t isrFunc, const uint32_t level, const bool enable = false)
    {
        if (level < MAXINTERRUPTS)
        {
            isr[level] = isrFunc;
        }

        if (enable)
        {
            enableIsr(level);
        }
    }
    void setIrqAsEdgeTriggered (const uint32_t mask)     {edgeTriggered = mask;}
    void clearEdgeTriggeredIrq (const uint32_t level) {int_active &= ~((1 << level) & edgeTriggered);}

protected:

    // Nested vectored interrupt process method. irq assumed active high and 0 is highest priority.
    void processIrq()
    {
        // Only process if the master interrupt enable is true
        if (interrupt_enable)
        {
            // Set bits for any pending interrupts that are enabled and not active
            // and that has the interrupt request input
            uint32_t int_new_int = isr_enable & ~int_active & irq;

            // Priority inspect the interrupts for servicing (0 = highest)
            for (int isr_idx = 0; isr_idx < MAXINTERRUPTS; isr_idx++)
            {
                bool higher_active = int_active & (0xffffffffULL >> (MAXINTERRUPTS-isr_idx));

                // Map the index to a unary value
                uint32_t int_unary = 1 << isr_idx;

                // If IRQ low for indexed bit when active clear active state unless edge triggered
                if(int_active & ~irq & ~edgeTriggered & int_unary)
                {
                    // Clear the indexed ISR active bit
                    int_active &= ~int_unary;
                }

                // If a new interrupt at index and no active higher priority interrupt, process it
                if ((int_new_int & int_unary) && !higher_active)
                {
                    // Set the active bit for the interrupt
                    int_active |= int_unary;

                    // Select the ISR and call it.
                    if (isr[isr_idx] != NULL)
                    {
                        (*(isr[isr_idx]))(irq);
                    }
                }
            }
        }
    }

private:
    // Internal state
    bool       interrupt_enable;   // master interrupt enables
    uint32_t   isr_enable;         // vector isr enables
    uint32_t   irq;                // vector irq state
    uint32_t   int_active;         // interrupt active status vector
    uint32_t   edgeTriggered;      // Mark irq vector edge triggerd inputs
    pIntFunc_t isr[MAXINTERRUPTS]; // pointers to ISR functions
};

#endif

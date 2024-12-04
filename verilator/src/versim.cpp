// ====================================================================
// versim.cpp                                          Date: 2024/12/03
//
// Copyright (c) 2024 Simon Southwell
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
// ====================================================================

#include <verilated_fst_c.h>

#include "verilated.h"
#include "Vtest.h"

static VerilatedFstC *trace_p  = new VerilatedFstC;
static bool           do_flush = true;

//-----------------------------------------
// Flush FST wave output for use externally
//-----------------------------------------

void flushfst()
{
   do_flush = true;
}

//-----------------------------------------
// Verilator main function
//-----------------------------------------

int main(int argc, char** argv)
{
   // Setup context
   Verilated::debug(0);
   const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
   contextp->traceEverOn(true);
   
   // Parse command line
   contextp->commandArgs(argc, argv);
   
   // Construct the Verilator model from generated Vtest.h header
   const std::unique_ptr<Vtest> test_p{new Vtest{contextp.get()}};

   // Set up some  timing parameters
   trace_p->set_time_resolution("1ps");
   trace_p->set_time_unit("1ns");
   
   // Trace using trace_p object
   test_p->trace(trace_p, 20);
   
   // Open a wave form file
   trace_p->open("waves.fst");

   // Simulate until $finish or no events left to process
   while (!contextp->gotFinish())
   {
      // If an outstanding external request to flush, do so now and clear request
      if (do_flush)
      {
          trace_p->flush();
          do_flush = false;
      }
      
      // Evaluate model
      test_p->eval();
      
      // Dump travce information
      trace_p->dump(contextp->time());

      // If now events to process end the simulation.
      if (!test_p->eventsPending())
          break;
  
      // Advance time
      contextp->time(test_p->nextTimeSlot());
   }

   // Flag if exit not due to $finish call
   if (!contextp->gotFinish())
   {
      VL_DEBUG_IF(VL_PRINTF("+ Exiting due to no events left to process\n"););
   }

   // Close trace object
   trace_p->close();

   // Cleanup
   test_p->final();
   
   return 0;
}


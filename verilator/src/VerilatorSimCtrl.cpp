// ====================================================================
// VerilatorSimCtrl.cpp                                Date: 2024/12/03
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
// ===================================================================

#include "VProcClass.h"
#include "VerilatorSimCtrl.h"

// I'm node 0
static const int node = 0;

// ---------------------------------------------
// advance_relative_cycles()
// ---------------------------------------------

static inline void advance_relative_cycles (VProc *vp, uint32_t &cyc_count_now, const uint32_t cycles)
{
    // If no advancement simply return
    if (cycles == 0)
    {
        return;
    }

    // If cycles is more than 1, advance time by cycles minus 1, as
    // re-reading of the cycle count takes a cycle
    else if (cycles > 1)
    {
        vp->tick(cycles-1);
    }

    flushfst();

    // In the last cycle, read the simulation's cycle count
    vp->read(VSC_CYC_COUNT_ADDR, &cyc_count_now);
}

// ---------------------------------------------
// advance_absolute_cycles()
// ---------------------------------------------

static inline void advance_absolute_cycles (VProc *vp, uint32_t &cyc_count_now, const uint32_t cycles)
{

    // If already at or passed the requested absolute count, just return.
    if (cycles <= cyc_count_now)
    {
        return;
    }
    // If the count is more than one cycle in the future, tick for
    // the difference less one, as re-reading of the cycle count
    // takes a cycle
    else if ((cycles - cyc_count_now) > 1)
    {
        vp->tick((cycles - cyc_count_now));
    }

    flushfst();

    // In the last cycle, read the simulation's cycle count
    vp->read(VSC_CYC_COUNT_ADDR, &cyc_count_now);
}

// ---------------------------------------------
// advance_absolute_time()
// ---------------------------------------------

static inline void advance_absolute_time (VProc *vp, uint32_t &cyc_count_now, const uint32_t clk_period_ps, const double time, const int units)
{

    // Convert ps time to cycles, rounding up to always pass the specified time,
    // and subtracting 1, as cycle count runs from 0
    uint32_t cycles = (uint32_t)ceil(TIME2PS(time, units) / (double)clk_period_ps) - 1;

    advance_absolute_cycles(vp, cyc_count_now, cycles);
}

// ---------------------------------------------
// advance_relative_time
// ---------------------------------------------

static inline void advance_relative_time (VProc *vp, uint32_t &cyc_count_now, const uint32_t clk_period_ps, const double time, const int units)
{
    // Convert ps time to cycles, rounding up to always pass the specified time.
    uint32_t cycles = (uint32_t)ceil(TIME2PS(time, units) / (double)clk_period_ps);

    advance_relative_cycles(vp, cyc_count_now, cycles);
}

// ---------------------------------------------
// is_number()
// ---------------------------------------------

static bool is_number(const std::string& s)
{
    static const std::regex number_regex(R"(^[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?$)");

    return std::regex_match(s, number_regex);
}

// ---------------------------------------------
// parse_number()
// ---------------------------------------------

static bool parse_number (std::vector<std::string> &splitcmd, double &num, int &units)
{
    if (is_number(splitcmd.at(2)))
    {
        num = stod(splitcmd.at(2));

        // extract units
        if (splitcmd.size() < 4)
        {
            std::cout << "No units specified, defaulting to cycles" << std::endl;
            units = VSC_TIME_CYCLES;
        }
        else
        {
            if (splitcmd.at(3) == "ps")
                units = VSC_TIME_PS;
            else if (splitcmd.at(3) == "ns")
                units = VSC_TIME_NS;
            else if (splitcmd.at(3) == "us")
                units = VSC_TIME_US;
            else if (splitcmd.at(3) == "ms")
                units = VSC_TIME_MS;
            else if (splitcmd.at(3) == "s")
                units = VSC_TIME_S;
            else if (splitcmd.at(3) == "cycle" || splitcmd.at(3) == "cycles")
                units = VSC_TIME_CYCLES;
            else
            {
                std::cout << "  *** unrecognised units" << std::endl;
                return false;
            }
        }
    }
    else
    {
        std::cout << "  *** unrecognised time (units must be separated by a space)" << std::endl;
        return false;
    }

    return true;
}

// ---------------------------------------------
// print_prompt()
// ---------------------------------------------

static void print_prompt (uint32_t const cyc_count_now, const uint32_t clk_period_ps)
{
    double time_val = COUNT2NSF(cyc_count_now, clk_period_ps);
    std::string units = "ns";

    if (time_val > 1000.0)
    {
        time_val /= 1000.0;
        units = "us";
    }
    if (time_val > 1000.0)
    {
        time_val /= 1000.0;
        units = "ms";
    }
    if (time_val > 1000.0)
    {
        time_val /= 1000.0;
        units = "s";
    }

    std::cout << "@cycle " << cyc_count_now << " (" << time_val << " " << units <<") VerSimCtrl>";
}

// ---------------------------------------------
// parse_command()
// ---------------------------------------------

static int parse_command(const std::string &command, VProc *vp, uint32_t &cyc_count_now, const uint32_t clk_period_ps)
{
    bool is_relative_time;
    bool is_cycles;

    double num;
    int    units;

    std::stringstream ss(command);
    std::istream_iterator<std::string> begin(ss);
    std::istream_iterator<std::string> end;
    std::vector<std::string> splitcmd(begin, end);

    // Check for finish commands (no args)
    if (splitcmd.at(0) == "finish" ||
        splitcmd.at(0) == "quit"   ||
        splitcmd.at(0) == "exit")
    {
        std::cout << "  Exiting Verilator..." << std::endl << std::endl;
        vp->write(VSC_FINISH_ADDR, 1);
        return VSC_FINISHING;
    }
    else if (splitcmd.at(0) == "run"      || splitcmd.at(0) == "r" ||
             splitcmd.at(0) == "continue" || splitcmd.at(0) == "c")
    {
      // Check number of arguments
      if (splitcmd.size() < 3)
      {
          std::cout << "  *** too few arguments" << std::endl;
          return VSC_SYNTAX_ERR;
      }

      // parse action
      if (splitcmd.at(1) == "until" || splitcmd.at(1) == "to")
      {
          is_relative_time = false;
      }
      else if (splitcmd.at(1) == "for")
      {
          is_relative_time = true;
      }
      else
      {
          std::cout << "  *** Unrecognised directive" << std::endl;
          return VSC_SYNTAX_ERR;
      }

       if (parse_number(splitcmd, num, units))
       {
           // Run actions
           if (units == VSC_TIME_CYCLES)
           {
               uint32_t cycles = (uint32_t)ceil(num);

               if (is_relative_time)
               {
                   advance_relative_cycles(vp, cyc_count_now, cycles);
               }
               else
               {
                   advance_absolute_cycles(vp, cyc_count_now, cycles);
               }
           }
           else
           {
               if (is_relative_time)
               {
                   advance_relative_time (vp, cyc_count_now, clk_period_ps, num, units);
               }
               else
               {
                   advance_absolute_time (vp, cyc_count_now, clk_period_ps, num, units);
               }
           }
       }
    }
    else
    {
        std::cout << "  *** Unrecognised command" << std::endl;
        return VSC_SYNTAX_ERR;
    }

    return VSC_NO_ERROR;
}

// ---------------------------------------------
// Function to run gtkwave in a thread
// ---------------------------------------------

void rungtkwave (void)
{
    system("gtkwave -A waves.fst > gtkwave.log 2>&1");
}

// ---------------------------------------------
// Top level Verilator simulation control
// function
// ---------------------------------------------

void VerilatorSimCtrl (void)
{
    uint32_t    clk_period_ps;
    uint32_t    cyc_count_now;
    int         error = 0;

    std::string command;

    // Create a VProc API object for this node
    VProc *vp = new VProc(node);

    // Get the clock period and current cycle count (request wave flush after each command)
    vp->read(VSC_CLK_PERIOD_ADDR, &clk_period_ps); flushfst();
    vp->read(VSC_CYC_COUNT_ADDR,  &cyc_count_now); flushfst();

    std::thread thread_obj(rungtkwave);

    // Print initial prompt
    std::cout << std::fixed << std::showpoint << std::setprecision(3);
    std::cout << std::endl << "  Verilator Simulator Control console" << std::endl;
    std::cout << "  Clock period configured at " << clk_period_ps/1000.0 << " ns" << std::endl;
    std::cout << "  Cycle count starts from 0. Times reckoned at end of cycle." << std::endl << std::endl;
    print_prompt(cyc_count_now-1, clk_period_ps);

    // Loop reading lines from user input
    while(true)
    {
       // Read line into string
       std::getline(std::cin, command);
       if (!command.empty())
       {
           // Parse command
           if (error = parse_command(command, vp, cyc_count_now, clk_period_ps))
           {
               // If return code is that $finish is executed, break out of loop
               if (error == VSC_FINISHING)
               {
                   break;
               }
           }
           // Request flush of wave output
           flushfst();
       }

       // print prompt
       print_prompt(cyc_count_now-1, clk_period_ps);
    }
}

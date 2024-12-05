// ====================================================================
// VuserMain0.cpp                                      Date: 2024/12/03
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

#include "VUserMain0.h"

// I'm node 0
static const int node = 0;

// ---------------------------------------------
// MAIN ENTRY POINT FOR NODE 0
// ---------------------------------------------

extern "C" void VUserMain0 (void)
{
    VerilatorSimCtrl(node);

    SLEEPFOREVER;
}
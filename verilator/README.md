# Verilator Simulation Control Module

The Verilator simulor control module is a _VProc_ wrapper that allows control of the running simulation on the console command line from where
the test bench with the module instnatiated is run. It consists of a SystemVerilog module defined in `verilator/verilator_sim_ctrl.sv` with a 
single clock input (`clk`) and a clock count output (`clk_count`) for use by the test bench if desired. The only other inputs to the module are
from its parameters:

* `NODE`: the _VProc_ node number, which must be unique to any other _VProc_ block in the simulation
* `CLK_PERIOD_PS`: the period of the connected clock in picoseconds. This must be accurate to get correct timing output in the user console
* `DISABLE_SIM_CTRL`: When non-zero, disables the simultion control and the test bench runs as normal

## Software

The software to run on the _VProc_ is provided in `verilator/src/VerilatorSimCtrl.cpp` along with an associated header. In addition, there
is a `versim.cpp` file in the same directory which is the Verilator execution loop, required to have control from the `VerilatorSimCtrl`
software. The simulation is compiled with the `--cc` flag (in place of `--binary`) and the `versim.cpp` compiled as the `--exe` file containing
`main` and the simulation setup and execution loop.

To use the features the `verilator_sim_ctrl` module is instantiated in the test bench and the `clk` input connected yto the main system clock, or
any clock in which it is most useful to run to whole cycle boundaries. A node number must be picked to be unique in the simulation from any other
_VProc_ component. The corresponding _VProc_ user code must then be compiled that matches the configured node number, along with the
`VerilatorSimCtrl.cpp` code. The example below shows user code for node 0:

```
#include "VerilatorSimCtrl.h"

#define SLEEPFOREVER {while(1) VTick(0x7fffffff, node);}

// I'm node 0
static const int node = 0;

// ---------------------------------------------
// MAIN ENTRY POINT FOR NODE 0
// ---------------------------------------------

extern "C" void VUserMain0 (void)
{
    VerilatorSimCtrl();

    SLEEPFOREVER;
}
```

## Commands

The code above makes a simple call to a function `VerilatorSimCtrl()` that starts the Verilator Simulation Control features and prints some
information about the configuration and then a prompt. The user can then enter commands to run the simulation for a given time, relative to
current time, or to a given absolute time in the future. The list below shows the form of the commands available

`run|continue for <n> <units>`

`run|continue until|to <n> <units>`

`quit|exit|finish`

The `run` and `continue` commands are synonymous and used to advance the simulation to a new place in the timeline. It has two forms, either
relative to current time, using `for` or absolute time using `until` or `to`. Following the directive argument, a number is specified, either
as a whole number or a decimal number, to say how many units to advance ro to have let pass before stopping again. The `units` argument specifies
what to use for the number specified and must be one of the following:

* `cycles`: clock cycle count
* `ps`: picoseconds
* `ns`: nanoseconds
* `us`: microseconds
* `ms`: milliseconds
* `s`: seconds

The `cycles` units are self explanitory and is independent of the clock period configured. The other units are time units and will advance the
simulation the required number of cycles to meet that need. In all cases, decimal numbers may be specified, and if the target time is not a whole
fraction of a clock cycle, the simulation is advanced to be the nearest clock edge _after_ the target time, so that the time is definitely
included in the simulation output. If a time has been rounded up, then that becomes the new starting point for any relative time specifications.
The current cycle and its time equivalent are displayed as part of the console prompt, so it is clear where any relative time command is to start
from. If an absolute time is specified that is in the past, then no action is taken and the current cycle remains unchanged.

All command elements must be separated by one or more whitespace characters, including the units from the number. Any syntax errors are
reported to the console and no actions taken, with time remaining unchanged.

There are a set of commands that will end the simulation, calling `$finish` when executed. These are `quit`, `exit` and `finish`. These all do
the same thing and the simulation completes. A typical session might look like the following:

<p><img src="https://github.com/user-attachments/assets/403d93be-0f78-4ee0-abd3-5404125a618d" width=615)</p>

## Output

The `versim` code is set up to open a VCD file (`waves.vcd`) for output of signal data and this can be viewed whilst the simulation is running.
Currently this has been tested with `gtkwave`. `surfer` has been tried but this fails to load the data whilst the wave file is still open, and
this is under investigation. The `VerilatorSimCtrl` will open a `gtkwave` window when it starts and display the start of the waveform. This will
be 3 cycles into the simulation as there must be some minimal data for `gtkwave` to open properly with the VCD file, and also the code must read
the current cycle count and clock period information in order to proceed. The _VProc_ used has delta cycle updates disabled, so reading a
parameter takes a cycle. The `gtkwave` window will not update automatically when the simulation is paused, but a `CTRL+SHIFT+'R'` updates the
waves. The `-I` interactive features of `gtkwave` are currently under investigation to auto-update.

The VCD is kept up-to-date using the flushing capabilties of the Verilated trace object, and this is done at each point the simulation stops.
The `VerilatorSimCtrl` code calls a function in `versim.cpp` that raises a request to flush. The execution loop will do a flush at the beginning
of the next loop if the request is active and clear the request. Thread safety for updating and clearing the request (the _VProc_ code is running
in a seperate thread) is taken care of by the _VProc_ code. The diagram below summarises the setup as a whole:

<p><img src="https://github.com/user-attachments/assets/0f0502ca-a27f-4c46-94a8-a40690c90956" width = 800></p>

## Test Bench

A simple test bench is provided in `verilator/test` with a `test.v` top level generating a clock and instantiating the `verilator_sim_ctrl` 
module, connected to the clock. The `test` module has paramters to set the clock period (`CLKPERIODNS`) a time out in cycles (`TIMEOUT`) and 
a means to disable the simulation control (`DISABLE_SIM_CTRL`). The test bench makes use of the `cycle_count` output to detect timeout
conditions and end the simulation. As well as the `test.v` file, the `verilator_sim_ctrl.sv` and `f_VProc.sv` are included in the HDL
compilation in Verilator, and these are the only two required HDL files for simulation control.

A `makefile` is provided to compile and run the simulation which can then be controlled from the console where `make run` was executed. The 
`makefile` uses the _VProc_ `makefile.verilator` the top level `test` directory, providing it with the include path for the VerilatorSimCtrl
software and using the `AUXDIR` and `AUX_C` variables to specifu where the VerilatorSimCtrl code is located (`verilator/src`) and which files
to compile (`VerilatorSimCtrl.cpp`). The resultant `libvproc.a` will then include the VerilatorSimCtrl as well as the `VUserMain0.cpp` and the
_VProc_ code. This library is than part of the Verilator compilation, include in its `LDFLAGS` to link it with the generated Verilator code.

The `verilator_sim_ctrl` module in this test bench is configured as node 0, and the `VUserMain0` function is defined in 
`verilator/test/usercode/VUserMain0.cpp`, and is of the form shown perviously, making a simple call to `VerilatorSimCtrl()`.


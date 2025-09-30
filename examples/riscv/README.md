# RISC-V ISS model demonstration example

This directory contains an example of co-simulating a RISC-V instruction set simulator C++ model. _rv32_, on _VProc_ with a simple test HDL environment with models for memory, timer, and a terminal model with UART interface to display text, capable of running a program in the FreeRTOS operating system. The setup is shown in the diagram below:

<p align="center">
<img src="https://github.com/wyvernSemi/vproc/assets/21970031/4531f2a5-b620-4812-b9bb-162c4e98eb4b" width=700>
</p>

## Simple assembly code test

To run the simple assembly code test to generate an interrupt and invoke an ISR, `vusermain.cfg` should be configured as follows:

    vusermain0 -rbH -D disassem.log -t ./interrupt/test.exe

The `-r` option enables run-time disassembler output, with the `-D` option directing this to the file `disassem.log`. The `-b` option specifies to halt execution at a specific address (defaulting to `0x00000040`) and the `-H` option specifies to halt on decoding an unimplemented instruction. The `-t` option selects the compiled RISC-V test executable to be loaded and run.

To run the test on _Questa_ (or _Verilator_ with the optional argument), use the `make` command:

    make [-f makefile.verilator] run

## FreeRTOS test (_Verilator_ only)

This example uses the demo code from the _rv32_ [RISC-V ISS repository](https://github.com/wyvernSemi/riscV/tree/main/freertos) found on github. An executable is provided in this directory (`main.exe`), but to compile the code from the ISS repository use the folllowing make command:

    make USRFLAGS="-DCOSIM"

This compiles the demo program (`demo/main.c`), support functions and FreeRTOS configuration (`rv32/*.[ch]`) and FreeRTOS operating system. The resultant executable's text and read-only data is compiled at offset `0x00000000`, data and BSS at `0x00080000`, and with heap above and stack top at `0x00082000`. The `mtime` timer registers are configured in FreeRTOS to start from `0xaffffffe0`, and the UART driver code expects the terminal to start at `0x80000000`.

To run FreeRTOS demo, `vusermain.cfg` must be set as follows:

    vusermain0 -T -t ./main.exe

The `-T` option specifies to use an external model for the `mtime`/`mtimecmp` timer, rather than the internal ISS model for the timer. This directs accesses to the timer to the memory mapped bus, and the HDL timer model is then accessed.

### Run FreeRTOS demo forever
To run the simulation without a timeout, and without generating waveform data, use the `make` command:

    make -f makefile.verilator USRSIMFLAGS="-GTIMEOUTCOUNT=0 -GRISCVTEST=1" run

### Run FreeRTOS demo for 20ms in GUI mode
To run the demo for a given time (20ms in example), generating waveform data to be displayed in _gtkwave_, use the `make` command:

    make -f makefile.verilator USRSIMFLAGS="-GVCD_DUMP=1 -GTIMEOUTCOUNT=2000000 -GRISCVTEST=1" gui

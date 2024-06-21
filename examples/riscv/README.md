# RISC-V ISS model demonstration example

This directory contains an example of co-simulating a RISC-V instruction set simulator C++ model on VProc with a simple test HDL environment with models for memory, timer, and a terminal model with UART interface to display text, capable of running a program in the FreeRTOS operating system. The setup is shown in the diagram below:

<p align="center">
<img src="https://github.com/wyvernSemi/vproc/assets/21970031/4531f2a5-b620-4812-b9bb-162c4e98eb4b" width=700>
</p>

## Simple assembly code test

To run the simple assembly code test to generate an interrupt and invoke an ISR, <tt>vusermain.cfg</tt> should be configured as follows:

    vusermain0 -rbH -D disassem.log -t ./interrupt/test.exe

The <tt>-r</tt> option enables run-time disassembler output, with the <tt>-D</tt> option directing this to the file <tt>disassem.log</tt>. The <tt>-b</tt> option specifies to halt at a specific address (defaulting to <tt>0x00000040</tt>) and the <tt>-H</tt> option specifies to halt on decoding an unimplemented instruction. The <tt>-t</tt> option selects the compiled RISC-V test executable to be loaded and run.

To run the test, use the make command:

    make [-f makefile.verilator] run

## FreeRTOS test (verilator only)

This example uses the demo code fro the rv32 RISC-V ISS repository found on github: https://github.com/wyvernSemi/riscV/tree/main/freertos. An executable is provided in this directory (<tt>main.exe</tt>), but to compile the code from the ISS repository use the folllowing make command:

    make USRFLAGS="-DCOSIM"

This compiles the demo program (<tt>demo/main.c</tt>), support functions and FreeRTOS configuration (<tt>rv32/*.[ch]</tt>) and FreeRTOS operating system. The resultant executable's text and read-only data is compiled at offset <tt>0x00000000</tt>, data and BSS at <tt>0x00080000</tt>, and with heap above and stack top at <tt>0x00082000</tt>. The mtime timer registers are configured in FreeRTOS to start from <tt>0xaffffffe0</tt>, and the UART driver code expects the terminal to start at <tt>0x80000000</tt>.

To run FreeRTOS demo, vusermain.cfg must be set as follows:

    vusermain0 -T -t ./main.exe

The <tt>-T</tt> option specifies to use an external model for the mtime/mtimecmp timer, rather than the internal ISS model for the timer. This directs accesses to the timer to the memory mapped bus, and the HDL timer model is then accessed.

### Run FreeRTOS demo forever
To run the simulation without a timeout, and without generating waveform data, use the make command:

    make -f makefile.verilator USRSIMFLAGS="-GTIMEOUTCOUNT=0 -GRISCVTEST=1" run

### Run FreeRTOS demo for 20ms in GUI mode
To run the demo for a given time (20ms in example), generating waveform data to be displayed in gtkwave, use the make command:

    make -f makefile.verilator USRSIMFLAGS="-GVCD_DUMP=1 -GTIMEOUTCOUNT=2000000 -GRISCVTEST=1" gui

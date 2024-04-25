# VProc
Virtual processor co-simulation element for Verilog and VHDL environment. 

Allows native C/C++ programs or Python scripts to co-simulate with Verilog, SystemVerilog or VHDL simulations, with a memory mapped read/write interface and support to model interrupts. This enables virtually limitless possibilities for control of a simulation from C/C++ or Python programs, running as if on a virtual processor in the simulation. This could be simple linear test programs, software models of processors and other SoC components or embedded software, amongst other things. The software running on the virtual processor can be debugged using such things as <tt>gdb</tt> and related tools.

Currently supported simulators:

 * ModelSim : Verilog with PLI or VPI, VHDL with FLI
 * Questa : Verilog with PLI or VPI, VHDL with FLI
 * Icarus : Verilog with PLI or VPI
 * Vivado Xsim : SystemVerilog with DPI-C
 * Verilator : SystemVerilog with DPI-C
 * NVC : VHDL with VHPIDIRECT
 * GHDL : VHDL with VHPIDIRECT

More information can be found in the documentation located in <code>doc/VProc.pdf</code> and related articles on virtual processors, co-simulation and VProc can be found <a href="https://www.linkedin.com/pulse/vproc-virtual-processor-vip-simon-southwell-pjmpe">here</a> and <a href="https://www.linkedin.com/pulse/extending-power-logic-simulations-using-programming-part-southwell-1e">here</a> to complement the information in the manual.

<hr>

### VProc HDL component
<p align="center">
<img src="https://github.com/wyvernSemi/vproc/assets/21970031/9a1d49bd-7111-42df-adb2-76b19e099e35" width=600>
</p>
<hr>

### VProc stack with Python

<p align="center">
<img src="https://github.com/wyvernSemi/vproc/assets/21970031/9173c345-2589-4cfa-a92e-3fca53a74369" width=600>
</p>

Copyright &copy; 2024

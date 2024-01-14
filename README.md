# vproc
Virtual processor co-simulation element for Verilog and VHDL environment. 

Allows native C/C++ programs to co-simulate with verilog or VHDL simulations, with a memory mapped read/write interface and support to model interrupts. This enables virtually limitless possibilities for control of a simulation from C or C++ programs, running as if on a virtual processor in the simulation. This could be simple linear test programs, software models of processors and other SoC components or embedded software, amongst other things. The software running on the virtual processor can be debugged using <tt>gdb</tt> and related tools.

<p align="center">
<img src="https://github.com/wyvernSemi/vproc/assets/21970031/9a1d49bd-7111-42df-adb2-76b19e099e35" width=800>
</p>

More information can be found in the documentation in <code>doc/VProc.pdf</code> and related articles on virtual processors, co-simulation and VProc can be found <a href="https://www.linkedin.com/pulse/vproc-virtual-processor-vip-simon-southwell-pjmpe">here</a> and <a href="https://www.linkedin.com/pulse/extending-power-logic-simulations-using-programming-part-southwell-1e">here</a> to complement the information in the manual.

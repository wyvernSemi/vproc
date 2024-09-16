# Bus Functional Model Wrappers

This directory contains simple VProc VHDL and Verilog bus functional model wrappers for the Altera Avalon and AXI4 memory mapped interfaces. Both models support the basic single word write and read transactions, but burst operations are not yet implemented. The AXI wrappers implement the minimal bus compliant signalling for an AXI4 manager with the xPROT signals fixed at 0. The Avalon wrappers also support byte enable signalling.

<p>&nbsp;</p>

<p align=center>
<img src="https://github.com/user-attachments/assets/6c0f6a6f-6712-4db7-9888-b7b2fe88b4e8" width=650>
</p>

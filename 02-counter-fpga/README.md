# Basic FPGA Example

This exercise consists of running a simple Verilog counter on the FPGA.  The counter requires a clock, which can either be the basic incoming FPGA clock at 125 MHz, or else a pulse signal that can be driven manually using the VIO.

The purpose of this exercise is to introduce you to the basics of compiling and running a design on the FPGA board, as well as basic debugging using the Integrated Logic Analyzer (ILA) and manual control using the Virtual Input/Output (VIO) mechanism.

## Programming the FPGA

### What is a bitfile

FPGAs are programmed using a configuration file, which is a binary file that contains details of how the individual Lookup Tables (LUTs) and flip-flops (FFs) inside the FPGA are meant to be configured, and also details of how they are connected through the wiring/switching matrix inside the FPGA.  This configuration file is called a *bit stream*, and the corresponding file is called a *bitfile* (or *bit file* or *bitstream file*).

The instructions below (*How to run*) show what needs to be done to generate the bit file.  If you have a Linux based system with Xilinx Vivado software installed, then just running `make` in the `scripts` folder should create the file.  If you are working on a Windows based system, you can still use the scripts, but may need to open a command terminal to type in the commands.

## My Implementation Results

### Environment

* Tool: Xilinx Vivado 2025.1
* FPGA Clock: 125 MHz (8 ns period)

### Synthesis and Implementation

* Synthesis: Completed Successfully
* Implementation: Completed Successfully
* Bitstream Generation: Completed Successfully

### Timing Results

* WNS (Worst Negative Slack): 2.433 ns
* TNS (Total Negative Slack): 0.000 ns
* WHS: 0.022 ns
* THS: 0.000 ns

### Estimated Maximum Frequency

Critical Path Delay = 8.000 ns - 2.433 ns = 5.567 ns

Estimated Fmax:

Fmax ≈ 1 / 5.567 ns ≈ 179.6 MHz

### Power

* Total On-Chip Power: 0.118 W

### Observations

* Timing constraints were met successfully.
* No failed routes were reported.
* Bitstream was generated successfully and the design is ready for FPGA deployment.



### JTAG

The bit file is loaded into the FPGA using a *JTAG* cable.  JTAG is normally used for testing digital circuits - however, here we can also use it for directly programming the FPGA.  This requires direct access to the computer where the FPGA is connected, and so cannot be done in remote mode.

### What is a VIO

Virtual Input/Output: The same JTAG cable that is used for programming the FPGA is also used for controlling some debug related circuits.  In the present project, we have added two kinds of debugging hardware.  One is the VIO module.

VIO allows us to create certain *ports* - these ports can be set using instructions sent from the host PC, or can be read back into the host PC.  In our case, we will use some of the VIO ports to set the various control signals of the counter, and read back the counter value on one of the VIO input ports.

Note that the direction of ports is reversed:
- Output of your module goes as Input to the VIO
- Output of the VIO is fed as Input to your module

### What is an ILA

A logic analyzer is a digital equivalent of an oscilloscope: instead of displaying an analog waveform on screen, it monitors digital signals and indicates their logic values.  It can typically monitor entire buses together, and several 10s to 100s of signals can be monitored simultaneously.

The *Integrated Logic Analyzer* or ILA is a module provided by Xilinx that can be added to the hardware design.  It can be connected to various inputs of the system, and monitor their values.  Here we use an ILA to monitor the output of the counter under various operating conditions.  In particular, when the clock selected is the system clock, you can see the counter value updating on every clock cycle - this is much faster than what the VIO can monitor.

## How to run

The source code is in the `src/` folder.  Go through this to understand the required functionality of the counter.  

- `counter_top.sv`: top level module that includes the VIO and ILA for control and debug.  Required only for implementation on the FPGA.  In particular, this is not meant to be simulated, which is why it is distinct from the base module.
- `counter.sv`: you need to add this file from your solution to the problem in [01-counter](../01-counter/).

The folder `scripts/` contains several TCL scripts to create the project and generate the bit file.  This is because this approach is more structured than using Vivado.  In particular, since lab access does not provide you with a GUI but only a terminal, you cannot run the GUI version of Vivado.  

The scripts are hopefully easy enough to understand and modify if needed.  For now, the only real thing you need to do is type:

```sh
make
```

on the command line.  Assuming that you have the Xilinx tools set up properly in your system path, this should result in the files getting compiled, and finally a `.bit` file (bitstream) will be generated.

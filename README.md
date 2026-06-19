
## Work Completed

### 01-counter: Simple Counter Simulation
- Implemented a 4-bit up/down counter in SystemVerilog.
- Added support for asynchronous reset, load, enable, and up/down control.
- Completed the testbench with clock generation and multiple test cases.
- Verified the design on EDA Playground.
- All simulation test cases passed successfully.

### 02-counter-fpga: FPGA Counter with VIO and ILA
- Added the completed counter RTL into the FPGA project.
- Used the provided `counter_top.sv` file for FPGA implementation.
- Generated the Vivado project using the provided Tcl scripts.
- Integrated VIO for manual control of counter inputs.
- Integrated ILA for observing counter output signals.
- Fixed module-name mismatch by using `updown_counter`.
- Successfully completed synthesis, implementation, and bitstream generation.
- Vivado status: `write_bitstream Complete`.

### 03-pins: FPGA Pin Mapping Counter
- Studied XDC pin mapping for the PYNQ-Z1 FPGA board.
- Used physical board pins for counter control and LED output.
- Mapped counter signals such as clock pulse, reset, switch input, and LEDs through the XDC file.
- Prepared the design for board-level testing.
- Final hardware verification requires the physical FPGA board.

## Tools Used

- SystemVerilog / Verilog
- EDA Playground
- Icarus Verilog
- GTKWave
- Xilinx Vivado 2025.1
- Git and GitHub
- PYNQ-Z1 FPGA board target

## Current Status

- Counter simulation completed.
- FPGA VIO/ILA bitstream generated successfully.
- Pin mapping design prepared for board demonstration.
- Repository uploaded to GitHub.
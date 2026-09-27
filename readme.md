# 32-Bit Parameterized Execution Unit (ALU) & Verification Suite

A synthesizable 32-bit Arithmetic Logic Unit (ALU) implemented in Verilog, supporting 10 core operations along with dedicated condition flag detection logic. The design is verified using an automated, self-checking Python testbench framework integrated with Icarus Verilog.

## Features
- **Configurable Bit-Width:** Parameterized datapath (default: 32-bit).
- **Core Operations:**
  - Arithmetic: ADD, SUB
  - Bitwise Logic: AND, OR, XOR
  - Comparisons: SLT (Signed Less Than), SLTU (Unsigned Less Than)
  - Barrel Shifts: SLL (Shift Left Logical), SRL (Shift Right Logical), SRA (Shift Right Arithmetic)
- **Status & Condition Flags:**
  - `zero_flag`: Asserted when output is zero.
  - `negative_flag`: Follows the MSB of the result.
  - `carry_flag`: Captures carry-out during addition and active-low borrow during subtraction.
  - `overflow_flag`: Detects 2's complement signed overflow during addition/subtraction.

## Simulation & Waveform Inspection
Waveforms were captured and analyzed using GTKWave across critical corner cases:

![ALU Waveform](alu_waves_screenshot.png)

## Verification Flow
1. `verify_alu.py` generates corner-case (boundary values, overflow traps) and randomized test vectors.
2. The script compiles and executes `alu.v` and `tb_alu.v` via `iverilog` and `vvp`.
3. Hardware simulation output is automatically compared against an integer golden reference model in Python.
# DLX Assembler and Simulator

![Language](https://img.shields.io/badge/language-C%2B%2B17-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey)
![Status](https://img.shields.io/badge/status-Academic%20Lab%20Project-success)

A compact C++ toolchain for a DLX-like ISA:

- `dlx_asm.cpp` assembles `.dlx` source into instruction/data `.mif` memory images.
- `simulator.cpp` executes generated memory images and prints instruction-level traces.

This repository includes sample programs (`example1.dlx`, `example2.dlx`, `example3.dlx`, `dlxFactorial.dlx`) and pre-generated `.mif` outputs for quick verification.

## Table of Contents

- [Why this project is useful](#why-this-project-is-useful)
- [Project layout](#project-layout)
- [How users can get started](#how-users-can-get-started)
  - [Prerequisites](#prerequisites)
  - [Build](#build)
  - [Assemble a program](#assemble-a-program)
  - [Run the simulator](#run-the-simulator)
  - [DLX source format](#dlx-source-format)
- [Where users can get help](#where-users-can-get-help)
- [Who maintains and contributes](#who-maintains-and-contributes)

## Why this project is useful

- Provides a complete assembler-to-simulation workflow for DLX assembly in a compact codebase.
- Supports a broad set of arithmetic, logic, shift, compare, branch, and jump instructions.
- Produces Quartus/FPGA-friendly `.mif` files (`DEPTH=1024`, `WIDTH=32`, hex radix).
- Includes realistic sample programs, including factorial with function call/return (`JAL`, `JR`).
- Useful for architecture labs, ISA experimentation, and teaching basic compilation/simulation flow.

## Project layout

- `dlx_asm.cpp` — assembler (`.dlx` → `data.mif` + `code.mif`)
- `simulator.cpp` — DLX simulator (loads `.mif`, executes and traces)
- `example1.dlx`, `example2.dlx`, `example3.dlx`, `dlxFactorial.dlx` — sample programs
- `data*.mif`, `code*.mif` — assembled memory images
- `PDF Instructions/` — lab and DLX instruction reference PDFs
- `Submission/` — report assets and submission material

## How users can get started

### Prerequisites

- A C++17-compatible compiler (`g++`, `clang++`, or MSVC)
- Git (optional, for cloning)
- A terminal (PowerShell, CMD, Bash, etc.)

### Build

From the repository root:

```bash
g++ -std=c++17 -O2 -o dlx_asm.exe dlx_asm.cpp
g++ -std=c++17 -O2 -o simulator.exe simulator.cpp
```

On Linux/macOS, you can build without the `.exe` extension:

```bash
g++ -std=c++17 -O2 -o dlx_asm dlx_asm.cpp
g++ -std=c++17 -O2 -o simulator simulator.cpp
```

### Assemble a program

Assembler usage:

```bash
./dlx_asm <input>.dlx <data>.mif <code>.mif
```

Example:

```bash
./dlx_asm dlxFactorial.dlx dataFactorial.mif codeFactorial.mif
```

Expected output includes:

```text
Assembly complete.
```

### Run the simulator

Current simulator behavior loads `codeFactorial.mif` and `dataFactorial.mif` directly from the working directory.

```bash
./simulator
```

On Windows, run `./simulator.exe` if needed. The simulator prints an instruction trace and final result (for the factorial sample, `Final f = 120` when `n = 5`).

### DLX source format

Programs use `.data` and `.text` sections.

- `.data` line format:
  - `<symbol> <count> <v1> <v2> ...`
  - Example: `n 1 5`
- `.text` supports labels and instructions.
- Comments start with `;` and continue to end-of-line.

Minimal example:

```asm
.data
n       1   5
f       1   0

.text
        LW      R1, n(R0)
        ADDI    R2, R0, 1
        JAL     fact
        SW      f(R0), R2

done
        J       done
```

## Where users can get help

- Read assignment/instruction docs in [PDF Instructions/](PDF%20Instructions/):
  - [DLX_ArchitectureOverview.pdf](PDF%20Instructions/DLX_ArchitectureOverview.pdf)
  - [DLX_Instructions.pdf](PDF%20Instructions/DLX_Instructions.pdf)
  - [Lab2_DLX_Assembler.pdf](PDF%20Instructions/Lab2_DLX_Assembler.pdf)
- Use sample programs as references:
  - [example1.dlx](example1.dlx)
  - [example2.dlx](example2.dlx)
  - [example3.dlx](example3.dlx)
  - [dlxFactorial.dlx](dlxFactorial.dlx)
- Open issues or discussions in the repository: <https://github.com/talhashahzad12345/dlxAssembler>

## Who maintains and contributes

- **Maintainer**: Talha Shahzad (<talhashahzad12345@gmail.com>)
- **Repository**: <https://github.com/talhashahzad12345/dlxAssembler>

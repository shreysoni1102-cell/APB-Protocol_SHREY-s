
# APB Protocol using Verilog Design and Verification

A hands-on project focused on understanding and verifying the **AMBA Advanced Peripheral Bus (APB)** protocol using Verilog HDL and QuestaSim.

## Project Overview

This repository contains RTL design and testbench work for an APB slave interface. The goal is to understand APB transfers, implement protocol-related behavior, and verify the design through simulation.

## Objectives

- Understand APB protocol operation and transfer phases.
- Develop an APB slave using Verilog HDL.
- Practice RTL design and testbench development.
- Verify read and write transactions.
- Observe signal timing and protocol behavior using simulation waveforms.
- Improve debugging and design verification skills.

## Repository Structure

```text
APB-Protocol_SHREY-s/
??? RTL/          # Verilog RTL design files
??? TB/           # Testbench files
??? SIM/          # Simulation scripts and setup
??? .gitignore    # Ignore rules for temporary files
??? README.md     # Project documentation
```

## APB Signals

The project focuses on commonly used APB signals:

| Signal | Description |
|---|---|
| `PCLK` | APB clock |
| `PRESETn` | Active-low reset |
| `PSEL` | Selects the peripheral |
| `PENABLE` | Indicates the access phase |
| `PWRITE` | Selects read or write operation |
| `PADDR` | Address bus |
| `PWDATA` | Write data bus |
| `PRDATA` | Read data bus |
| `PREADY` | Indicates transfer completion |
| `PSLVERR` | Indicates a transfer error |
| `PSTRB` | Write byte strobes |

## Verification Focus

The design and testbench work explores APB behavior, including:

- Read and write transfers
- Setup and access phases
- Transfers with and without wait states
- Reset behavior
- Address validation and error responses
- Byte-strobe behavior
- Checking expected read data and control signals

The verification scope depends on the current RTL and testbench implementation.

## Tools and Technologies

- **HDL:** Verilog
- **Simulation:** QuestaSim
- **Version Control:** Git and GitHub

## Running the Simulation

1. Compile the required RTL files.
2. Compile the corresponding testbench.
3. Run the testbench in QuestaSim.
4. Inspect the simulation transcript and waveforms.
5. Compare the observed behavior with the expected APB protocol behavior.

The exact commands depend on the testbench and simulation files in the `SIM/` directory.

## Learning Outcomes

This project supports practical learning in RTL design, bus protocols, testbench development, waveform debugging, and design verification fundamentals.

## Author

**Shrey Soni**

GitHub: [shreysoni1102-cell](https://github.com/shreysoni1102-cell)


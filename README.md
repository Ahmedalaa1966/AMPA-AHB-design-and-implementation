# AMBA-AHB Design and Implementation

## Introduction

This project presents a synthesizable **AMBA AHB (Advanced High-performance Bus)** implementation developed in **SystemVerilog**. The design follows the AMBA AHB protocol specifications and supports communication between a single bus manager (master) and four subordinate (slave) devices through an address decoder and response multiplexing logic.

The project was validated through an extensive set of simulation test cases to ensure compliance with the AMBA AHB specification.

---

## Features

- Synthesizable SystemVerilog RTL
- Single Manager (Master)
- Four Subordinates (Slaves)
- Address Decoder
- Read Data Multiplexer
- HREADY Response Multiplexer
- HRESP Response Multiplexer
- Configurable address mapping
- Modular and scalable architecture

---

## Supported AHB Transactions

The implementation has been verified using the following transaction types:

### Single Transfers
- Single Write
- Single Read

### Incrementing Burst Transfers
- INCR4 Write Burst
- INCR4 Read Burst
- INCR8 Write Burst
- INCR8 Read Burst
- INCR16 Write Burst
- INCR16 Read Burst

### Wrapping Burst Transfers
- WRAP4 Write Burst
- WRAP4 Read Burst
- WRAP8 Write Burst
- WRAP8 Read Burst
- WRAP16 Write Burst
- WRAP16 Read Burst

### BUSY Transfer Support
The design correctly handles BUSY transfers during both:
- Write transactions
- Read transactions

### Wait-State Handling

The implementation fully supports slave wait states by correctly handling cases where **HREADY** remains LOW for one or more clock cycles during both write and read operations.

---

## Validation

The design has been validated through simulation to verify:

- Correct address decoding
- Proper slave selection (HSEL)
- Correct read/write data transfers
- Burst address generation
- Incrementing burst operation
- Wrapping burst operation
- BUSY transfer handling
- HREADY wait-state behavior
- HRESP propagation
- Read data multiplexing
- Protocol-compliant operation

---

# Repository Structure

```
AMBA-AHB-design-and-implementation
│
├── Architecture/
├── rtl/
├── Testbench/
├── Simulation/
├── Script/
├── Questasim transcript/
└── README.md
```

## Architecture

Contains the design documentation and architecture diagrams, including:

- Overall system architecture
- Master interface
- Slave interface
- Address decoder
- Bus interconnections
- Signal flow diagrams

---

## rtl

Contains the synthesizable SystemVerilog source files implementing the AMBA AHB bus, including:

- Top module
- Manager (Master)
- Subordinates (Slaves)
- Address decoder
- Read-data multiplexer
- HREADY multiplexer
- HRESP multiplexer
- Supporting RTL modules

---

## Testbench

Contains the complete SystemVerilog verification environment used to validate the RTL implementation.

This folder includes:

- Top-level testbench
- Stimulus generation
- Transaction tasks
- Test scenarios
- Functional checking

---

## Simulation

Contains simulation outputs and generated results, such as:

- Waveform screenshots
- Simulation captures
- Verification results

---

## Script

Contains automation scripts used for simulation.

Examples include:

- Compilation scripts
- Simulation scripts
- Waveform loading scripts
- Run scripts

---

## Questasim transcript

Contains transcript files generated during QuestaSim simulation runs, including:

- Compilation logs
- Simulation logs
- Debug output
- Error and warning messages

---

# Tools Used

- SystemVerilog
- QuestaSim

# Future Improvements

- Multi-master AHB support
- Bus arbitration
- AHB-to-APB bridge
- UVM verification environment
- Functional coverage
- SystemVerilog Assertions (SVA)

---

# Author

**Ahmed Alaa Mohamed**

Electrical and Communication Engineering

SystemVerilog RTL Design | Digital Design | ASIC Design

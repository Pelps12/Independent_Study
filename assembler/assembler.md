# Assembler How-To Guide

This guide explains how to use the provided assembler to convert assembly code into machine code for the target architecture.

---

## Table of Contents

1.  [Building the Assembler](#building-the-assembler)
2.  [Writing Assembly Code](#writing-assembly-code)

    - [Instruction Syntax](#instruction-syntax)
    - [Registers](#registers)
    - [Directives](#directives)

3.  [Running the Assembler](#running-the-assembler)
4.  [Full Instruction Set](#full-instruction-set)
5.  [Notes](#notes)

---

## Building the Assembler

1.  **Prerequisites**  
    Ensure `g++` is installed.
2.  **Compile**  
    Run the following command to build the assembler:

    bash

    CopyEdit

    `make`

    This generates an executable named `out`.

---

## Writing Assembly Code

### Instruction Syntax

- **General Format**

  css

  CopyEdit

  `[label:] OPCODE [operands]  [// comment]`

  Example:

  asm

  CopyEdit

  `Loop: addi $r1 $r1 0x1 // Increment R1`

- **Supported Instructions**

Instruction

Syntax

Description

`add`

`add $rd $rs $rt`

Add registers

`sub`

`sub $rd $rs $rt`

Subtract registers

`addi`

`addi $rt $rs imm`

Add immediate

`lw`

`lw offset($rb) $rd`

Load word from memory

`sw`

`sw offset($rb) $rd`

Store word to memory

`jump`

`jump label`

Jump to label (immediate)

`jump_l`

`jump_l label`

Jump to label and link

`beq`

`beq $rs $rt label`

Branch if equal

`int`

`int 0x01`

Trigger interrupt

`iret`

`iret`

Return from interrupt

`btsli`

`btsli $rd $rs imm`

Bit shift left immediate

`btsri`

`btsri $rd $rs imm`

Bit shift right immediate

`word`

`word value`

Define a data word

See the [Full Instruction Set](#full-instruction-set) for categorized types.

- **Immediate Values**  
  Use `0x` for hexadecimal (e.g., `0x1F`) or plain decimal (e.g., `31`).
- **Memory Access**  
  Use `offset($register)` syntax.  
  Example:

  asm

  CopyEdit

  `lw 16($r0) $r3`

  This loads from address `$r0 + 16` into `$r3`.

---

### Registers

- **General-Purpose Registers**  
  `$r0` to `$r12`, `$r25`, `$temp` (alias for `$r31`)
- **Special Registers**

Register

Purpose

`$sp`

Stack pointer

`$pc`

Program counter

`$lr`

Link register

`$int_p`

Interrupt pointer

`$axi_status`

AXI bus status

Refer to `assembler.cpp` for the full list.

---

### Directives

1.  **`section`** – Set the current address.  
    Example:

    asm

    CopyEdit

    `section 0x100`

2.  **Labels** – Define jump targets.  
     Example:

    asm

    CopyEdit

    `Loop:
addi $r1 $r1 1
jump Loop`

3.  **Data Definition** – Use `word` to embed raw values.  
    Example:

    asm

    CopyEdit

    `word 0xDEADBEEF`

---

## Running the Assembler

Run the assembler with an input file and specify the output file:

bash

CopyEdit

`make -B && ./out input.asm output.hex`

The generated `output.hex` contains the machine code in hexadecimal format.

---

## Full Instruction Set

Instruction

Type

Syntax

`add` / `sub`

ALU

`add $rd $rs $rt`

`addi` / `subi`

ALU

`addi $rt $rs imm`

`lw` / `sw`

MEM

`lw offset($rb) $rd`

`jump`

JUMP

`jump label`

`beq` / `bneq`

BRANCH

`beq $rs $rt label`

`word`

DATA

`word value`

`no-op`

NO_OP

`no-op`

Refer to `assembler.cpp` for the full mapping of opcodes and command types.

---

## Notes

- **Two-Pass Assembly**  
  Labels can be used before they are defined.
- **Branch Bug**  
  There must be a `no-op` after a label for correct execution in some cases.
- **Errors**  
  The assembler reports errors for:

  - Invalid syntax
  - Unknown instructions
  - Unresolved labels

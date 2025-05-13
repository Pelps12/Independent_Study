# Assembler How-To Guide

This guide explains how to use the provided assembler to convert assembly code into machine code for the target architecture.

## Table of Contents

1. [Building the Assembler](#building-the-assembler)
2. [Writing Assembly Code](#writing-assembly-code)

   - [Instruction Syntax](#instruction-syntax)
   - [Registers](#registers)
   - [Directives](#directives)

3. [Running the Assembler](#running-the-assembler)
4. [Full Instruction Set](#full-instruction-set)

---

## Building the Assembler

1. **Prerequisites**:
   Ensure `g++` is installed. No external libraries are required.

2. **Compile**:
   Run the following command to build the assembler:

   ```bash
   make
   ```

   This generates an executable named `./out`.

---

## Writing Assembly Code

### Instruction Syntax

- **General Format**:
  `[label:] OPCODE [operands] [// comment]`
  Example:
  `Loop: addi $r1 $r1 0x1 // Increment R1`

- **Supported Instructions**:

| Instruction | Syntax               | Description                           |
| ----------- | -------------------- | ------------------------------------- |
| `add`       | `add $rd $rs $rt`    | Add registers                         |
| `sub`       | `sub $rd $rs $rt`    | Subtract registers                    |
| `addi`      | `addi $rt $rs imm`   | Add immediate                         |
| `lw`        | `lw offset($rb) $rd` | Load word from memory                 |
| `sw`        | `sw offset($rb) $rd` | Store word to memory                  |
| `jump`      | `jump label`         | Jump to label (immediate)             |
| `jump_l`    | `jump_l label`       | Jump to label and link                |
| `beq`       | `beq $rs $rt label`  | Branch if equal                       |
| `int`       | `int 0x01`           | Trigger interrupt                     |
| `iret`      | `iret`               | Return from interrupt                 |
| `btsli`     | `btsli $rd $rs imm`  | Bit shift left immediate              |
| `btsri`     | `btsri $rd $rs imm`  | Bit shift right immediate             |
| `mov`       | `mov $dest $src`     | Move register to register (dest 1st)  |
| `movi`      | `movi $dest imm`     | Move immediate to register (dest 1st) |
| `word`      | `word value`         | Define a data word                    |

See Full Instruction List for more details.

- **Immediate Values**:
  Use `0x` for hexadecimal (e.g., `0x1F`) or decimal (e.g., `31`).

- **Memory Access**:
  Use `offset($register)` syntax:
  Example: `lw 16($r0) $r3` loads from address `$r0 + 16` into `$r3`.

### Registers

- **General-Purpose**: `$r0` to `$r12`, `$r25`, `$temp` (`$r31`).

- **Special Registers**:

| Register      | Purpose           |
| ------------- | ----------------- |
| `$sp`         | Stack pointer     |
| `$pc`         | Program counter   |
| `$lr`         | Link Register     |
| `$int_p`      | Interrupt pointer |
| `$axi_status` | AXI bus status    |

Full list in `assembler.cpp`.

### Directives

1. **`section`**: Set the current address.
   Example: `section 0x100` starts assembling at address `0x100`.

2. **Labels**: Define jump targets.
   Example:

   ```asm
   Loop:
     addi $r1 $r1 1
     jump Loop
   ```

3. **Data**: Use `word` to embed raw values.
   Example: `word 0xDEADBEEF` writes `0xDEADBEEF` to the current address.

---

## Running the Assembler

Execute the assembler with an input file and output file:

```bash
make -B && ./out input.asm output.hex
```

The generated `output.hex` contains machine code in hexadecimal format.

---

## Full Instruction List

| Instruction     | Type   | Syntax                             |
| --------------- | ------ | ---------------------------------- |
| `add` / `sub`   | ALU    | `add $rd $rs $rt`                  |
| `addi` / `subi` | ALU    | `addi $rt $rs imm`                 |
| `lw` / `sw`     | MEM    | `lw offset($rb) $rd`               |
| `jump`          | JUMP   | `jump label`                       |
| `beq` / `bneq`  | BRANCH | `beq $rs $rt label`                |
| `mov` / `movi`  | ALU    | `mov $dest $src`, `movi $dest imm` |
| `word`          | DATA   | `word value`                       |
| `no-op`         | NO_OP  | `no-op`                            |

Refer to `assembler.cpp` for the complete mapping of opcodes and command types.

---

## Notes

- **Two-Pass Assembly**: Labels can be used before they are defined.
- **Branch Bug**: There must be a `no-op` after a label.
- **Errors**: The assembler throws errors for invalid syntax, unknown instructions, or unresolved labels.

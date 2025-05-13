# Critical Pre-FPGA Step: Run Assembler First!

**⚠️ You MUST generate updated machine code before flashing!**  
The TCL script **cannot** create your program binary - it only flashes existing files. Go here to see how to generate the file in [assembler](https://github.com/Pelps12/Independent_Study/blob/main/assembler/assembler.md)

---

## Simplified Workflow

1. **Build Assembler**
   ```bash
   cd assembler && make
   ```
2. **Generate Machine Code**

   ```bash
   # Syntax: ./out <input.asm> <output.bin>
   ./out firmware.asm ../designs/memory.mem
   ```

3. **Run Vivado TCL Script**

   ```bash
   vivado -mode batch -source workflow.tcl
   ```

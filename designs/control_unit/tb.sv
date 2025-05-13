`timescale 1ns / 1ps

module Reg_File_tb;
    logic clk;
    logic rst;
    logic[4:0] op_code;
    logic zero, int_flag;
    logic [4:0] current_int_id;
    logic ack_start, ack_end;
    logic [4:0] ack_start_id, ack_end_id;

    logic i_or_d, mem_read, rom_read, mem_write, ir_write, alu_src_a,
        pc_sel, reg_write, global_jump, pc_to_mem, int_jump, int_write_addr_enable, int_flags_sw_clr,
        int_r_dest;

    logic[1:0] data_mux_sel, int_src_r1;
    logic[2:0] int_src_r2, alu_src_b, alu_op, pc_source, reg_data_sel, reg_dst;
    int debug_state;

    Control_Unit uut(
        .clk(clk),
        .rst(rst),
        .op_code(op_code),
        .zero(zero),
        .int_flag(int_flag),
        .current_int_id(current_int_id),
        .ack_start(ack_start),
        .ack_end(ack_end),
        .ack_start_id(ack_start_id),
        .ack_end_id(ack_end_id),
        .i_or_d(i_or_d),
        .mem_read(mem_read),
        .rom_read(rom_read),//
        .mem_write(mem_write),
        .ir_write(ir_write),
        .alu_src_a(alu_src_a),
        .pc_sel(pc_sel),
        .reg_write(reg_write),
        .global_jump(global_jump),
        .pc_to_mem(pc_to_mem),
        .int_src_r1(int_src_r1),
        .int_jump(int_jump),
        .int_write_addr_enable(int_write_addr_enable),
        .int_flags_sw_clr(int_flags_sw_clr),
        .int_r_dest(int_r_dest),
        .data_mux_sel(data_mux_sel),
        .alu_src_b(alu_src_b),
        .int_src_r2(int_src_r2),
        .reg_dst(reg_dst),
        .alu_op(alu_op),
        .pc_source(pc_source),
        .reg_data_sel(reg_data_sel)
    );

    initial
    begin
        // Open VCD file for waveform dumping
        $dumpfile("trace.vcd");
        $dumpvars(0, Reg_File_tb, uut); // Dump all signals in the testbench
    end

    initial clk = 0;
    always #20 clk = ~clk;

    initial begin
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #40;

        while (op_code < 'h16) begin
            if(uut.state == 32'h0) begin
                op_code = op_code + 1;
            end

            #40;
        end

        op_code = 0;
        int_flag = 1;
        #600;
        int_flag= 0;
        #200;
    
    
        $finish;
    end

    always_ff @(posedge clk) begin
        $display("CLK: %x, RST: %x, Op_Code: %x, Zero: %x, Int_Flag: %x, Current_Int_ID: %x, Ack_Start: %x, Ack_End: %x, Ack_Start_ID: %x, Ack_End_ID: %x, I_or_D: %x, Mem_Read: %x, Mem_Write: %x, IR_Write: %x, Alu_Src_A, %x, Pc_Sel: %x, Reg_Write: %x, Global_Jump: %x, Pc_to_Mem: %x, Int_Src_R1: %x, Int_Jump: %x, Int_Write_Addr_Enable: %x, Int_Flags_Sw_Clr: %x, Int_r_dest: %x, Data_Mux_Sel: %x, Alu_Src_B: %x, Int_Src_R2: %x, Reg_Dst: %x, Alu_Op: %x, Pc_Source: %x, Reg_Data_Sel: %x, State: %x", clk, rst, op_code, zero, int_flag, current_int_id, ack_start, ack_end, ack_start_id, ack_end_id, i_or_d, mem_read, mem_write, ir_write, alu_src_a, pc_sel, reg_write, global_jump, pc_to_mem, int_src_r1, int_jump, int_write_addr_enable, int_flags_sw_clr, int_r_dest, data_mux_sel, alu_src_b, int_src_r2, reg_dst, alu_op, pc_source, reg_data_sel, uut.state);
    end
    
endmodule
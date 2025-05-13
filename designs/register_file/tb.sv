`timescale 1ns / 1ps

module Reg_File_tb;
    logic clk;
    logic rst;
    logic [4:0] rs1_addr;
    logic[4:0] rs2_addr;
    logic[4:0] write_addr;
    logic[31:0] write_data;
    logic write_enable;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic[31:0] p_state;
    logic[31:0] pc_from_reg;
    logic[31:0] ivt_b_p;
    logic[4:0] current_int_id;
    logic gie;

    Registers uut(
        .clk(clk),
        .rst(rst),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_enable(write_enable),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .p_state(p_state),
        .pc_from_reg(pc_from_reg),
        .ivt_b_p(ivt_b_p),
        .current_int_id(current_int_id),
        .gie(gie)
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
        write_enable = 0;
        write_data = 32'h96;
        write_addr = 23;
        rs1_addr = 5;
        rs2_addr = 23;
        #20;
        rst = 1;
        #20;
        rst = 0;
        write_enable = 1;
        #40;
        write_addr = 32'h5;
        write_data = 32'h659;
    
        
        #1000;
        $finish;
    end
    
endmodule
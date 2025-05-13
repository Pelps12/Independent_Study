`timescale 1ns/1ps

module Mem_tb;

    // Clock signal
    logic clk;

    // Signals for Memory module
    logic mem_read;
    logic mem_write;
    logic rst;
    logic [31:0] addr;
    logic [31:0] write_data;
    logic [31:0] mem_data;

    // Clock generation
    initial begin
        clk = 1;
        forever #0.5 clk = ~clk; // 1ns period clock
    end

    // Memory instance
    Memory uut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .rst(rst),
        .addr(addr),
        .write_data(write_data),
        .mem_data(mem_data)
    );

    initial
    begin
        // Open VCD file for waveform dumping
        $dumpfile("trace.vcd");
        $dumpvars(0, Mem_tb, uut); // Dump all signals in the testbench
    end

    // Simulation
    initial begin
        // Reset sequence
        rst = 1;
        #1 rst = 0;

        // Read operation 1
        mem_read = 1;
        addr = 32'd512;
        #1;
        
        mem_read = 0;
        mem_write = 1;
        addr = 32'd200;
        write_data = 32'habc;
        #1;

        // Read operation 2
        mem_read = 1;
        mem_write = 0;
        addr = 32'd200;
        #1;
        
        

        // Finish simulation
        $finish;
    end

endmodule
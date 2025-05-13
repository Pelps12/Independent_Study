`timescale 1ns / 1ps

module IR_tb;
    logic clk, enable, rst;
    logic [31:0] data_in, data_out;

    Intermediate_Register uut(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out),
        .enable(enable)
    );

    initial
    begin
        // Open VCD file for waveform dumping
        $dumpfile("trace.vcd");
        $dumpvars(0, IR_tb, uut); // Dump all signals in the testbench
    end

    initial clk = 0;
    always #20 clk = ~clk;

    initial begin
        rst = 0;
        enable = 0;
        data_in = 32'h96;
        #20;
        rst = 1;
        #20;
        rst = 0;
        enable = 1;
        #1000;
        $finish;
    end
    
endmodule
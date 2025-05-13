`timescale 1ns / 1ps

module ALU_tb;

    logic [2:0] alu_op;
    logic [31:0] operand1;
    logic [31:0] operand2;

    logic zero;
    logic [31:0] result;



    // Instantiate the I2CPeripheral module
    ALU uut (
        .alu_op(alu_op),
        .operand1(operand1),
        .operand2(operand2),
        .zero(zero),
        .result(result)
    );



    initial
    begin
        // Open VCD file for waveform dumping
        $dumpfile("trace.vcd");
        $dumpvars(0, ALU_tb, uut); // Dump all signals in the testbench
    end

    // Testbench stimulus
    initial begin

        // Initialize signals
        alu_op = 03'b000;
        operand1 = 10;
        operand2 = 10;
        #20;            // Hold reset for 20 time units
        
        $finish;
    end

endmodule
`timescale 1ns / 1ps
module interrupt_tb;

    logic clk;
    logic rst, etic_flag_out, gie, int_flag_out;
    logic ack_start, ack_end;
    logic [31:0] interrupt_flags, interrupt_enables, interrupt_flags_sw, int_b_p, p_state, ivt_addr;
    logic [27:0] int_addr;
    logic [2:0] _priority, processor_priority;
    logic [4:0] int_ID, ack_end_id, ack_start_id, processor_int_ID;
    logic flag_signals[31:0], flag_signals_sw[31:0];

    // Clock generation
    initial begin
        clk = 1;
    end
    always #0.5 clk = ~clk;

    assign processor_int_ID = p_state[5:1];

    initial
    begin
        // Open VCD file for waveform dumping
        $dumpfile("trace.vcd");
        $dumpvars(0, interrupt_tb, uut, int_decider); // Dump all signals in the testbench
    end

    // Module instantiations
    Interrupt_Controller uut (
        .rst(rst),
        .int_flag(etic_flag_out),
        .int_ID(int_ID),
        ._priority(_priority),
        .gie(gie),
        .ack_end(ack_end),
        .ack_start(ack_start),
        .ack_end_id(ack_end_id),
        .ack_start_id(ack_start_id),
        .flag_signals(flag_signals),
        .flag_signals_sw(flag_signals_sw)
    );

    Interrupt_Decider int_decider (
        .processor_int_ID(processor_int_ID),
        .gie(p_state[0]),
        .ivt_b_p(int_b_p),
        .int_ID(int_ID),
        .int_flag_in(etic_flag_out),
        .ivt_addr(ivt_addr),
        .int_flag_out(int_flag_out)


    );

    // Testbench logic
    initial begin
        rst = 1;
        gie = 1;
        ack_start = 0;
        ack_end = 0;
        int_b_p = 200;
        p_state = 32'hF00000FF;

        // Wait for some time
        #1;
        rst = 0;

        // Trigger interrupts
        flag_signals[2] = 1;
        flag_signals[5] = 1;
        interrupt_enables = 32'hFFFFFFFF;
        interrupt_flags_sw = 32'h80000000;

        #1;
        flag_signals[2] = 0;
        flag_signals[5] = 0;

        #4.75;
        gie = 0;
        ack_start = 1;
        ack_start_id = 5'd2;
        p_state = 0;

        #1;
        ack_end = 1;

        #1;
        ack_start = 0;

        #1;
        gie = 1;

        #7;
        ack_end = 1;
        ack_end_id = 5'd2;

        #1;
        p_state = 32'hF00000FF;

        #5;
        ack_start = 1;
        ack_start_id = 5'd5;

        #4;
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype none

module mux_tb;
logic [31:0] in1, in2, in3, in4, out;
logic[1:0] sel;

 
Mux_4x1 uut(
    .in1(in1),
    .in2(in2),
    .in3(in3),
    .in4(in4),
    .sel(sel),
    .out(out)
);


initial begin
    $dumpfile("mux_tb.vcd");
    $dumpvars(0, mux_tb, uut);
end

initial begin
    in1 = 54;
    in2 = 67;
    in3 = 89;
    in4 = 68;
    sel = 0;
    #20;
    for (int i  = 0; i < 4; i = i + 1) begin
        sel = sel + 1;
        #20;
    end
end

endmodule

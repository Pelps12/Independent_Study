module Mux_2x1 #(
    parameter N = 32
) (
    input logic [N-1:0] in1,
    input logic [N-1:0] in2,
    input logic  sel,
    output logic[N-1:0] out
);

always_comb begin
    if (sel) begin
        out = in2;
    end
    else begin
        out = in1;
    end
end
    
endmodule
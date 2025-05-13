/* verilator lint_off MULTITOP */
module Mux_3x1 #(
    parameter N = 32
) (
    input logic [N-1:0] in1,
    input logic [N-1:0] in2,
    input logic [N-1:0] in3,
    input logic [1:0] sel,
    output logic[N-1:0] out
);

always_comb begin
    case (sel)
        2'b00: begin
            out = in1;
        end
        2'b01: begin
            out = in2;
        end
        2'b10: begin
            out = in3;
        end
        default: begin
            $error("Not even possible");
        end
    endcase
end
    
endmodule


module Mux_4x1 #(
    parameter N = 32
) (
    input logic [N-1:0] in1,
    input logic [N-1:0] in2,
    input logic [N-1:0] in3,
    input logic [N-1:0] in4,
    input logic [1:0] sel,
    output logic[N-1:0] out
);

always_comb begin
    case (sel)
        2'b00: begin
            out = in1;
        end
        2'b01: begin
            out = in2;
        end
        2'b10: begin
            out = in3;
        end
        2'b11: begin
            out = in4;
        end
        default: begin
            $error("Not even possible");
        end
    endcase
end
    
endmodule


module Mux_6x1 #(
    parameter N = 32
)(
    input logic [N-1:0] in1,
    input logic [N-1:0] in2,
    input logic [N-1:0] in3,
    input logic [N-1:0] in4,
    input logic [N-1:0] in5,
    input logic [N-1:0] in6,
    input logic [2:0] sel,
    output logic [N-1:0] out
);

always_comb begin
    case (sel)
        3'b00: begin
            out = in1;
        end
        3'b01: begin
            /* verilator lint_off WIDTHEXPAND */
            out = in2;
        end
        3'b10: begin
            out = in3;
        end
        3'b11: begin
            out = in4;
        end
        3'b100: begin
            /* verilator lint_off WIDTHEXPAND */
            out = in5;
        end
        3'b101: begin
            out = in6;
        end
        default: begin
            out = 0;
            $error("Not even possible");
        end
    endcase
end
    
endmodule


module Mux_5x1#(
    parameter N = 32
)(
    input logic [N-1:0] in1,
    input logic [N-1:0] in2,
    input logic [N-1:0] in3,
    input logic [N-1:0] in4,
    input logic [N-1:0] in5,
    input logic [2:0] sel,
    output logic [N-1:0] out
);

always_comb begin
    case (sel)
        3'b00: begin
            out = in1;
        end
        3'b01: begin
            /* verilator lint_off WIDTHEXPAND */
            out = in2;
        end
        3'b10: begin
            out = in3;
        end
        3'b11: begin
            out = in4;
        end
        3'b100: begin
            /* verilator lint_off WIDTHEXPAND */
            out = in5;
        end
        default: begin
            out = 0;
            $error("Not even possible");
        end
    endcase
end
    
endmodule

module Mux_7x1#(
    parameter N = 32
)(
    input logic [N-1:0] in1,
    input logic [N-1:0] in2,
    input logic [N-1:0] in3,
    input logic [N-1:0] in4,
    input logic [N-1:0] in5,
    input logic [N-1:0] in6,
    input logic [N-1:0] in7,
    input logic [2:0] sel,
    output logic [N-1:0] out
);

always_comb begin
    case (sel)
        3'b00: begin
            out = in1;
        end
        3'b01: begin
            /* verilator lint_off WIDTHEXPAND */
            out = in2;
        end
        3'b10: begin
            out = in3;
        end
        3'b11: begin
            out = in4;
        end
        3'b100: begin
            /* verilator lint_off WIDTHEXPAND */
            out = in5;
        end
        3'b101: begin
            out = in6;
        end
        5'b110: begin
            out = in7;
        end
        default: begin
            out = 0;
            $error("Not even possible");
        end
    endcase
end
    
endmodule
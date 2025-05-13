module ALU(
    input logic [2:0] alu_op,
    input logic [31:0] operand1,
    input logic [31:0] operand2,

    output logic zero,
    output logic [31:0] result
);

assign zero = (result == 0);

    always_comb begin : calculation

        case (alu_op)
            3'b000: begin
                result = operand1 + operand2;
            end
            3'b001: begin
                result = operand1 - operand2;
            end
            3'b010: begin
                result = operand1 & operand2;
            end
            3'b011: begin
                result = operand1 | operand2;
            end
            3'b100: begin
                result = operand1 ^ operand2;
            end
            3'b101: begin
                result = ~operand1;
            end
            3'b110: begin
                result = operand1 <<< operand2;
            end
            3'b111: begin
                result = operand1 >>> operand2;
            end
            
            default: begin
                result = 0;
                $error("Invalid ALU Op Code");
            end
        endcase
    end
    
endmodule
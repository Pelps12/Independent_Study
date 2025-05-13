module Intermediate_Register #(parameter N = 32, parameter initial_value = 0)(
    input logic clk,    
    input logic rst,
    input logic enable,
    input logic [N-1:0] data_in,
    output logic [N-1:0] data_out
);

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        data_out <= initial_value;
    end
    else begin
        //$display("Let's look: Enable: %b Value: %h", enable, data_in);
        if (enable) begin
            data_out <= data_in;
        end
        
    end   
end

    
endmodule
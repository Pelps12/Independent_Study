module Clock (
    input logic clk,
    input logic rst,
    output logic led
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        led = 0;
    end
    else begin
        led = ~led;
    end
end
    
endmodule
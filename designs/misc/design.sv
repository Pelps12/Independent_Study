/* verilator lint_off MULTITOP */

module Ack_Start_Module (
    input logic clk,
    input logic rst,
    input logic [4:0] int_ID,
    input logic ack_start_in,
    output logic ack_start,
    output logic[4:0] ack_start_id
);

assign ack_start = ack_start_in;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        ack_start_id = 0;
    end
    else begin
        if (ack_start_in) begin
            ack_start_id = int_ID;
        end
        else begin
            ack_start_id = 0;
        end
    end
end
    
endmodule

module Ack_End_Module (
    input logic clk,
    input logic rst,
    input logic [4:0] int_ID,
    input logic ack_end_in,
    output logic ack_end,
    output logic[4:0] ack_end_id
);

assign ack_end = ack_end_in;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        ack_end_id = 0;
    end
    else begin
        if (ack_end_in) begin
            ack_end_id = int_ID;
        end
        else begin
            ack_end_id = 0;
        end
    end
end
    
endmodule


module Decoder #(
    parameter N = 32,
    parameter ADDR_WIDTH = 5 // log2(N)
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic [ADDR_WIDTH-1:0] in,
    input  logic                   enable,
    output logic [N-1:0]           sw_flag
);

    logic [N-1:0] sw_flag_reg;

    // Output assignment
    assign sw_flag = sw_flag_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sw_flag_reg  <= '0;
        end else begin
            sw_flag_reg <= '0;
            if (enable) begin
                sw_flag_reg[in] <= 1'b1; // 1-cycle pulse    
            end
        end
    end

endmodule

module WDT_Basic #(
    // Clock frequency in Hz
    parameter integer CLK_FREQ_HZ   = 3_000_000,  
    // Width of the counter: enough bits to hold CLK_FREQ_HZ-1
    parameter integer CNT_WIDTH     = $clog2(CLK_FREQ_HZ)
)(
    input  logic               clk,      // 3 MHz clock
    input  logic               rst_n,    // active-low reset
    output logic               pulse_1s  // goes high for one clk tick every 1 s
);

    // Maximum count value
    localparam integer MAX_COUNT = (CLK_FREQ_HZ) - 1;

    // Counter register
    logic [CNT_WIDTH-1:0] count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count     <= '0;
            pulse_1s  <= 1'b0;
        end else begin
            if (count == MAX_COUNT[CNT_WIDTH-1:0]) begin
                count     <= '0;
                pulse_1s  <= 1'b1;   // one-cycle pulse
            end else begin
                count     <= count + 1;
                pulse_1s  <= 1'b0;
            end
        end
    end

endmodule
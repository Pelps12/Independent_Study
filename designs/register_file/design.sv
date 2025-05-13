module Registers #(
    parameter PC = 32'h200,
    parameter SP = 32'd500
) (
    input logic clk,
    input logic rst,
    input logic[4:0] rs1_addr,
    input logic[4:0] rs2_addr,
    input logic[4:0] write_addr,
    input logic[31:0] write_data,
    input logic write_enable,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic[31:0] p_state,
    output logic[31:0] pc_from_reg,
    output logic[31:0] ivt_b_p,
    output logic[4:0] current_int_id,
    output logic gie,
    output logic counter_flag,
    output logic zero_valid
);


logic [31:0] regs[0:31];
assign current_int_id = regs[25][4:0]; // This could be merged with processor state
assign p_state = regs[27];
assign gie = regs[27][0];
assign ivt_b_p = regs[28];
assign pc_from_reg = regs[23];
assign zero_valid = regs[29] == 0;

always_comb begin : Read_Block
    if (rst) begin
        rs1_data = 0;
        rs2_data = 0;
    end
    else begin
        rs1_data = regs[rs1_addr];
        rs2_data = regs[rs2_addr];
    end
end

always_ff @( posedge clk, posedge rst ) begin : Counter_Block
    if (rst) begin
        counter_flag <= 0;
    end
    else begin
        counter_flag <= (regs[5'h04] == 32'hA);
    end
end

always_ff @( posedge clk, posedge rst ) begin : Write_Block
    if (rst) begin
        for (integer i = 0; i < 32; i = i + 1) begin
            regs[i] = 0;
        end
        regs[23] = PC;
        regs[27] = 32'hF;
        regs[30] = SP;
        regs[25] = 32'd31;
    end
    

    else begin
        if (write_enable) begin
            `ifndef SYNTHESIS
                if (write_addr == 5'd23) begin
                    $display("PC: %x, Value: %x", write_addr, write_data);
                end
            `endif
            if (write_addr != 5'd20 || write_addr != 5'd17) begin
                regs[write_addr] = write_data;
            end
        end
    end
end
    
endmodule
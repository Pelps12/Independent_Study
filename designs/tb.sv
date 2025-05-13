`timescale 1ns/1ps
`include "i2c/design.sv"

module tb_computer;
reg clk, axi_clk;
reg rst;
logic if_flag;
logic correct_instruction_flag, clk_out, counter_flag, gie;
logic int_pulse, int_read,int_flag_out, int_flag, p_state_correct, zero_valid;
wire sda, scl, iic2intc_irpt_0;

i2c_slave #(.ADDR(7'h34)) slave(
    .SCL(scl),
    .SDA(sda),
    .RST(rst)
);

Computer_Wrapper uut 
(
    .s_clk(clk),
    .rst(rst),
    .axi_clk(axi_clk),
    .if_flag(if_flag),
    .correct_instruction_flag(correct_instruction_flag),
    .clk_out(clk_out),
    .counter_flag(counter_flag),
    .int_read(int_read),
    .gie(gie),
    .int_flag_out(int_flag_out),
    .int_flag(int_flag),
    .p_state_correct(p_state_correct),
    .zero_valid(zero_valid),
    .sda(sda),
    .scl(scl),
    .iic2intc_irpt_0(iic2intc_irpt_0)
);



initial clk = 0;
initial axi_clk = 0;
always #41.67 clk = ~clk;       // ~12 MHz
always #5 axi_clk = ~axi_clk;

initial begin
    $dumpfile("tb_computer.vcd");
    $dumpvars(0, tb_computer, uut);
end

    // I2C pull-up resistors
    pullup(scl);
    pullup(sda);

initial begin
    rst = 0;
    #4000;
    rst = 1;
    #1600;
    rst = 0;
    //slave.regs[5] = 'haa;

/*     wait(axi_awvalid && axi_wvalid);
    #2500;
    axi_awready = 1;
    axi_wready = 1;
    wait(axi_bready);
    #2500;
    axi_awready = 0;
    axi_wready = 0;
    axi_bvalid = 1;

    $display("YESSSSSSS"); */
    //int_pulse = 1;
    #100000000;
    $finish;
end

endmodule
`default_nettype wire
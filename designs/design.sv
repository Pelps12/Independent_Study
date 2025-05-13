`include "intermmediate_register/design.sv"
`include "control_unit/design.sv"
`include "mux_4x1/design.sv"
`include "mux_2x1/design.sv"
`include "memory/design.sv"
`include "register_file/design.sv"
`include "alu/design.sv"
`include "interrupt_controller/design.sv"
`include "misc/design.sv"


module level_to_pulse (
    input  wire clk,      // system clock
    input  wire rstn,     // active‐low reset
    input  wire level,    // incoming level signal
    output reg  pulse     // one‐cycle pulse when level goes high
);

    // register to hold previous cycle’s value of level
    reg level_d;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            level_d <= 1'b0;
            pulse   <= 1'b0;
        end else begin
            // pulse is high for exactly one clock when level transitions 0→1
            pulse   <= level & ~level_d;
            // capture current level for next comparison
            level_d <= level;
        end
    end

endmodule

module Computer_Wrapper (
    input logic s_clk,
    input logic rst,
    output logic if_flag,
    output logic correct_instruction_flag,clk_out, counter_flag, int_read, gie, 
    int_flag_out, int_flag, p_state_correct, zero_valid,
    inout wire scl,
    inout wire sda,
    input logic axi_clk,
    output wire iic2intc_irpt_0
);

    logic [4:0] ack_start_id, ack_end_id, current_int_id, input_int_id;
    logic ack_start, ack_end, clk_2, clk_4, clk_8;
    logic [2:0] _priority;
    logic flag_signals_sw[31:0], flag_signals[31:0];
    logic[31:0] p_state, axi_wdata, int_sw_flags;
    logic i2c_pulse, pulse_1s;
    logic [8:0] axi_addr;
    

    level_to_pulse ll(
        .clk(clk_4),
        .rstn(~rst),
        .level(iic2intc_irpt_0),
        .pulse(i2c_pulse)
    );


    
    // Inputs
    reg [8:0] S_AXI_0_araddr;
    reg [8:0] S_AXI_0_awaddr;
    reg S_AXI_0_arvalid;
    reg S_AXI_0_awvalid;
    reg S_AXI_0_bready;
    reg S_AXI_0_rready;
    reg [31:0] S_AXI_0_wdata;
    reg [3:0] S_AXI_0_wstrb;
    reg S_AXI_0_wvalid;
    reg clk_in1_0;
    
    logic[31:0] data, pc_from_reg;

    // Outputs
    wire S_AXI_0_arready;
    wire S_AXI_0_awready;
    wire [1:0] S_AXI_0_bresp;
    wire S_AXI_0_bvalid;
    wire [31:0] S_AXI_0_rdata;
    wire [1:0] S_AXI_0_rresp;
    wire S_AXI_0_rvalid;
    wire S_AXI_0_wready;
    wire [0:0] gpo_0;
    

    assign clk_out = clk_2;
    assign flag_signals[2] = i2c_pulse;
    assign flag_signals[1] = pulse_1s;
    //assign flag_signals[2] = int_pulse;
    assign p_state_correct = current_int_id == 5'd31;

    always_ff @( posedge s_clk, posedge rst ) begin 
        if (rst) begin
            clk_2 <= 0;
        end
        else begin
            clk_2 <= ~clk_2;
        end
        
    end
    always_ff @( posedge clk_2, posedge rst ) begin
        if (rst) begin
            clk_4 <= 0;
        end
        else begin
            clk_4 <= ~clk_4;
        end
    end
    always_ff @( posedge clk_4, posedge rst ) begin
        if (rst) begin
            clk_8 <= 0;
        end
        else begin
            clk_8 <= ~clk_8;
        end
    end

    // …after instantiating ic, do:
    genvar i;
    generate
    for (i = 0; i < 32; i++) begin : PACK_UNPACK
        // pack array into vector
        //assign int_sw_flags[i]    = flag_signals_sw[i];
        // if you ever need the other direction:
        assign flag_signals_sw[i] = int_sw_flags[i];
    end
    endgenerate
    


    ila_0 ila_computer (
        .clk(axi_clk), // input wire clk
         .probe0(i2c_pulse), // input wire [0:0]  probe0  
        .probe1(pulse_1s), // input wire [0:0]  probe1 
        .probe2(p_state_correct), // input wire [0:0]  probe2 
        .probe3(iic2intc_irpt_0), // input wire [0:0]  probe3 
        .probe4(int_flag), // input wire [0:0]  probe4 
        .probe5(int_flag_out), // input wire [0:0]  probe5 
        .probe6(pc_from_reg), // input wire [31:0]  probe6
        .probe7(S_AXI_0_awaddr), // input wire [8:0]  probe7 
        .probe8(S_AXI_0_wdata), // input wire [31:0]  probe8 
        .probe9(S_AXI_0_rdata), // input wire [31:0]  probe9 
        .probe10(S_AXI_0_bvalid), // input wire [0:0]  probe10 
        .probe11(S_AXI_0_bresp) // input wire [1:0]  probe11
    );
   



    iic_wrapper uut (
        .S_AXI_0_araddr(S_AXI_0_awaddr),
        .S_AXI_0_arready(S_AXI_0_arready),
        .S_AXI_0_arvalid(S_AXI_0_arvalid),
        .S_AXI_0_awaddr(S_AXI_0_awaddr),
        .S_AXI_0_awready(S_AXI_0_awready),
        .S_AXI_0_awvalid(S_AXI_0_awvalid),
        .S_AXI_0_bready(S_AXI_0_bready),
        .S_AXI_0_bresp(S_AXI_0_bresp),
        .S_AXI_0_bvalid(S_AXI_0_bvalid),
        .S_AXI_0_rdata(S_AXI_0_rdata),
        .S_AXI_0_rready(S_AXI_0_rready),
        .S_AXI_0_rresp(S_AXI_0_rresp),
        .S_AXI_0_rvalid(S_AXI_0_rvalid),
        .S_AXI_0_wdata(S_AXI_0_wdata),
        .S_AXI_0_wready(S_AXI_0_wready),
        .S_AXI_0_wstrb(S_AXI_0_wstrb),
        .S_AXI_0_wvalid(S_AXI_0_wvalid),
        .clk_in1_0(axi_clk),
        .iic2intc_irpt_0(iic2intc_irpt_0),
        .IIC_0_scl_io(scl),
        .IIC_0_sda_io(sda),
        .s_axi_aresetn_0(~rst)
    );

    WDT_Basic #(
    .CLK_FREQ_HZ(6_000_000)
    ) wdt (
    .clk      (clk_2),
    .rst_n    (~rst),
    .pulse_1s (pulse_1s)
  );

    Interrupt_Controller ic(
        .rst(rst),
        .int_flag(int_flag),
        .int_ID(input_int_id),
        ._priority(_priority),
        .clk(axi_clk),
        .gie(gie),
        .ack_end(ack_end),
        .ack_start(ack_start),
        .ack_end_id(ack_end_id),
        .ack_start_id(ack_start_id),
        .flag_signals(flag_signals),
        .flag_signals_sw(flag_signals_sw),
        .int_read(int_read)
    );

    Computer computer(
        .clk(clk_2),
        .ic_clk(axi_clk),
        .rst(rst),
        .ack_start_out(ack_start),
        .ack_end_out(ack_end),
        .ack_start_id(ack_start_id),
        .ack_end_id(ack_end_id),
        .input_int_id(input_int_id),
        .gie(gie),
        .if_flag(if_flag),
        .correct_instruction_flag(correct_instruction_flag),
        .counter_flag(counter_flag),
        .int_flag(int_flag),
        .int_flag_out(int_flag_out),
        .current_int_id(current_int_id),
        .zero_valid(zero_valid),
        .axi_addr(S_AXI_0_awaddr),
        .axi_wdata(S_AXI_0_wdata),
        .axi_rdata(S_AXI_0_rdata),
        .axi_awvalid(S_AXI_0_awvalid),
        .axi_wvalid(S_AXI_0_wvalid),
        .axi_bready(S_AXI_0_bready),
        .axi_awready(S_AXI_0_awready),
        .axi_wready(S_AXI_0_wready),
        .axi_bvalid(S_AXI_0_bvalid),
        .axi_arready(S_AXI_0_arready),
        .axi_rvalid(S_AXI_0_arvalid),
        .axi_arvalid(S_AXI_0_arvalid),
        .axi_rready(S_AXI_0_rready),
        .int_sw_flags(int_sw_flags),
        .pc_from_reg(pc_from_reg)
    );
endmodule

module Computer(
    input logic clk,
    input logic ic_clk,
    input logic rst,
    input logic int_flag,
    input logic [4:0] input_int_id,
    output logic ack_start_out, ack_end_out, gie,
    output logic [4:0] ack_start_id, ack_end_id,
    output logic if_flag,
    output logic correct_instruction_flag,
    output logic counter_flag,
    output logic int_flag_out,
    output logic[4:0] current_int_id,
    output logic zero_valid,
    output logic[8:0] axi_addr,
    output logic[31:0] axi_wdata,
    input logic[31:0] axi_rdata,
    output logic[31:0] pc_from_reg,
    output logic axi_awvalid,
    output logic axi_wvalid,
    output logic axi_bready,
    output logic axi_arvalid,
    output logic axi_rready,
    input logic axi_awready,
    input logic axi_wready,
    input logic axi_bvalid,
    input logic axi_arready,
    input logic axi_rvalid,
    output logic[31:0] int_sw_flags
);

    assign axi_awvalid = axi_status_to[0];
    assign axi_wvalid = axi_status_to[1];
    assign axi_bready = axi_status_to[2];
    assign axi_arvalid = axi_status_to[3];
    assign axi_rready = axi_status_to[4];
    assign axi_status_from[0] = axi_awready;
    assign axi_status_from[1] = axi_wready;
    assign axi_status_from[2] = axi_bvalid;
    assign axi_status_from[3] = axi_arready;
    assign axi_status_from[4] = axi_rvalid;

    logic pc_write, mem_read, rom_read,
        i_or_d, reg_write, mem_write,
        ir_write, zero, global_jump, pc_to_mem, int_r_dest, int_jump, int_write_addr_enable,
        int_flags_sw_clr, ack_start, ack_end, int_sw_enable;

    logic [4:0] i_31_27, i_26_22, i_21_17,
        i_16_12, reg_addr, r1_addr, r2_addr, i_4_0, reg_addr_mux_out;

    logic [1:0] data_mux_sel, int_src_r1;
    logic [2:0] int_src_r2, pc_source, reg_dst, reg_data_sel;

    /* verilator lint_off UNOPTFLAT */
    logic [2:0] alu_src_b, alu_op;
    /* verilator lint_off UNOPTFLAT */
    logic alu_src_a;

    logic [4:0] op_code;

    assign op_code = ir_out[31:27];

    /* verilator lint_off WIDTHEXPAND */
    assign jump_addr_shifter_out = ir_out[25:0];
    logic [15:0] axi_status_from, axi_status_to;
    
    logic [31:0] mem_data, rom_data, true_mem_data, alu_out,
        alu_i_reg_out, alu_result, mdr_out, reg_data,
        rs1_data, rs2_data, ra_out, rb_out, extend_out, shift_out,
        alu_src_a_mux_out, alu_src_b_mux_out, jump_addr_shifter_out,
        mem_addr, mem_write_data, int_addr_32, int_jump_mux_out, int_addr_32_out,
        int_flags_sw_in, ivt_b_p, ivt_addr, data_addr, int_ID_extended,
         pc_in, ir_out, p_state, int_sw_flags;

    Interrupt_Decider int_decider (
        .processor_int_ID(current_int_id),
        .gie(p_state[0]),
        .ivt_b_p(ivt_b_p),
        .int_ID(input_int_id),
        .int_flag_in(int_flag),
        .ivt_addr(ivt_addr),
        .int_flag_out(int_flag_out)
    );
    


    Mux_4x1 data_mux(
        .in1(alu_i_reg_out),
        .in2(ivt_addr),
        .in3(ra_out),
        .in4(0),
        .sel(data_mux_sel),
        .out(data_addr)
    );

    Memory memory(
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(i_or_d ? data_addr : pc_from_reg),
        .write_data(rb_out),
        .correct_instruction_flag(correct_instruction_flag),
        .mem_data(mem_data),
        .axi_status_from(axi_status_from),
        .axi_status_to(axi_status_to),
        .axi_addr(axi_addr),
        .axi_wdata(axi_wdata),
        .axi_rdata(axi_rdata)
    );

    Intermediate_Register mIR(
        .clk(clk),
        .rst(rst),
        .enable(ir_write),
        .data_in(mem_data),
        .data_out(ir_out)
    );



    Intermediate_Register MDR(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .data_in(mem_data),
        .data_out(mdr_out)
    );

    /* verilator lint_off WIDTHEXPAND */
    Mux_7x1 reg_addr_mux (
        .in1(r2_addr),
        .in2(ir_out[16:12]),
        .in3(32'd30),
        .in4(32'd25),
        .in5(32'd23),
        .in6(32'd27),
        .in7(32'd26),
        .sel(reg_dst),
        .out(reg_addr)
    );

    /* verilator lint_off WIDTHEXPAND */
    Mux_6x1 reg_data_mux_inst (
        .in1(alu_i_reg_out),
        .in2(mdr_out),
        .in3(input_int_id),
        .in4(ra_out),
        .in5(pc_in),
        .in6({{15{ir_out[16]}}, ir_out[16:0]}),
        .sel(reg_data_sel),
        .out(reg_data)
    );

    Mux_3x1 #(.N('d5)) r1_mux(
        .in1(ir_out[26:22]),
        .in2(5'd30),
        .in3(5'd23),
        .sel(int_src_r1),
        .out(r1_addr)
    );

    Mux_4x1 #(.N('d5)) r2_mux(
        .in1(ir_out[21:17]),
        .in2(5'd25), //Current Int ID
        .in3(5'd26), //Link Register
        .in4(5'd23),
        .sel(int_src_r2[1:0]),
        .out(r2_addr)
    );


    Registers #(.PC('h130), .SP('d500)) reg_file(
        .clk(clk),
        .rst(rst),
        .rs1_addr(r1_addr),
        .rs2_addr(r2_addr),
        .write_addr(reg_addr),
        .write_data(reg_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .write_enable(reg_write),
        .p_state(p_state),
        .ivt_b_p(ivt_b_p),
        .current_int_id(current_int_id),
        .pc_from_reg(pc_from_reg),
        .gie(gie),
        .counter_flag(counter_flag),
        .zero_valid(zero_valid)
    );

    Intermediate_Register Ra(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .data_in(rs1_data),
        .data_out(ra_out)
    );

    Intermediate_Register Rb(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .data_in(rs2_data),
        .data_out(rb_out)
    );

    Mux_2x1 alu_src_a_mux(
        .in1(pc_from_reg),
        .in2(ra_out),
        .sel(alu_src_a),
        .out(alu_src_a_mux_out)
    );

    /* verilator lint_off WIDTHEXPAND */
    Mux_6x1 alu_src_b_mux(
        .in1(rb_out),
        .in2(32'h1),
        .in3({{15{ir_out[16]}}, ir_out[16:0]}),  // Sign-extend to 32 bits
        .in4({{15{ir_out[16]}}, ir_out[16:0]}),
        .in5(32'h0),
        .in6(32'hfffffffe),
        .sel(alu_src_b),
        .out(alu_src_b_mux_out)
    );

    ALU alu(
        .alu_op(alu_op),
        .operand1(alu_src_a_mux_out),
        .operand2(alu_src_b_mux_out),
        .zero(zero),
        .result(alu_result)
    );

    Intermediate_Register alu_IR(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .data_in(alu_result),
        .data_out(alu_i_reg_out)
    );

    Mux_5x1 pc_source_mux (
        .in1(alu_result),
        .in2(alu_i_reg_out),
        .in3(jump_addr_shifter_out),
        .in4(pc_from_reg),
        .in5(mdr_out),
        .sel(pc_source),
        .out(pc_in)
    );

    Ack_Start_Module ack_start_module(
        .clk(ic_clk),
        .rst(rst),
        .int_ID(current_int_id),
        .ack_start_in(ack_start),
        .ack_start(ack_start_out),
        .ack_start_id(ack_start_id)
    );

    Ack_End_Module ack_end_module(
        .clk(ic_clk),
        .rst(rst),
        .int_ID(current_int_id),
        .ack_end_in(ack_end),
        .ack_end(ack_end_out),
        .ack_end_id(ack_end_id)
    );

    Decoder int_decoder(
        .clk(clk),
        .rst(rst),
        .in(ir_out[4:0]),
        .enable(int_sw_enable),
        .sw_flag(int_sw_flags)
    );

    Control_Unit control(
        .clk(clk),
        .rst(rst),
        .op_code(op_code),
        .zero(zero),
        .i_or_d(i_or_d),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .ir_write(ir_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_op(alu_op),
        .pc_source(pc_source),
        .pc_sel(pc_write),
        .reg_write(reg_write),
        .reg_dst(reg_dst),
        .reg_data_sel(reg_data_sel),
        .global_jump(global_jump),
        .pc_to_mem(pc_to_mem),
        .int_flag(int_flag_out),
        .int_src_r1(int_src_r1),
        .int_src_r2(int_src_r2),
        .int_jump(int_jump),
        .int_write_addr_enable(int_write_addr_enable),
        .int_flags_sw_clr(int_flags_sw_clr),
        .int_r_dest(int_r_dest),
        .rom_read(rom_read),
        .ack_start(ack_start),
        .ack_end(ack_end),
        .data_mux_sel(data_mux_sel),
        .if_flag(if_flag),
        .int_sw_enable(int_sw_enable)
    );

endmodule
/* verilator lint_off MULTITOP */

module Interrupt_Controller(
    input logic clk,
    input logic rst,
    input logic gie,
    input logic flag_signals[31:0],
    input logic flag_signals_sw[31:0],
    input logic ack_start,
    input logic [4:0] ack_start_id,
    input logic ack_end,
    input logic [4:0] ack_end_id,
    output logic int_flag,
    output logic [4:0] int_ID,
    output logic [2:0] _priority,
    output logic int_read

);


    logic ack_end_arr[0:31];
    logic ack_start_arr[0:31];
    logic[1:0] control_state[0:31];
    logic int_flags[0:31];
    logic[7:0] reg_out[0:31];
    assign int_read = reg_out[2][7];
                                                                                                                                    

    genvar i;

	// Generate for loop to instantiate N times
	generate
		for (i = 0; i < 32; i = i + 1) begin
            Interrupt_Register #(.PRIORITY(i / 4)) int_regs(
                .int_flag(int_flags[i]),
                .state_in(control_state[i]),
                .reg_out(reg_out[i])
            );

            Interrupt_Control_Unit int_control(
                .ack_end(ack_end_arr[i]),
                .ack_start(ack_start_arr[i]),
                .clk(clk),
                .rst(rst),
                .control_state(control_state[i]),
                .int_flag_in(flag_signals[i]),
                .int_flag_in_sw(flag_signals_sw[i]),
                .int_flag_out(int_flags[i])
            );
		end
	endgenerate

    Master_Control_Unit master_cu(
        .gie(gie),
        .int_flag(int_flag),
        .int_ID(int_ID),
        ._priority(_priority),
        .ack_end(ack_end),
        .ack_end_id(ack_end_id),
        .ack_start(ack_start),
        .ack_start_id(ack_start_id),
        .regs(reg_out),
        .ack_end_arr(ack_end_arr),
        .ack_start_arr(ack_start_arr)
    );
    
endmodule

module Master_Control_Unit(
    input logic [7:0] regs[0:31],
    input logic ack_start,
    input logic [4:0] ack_start_id,
    input logic ack_end,
    input logic [4:0] ack_end_id,
    input logic gie,
    output logic int_flag,
    output logic [4:0] int_ID,
    output logic [2:0] _priority,
    output logic ack_start_arr[0:31],
    output logic ack_end_arr[0:31]
);

always_comb begin
    int_ID = 0;
    _priority = 3'h7;
    int_flag = 0;

    for (int i = 31; i >= 0 ; i = i - 1) begin
            //Highest Pending or Active Interrupt is the intID
        if ((regs[i][5:4] == 2'h1 || regs[i][5:4] == 2'h2)&& regs[i][7] && gie) begin
            /* verilator lint_off WIDTHTRUNC */
            int_ID = i;
            _priority = regs[i][3:1];
            int_flag = 1;
        end
    end

end

always_comb begin
    for (int i=0; i<32; i = i + 1) begin
        ack_start_arr[i] = 0;
        ack_end_arr[i] = 0;

        /* verilator lint_off WIDTHEXPAND */
        if (ack_start && ack_start_id == i) begin
            ack_start_arr[i] = 1;
        end

        /* verilator lint_off WIDTHEXPAND */
        if (ack_end && ack_end_id == i) begin
            ack_end_arr[i] = 1;
        end
    end
end
    
endmodule


//Wrong State Machine
module Interrupt_Control_Unit (
    input logic clk,
    input logic rst,
    input logic int_flag_in,
    input logic int_flag_in_sw,
    input logic ack_start,
    input logic ack_end,
    output logic [1:0] control_state,     // Assuming 2-bit state representation
    output logic int_flag_out
);

    typedef enum {INACTIVE = 2'b00, PENDING = 2'b01, ACTIVE = 2'b10, TRANS = 2'b11} state_int;

    state_int state, next_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= INACTIVE;
        end
        else begin
            state <= next_state;
            control_state <= next_state;  
        end

    end

/*     always_comb begin : Assign
        if (rst) begin
            state = INACTIVE;
        end
        else begin
            state = next_state;
        end
    end */

    always_comb begin
        case (state)
            INACTIVE: begin
                if (int_flag_in || int_flag_in_sw)
                    next_state = PENDING;
                else
                    next_state = INACTIVE;
            end
            PENDING: begin
                if (ack_start)
                    next_state = ACTIVE;
                else
                    next_state = PENDING;
            end
            ACTIVE: begin
                if (ack_end)
                    next_state = INACTIVE;
                else
                    next_state = ACTIVE;
            end
            default: next_state = INACTIVE;
        endcase
    end

    always_comb begin
        case (state)
            INACTIVE: int_flag_out = 0;
            PENDING:  int_flag_out = 1;
            ACTIVE:   int_flag_out = 0;
        endcase
    end

endmodule

module Interrupt_Register #(
    parameter PRIORITY = 0
) (
    input logic int_flag,
    input logic [1:0] state_in,
    output logic [7:0] reg_out
);

always_comb begin
    reg_out[3:1] = PRIORITY;
    reg_out[5:4] = state_in;
    reg_out[7] = int_flag;
end
    
endmodule


module Interrupt_Decider (
    input logic [31:0] ivt_b_p,
    input logic [4:0] int_ID,
    input logic [4:0] processor_int_ID,
    input logic gie,
    input logic int_flag_in,
    output logic [31:0] ivt_addr,
    output logic int_flag_out
);

    //NOTE: VERY TRICKY. INTERRUPT CAN OCCUR FOR SAME PRIORITY.
    //THIS IS BECAUSE OF PROCESSOR DEFAULT PRIORITY (ID = 32),
    //THIS IS NOT IDEAL BECAUSE VOLTAGE NEEDS TO BE ON THE 5 LINES
    //ALMOST ALL THE TIME. SOLUTION: FLIP PRIORITY ENDIANESS
    always_latch begin
        int_flag_out = 0;
        if (int_flag_in && int_ID < processor_int_ID && gie) begin
            ivt_addr = ivt_b_p + int_ID;
            int_flag_out = 1;
        end
    end
endmodule
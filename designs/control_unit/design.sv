module Control_Unit(
    input logic clk,
    input logic rst,
    input logic[4:0] op_code,
    input logic zero, int_flag,
    output logic ack_start,
    output logic ack_end,

    output logic i_or_d, mem_read, rom_read, mem_write, ir_write, alu_src_a,
        pc_sel, reg_write, global_jump, pc_to_mem, int_jump, int_write_addr_enable, int_flags_sw_clr,
        int_r_dest,
    
    output logic[1:0] data_mux_sel, int_src_r1,
    output logic[2:0] int_src_r2, alu_src_b, alu_op, pc_source, reg_data_sel, reg_dst,
    output logic if_flag, int_sw_enable
);

    logic pc_write_cond;
    typedef enum
{
    PRESTART = 35,
    MEM_DELAY = 36,
    MEM_DELAY_INT = 37,
    IF  = 0,        // INSTRUCTION_FETCH
    ID_RF = 1,     // INSTRUCTION_DECODE/REGISTER_FETCH
    M_COMP = 2,    // MEMORY_ADDRESS_COMPUTATION
    M_READ = 3,    // MEMORY READ
    WRB = 4,       // WRITE_BACK STEP
    M_WRITE = 5,   // MEMORY WRITE
    EXEC = 6,      // EXECUTION
    R_COMP = 7,    // R-TYPE COMPLETION
    B_COMP = 8,    // BRANCH COMPLETION
    J_COMP = 9,    // JUMP COMPLETION
    IM_EXEC = 10,  // EXECUTION IMMEDIATE
    IR_COMP = 11,  // EXEC IMM COMPLETION
    JUMP_REG = 12, // JUMP ADDR COMPUTATION
    FETCH_SP = 13,
    DECREMENT_SP_1 = 14,
    UPDATE_SP_FETCH_SP_1 = 15,
    FETCH_SP_1 = 28,
    STORE_CURR_INT_ID = 16,
    DECREMENT_SP_2 = 17,
    UPDATE_SP_FETCH_SP_2 = 18,
    FETCH_SP_2 = 29,
    STORE_PC = 19,
    UPDATE_CURRENT_INT_ID = 20,
    UPDATE_PC = 21,
    RET_FETCH_SP=22,
    RET_READ_SP=23,
    RET_UPDATE_PC=24,
    IRET_FETCH_SP_2=25,
    IRET_FETCH_SP_2_DELAY= 30,
    IRET_READ_SP_2=26,
    IRET_UPDATE_CURRENT_INT_ID=27,
    IRET_UPDATE_CURRENT_INT_ID_DELAY= 31,
    INT_STAGE=32
} state_e;

typedef enum { 
    ADD  = 0,
    SUB = 1,
    AND = 2,
    OR = 3,
    XOR = 4,
    NOT = 5,
    ADDI = 'hA,
    SUBI = 'hB,
    ANDI = 'h13,
    ORI = 'h14,
    LW = 'h07,
    SW = 'h08,
    JUMP = 'h09,
    G_JUMP_IMM = 'hC,
    G_JUMP = 'hF,
    BEQ = 'h6,
    BNEQ = 'h18,
    NO_OP = 'hE,
    INT = 'h10,
    SW_PC = 'hD,
    MOV = 'h12,
    MOVI = 'h15,
    JUMP_N_LINK = 'h11,
    IRET='h17,
    BTSLI='h19,
    BTSRI='h1a

} op_code_enum;

state_e state;
state_e next_state;
op_code_enum op_code_internal;
assign op_code_internal = op_code_enum'(op_code);



always_ff @( posedge clk, posedge rst ) begin : FSM_Update
    if(rst) begin
        state <= PRESTART;
    end
    else begin
        state <= next_state;
    end
end



always_comb begin : Pin_Change
    i_or_d = 0;
    mem_read = 0;
    mem_write = 0;
    reg_data_sel = 0;
    ir_write = 0;
    alu_src_a = 0;
    alu_src_b = 0;
    reg_write = 0;
    reg_dst = 0;
    alu_op = 0;
    pc_write_cond = 0;
    pc_source = 0;
    global_jump = 0;
    pc_to_mem = 0;
    int_src_r1 = 0;
    int_src_r2 = 0;
    int_jump = 0;
    int_write_addr_enable = 0;
    int_flags_sw_clr = 0;
    int_r_dest = 0;
    ack_start = 0;
    ack_end = 0;
    data_mux_sel = 0;
    if_flag = 0;
    int_sw_enable = 0;
    

    case (state)
        IF: begin
            i_or_d = 0;
            mem_read= 1;
            ir_write= 1;
            alu_src_a = 0;
            alu_src_b = 3'b01; // Increment PC
            alu_op = 3'b000;   // ADD
            pc_source = 0;

            if_flag = 1;

            reg_dst = 3'b100;
            reg_data_sel = 3'b100;
            reg_write=  1;

            if (int_flag) begin
                $display("INTERRUPTING");
                reg_write = 0;
            end
        end
        ID_RF: begin
            alu_src_a = 0;
            alu_src_b = 3'b11; //Extend and Shift
            alu_op = 3'b000; //ADD
        end
        EXEC: begin
            alu_src_a = 1;
            alu_src_b = 3'b00;
            case (op_code_internal)
                ADD: begin
                    alu_op = 3'b000;
                end
                SUB: begin
                    alu_op = 3'b001;
                end
                AND: begin
                    alu_op = 3'b010;
                end
                OR: begin
                    alu_op = 3'b011;
                end
                XOR: begin
                    alu_op = 3'b100;
                end
                NOT: begin
                    alu_op = 3'b101;
                end
                default: 
                    $error("OOpsie");
            endcase
            alu_op = op_code[2:0];
        end
        IM_EXEC: begin
            alu_src_a = 1;
            alu_src_b = 3'b10;
            case (op_code_internal)
                ADDI: begin
                    alu_op = 3'b000;
                end
                SUBI: begin
                    alu_op = 3'b001;
                end
                ANDI: begin
                    alu_op = 3'b010;
                end
                ORI: begin
                    alu_op = 3'b011;
                end
                BTSLI: begin
                    alu_op = 3'b110;
                end
                BTSRI: begin
                    alu_op = 3'b111;
                end
                default: 
                    $error("OOpsie");
            endcase
        end
        R_COMP: begin
            reg_write = 1;
            reg_dst = 1;
            reg_data_sel = 0;
        end
        IR_COMP: begin
            reg_write = 1;
            reg_dst = 0;
            reg_data_sel = 0;
        end
        B_COMP: begin
            alu_src_a = 1;
            alu_src_b = 3'b00;
            alu_op = 3'b001;
            pc_source = 3'b01;

            //IF BRANCH CONDITION IS 0, UPDATE PC
            if((zero && op_code_internal == BEQ) || (~zero && op_code_internal == BNEQ)) begin
                reg_dst = 3'b100;
                reg_data_sel = 3'b100;
                reg_write = 1;
            end
        end
        JUMP_REG: begin
            alu_src_a = 1;
            alu_src_b = 3'b10;
            alu_op = 0;
        end
        J_COMP: begin
            reg_dst = 3'b100;
            reg_data_sel = 3'b100;
            reg_write = 1;
            case (op_code_internal)
                G_JUMP_IMM: begin
                    global_jump = 1;
                    pc_source = 3'b10;
                end
                G_JUMP: begin
                    pc_source = 3'b01;
                end
                default: begin
                    pc_source = 3'b10;
                end
            endcase
        end
        M_COMP: begin
            alu_src_a = 1;
            alu_src_b = 3'b10;
            alu_op = 0;
        end
        M_READ: begin
            mem_read = 1;
            i_or_d = 1;
        end
        M_WRITE: begin
            mem_write = 1;
            i_or_d = 1;
            if (op_code == 'hd) begin
                pc_to_mem = 1;
            end
        end
        WRB: begin

            //Use LR if JUMP_N_LINK
            reg_dst = (op_code_internal == JUMP_N_LINK) ? 3'b110 : 3'b000;
            
            reg_write = 1;
            case (op_code_internal)
                LW: begin
                    reg_data_sel = 3'b001;
                end
                MOV: begin
                    reg_data_sel = 3'b011;
                end
                MOVI: begin
                    reg_data_sel = 3'b101;
                end
                JUMP_N_LINK: begin
                    pc_source = 3'b011;
                    reg_data_sel = 3'b100;
                end
                default: 
                    $error(":)");
            endcase
        end
        FETCH_SP: begin
            int_src_r1 = 1;
        end
        DECREMENT_SP_1: begin
            alu_src_a = 1;
            alu_src_b = 3'b001;
            alu_op = 3'b001;
        end
        UPDATE_SP_FETCH_SP_1: begin
            reg_write = 1;
            reg_dst = 3'b010;
            reg_data_sel = 3'b000;

        end
        FETCH_SP_1: begin
            int_src_r1 = 1;
            int_src_r2 = 3'b001;
        end
        STORE_CURR_INT_ID: begin
            mem_write = 1;
            i_or_d = 1;
            data_mux_sel = 2'b10;

            int_src_r1 = 1;
        end
        DECREMENT_SP_2: begin
            alu_src_a = 1;
            alu_src_b = 3'b001;
            alu_op = 3'b001;
        end
        UPDATE_SP_FETCH_SP_2: begin
            reg_write = 1;
            reg_dst = 3'b010;
            reg_data_sel = 3'b000;
        end
        FETCH_SP_2: begin
            int_src_r1 = 1;
            int_src_r2 = 3'b011;
        end
        STORE_PC: begin
            mem_write = 1;
            i_or_d = 1;
            data_mux_sel = 2'b10;

            int_src_r1 = 1;
        end
        UPDATE_CURRENT_INT_ID: begin
            reg_data_sel = 3'b010;
            reg_write = 1;
            reg_dst = 3'b011;

            //Fetch IVT
            i_or_d = 1;
            data_mux_sel = 2'b01;
            mem_read = 1;
        end

        UPDATE_PC: begin
            reg_write = 1;
            reg_dst = 3'b100;
            reg_data_sel = 3'b001;

            //Wait for new Current Int ID to propagate
            ack_start = 1;
        end

        RET_FETCH_SP: begin
            int_src_r1 = 1;
        end
        RET_READ_SP: begin
            mem_read = 1;
            i_or_d = 1;
            data_mux_sel = 2'b10;

            int_src_r1 = 1;
        end
        RET_UPDATE_PC: begin
            // Logic for RET_UPDATE_PC
            reg_write = 1;
            reg_dst = 3'b100;
            reg_data_sel = 3'b001;

            //increment SP
            alu_src_a = 1;
            alu_src_b = 3'b001;
            alu_op = 3'b000;


        end
        IRET_FETCH_SP_2: begin
            // Logic for IRET_FETCH_SP_2
            reg_write = 1;
            reg_dst = 3'b010;
            reg_data_sel = 3'b000;

            
        end
        IRET_FETCH_SP_2_DELAY: begin
            int_src_r1 = 1;
        end
        IRET_READ_SP_2: begin
            // Logic for IRET_READ_SP_2
            mem_read = 1;
            i_or_d = 1;
            data_mux_sel = 2'b10;

            int_src_r1 = 1;
        end
        IRET_UPDATE_CURRENT_INT_ID: begin
            // Logic for IRET_UPDATE_CURRENT_INT_ID
            reg_data_sel = 3'b001;
            reg_write = 1;
            reg_dst = 3'b011;
            ack_end = 1;

            int_src_r1 = 1;


            //increment SP
            alu_src_a = 1;
            alu_src_b = 3'b001;
            alu_op = 3'b000;
        end
        IRET_UPDATE_CURRENT_INT_ID_DELAY: begin
            reg_write = 1;
            reg_dst = 3'b010;
            reg_data_sel = 3'b000;
        end

        INT_STAGE: begin
            int_sw_enable = 1;
        end
        
/*         G_JUMP_COMP: begin
            reg_dst = 3'b100;
            reg_data_sel = 3'b100;
            reg_write = 1;
            global_jump = 1;
            pc_source = 3'b100;
            int_jump = 1;
            ack_start = 1;
            ack_start_id = current_int_id;
        end */

        PRESTART: begin
            //$display("Prestart");
        end
        MEM_DELAY: begin
            //$display("Mem Delay");
        end
        MEM_DELAY_INT: begin
            //$display("Memory Delay Interrupt");
        end
        default: begin
            
        end
    endcase

end

always_comb begin : FSM_Next_State
    case (state)
        PRESTART: begin
            next_state = IF;
        end
        IF: begin
            if (int_flag) begin
                next_state = FETCH_SP;
            end
            else begin
                next_state = MEM_DELAY;
            end
        end
        MEM_DELAY: begin
            next_state = ID_RF;
        end
        ID_RF: begin
            case (op_code_internal)
                ADD, SUB, AND, OR, XOR, NOT: begin
                    next_state = EXEC;
                end
                BEQ, BNEQ: begin
                    next_state = B_COMP;
                end
                LW, SW, SW_PC: begin
                    next_state = M_COMP;
                end
                JUMP, G_JUMP_IMM: begin
                    next_state = J_COMP;
                end
                G_JUMP: begin
                    next_state = JUMP_REG;
                end

                NO_OP: begin
                    next_state = IF;
                end
                MOV, MOVI, JUMP_N_LINK: begin
                    next_state = WRB;
                end
                ADDI, SUBI, ANDI, SUBI, ORI, BTSLI, BTSRI: begin
                    next_state = IM_EXEC;
                end
                IRET: begin
                    next_state = RET_FETCH_SP;
                end
                INT: begin
                    next_state = INT_STAGE;
                end


                default: begin
                    $error("OpCode not Implemented  %x", op_code);
                end
            endcase
        end
        EXEC: begin
            next_state = R_COMP;
        end
        IM_EXEC: begin
            next_state = IR_COMP;
        end
        JUMP_REG: begin
            next_state = J_COMP;
        end
        R_COMP, IR_COMP, B_COMP, J_COMP: begin
            next_state = IF;
        end
        M_COMP: begin
            case (op_code_internal)
                LW: begin
                    next_state = M_READ;
                end
                SW, SW_PC: begin
                    next_state = M_WRITE;
                end
                default: begin
                    $error("Oopsie");
                end
            endcase
        end
        M_READ: begin
            next_state = WRB;
        end
        M_WRITE: begin
            next_state = IF;
        end
        WRB: begin
            next_state = op_code_internal == JUMP_N_LINK ? J_COMP : IF;
        end
        FETCH_SP: begin
            next_state = DECREMENT_SP_1;
        end
        DECREMENT_SP_1: begin
            next_state = UPDATE_SP_FETCH_SP_1;
        end
        UPDATE_SP_FETCH_SP_1: begin
            next_state = FETCH_SP_1;
        end
        FETCH_SP_1: begin
            next_state = STORE_CURR_INT_ID;
        end
        STORE_CURR_INT_ID: begin
            next_state = DECREMENT_SP_2;
        end
        DECREMENT_SP_2: begin
            next_state = UPDATE_SP_FETCH_SP_2;
        end
        UPDATE_SP_FETCH_SP_2: begin
            next_state = FETCH_SP_2;
        end
        FETCH_SP_2: begin
            next_state = STORE_PC;
        end
        STORE_PC: begin
            next_state = UPDATE_CURRENT_INT_ID;
        end
        UPDATE_CURRENT_INT_ID: begin
            next_state = UPDATE_PC;
        end
        RET_FETCH_SP: begin
            next_state = RET_READ_SP;
        end
        RET_READ_SP: begin
            next_state = RET_UPDATE_PC;
        end
        RET_UPDATE_PC: begin
            next_state = IRET_FETCH_SP_2;  // Assuming it returns to normal execution
        end
        IRET_FETCH_SP_2: begin
            next_state = IRET_FETCH_SP_2_DELAY;
        end
        IRET_FETCH_SP_2_DELAY: begin
            next_state = IRET_READ_SP_2;
        end
        IRET_READ_SP_2: begin
            next_state = IRET_UPDATE_CURRENT_INT_ID;
        end
        IRET_UPDATE_CURRENT_INT_ID: begin
            next_state = IRET_UPDATE_CURRENT_INT_ID_DELAY;  // Assuming normal execution resumes
        end
        IRET_UPDATE_CURRENT_INT_ID_DELAY: begin
            next_state = IF;
        end
        INT_STAGE: begin
            next_state = IF;
        end

        UPDATE_PC: begin
            next_state = IF;  // Assuming it loops back to the beginning
        end




    endcase
end


endmodule
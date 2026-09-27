`timescale 1ns / 1ps

module riscv_alu #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0] a,
    input  wire [DATA_WIDTH-1:0] b,
    input  wire [3:0]            alu_ctrl,
    output reg  [DATA_WIDTH-1:0] alu_out,
    output reg                   zero_flag,
    output reg                   carry_flag,
    output reg                   overflow_flag,
    output reg                   negative_flag
);

    // Operation codes simple parameters mein
    localparam ADD  = 4'd0;
    localparam SUB  = 4'd1;
    localparam AND  = 4'd2;
    localparam OR   = 4'd3;
    localparam XOR  = 4'd4;
    localparam SLT  = 4'd5;
    localparam SLTU = 4'd6;
    localparam SLL  = 4'd7;
    localparam SRL  = 4'd8;
    localparam SRA  = 4'd9;

    // Shift amount (32-bit ke liye sirf last 5 bits chahiye: 0 to 31)
    wire [4:0] shamt;
    assign shamt = b[4:0];

    // Sign bits alag se nikaal liye taaki overflow samajhna aasan ho
    wire a_sign;
    wire b_sign;
    wire res_sign;

    assign a_sign   = a[DATA_WIDTH-1];
    assign b_sign   = b[DATA_WIDTH-1];
    assign res_sign = alu_out[DATA_WIDTH-1];

    // Main ALU Operations
    always @(*) begin
        // Default values taaki unintentional latch na bane
        alu_out    = 0;
        carry_flag = 0;

        case (alu_ctrl)
            ADD: begin
                {carry_flag, alu_out} = a + b;
            end

            SUB: begin
                {carry_flag, alu_out} = a - b;
            end

            AND: begin
                alu_out = a & b;
            end

            OR: begin
                alu_out = a | b;
            end

            XOR: begin
                alu_out = a ^ b;
            end

            SLT: begin
                // Signed comparison: agar a < b, toh output 1 warna 0
                if ($signed(a) < $signed(b))
                    alu_out = 1;
                else
                    alu_out = 0;
            end

            SLTU: begin
                // Unsigned comparison: agar a < b, toh output 1 warna 0
                if (a < b)
                    alu_out = 1;
                else
                    alu_out = 0;
            end

            SLL: begin
                alu_out = a << shamt;
            end

            SRL: begin
                alu_out = a >> shamt;
            end

            SRA: begin
                alu_out = $signed(a) >>> shamt;
            end

            default: begin
                alu_out    = 0;
                carry_flag = 0;
            end
        endcase
    end

    // Flags generation (alag se clean block mein)
    always @(*) begin
        // 1. Zero Flag: agar result 0 hai toh 1
        if (alu_out == 0)
            zero_flag = 1'b1;
        else
            zero_flag = 1'b0;

        // 2. Negative Flag: result ka MSB bit
        negative_flag = res_sign;

        // 3. Overflow Flag: wahi logic jo humne discuss kiya tha
        overflow_flag = 1'b0; // default zero

        if (alu_ctrl == ADD) begin
            // Dono same sign ke the par result ka sign alag aa gaya
            if ((a_sign == b_sign) && (res_sign != a_sign))
                overflow_flag = 1'b1;
        end
        else if (alu_ctrl == SUB) begin
            // Dono alag sign ke the par result galat sign ka aa gaya
            if ((a_sign != b_sign) && (res_sign != a_sign))
                overflow_flag = 1'b1;
        end
    end

endmodule
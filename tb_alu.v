`timescale 1ns / 1ps

module tb_riscv_alu;

    parameter DATA_WIDTH = 32;

    reg  [DATA_WIDTH-1:0] a;
    reg  [DATA_WIDTH-1:0] b;
    reg  [3:0]            alu_ctrl;
    wire [DATA_WIDTH-1:0] alu_out;
    wire                  zero_flag;
    wire                  carry_flag;
    wire                  overflow_flag;
    wire                  negative_flag;

    integer in_file, out_file, status;

    // Instantiate DUT (Device Under Test)
    riscv_alu #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .alu_out(alu_out),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag),
        .negative_flag(negative_flag)
    );

    initial begin
        // GTKWave waveform dump
        $dumpfile("alu_waves.vcd");
        $dumpvars(0, tb_riscv_alu);

        in_file  = $fopen("test_vectors.txt", "r");
        out_file = $fopen("results.txt", "w");

        if (in_file == 0) begin
            $display("[ERROR] Could not open test_vectors.txt");
            $finish;
        end

        // Read vectors: a (hex), b (hex), alu_ctrl (hex)
        while (!$feof(in_file)) begin
            status = $fscanf(in_file, "%h %h %h\n", a, b, alu_ctrl);
            if (status == 3) begin
                #10; // Wait 10ns for combinational propagation
                // Log: alu_out, zero, carry, overflow, negative
                $fdisplay(out_file, "%h %b %b %b %b", alu_out, zero_flag, carry_flag, overflow_flag, negative_flag);
            end
        end

        $fclose(in_file);
        $fclose(out_file);
        $finish;
    end

endmodule
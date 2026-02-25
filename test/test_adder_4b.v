/*
 * Testbench — Additionneur 4-bit ripple carry
 * Verifie toutes les combinaisons A + B + Cin
 */

`timescale 1ns/1ps

module test_adder_4b;

    reg  [3:0] r_a, r_b;
    reg        r_cin;
    wire [3:0] w_sum;
    wire       w_cout;

    // DUT
    adder_4b dut (
        .i_a   (r_a),
        .i_b   (r_b),
        .i_cin (r_cin),
        .o_sum (w_sum),
        .o_cout(w_cout)
    );

    integer cpt_a, cpt_b, cpt_c;
    integer errors;
    reg [4:0] expected;

    initial begin
        $dumpfile("tmp/signal_adder_4b.vcd");
        $dumpvars(0, test_adder_4b);

        errors = 0;

        for (cpt_a = 0; cpt_a < 16; cpt_a = cpt_a + 1) begin
            for (cpt_b = 0; cpt_b < 16; cpt_b = cpt_b + 1) begin
                for (cpt_c = 0; cpt_c < 2; cpt_c = cpt_c + 1) begin
                    r_a   = cpt_a[3:0];
                    r_b   = cpt_b[3:0];
                    r_cin = cpt_c[0];
                    #10;

                    expected = cpt_a + cpt_b + cpt_c;

                    if ({w_cout, w_sum} !== expected) begin
                        $display("ERREUR : %0d + %0d + %0d = %0d (attendu %0d)",
                                 cpt_a, cpt_b, cpt_c, {w_cout, w_sum}, expected);
                        errors = errors + 1;
                    end
                end
            end
        end

        if (errors == 0)
            $display("OK — 512 tests passes sans erreur");
        else
            $display("ECHEC — %0d erreurs sur 512 tests", errors);

        $finish;
    end

endmodule

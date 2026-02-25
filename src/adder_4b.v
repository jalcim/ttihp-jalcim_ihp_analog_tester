/*
 * Copyright (c) 2026 jalcim
 * SPDX-License-Identifier: Apache-2.0
 *
 * Additionneur 4-bit ripple carry — netlist structurelle SG13G2
 * Cellules : sg13g2_xor2_1 (XOR2), sg13g2_and2_1 (AND2), sg13g2_a21o_1 (AO21)
 *
 * Full Adder par bit :
 *   P = A XOR B                        (propagate)
 *   S = P XOR Cin                      (sum)
 *   G = A AND B                        (generate)
 *   Cout = (Cin AND P) OR G            (carry) = a21o(Cin, P, G)
 */

module adder_4b (
    input  wire [3:0] i_a,
    input  wire [3:0] i_b,
    input  wire       i_cin,
    output wire [3:0] o_sum,
    output wire       o_cout
);

    wire [3:0] w_p;   // propagate
    wire [3:0] w_g;   // generate
    wire [4:0] w_c;   // carry chain (w_c[0] = cin, w_c[4] = cout)

    assign w_c[0] = i_cin;
    assign o_cout = w_c[4];

    // --- Bit 0 ---
    sg13g2_xor2_1 u_p0  (.X(w_p[0]), .A(i_a[0]), .B(i_b[0]));
    sg13g2_xor2_1 u_s0  (.X(o_sum[0]), .A(w_p[0]), .B(w_c[0]));
    sg13g2_and2_1 u_g0  (.X(w_g[0]), .A(i_a[0]), .B(i_b[0]));
    sg13g2_a21o_1 u_c0  (.X(w_c[1]), .A1(w_c[0]), .A2(w_p[0]), .B1(w_g[0]));

    // --- Bit 1 ---
    sg13g2_xor2_1 u_p1  (.X(w_p[1]), .A(i_a[1]), .B(i_b[1]));
    sg13g2_xor2_1 u_s1  (.X(o_sum[1]), .A(w_p[1]), .B(w_c[1]));
    sg13g2_and2_1 u_g1  (.X(w_g[1]), .A(i_a[1]), .B(i_b[1]));
    sg13g2_a21o_1 u_c1  (.X(w_c[2]), .A1(w_c[1]), .A2(w_p[1]), .B1(w_g[1]));

    // --- Bit 2 ---
    sg13g2_xor2_1 u_p2  (.X(w_p[2]), .A(i_a[2]), .B(i_b[2]));
    sg13g2_xor2_1 u_s2  (.X(o_sum[2]), .A(w_p[2]), .B(w_c[2]));
    sg13g2_and2_1 u_g2  (.X(w_g[2]), .A(i_a[2]), .B(i_b[2]));
    sg13g2_a21o_1 u_c2  (.X(w_c[3]), .A1(w_c[2]), .A2(w_p[2]), .B1(w_g[2]));

    // --- Bit 3 ---
    sg13g2_xor2_1 u_p3  (.X(w_p[3]), .A(i_a[3]), .B(i_b[3]));
    sg13g2_xor2_1 u_s3  (.X(o_sum[3]), .A(w_p[3]), .B(w_c[3]));
    sg13g2_and2_1 u_g3  (.X(w_g[3]), .A(i_a[3]), .B(i_b[3]));
    sg13g2_a21o_1 u_c3  (.X(w_c[4]), .A1(w_c[3]), .A2(w_p[3]), .B1(w_g[3]));

endmodule

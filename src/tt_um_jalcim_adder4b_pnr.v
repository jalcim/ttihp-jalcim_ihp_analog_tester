/*
 * Copyright (c) 2026 jalcim
 * SPDX-License-Identifier: Apache-2.0
 *
 * Netlist plate pour PnR OpenROAD — Additionneur 4-bit ripple carry
 * Module nomme tt_um_jalcim_adder4b pour correspondre au top_module TT
 *
 * Ports TT digitaux uniquement (power et analog geres separement)
 *
 * Pinout :
 *   ui_in[3:0]  = A[3:0]
 *   ui_in[7:4]  = B[3:0]
 *   uio_in[0]   = Cin
 *   uo_out[3:0] = Sum[3:0]
 *   uo_out[4]   = Cout
 *   uo_out[7:5] = 0 (tie low)
 *   uio_out     = 0 (tie low)
 *   uio_oe      = 0 (tie low, toutes les bidir en input)
 */

module tt_um_jalcim_adder4b (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // --- Wires internes ---
    wire [3:0] w_p;    // propagate = A XOR B
    wire [3:0] w_g;    // generate  = A AND B
    wire [4:0] w_c;    // carry chain
    wire [3:0] w_sum;  // sum outputs
    wire       w_lo;   // tie low

    // --- Carry in ---
    // w_c[0] = uio_in[0] = Cin (connexion directe, pas de cellule)

    // --- Tie cell pour les sorties inutilisees ---
    sg13g2_tielo u_tie (.L_LO(w_lo));

    // --- Bit 0 ---
    sg13g2_xor2_1 u_p0 (.X(w_p[0]), .A(ui_in[0]),  .B(ui_in[4]));
    sg13g2_xor2_1 u_s0 (.X(w_sum[0]), .A(w_p[0]),  .B(uio_in[0]));
    sg13g2_and2_1 u_g0 (.X(w_g[0]), .A(ui_in[0]),   .B(ui_in[4]));
    sg13g2_a21o_1 u_c0 (.X(w_c[1]), .A1(uio_in[0]), .A2(w_p[0]), .B1(w_g[0]));

    // --- Bit 1 ---
    sg13g2_xor2_1 u_p1 (.X(w_p[1]), .A(ui_in[1]), .B(ui_in[5]));
    sg13g2_xor2_1 u_s1 (.X(w_sum[1]), .A(w_p[1]), .B(w_c[1]));
    sg13g2_and2_1 u_g1 (.X(w_g[1]), .A(ui_in[1]), .B(ui_in[5]));
    sg13g2_a21o_1 u_c1 (.X(w_c[2]), .A1(w_c[1]),  .A2(w_p[1]), .B1(w_g[1]));

    // --- Bit 2 ---
    sg13g2_xor2_1 u_p2 (.X(w_p[2]), .A(ui_in[2]), .B(ui_in[6]));
    sg13g2_xor2_1 u_s2 (.X(w_sum[2]), .A(w_p[2]), .B(w_c[2]));
    sg13g2_and2_1 u_g2 (.X(w_g[2]), .A(ui_in[2]), .B(ui_in[6]));
    sg13g2_a21o_1 u_c2 (.X(w_c[3]), .A1(w_c[2]),  .A2(w_p[2]), .B1(w_g[2]));

    // --- Bit 3 ---
    sg13g2_xor2_1 u_p3 (.X(w_p[3]), .A(ui_in[3]), .B(ui_in[7]));
    sg13g2_xor2_1 u_s3 (.X(w_sum[3]), .A(w_p[3]), .B(w_c[3]));
    sg13g2_and2_1 u_g3 (.X(w_g[3]), .A(ui_in[3]), .B(ui_in[7]));
    sg13g2_a21o_1 u_c3 (.X(w_c[4]), .A1(w_c[3]),  .A2(w_p[3]), .B1(w_g[3]));

    // --- Sorties ---
    assign uo_out[0] = w_sum[0];
    assign uo_out[1] = w_sum[1];
    assign uo_out[2] = w_sum[2];
    assign uo_out[3] = w_sum[3];
    assign uo_out[4] = w_c[4];
    assign uo_out[5] = w_lo;
    assign uo_out[6] = w_lo;
    assign uo_out[7] = w_lo;

    sg13g2_tielo u_tie_uio_out0 (.L_LO(uio_out[0]));
    sg13g2_tielo u_tie_uio_out1 (.L_LO(uio_out[1]));
    sg13g2_tielo u_tie_uio_out2 (.L_LO(uio_out[2]));
    sg13g2_tielo u_tie_uio_out3 (.L_LO(uio_out[3]));
    sg13g2_tielo u_tie_uio_out4 (.L_LO(uio_out[4]));
    sg13g2_tielo u_tie_uio_out5 (.L_LO(uio_out[5]));
    sg13g2_tielo u_tie_uio_out6 (.L_LO(uio_out[6]));
    sg13g2_tielo u_tie_uio_out7 (.L_LO(uio_out[7]));

    sg13g2_tielo u_tie_uio_oe0 (.L_LO(uio_oe[0]));
    sg13g2_tielo u_tie_uio_oe1 (.L_LO(uio_oe[1]));
    sg13g2_tielo u_tie_uio_oe2 (.L_LO(uio_oe[2]));
    sg13g2_tielo u_tie_uio_oe3 (.L_LO(uio_oe[3]));
    sg13g2_tielo u_tie_uio_oe4 (.L_LO(uio_oe[4]));
    sg13g2_tielo u_tie_uio_oe5 (.L_LO(uio_oe[5]));
    sg13g2_tielo u_tie_uio_oe6 (.L_LO(uio_oe[6]));
    sg13g2_tielo u_tie_uio_oe7 (.L_LO(uio_oe[7]));

endmodule

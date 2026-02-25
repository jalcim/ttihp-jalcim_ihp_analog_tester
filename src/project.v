/*
 * Copyright (c) 2026 jalcim
 * SPDX-License-Identifier: Apache-2.0
 *
 * Wrapper Tiny Tapeout — Additionneur 4-bit ripple carry
 *
 * Pinout :
 *   ui_in[3:0]  = A[3:0]
 *   ui_in[7:4]  = B[3:0]
 *   uio_in[0]   = Cin
 *   uo_out[3:0] = Sum[3:0]
 *   uo_out[4]   = Cout
 *   uo_out[7:5] = 0
 */

`default_nettype none

module tt_um_jalcim_adder4b (
    input  wire       VGND,
    input  wire       VDPWR,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    inout  wire [7:0] ua,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [3:0] w_sum;
    wire       w_cout;

    adder_4b u_adder (
        .i_a   (ui_in[3:0]),
        .i_b   (ui_in[7:4]),
        .i_cin (uio_in[0]),
        .o_sum (w_sum),
        .o_cout(w_cout)
    );

    assign uo_out  = {3'b000, w_cout, w_sum};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

endmodule

// Copyright (C) 2022  Ewen Crawford
`timescale 1ns / 1ps

module metaball #(
    parameter WIDTH = 32'h000f_8000, // Display width - 1 (x-axis) = 31
    parameter HEIGHT = 32'h000f_c000, // Display height - 1 (y-axis) = 63
    parameter RAD = 32'h0001_4000, // Initial radius = 2.5
    parameter I_X = 32'h0007_c000, // Initial x-position = 15.5 (centered)
    parameter I_Y = 32'h0000_0000, // Initial y-position = 0 (bottom)
    // Speed hardcoded for 60 Hz update rate
    parameter IV_X = 32'h0000_0000, // Initial x-speed = 0 px/cycle (0 px/s)
    parameter IV_Y = 32'h0000_0333 // Initial y-speed = 0.025 px/cycle (1.5 px/s)
  )(
    input clk,
    input rst,
    input mov_en, // Move enable; update position when high
    input px_stb, // New pixel strobe signal (begins output calculation)
    input int p_x, // Pixel sample x-position
    input int p_y, // Pixel sample y-position
    output logic vld, // Output calculation is complete
    output logic [31:0] out // Output contribution to the sample weighting
  );
  logic [31:0] x = I_X, y = I_Y; // Position
  logic [31:0] v_x = IV_X, v_y = IV_Y;
  // Since the adders are combinatorial and are driven by any change in the
  // addends, we cannot directly increment the given coordinate by its
  // associated speed as this would cause an infinite feedback loop. Instead,
  // we introduce a buffer register to hold the incremented value and only
  // store this in the source coordinate register once per update cycle.
  logic [31:0] x_next, y_next;
  qadd #(15, 32) sum_x(.a(x), .b(v_x), .c(x_next));
  qadd #(15, 32) sum_y(.a(y), .b(v_y), .c(y_next));

  always_ff @ (posedge clk) begin
    if (rst) begin
      x <= I_X;
      y <= I_Y;
    end else begin
      if (mov_en) begin
	x <= x_next;
	y <= y_next;
	// Toggle speed sign bits when bounds of display are reached
	if (x_next >= WIDTH | x_next <= 0) v_x[31] = ~v_x[31];
	if (y_next >= HEIGHT | y_next <= 0) v_y[31] = ~v_y[31];
      end
    end
  end
endmodule

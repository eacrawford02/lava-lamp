// Copyright (C) 2022  Ewen Crawford
`timescale 1ns / 1ps

`ifndef MAX
`define MAX(a, b) ((a) > (b) ? (a) : (b))
`endif

`ifndef MIN
`define MIN(a, b) ((a) > (b) ? (b) : (a))
`endif

module metaball #(
    parameter WIDTH  = 32'h000f_8000, // Display width - 1 (x-axis) = 31
    parameter HEIGHT = 32'h001f_8000, // Display height - 1 (y-axis) = 63
    parameter RAD    = 32'h0001_4000, // Initial radius = 2.5
    parameter I_X    = 32'h0007_c000, // Initial x-position = 15.5 (centered)
    parameter I_Y    = 32'h000f_8000, // Initial y-position = 31 (centered)
    // Speed hardcoded for 60 Hz update rate
    parameter IV_X   = 32'h0000_0000, // Initial x-speed = 0 px/cycle (0 px/s)
    parameter IV_Y   = 32'h0000_0333  // Initial y-speed = 0.025 px/cycle 
				      // (1.5 px/s)
  )(
    input               clk,
    input               rst,
    input               mov_en, // Move enable; update position when high
    input               px_stb, // New pixel strobe signal (begins output 
                                // calculation)
    input int           p_x,    // Pixel sample x-position
    input int           p_y,    // Pixel sample y-position
    output logic        vld,    // Output calculation is complete. Stays high 
                                // until px_stb is driven high
    output logic [31:0] out     // Output contribution to the sample weighting
  );

  // Position
  logic [31:0] x      = `MAX(RAD + 32'h1, `MIN(I_X, WIDTH - RAD - 32'h1)),
	       y      = `MAX(RAD + 32'h1, `MIN(I_Y, HEIGHT - RAD - 32'h1)),
	       next_x = I_X + IV_X,
	       next_y = I_Y + IV_Y;
  // Speed
  logic [31:0] v_x = IV_X,
	       v_y = IV_Y;

  // For all addition/subtraction operations, we assume the numbers are
  // unsigned, i.e., the lower bounds of the coordinate system is 0 (no
  // negative positions)
  wire [31:0] dx, dy, dx_abs, dy_abs, dx_sq, dy_sq;
  // Because the qmult module doesn't use the sign bits of the multiplicand or
  // multiplier (dx[31] and dy[31] in this case), Vivado may throw a warning
  // that p_x[31] and p_y[31] are unconnected. This is to be expected
  assign dx = p_x - x;
  assign dy = p_y - y;
  // The qmult module can't do signed multiplication correctly
  assign dx_abs = dx[31] ? ~dx + 1 : dx;
  assign dy_abs = dy[31] ? ~dy + 1 : dy;

  wire [63:0] rad_sq;
  wire [31:0] dividend, divisor;
  assign rad_sq = RAD * RAD;
  assign dividend = rad_sq[45:15];

  qmult #(15,32) sq1(
    .i_multiplicand(dx_abs),
    .i_multiplier(dx_abs),
    .o_result(dx_sq),
    .ovr()
  );
  qmult #(15,32) sq2(
    .i_multiplicand(dy_abs),
    .i_multiplier(dy_abs),
    .o_result(dy_sq),
    .ovr()
  );
  assign divisor = dx_sq + dy_sq;
  qdiv #(15,32) func(
    .i_dividend(dividend),
    .i_divisor(divisor),
    .i_start(px_stb),
    .i_clk(clk),
    .o_quotient_out(out),
    .o_complete(vld),
    .o_overflow()
  );
  
  always_ff @ (posedge clk) begin
    if (rst) begin
      x <= I_X;
      y <= I_Y;
      next_x <= I_X + IV_X;
      next_y <= I_Y + IV_Y;
    end else begin
      if (mov_en) begin
	x <= next_x;
	y <= next_y;
	// Negate speed vectors when bounds of display are reached and prevent
	// metaball from getting stuck outside bounds
	if (next_x >= (WIDTH - RAD) || next_x <= RAD) begin
	  v_x <= ~v_x + 1;
	  next_x <= x;
	end else begin
	  next_x <= x + v_x;
	end
	if (next_y >= (HEIGHT - RAD) || next_y <= RAD) begin
	  v_y <= ~v_y + 1;
	  next_y <= y;
	end else begin
	  next_y <= y + v_y;
	end
      end
    end
  end
endmodule

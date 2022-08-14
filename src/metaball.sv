`timescale 1ns / 1ps

module metaball #(
    parameter WIDTH = 32, // Display width (x-axis)
    parameter HEIGHT = 64, // Display height (y-axis)
    parameter RAD = 8'h0001_4000, // Initial radius = 2.5
    parameter I_X = 8'h0007_c000, // Initial x-position = 15.5 (centered)
    parameter I_Y = 8'h0000_0000, // Initial y-position = 0 (bottom)
    // Speed hardcoded for 60 Hz update rate
    parameter IV_X = 8'h0000_0000, // Initial x-speed = 0 px/cycle (0 px/s)
    parameter IV_Y = 8'h0000_0333 // Initial y-speed = 0.025 px/cycle (1.5 px/s)
  )(
    input clk,
    input mov_en, // Move enable; update position when high
    input int p_x, // Pixel sample x-position
    input int p_y, // Pixel sample y-position
    output logic [31:0] out // Output contribution to the sample weighting
  );
  logic [31:0] x = I_X, y = I_Y; // Position
  // Movement states for x- and y-dimensions
  localparam ADD = 0, // Add to position coordinate
	     SUB = 1; // Subtract from position coordinate
  logic mov_x = ADD,
	mov_y = ADD;
endmodule

// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps
module dspl_ctrl (
    input clk,
    input rst,
    input [11:0] din_top,
    input [11:0] din_btm,
    output logic [9:0] r_addr,
    output sclk,
    output logic latch,
    output logic blank,
    output logic [2:0] dout_top,
    output logic [2:0] dout_btm,
    output logic [3:0] row_sel
);
  localparam BLANK = 0, LATCH = 1, SHIFT = 3, WAIT = 2;
  logic [1:0] state;

  logic [11:0] timer;

  logic [1:0] bit_sel;

  // The start of the clock cycle (when sclk is 0) is preceded by the end of
  // the previous clock cycle (when sclk was 1, i.e., prev_sclk is 1)
  logic prev_sclk = 1;
  logic [1:0] clk_div = 0;
  assign sclk = clk_div[1];

  // Assign the output RGB to the LSB of each component in the input data plus
  // the bit select offset
  assign dout_top[0] = din_top[0 + bit_sel];
  assign dout_top[1] = din_top[4 + bit_sel];
  assign dout_top[2] = din_top[8 + bit_sel];
  assign dout_btm[0] = din_btm[0 + bit_sel];
  assign dout_btm[1] = din_btm[4 + bit_sel];
  assign dout_btm[2] = din_btm[8 + bit_sel];

  always_ff @ (posedge clk) begin
    if (rst) begin
      state <= SHIFT;
      timer <= 255;
      bit_sel <= 0;
      latch <= 0;
      blank <= 1; // Leave display blanked until initial data is shifted in
      row_sel <= 0;
      prev_sclk <= 1;
      clk_div <= 0;
      r_addr <= 0;
    end else begin
      case (state)
	SHIFT: begin
	  if (timer == 0) begin
	    case (bit_sel)
	      1: begin
		state <= WAIT;
		timer <= 255;
		r_addr <= r_addr - 63;
	      end
	      2: begin
		state <= WAIT;
		timer <= 767; // 256*2^n-256
		r_addr <= r_addr - 63;
	      end
	      3: begin
		state <= WAIT;
		timer <= 1791;
		r_addr <= r_addr + 1;
	      end
	      default: begin
		state <= BLANK;
		timer <= 4;
		blank <= 1;
		r_addr <= r_addr - 63;
	      end
	    endcase
	  end else begin
	    timer <= timer - 1;
	    if (prev_sclk & sclk) begin
	      r_addr <= r_addr + 1;
	    end
	  end
	  // Increment sclk outside of if-else so that it rolls over during
	  // the final cycle of clk for the SHIFT state
	  clk_div <= clk_div + 1;
	  prev_sclk <= sclk;
	end
	BLANK: begin
	  if (timer == 0) begin
	    state <= LATCH;
	    timer <= 1;
	    latch <= 1;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	LATCH: begin
	  if (timer == 0) begin
	    state <= SHIFT;
	    timer <= 255;
	    latch <= 0; // Deassert latch signal and unblank display
	    blank <= 0; // Display current data while shifting in new data
	    bit_sel <= bit_sel + 1;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	WAIT: begin
	  if (timer == 0) begin
	    state <= BLANK;
	    timer <= 4;
	    blank <= 1;
	    if (bit_sel == 3) begin
	      // Increment row after highest bit for last column is reached
	      row_sel <= row_sel + 1;
	    end
	  end else begin
	    timer <= timer - 1;
	  end
	end
	default: begin
	  state <= SHIFT;
	  timer <= 255;
	  bit_sel <= 0;
	  latch <= 0;
	  blank <= 1; // Leave display blanked until initial data is shifted in
	  row_sel <= 0;
	  prev_sclk <= 1;
	  clk_div <= 0;
	  r_addr <= 0;
	end
      endcase
    end
  end
endmodule

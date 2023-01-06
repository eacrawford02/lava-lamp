// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps

module dspl_ctrl #(
    parameter CLK_FRAC   = 8,
    parameter MIN_WAIT   = 512, // Minimum number of clock cycles to shift data
			        // into display
    parameter SREG_WIDTH = 64,
    parameter LATCH_TIME = 4,
    parameter BLANK_TIME = 5
  )(
    input		clk,
    input		rst,
    input	 [11:0] din_top,
    input	 [11:0] din_btm,
    output logic [9:0]	r_addr,
    output		sclk,
    output logic        latch,
    output logic	blank,
    output logic [2:0]	dout_top,
    output logic [2:0]	dout_btm,
    output logic [3:0]	row_sel
);
  localparam BLANK = 0,
	     LATCH = 1,
	     SHIFT = 3,
	     WAIT  = 2;
  
  logic [1:0]  state;
  logic [12:0] timer;
  logic [1:0]  bit_sel;

  // The start of the clock cycle (when sclk is 0) is preceded by the end of
  // the previous clock cycle (when sclk was 1, i.e., prev_sclk is 1)
  logic prev_sclk = 0;
  logic [$clog2(CLK_FRAC)-1:0] clk_div = 0;
  assign sclk = clk_div[$clog2(CLK_FRAC)-1]; // Grab MSB of clock divider

  // Assign the output RGB to the LSB of each component in the input data plus
  // the bit select offset
  assign dout_top[0] = din_top[8 + bit_sel];
  assign dout_top[1] = din_top[4 + bit_sel];
  assign dout_top[2] = din_top[0 + bit_sel];
  assign dout_btm[0] = din_btm[8 + bit_sel];
  assign dout_btm[1] = din_btm[4 + bit_sel];
  assign dout_btm[2] = din_btm[0 + bit_sel];

  always_ff @ (posedge clk) begin
    if (rst) begin
      state <= SHIFT;
      timer <= MIN_WAIT - 1;
      bit_sel <= 0;
      latch <= 0;
      blank <= 1; // Leave display blanked until initial data is shifted in
      row_sel <= 15;
      prev_sclk <= 0;
      clk_div <= 0;
      r_addr <= 0;
    end else begin
      prev_sclk <= sclk;
      case (state)
	SHIFT: begin
	  if (timer == 0) begin
	    // Note that we determine the wait time (if any) based on the
	    // PREVIOUS data shifted in (i.e., if bit_sel == 3, that means we 
	    // are currently displaying the data corresponding a bit_sel value
	    // of 2
	    case (bit_sel)
	      1: begin
		state <= BLANK;
		timer <= BLANK_TIME - 1;
		blank <= 1;
		r_addr <= r_addr - (SREG_WIDTH - 1);
	      end
	      2: begin
		state <= WAIT;
		timer <= MIN_WAIT - 1;
		r_addr <= r_addr - (SREG_WIDTH - 1);
	      end
	      3: begin
		state <= WAIT;
		timer <= MIN_WAIT * $pow(2, 2) - MIN_WAIT - 1; // 512*2^n-512
		r_addr <= r_addr + 1;
	      end
	      default: begin
		state <= WAIT;
		timer <= MIN_WAIT * $pow(2, 3) - MIN_WAIT - 1;
		r_addr <= r_addr - (SREG_WIDTH - 1);
	      end
	    endcase
	  end else begin
	    timer <= timer - 1;
	    // Initiate new memory read on falling edge of sclk cycle so that 
	    // data is stable by second quarter of sclk cycle (before rising 
	    // edge)
	    if (prev_sclk & !sclk) r_addr <= r_addr + 1;
	  end
	  // Increment sclk outside of if-else so that it rolls over during
	  // the final cycle of clk for the SHIFT state
	  clk_div <= clk_div + 1;
	end
	BLANK: begin
	  if (timer == 0) begin
	    state <= LATCH;
	    timer <= LATCH_TIME - 1;
	    latch <= 1;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	LATCH: begin
	  if (timer == 0) begin
	    state <= SHIFT;
	    timer <= MIN_WAIT - 1;
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
	    timer <= BLANK_TIME - 1;
	    blank <= 1;
	    // Increment row after highest bit for last column is *displayed*
	    if (bit_sel == 0) row_sel <= row_sel + 1;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	default: begin
	  state <= SHIFT;
	  timer <= MIN_WAIT - 1;
	  bit_sel <= 0;
	  latch <= 0;
	  blank <= 1; // Leave display blanked until initial data is shifted in
	  // Start at row 16 to account for row_sel increment in wait state 
	  // after initial data (row 0) is shifted in
	  row_sel <= 15;
	  prev_sclk <= 0;
	  clk_div <= 0;
	  r_addr <= 0;
	end
      endcase
    end
  end
endmodule

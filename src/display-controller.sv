// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps
module dspl_ctrl (
    input clk,
    input rst,
    input [11:0] din_top,
    input [11:0] din_btm,
    output [9:0] r_addr,
    output sclk,
    output latch,
    output blank,
    output [2:0] dout_top,
    output [2:0] dout_btm,
    output [3:0] row_sel
);
  localparam BLANK = 0, LATCH = 1, SHIFT = 3, WAIT = 2;
  logic [1:0] state;

  logic [11:0] timer;
  logic [11:0] wait_timer;

  logic [1:0] bit_sel;

  always_ff @ (posedge clk) begin
    if (rst) begin
    end else begin
      case (state)
	SHIFT: begin
	  if (timer == 0) begin
	    case (bit_sel)
	      1: begin
		state <= WAIT;
		timer <= 255;
	      end
	      2: begin
		state <= WAIT;
		timer <= 511;
	      end
	      3: begin
		state <= WAIT;
		timer <= 1023;
	      end
	      default: begin
		state <= BLANK;
		timer <= 4;
	      end
	    endcase
	    bit_sel <= bit_sel + 1;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	BLANK: begin
	  if (timer == 0) begin
	    state <= LATCH;
	    timer <= 1;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	LATCH: begin
	  if (timer == 0) begin
	    state <= SHIFT;
	    timer <= 255;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	WAIT: begin
	  if (timer == 0) begin
	    state <= BLANK;
	    timer <= 4;
	  end else begin
	    timer <= timer - 1;
	  end
	end
	default: begin
	  state <= SHIFT;
	  timer <= 255;
	  bit_sel <= 0;
	  wait_timer <= 0;
	end
      endcase
    end
  end
endmodule

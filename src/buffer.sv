// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps
module buffer (
    input		clk,
    input		rst,
    input		en,
    input		swap_en,
    input		w_en,
    input  logic [9:0]  addr,
    input  logic [11:0] din,
    output logic [11:0] dout
);
  logic [11:0] buff_a [1023:0];
  logic [11:0] buff_b [1023:0];
  logic cur_buff = 0;

  always_ff @ (posedge clk) begin
    if (en) begin
      if (swap_en) begin
	cur_buff <= ~cur_buff;
      end
      // Write to current buffer, swap_en must settle before writes reflect
      // buffer swap (i.e., must wait until next clock edge to write to new
      // buffer)
      if (w_en) begin
	case (cur_buff)
	  0: buff_a[addr] <= din;
	  1: buff_b[addr] <= din;
	endcase
	dout <= din; // Write first
      end
    end else begin
      dout <= ~cur_buff ? buff_a[addr] : buff_b[addr];
    end
  end
endmodule

// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps
module buffer (
    input		clk,
    input		en,
    input		swap_en,
    input		w_en,
    input  logic [9:0]  addr,
    input  logic [11:0] din,
    output logic [11:0] dout
);

  logic [11:0] a_out,
               b_out;
  logic        w_en_a,
               w_en_b;
  logic        cur_buff = 0;

  assign w_en_a = w_en & ~cur_buff;
  assign w_en_b = w_en & cur_buff;

  bram_sp_rf buff_a (
    .clk(clk),
    .en(en),
    .w_en(w_en_a),
    .addr(addr),
    .din(din),
    .dout(a_out)
  );

  bram_sp_rf buff_b (
    .clk(clk),
    .en(en),
    .w_en(w_en_b),
    .addr(addr),
    .din(din),
    .dout(b_out)
  );
  

  always_ff @ (posedge clk) begin
      if (en & swap_en) cur_buff <= ~cur_buff;
  end

  // Opposite of what the current buffer should be
  assign dout = cur_buff ? a_out : b_out;
endmodule

module bram_sp_rf (
  input		      clk,
  input		      en,
  input		      w_en,
  input  logic [9:0]  addr,
  input  logic [11:0] din,
  output logic [11:0] dout
);
  logic [11:0] bram [1023:0];

  always_ff @ (posedge clk) begin
    if (en) begin
      if (w_en) bram[addr] <= din;
      dout <= bram[addr]; // Read-first
    end
  end
endmodule

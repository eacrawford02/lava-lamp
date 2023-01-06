// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps
module buffer (
    input	  clk,
    input	  en,
    input	  swap_en,
    input	  w_en,
    input  [9:0]  w_addr,
    input  [9:0]  r_addr,
    input  [11:0] din,
    output [11:0] dout
);

  wire         w_en_a,
               w_en_b;
  logic [9:0]  addr_a,
               addr_b;
  wire  [11:0] a_out,
               b_out;
  logic [1:0]  cur_buff = 0;

  assign w_en_a = w_en & ~cur_buff;
  assign w_en_b = w_en & cur_buff;

  bram_sp_rf buff_a (
    .clk(clk),
    .en(en),
    .w_en(w_en_a),
    .addr(addr_a),
    .din(din),
    .dout(a_out)
  );

  bram_sp_rf buff_b (
    .clk(clk),
    .en(en),
    .w_en(w_en_b),
    .addr(addr_b),
    .din(din),
    .dout(b_out)
  );
  
  always_comb begin
    if (cur_buff[0]) begin
      addr_a <= r_addr;
      addr_b <= w_addr;
    end else begin
      addr_a <= w_addr;
      addr_b <= r_addr;
    end
  end

  always_ff @ (posedge clk) begin
    // It takes one cycle for BRAM output to reflect r/w address change. We
    // use cur_buff as a sort of shift register to account for this delay and
    // ensure that the expected output is produced following a swap
    if (en & swap_en) begin
      cur_buff <= {cur_buff[0], ~cur_buff[1]};
    end else begin
      cur_buff <= {2{cur_buff[0]}};
    end
  end

  // Opposite of what the current buffer should be
  assign dout = cur_buff[1] ? a_out : b_out;
endmodule

module bram_sp_rf (
  input		      clk,
  input		      en,
  input		      w_en,
  input        [9:0]  addr,
  input        [11:0] din,
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

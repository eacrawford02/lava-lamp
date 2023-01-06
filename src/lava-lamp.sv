// Copyright (C) 2022  Ewen Crawford
`timescale 1ns / 1ps

module lava_lamp #(
    parameter WIDTH  = 32'h000f_8000, // Display width - 1 (x-axis) = 31
    parameter HEIGHT = 32'h001f_8000 // Display height - 1 (y-axis) = 63
  )(
    input        clk,
    input        rst_n,
    output       sclk,
    output       latch,
    output       blank,
    output [2:0] dout_top,
    output [2:0] dout_btm,
    output [3:0] row_sel
  );
  
  wire rst = !rst_n;

  // Generate 60 Hz movement enable strobe signal.
  // 2^32 / (100E6 / 60) = 2576.98 ~= 0xa11
  logic [31:0] cnt = 0;
  logic mov_stb = 0;
  always_ff @ (posedge clk) {mov_stb, cnt} <= cnt + 12'ha11;
  
  logic px_stb = 1;
  // Current pixel being sampled; shared by all metaballs
  logic [31:0] p_x = 0,
	       p_y = 0;

  logic mb1_vld; // Note that valid signals stay high until px_stb is asserted
  logic [31:0] mb1_out;
  metaball #(
    .I_Y(32'h0002_8000),
    .IV_Y(32'h0000_0666),
    .RAD(32'h0002_8000)
  ) mb1 (
    .clk(clk),
    .rst(rst),
    .mov_en(mov_stb),
    .px_stb(px_stb),
    .p_x(p_x),
    .p_y(p_y),
    .vld(mb1_vld),
    .out(mb1_out)
  );

  logic mb2_vld;
  logic [31:0] mb2_out;
  metaball #(
    .I_Y(32'h001d_0000),
    .IV_Y(32'hffff_f99a),
    .RAD(32'h0002_8000)
  ) mb2 (
    .clk(clk),
    .rst(rst),
    .mov_en(mov_stb),
    .px_stb(px_stb),
    .p_x(p_x),
    .p_y(p_y),
    .vld(mb2_vld),
    .out(mb2_out)
  );
  
  logic [31:0] sum;
  assign sum = mb1_out + mb2_out;

  logic	en       = 1,
	swap_en  = 0,
	w_en     = 0,
	w_mask   = 1;
  wire  top_w_en = w_en & ~w_mask, // Write to top ram when write mask is 0 
        btm_w_en = w_en & w_mask; // Write to bottom ram when write mask is 1
  logic [9:0]  w_addr = 1023;
  wire  [9:0]  r_addr;
  logic [11:0] din;
  wire  [11:0] dout_top_buff, dout_btm_buff;

  buffer top_buff(
    .clk(clk),
    .en(en),
    .swap_en(swap_en),
    .w_en(top_w_en),
    .w_addr(w_addr),
    .r_addr(r_addr),
    .din(din),
    .dout(dout_top_buff)
  );
  
  buffer btm_buff(
    .clk(clk),
    .en(en),
    .swap_en(swap_en),
    .w_en(btm_w_en),
    .w_addr(w_addr),
    .r_addr(r_addr),
    .din(din),
    .dout(dout_btm_buff)
  );

  dspl_ctrl ctrl(
    .clk(clk),
    .rst(rst),
    .din_top(dout_top_buff),
    .din_btm(dout_btm_buff),
    .r_addr(r_addr),
    .sclk(sclk),
    .latch(latch),
    .blank(blank),
    .dout_top(dout_top),
    .dout_btm(dout_btm),
    .row_sel(row_sel)
  );

  always_ff @ (posedge clk) begin
    if (rst) begin
      p_x <= '0;
      p_y <= '0;
      px_stb <= 0;
      swap_en <= 0;
      w_en <= 0;
      w_mask <= 1;
      w_addr <= 1023;
    end else begin
      // Note that there is a 1 cycle delay between asserting px_stb and the
      // valid signals falling
      if (mb1_vld & mb2_vld & ~px_stb) begin
	// Advance pixel position, wrapping around if display boundaries are
	// reached
	if (p_y >= HEIGHT) begin
	  p_y <= '0;
	  if (p_x >= WIDTH) begin
	    p_x <= '0;
	    swap_en <= 1; // Swap buffer
	  end else begin
	    p_x <= p_x + 32'h0000_8000;
	  end
	end else begin
	  p_y <= p_y + 32'h0000_8000;
	  swap_en <= 0;
	end
	px_stb <= 1; // Tell metaballs to begin calculation for new pixel
	// Write output to memory
	w_en <= 1;
	w_addr <= w_addr + 1;
	if (w_addr == 1023) w_mask <= ~w_mask;
	if (sum >= 32'h0000_8000) begin
	  din <= '1; // R = 1, G = 1, B = 1 (white);
	end else begin
	  din <= 0;
	end
      end else begin
	// Ensure that the strobe and enable signals only stay high for
	// a signle cycle
	px_stb <= 0;
	swap_en <= 0;
	w_en <= 0;
      end
    end
  end
endmodule

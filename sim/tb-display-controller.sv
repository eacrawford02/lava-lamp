// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps

module tb_dspl_ctrl (
    input event start,
    input event done
);
  logic clk = 0,
	rst = 0;
  logic [11:0] din_top, din_btm;
  logic [9:0] r_addr;
  logic sclk, latch, blank;
  logic [2:0] dout_top, dout_btm;
  logic [3:0] row_sel;

  always #5 clk <= ~clk; // 100 MHz clock

  dspl_ctrl dut(
    .clk(clk),
    .rst(rst),
    .din_top(din_top),
    .din_btm(din_btm),
    .r_addr(r_addr),
    .sclk(sclk),
    .latch(latch),
    .blank(blank),
    .dout_top(dout_top),
    .dout_btm(dout_btm),
    .row_sel(row_sel)
  );

  initial begin
    wait (start.triggered);
    $display("=== DISPLAY CONTROLLER TEST STARTED ===");
    $display("=== DISPLAY CONTROLLER TEST FINISHED ===");
    #38400;
    ->done;
  end
endmodule

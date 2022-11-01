// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps

module tb_dspl_ctrl (
    input event start,
    input event done
);
  logic clk = 0,
	rst = 0;
  logic [11:0] din_top = 0, din_btm = 0;
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

  logic [9:0] prev_r_addr = 0;
  always @ (posedge clk) begin
    if (prev_r_addr != r_addr) begin
      din_top <= din_top + 1;
      din_btm <= din_btm + 1;
    end
    prev_r_addr <= r_addr;
  end

  initial begin
    wait (start.triggered);
    $display("=== DISPLAY CONTROLLER TEST STARTED ===");
    #618880;
    $display("=== DISPLAY CONTROLLER TEST FINISHED ===");
    ->done;
  end
endmodule

bind tb_dspl_ctrl.dut dspl_ctrl_assertions sva(
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
  .row_sel(row_sel),
  .state(state),
  .timer(timer),
  .bit_sel(bit_sel)
);

module dspl_ctrl_assertions (
  input clk,
  input rst,
  input [11:0] din_top,
  input [11:0] din_btm,
  input logic [9:0] r_addr,
  input sclk,
  input logic latch,
  input logic blank,
  input logic [2:0] dout_top,
  input logic [2:0] dout_btm,
  input logic [3:0] row_sel,
  input logic [1:0] state,
  input logic [11:0] timer,
  input logic [1:0] bit_sel
);
  // Assert that the display wait times are correct for binary coded
  // modulation
  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : bit_sel_assert
      prop_bit_sel: assert property (
	@ (posedge clk) disable iff (rst)
	(bit_sel != $past(bit_sel, 1) & bit_sel == i) |-> (##1 $stable(bit_sel)[*(256 * $pow(2, i) + 5 + 2 - 1)] ##1 !$stable(bit_sel))
      );
    end
  endgenerate

  // Assert that bit_sel signal is incremented whenever it changes (barring
  // wrap-around-to-0 case)
  prop_bit_sel_incr: assert property (
    @ (posedge clk) disable iff (rst)
    !$stable(bit_sel) & bit_sel > 0 |-> bit_sel == $past(bit_sel, 1) + 1
  );

  // Assert that sclk starts when the shift state is entered that the sclk 
  // frequency is correct (1/4 of the source clock frequency)
  prop_sclk_on: assert property (
    @ (posedge clk) disable iff (rst)
    (!$stable(state) & state == dut.SHIFT) |-> (!sclk ##1 !sclk ##1 sclk ##1 sclk)[*64]
  );

  // Assert that sclk stops when no longer in the shift state
  prop_sclk_off: assert property (
    @ (posedge clk) disable iff (rst)
    (state != dut.SHIFT) |-> !sclk
  );

  // Assert 3 ns setup time and 5 ns hold time for output data changes
  prop_dout_top: assert property (
    @ (posedge clk) disable iff (rst)
    !$stable(dout_top) |-> !sclk[*0:$] ##1 $rose(sclk) & $stable(dout_top)[*0:$]
  );
  
  prop_dout_btm: assert property (
    @ (posedge clk) disable iff (rst)
    !$stable(dout_btm) |-> !sclk[*0:$] ##1 $rose(sclk) & $stable(dout_btm)[*0:$]
  );

  // Assert latch signal goes high during latch state with a 20 ms pulse width
  prop_latch_on: assert property (
    @ (posedge clk) disable iff (rst)
    (!$stable(state) & state == dut.LATCH) |-> $rose(latch) ##2 $fell(latch)
  );

  // Assert latch signal remains low while not in latch state
  prop_latch_off: assert property (
    @ (posedge clk) disable iff (rst)
    (state != dut.LATCH) |-> !latch
  );

  // Assert 5 ns setup time and 30 ns hold time for latch signal
  prop_latch_su_h: assert property (
    @ (posedge clk) disable iff (rst)
    $fell(latch) |-> !latch[*0:$] ##1 $rose(sclk) ##1 !latch[*3:$]
  );

  // Assert blank signal goes high during blank state with a 70 ms pulse width
  prop_blank_on: assert property (
    @ (posedge clk) disable iff (rst)
    (!$stable(state) & state == dut.BLANK) |-> blank ##7 !blank
  );

  // Assert blank signal remains low while not in blank state except for when
  // initially shifting in data at startup (takes 256 cycles)
  prop_blank_off: assert property (
    @ (posedge clk) disable iff (rst)
    (state != dut.BLANK & state != dut.LATCH) & $time > 2565 |-> !blank
  );

  // Assert that row select signal is held stable for the correct number of
  // cycles then immediately followed by a change.
  // We specify a range because the blank/latch states are initially skipped
  // in the sequence following a reset
  prop_row_sel: assert property (
    @ (posedge clk) disable iff (rst)
    !$stable(row_sel) |-> ##1 $stable(row_sel)[*3861 - 1:3868 - 1] ##1 !$stable(row_sel)
  );

  // Assert that row select signal is incremented whenever it changes (barring
  // wrap-around-to-0 case)
  prop_row_incr: assert property (
    @ (posedge clk) disable iff (rst)
    !$stable(row_sel) & row_sel > 0 |-> row_sel == $past(row_sel, 1) + 1
  );
endmodule

// Copywrite (C) 2022 Ewen Crawford
`timescale 1ns / 1ps

module tb_buffer #(
    parameter DATA_RANGE = 4096,
    parameter RAM_DEPTH = 1024
)(
    input event start,
    input event done
);
  logic clk     = 0,
	rst     = 0,
	en      = 0,
	swap_en = 0,
	w_en    = 0;
  logic [9:0]  addr;
  logic [11:0] din,
	       dout;

  always #10 clk <= ~clk;

  buffer dut(
    .clk(clk),
    .rst(rst),
    .en(en),
    .swap_en(swap_en),
    .w_en(w_en),
    .addr(addr),
    .din(din),
    .dout(dout)
  );

  logic [9:0] gen_addr;
  logic [11:0] gen_data;
  string status;

  initial begin
    wait (start.triggered);
    $display("=== BUFFER TEST STARTED ===");
    $display("Address\tExpected\tActual\tStatus");
    // Drive test signals in sync with clock
    @ (posedge clk);
    // Write data then signal buffer swap
    en = 1;
    w_en = 1;
    gen_addr = $urandom_range(0, RAM_DEPTH-1);
    addr = gen_addr;
    gen_data = $urandom_range(0, DATA_RANGE-1);
    din = gen_data;
    swap_en = 1;
    // Deassert signals and check output after buffer swap
    @ (posedge clk);
    en = 0;
    w_en = 0;
    swap_en = 0;
    if (dout == gen_data) status = "PASS";
    else status = "FAIL";
    $display("%h\t%h\t\t%h\t%s", addr, gen_data, dout, status);
    $display("=== BUFFER TEST FINISHED ===");
    ->done;
  end
endmodule
